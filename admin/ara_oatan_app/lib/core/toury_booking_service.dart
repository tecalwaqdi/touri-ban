import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/app_state.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/toury_location_service.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_pricing.dart';

class TouryCashBookingResult {
  const TouryCashBookingResult({
    required this.success,
    this.orderId,
    this.error,
    this.viaFallback = false,
  });

  final bool success;
  final String? orderId;
  final String? error;
  final bool viaFallback;
}

String touryCashOrderDocId(String uid, String idempotencyKey) {
  return sha256.convert(utf8.encode('$uid:cash:$idempotencyKey')).toString();
}

bool _isMissingCallable(Map<String, dynamic> data) {
  final code = (data['code'] ?? '').toString().toLowerCase();
  final error = (data['error'] ?? '').toString().toLowerCase();
  return code.contains('not-found') ||
      code.contains('not_found') ||
      error.contains('not-found') ||
      error.contains('not found') ||
      error.contains('not_found');
}

/// Direct Firestore cash create when CF is missing (no Blaze) or unreachable.
bool _isUndeployedOrUnavailableCallable(Map<String, dynamic> data) {
  if (_isMissingCallable(data)) return true;
  final code = (data['code'] ?? '').toString().toLowerCase();
  final error = (data['error'] ?? '').toString().toLowerCase();
  final combined = '$code $error';
  return combined.contains('unavailable') ||
      combined.contains('unimplemented') ||
      combined.contains('deadline') ||
      combined.contains('not been deployed') ||
      combined.contains('does not exist') ||
      combined.contains('not-found') ||
      (combined.contains('failed-precondition') &&
          combined.contains('billing'));
}

bool _shouldUseCashFirestoreFallback(Map<String, dynamic> data) {
  if (!TouryPaymentFlags.allowClientCashFallback) return false;
  return _isUndeployedOrUnavailableCallable(data);
}

/// Creates a cash booking through the trusted Cloud Function only.
Future<TouryCashBookingResult> touryCreateCashBookingFromCurrentState() async {
  final app = FFAppState();
  // Ensure pickup exists before validating — GPS / village center as fallback.
  if (app.mkanuserorder == null) {
    if (app.latlngvill != null) {
      app.mkanuserorder = app.latlngvill;
    } else if (app.akrLoceshn != null) {
      app.mkanuserorder = app.akrLoceshn;
    } else {
      final gps = await TouryLocationService.getUserPositionOrNull();
      if (gps != null) {
        app.mkanuserorder = gps;
        app.latlngvill ??= gps;
      }
    }
  }

  final carRef = app.typecarRev;
  final countryRef = app.dolh;
  final pickup = app.mkanuserorder;
  final userRef = currentUserReference;
  if (carRef == null) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_missing_car',
    );
  }
  if (countryRef == null) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_missing_country',
    );
  }
  if (pickup == null) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_missing_pickup',
    );
  }
  if (userRef == null || currentUserUid.isEmpty) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_missing_user',
    );
  }

  if (app.paymentIdempotencyKey.isEmpty) {
    app.paymentIdempotencyKey =
        'cash_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
  }
  final quote = touryRecalculateCheckoutPrice(app);
  if (!quote.isConsistent || quote.customerTotalHalalas <= 0) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_price_inconsistent',
    );
  }

  // No-Billing / cash-only: skip missing CF and write Firestore directly.
  if (TouryPaymentFlags.cashOnlyMode &&
      TouryPaymentFlags.allowClientCashFallback) {
    debugPrint(
      'createCashBooking skipped (cash-only / no-billing) — '
      'using Firestore cash fallback.',
    );
    return touryCreateCashBookingViaFirestoreFallback(
      app: app,
      quote: quote,
      userRef: userRef,
      carRef: carRef,
      countryRef: countryRef,
    );
  }

  final data = await makeCloudCall('createCashBooking', {
    'idempotencyKey': app.paymentIdempotencyKey,
    'carPath': carRef.path,
    'countryPath': countryRef.path,
    'bookingHours': quote.bookingHours,
    'additionalHours': app.addhors,
    'booking': TouryOrderIntegration.cloudBookingPayload(),
  });

  if (!data.containsKey('error')) {
    final orderId = (data['orderId'] ?? data['id'])?.toString();
    return TouryCashBookingResult(
      success: orderId != null && orderId.isNotEmpty,
      orderId: orderId,
    );
  }

  if (!_shouldUseCashFirestoreFallback(data)) {
    return TouryCashBookingResult(
      success: false,
      error: data['code']?.toString() ?? data['error']?.toString(),
    );
  }

  debugPrint(
    'createCashBooking unavailable (${data['code'] ?? data['error']}) — '
    'using Firestore cash fallback.',
  );
  return touryCreateCashBookingViaFirestoreFallback(
    app: app,
    quote: quote,
    userRef: userRef,
    carRef: carRef,
    countryRef: countryRef,
  );
}

@visibleForTesting
Future<TouryCashBookingResult> touryCreateCashBookingViaFirestoreFallback({
  required FFAppState app,
  required TouryPriceQuote quote,
  required DocumentReference userRef,
  required DocumentReference carRef,
  required DocumentReference countryRef,
}) async {
  final pickup = app.mkanuserorder;
  if (pickup == null ||
      (pickup.latitude == 0 && pickup.longitude == 0) ||
      pickup.latitude.isNaN ||
      pickup.longitude.isNaN) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_missing_required_data',
    );
  }

  // C-03: refuse inconsistent client quotes; CF remains authoritative when live.
  if (!quote.isConsistent ||
      quote.customerTotalHalalas <= 0 ||
      quote.customerTotalHalalas >= 100000000 ||
      quote.hourlyRateHalalas <= 0) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_price_inconsistent',
    );
  }

  final orderId = touryCashOrderDocId(
    currentUserUid,
    app.paymentIdempotencyKey,
  );
  final orderRef = OrderRecord.collection.doc(orderId);
  final user = currentUserDocument;
  final booking = TouryOrderIntegration.cloudBookingPayload();
  final now = FieldValue.serverTimestamp();
  final totalMajor = quote.customerTotalHalalas / 100;

  try {
    final alreadyExisted = await FirebaseFirestore.instance.runTransaction(
      (tx) async {
        final existing = await tx.get(orderRef);
        if (existing.exists) return true;

        final stops = (booking['stops'] as List?) ?? const [];
        tx.set(orderRef, {
          'USER': userRef,
          'total': totalMajor,
          'amount_halalas': quote.customerTotalHalalas,
          'currency': 'SAR',
          'data_order': now,
          'LOKESHN': GeoPoint(pickup.latitude, pickup.longitude),
          'mapuser': GeoPoint(pickup.latitude, pickup.longitude),
          'originLatitude': pickup.latitude,
          'originLongitude': pickup.longitude,
          'carRev': carRef,
          'Rev_dolh': countryRef,
          if (app.mdenh != null) 'cities_user_now': app.mdenh,
          if (app.villnow != null) 'vill': app.villnow,
          'vill_text': app.villtextnow,
          'cartext': app.tebycar,
          'naim_user_text':
              user?.displayName ?? currentUserDisplayName,
          'phone_numper':
              num.tryParse(user?.phoneNumber ?? currentPhoneNumber) ?? 0,
          'imgProfileClent': user?.photoUrl ?? currentUserPhoto,
          'total_taim': quote.bookingHours,
          'total_app': quote.appFeeHalalas / 100,
          'total_vat': quote.vatHalalas / 100,
          'ksm': quote.discountHalalas / 100,
          'SrSAAH': quote.hourlyRateHalalas / 100,
          'DriverGuide': app.DriverGuideState,
          if (app.dataSchedule != null) 'Schedule': app.dataSchedule,
          'fullSchedule': app.fulltextSchedule,
          'listAmakn': stops,
          'plannedWaypoints': booking['plannedWaypoints'] ?? const [],
          'trip_type': TouryOrderIntegration.resolveTripType(app),
          'luggage_estimate': app.luggageEstimate,
          'routeProvider': booking['routeProvider'] ?? 'waypoints',
          'routeVersion': 1,
          'plannedDistanceMeters': booking['plannedDistanceMeters'] ?? 0,
          'plannedDurationSeconds': booking['plannedDurationSeconds'] ?? 0,
          // Mark explicitly as non-authoritative until createCashBooking is live.
          'pricing_authority': 'client_fallback_pending_cf',
          'pricing_quote_halalas': quote.customerTotalHalalas,
          'pricing_hourly_halalas': quote.hourlyRateHalalas,
          'pricing_hours': quote.bookingHours,
          'IDorder': 'CASH-${orderId.substring(0, 10).toUpperCase()}',
          'halh_order': 'Cash',
          'halh': 'pending_cash',
          'halh_text': TouryOrderIntegration.pendingStatusText,
          'status_code': 'pending_driver',
          'payment_status': 'pending_cash',
          'cash_collection_status': 'uncollected',
          'PaymentMethod': 'Cash',
          // Explicit null so open-pool queries/rules can treat as unassigned.
          'mndob_user': null,
          'ALLNOW': true,
          'ActiveOrder': false,
          'ReviewMndonsend': false,
          'created_by_function': false,
          'created_by_client_cash_fallback': true,
          'idempotency_key': app.paymentIdempotencyKey,
          'additional_hours': app.addhors,
          ...TouryOrderIntegration.firestoreExtras(),
        });
        return false;
      },
    );

    return TouryCashBookingResult(
      success: true,
      orderId: orderId,
      viaFallback: true,
      error: alreadyExisted ? null : null,
    );
  } on FirebaseException catch (e) {
    debugPrint('Cash Firestore fallback failed: ${e.code} ${e.message}');
    return TouryCashBookingResult(
      success: false,
      error: e.code,
      viaFallback: true,
    );
  } catch (e) {
    debugPrint('Cash Firestore fallback failed: $e');
    return TouryCashBookingResult(
      success: false,
      error: 'booking_save_failed',
      viaFallback: true,
    );
  }
}

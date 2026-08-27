import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/app_state.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/payments/touri_payment_lock.dart';
import '/core/toury_active_booking.dart';
import '/core/toury_currency.dart';
import '/core/toury_location_service.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_flow.dart';
import '/core/toury_payment_labels.dart';
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

/// Prevents double-tap / concurrent cash creates on the same client.
bool _touryCashCreateInFlight = false;

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
  if (!TouryPaymentFlags.allowClientCashFallbackRuntime) return false;
  if (_isUndeployedOrUnavailableCallable(data)) return true;
  // createCashBooking returns permission-denied when Admin SDK lacks
  // Firestore IAM — still allow the constrained client write path.
  final code = (data['code'] ?? '').toString().toLowerCase();
  final error = (data['error'] ?? '').toString().toLowerCase();
  final combined = '$code $error';
  return combined.contains('internal') ||
      combined.contains('permission-denied') ||
      combined.contains('permission_denied') ||
      combined.contains('check function iam');
}

/// Creates a cash booking through the trusted Cloud Function only.
Future<TouryCashBookingResult> touryCreateCashBookingFromCurrentState() async {
  if (_touryCashCreateInFlight) {
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_active_exists',
    );
  }
  _touryCashCreateInFlight = true;
  try {
    return await _touryCreateCashBookingFromCurrentStateImpl();
  } finally {
    _touryCashCreateInFlight = false;
  }
}

Future<TouryCashBookingResult> _touryCreateCashBookingFromCurrentStateImpl() async {
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

  // Block before CF/fallback when an operational booking already exists.
  // Unpaid electronic drafts are converted to cash on the SAME booking.
  final existingActive = await touryFindActiveBookingForCurrentUser();
  if (existingActive != null) {
    final pay = (existingActive.order?.snapshotData['payment_status'] ?? '')
        .toString();
    if (touriIsUnpaidDraft(
      statusCode: existingActive.statusCode ?? '',
      paymentStatus: pay,
    )) {
      return _touryConvertUnpaidOrderToCash(existingActive.orderId);
    }
    return TouryCashBookingResult(
      success: false,
      error: 'booking_active_exists',
      orderId: existingActive.orderId,
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

  // Prefer createCashBooking CF (Admin SDK lock is authoritative).
  // Client fallback is only for undeployed / IAM failures — never skip CF
  // just because cash-only mode is on (that caused parallel creates).
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
    final raw = '${data['code'] ?? ''} ${data['error'] ?? ''} ${data['message'] ?? ''}'
        .toLowerCase();
    if (raw.contains('active_booking_exists')) {
      return TouryCashBookingResult(
        success: false,
        error: 'booking_active_exists',
        orderId: (data['activeOrderId'])?.toString(),
      );
    }
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
  CountriesRecord? countryDoc;
  try {
    countryDoc = await CountriesRecord.getDocumentOnce(countryRef);
  } catch (_) {
    countryDoc = null;
  }
  final currencyFields = TouryCurrency.fieldsForCreate(country: countryDoc);

  // Refuse if any active booking exists (lock field OR recent order scan).
  final existingActive = await touryFindActiveBookingForCurrentUser();
  if (existingActive != null && existingActive.orderId != orderId) {
    return TouryCashBookingResult(
      success: false,
      error: 'booking_active_exists',
      viaFallback: true,
      orderId: existingActive.orderId,
    );
  }

  try {
    // Phase 1 — commit lock first (rules require this before order create).
    final blockingId = await touryClaimActiveOrderCommitted(
      userRef: userRef,
      orderId: orderId,
    );
    if (blockingId != null) {
      return TouryCashBookingResult(
        success: false,
        error: 'booking_active_exists',
        viaFallback: true,
        orderId: blockingId,
      );
    }

    final alreadyExisted = await FirebaseFirestore.instance.runTransaction(
      (tx) async {
        final existing = await tx.get(orderRef);
        if (existing.exists) return true;

        final userSnap = await tx.get(userRef);
        final aid = ((userSnap.data() as Map<String, dynamic>?)?['active_order_id'] ??
                '')
            .toString()
            .trim();
        if (aid != orderId) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'ACTIVE_BOOKING_EXISTS:$aid',
          );
        }

        final stops = (booking['stops'] as List?) ?? const [];
        final acceptanceDeadlineMs =
            DateTime.now().millisecondsSinceEpoch + (60 * 60 * 1000);
        tx.set(orderRef, {
          'USER': userRef,
          'total': totalMajor,
          'amount_halalas': quote.customerTotalHalalas,
          ...currencyFields,
          'data_order': now,
          'acceptanceDeadline': Timestamp.fromMillisecondsSinceEpoch(
            acceptanceDeadlineMs,
          ),
          'acceptance_deadline_ms': acceptanceDeadlineMs,
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
    final msg = (e.message ?? '').toLowerCase();
    if (msg.contains('active_booking_exists')) {
      return TouryCashBookingResult(
        success: false,
        error: 'booking_active_exists',
        viaFallback: true,
        orderId: msg.contains(':') ? msg.split(':').last : null,
      );
    }
    final mapped = switch (e.code) {
      'permission-denied' => 'booking_permission_denied',
      'unauthenticated' => 'booking_auth_required',
      'unavailable' || 'deadline-exceeded' => 'booking_service_unavailable',
      'failed-precondition' => 'booking_active_exists',
      _ => 'booking_unknown_error',
    };
    return TouryCashBookingResult(
      success: false,
      error: mapped,
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

/// Card → cash switch on the same unpaid booking. No N-Genius.
Future<TouryCashBookingResult> _touryConvertUnpaidOrderToCash(
  String orderId,
) async {
  try {
    await OrderRecord.collection.doc(orderId).set(
      {
        'payment_method': TouryPaymentKeys.cash,
        'payth': TouryPaymentKeys.cash,
        'payment_status': 'cash_pending',
        'status_code': 'pending_driver',
        'ALLNOW': true,
        'ElectronicPayment': false,
        'last_payment_attempt_status': 'switched_to_cash',
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    try {
      await touryCancelPaymentAttempt(bookingId: orderId);
    } catch (_) {}
    return TouryCashBookingResult(success: true, orderId: orderId);
  } catch (e) {
    debugPrint('Convert unpaid to cash failed: $e');
    return const TouryCashBookingResult(
      success: false,
      error: 'booking_save_failed',
    );
  }
}

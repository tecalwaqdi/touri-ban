import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/schema/enums/enums.dart';
import '/core/driver_app_lifecycle_coordinator.dart';
import '/core/driver_offline_queue.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_wallet_service.dart';
import '/core/toury_system_status_codes.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/flutter_flow_util.dart';

class DriverWalletGateResult {
  const DriverWalletGateResult({required this.ok, this.message, this.code});

  final bool ok;
  final String? message;
  final String? code;
}

/// منطق الرحلة الموحّد للمندوب (مصدر الحقيقة لمسار القبول/الوصول/البدء/الإنهاء).
abstract final class DriverTripService {
  DriverTripService._();

  static const double arrivalRadiusMeters = 80.0;
  static const double dropoffRadiusMeters = 150.0;
  /// Minimum seconds after start before complete is allowed without dropoff proximity.
  static const int minTripSecondsBeforeComplete = 60;

  static Future<double> minWalletFromSettings() async {
    final settings = await querySettingsRecordOnce(
      queryBuilder: (q) => q.where('id', isEqualTo: 1),
      singleRecord: true,
    ).then((l) => l.firstOrNull);
    return settings?.minDriverWallet ?? 0.0;
  }

  static Future<DriverWalletGateResult> validateWalletForAccept({
    OrderRecord? order,
    PaymentMethod? paymentMethod,
  }) async {
    final method = paymentMethod ?? order?.paymentMethod;
    if (!DriverPaymentLabels.isCash(method)) {
      return const DriverWalletGateResult(ok: true);
    }

    const requireWallet = bool.fromEnvironment(
      'TOURY_REQUIRE_DRIVER_WALLET',
      defaultValue: true,
    );
    if (!requireWallet) {
      return const DriverWalletGateResult(ok: true);
    }

    final fromSettings = await minWalletFromSettings();
    final minimum = fromSettings > 0
        ? fromSettings
        : DriverWalletRules.minCashWalletBalance;

    double balance;
    try {
      balance = await DriverWalletService.availableBalance();
    } catch (_) {
      balance = 0;
    }
    if (balance < minimum) {
      return DriverWalletGateResult(
        ok: false,
        code: 'DRIVER_WALLET_INSUFFICIENT',
        message:
            'يجب أن يكون رصيد محفظتك ${minimum.toStringAsFixed(0)} ريال على الأقل لقبول الطلبات النقدية.',
      );
    }
    return const DriverWalletGateResult(ok: true);
  }

  /// Accept with server CF when available; falls back to Firestore transaction.
  static Future<DriverWalletGateResult> acceptOrder({
    required OrderRecord order,
    required LatLng? driverLocation,
    required void Function() onStateChanged,
  }) async {
    final net = await DriverAppLifecycleCoordinator.requireOnlineOrEnqueue(
      type: DriverOfflineOpType.acceptOrder,
      orderPath: order.reference.path,
      allowQueue: false,
    );
    if (!net.ok) {
      return DriverWalletGateResult(
        ok: false,
        code: 'OFFLINE',
        message: net.message ?? 'Connection required to accept.',
      );
    }

    final walletGate = await validateWalletForAccept(order: order);
    if (!walletGate.ok) {
      return walletGate;
    }

    final driverRef = currentUserReference;
    if (driverRef == null) {
      return const DriverWalletGateResult(
        ok: false,
        code: 'AUTH_REQUIRED',
        message: 'Please sign in first.',
      );
    }

    // Prefer Admin SDK callable (wallet re-check + atomic claim).
    final cf = await makeCloudCall('acceptDriverOrder', {
      'orderId': order.reference.id,
      'orderPath': order.reference.path,
      if (driverLocation != null) ...{
        'lat': driverLocation.latitude,
        'lng': driverLocation.longitude,
      },
      'displayName': currentUserDisplayName,
      'phone': valueOrDefault(currentUserDocument?.phoneN, 0),
      'carLabel':
          '${valueOrDefault(currentUserDocument?.textTypeCarMndob, '')}- ${valueOrDefault(currentUserDocument?.numberLohhCar, '')}',
      'NameCar': valueOrDefault(currentUserDocument?.nameCar, ''),
      'ModelCar': valueOrDefault(currentUserDocument?.modelCar, ''),
    });

    if (cf['error'] == null && cf['ok'] == true) {
      FFAppState().revOrder = order.reference;
      onStateChanged();
      unawaited(_postAcceptSideEffects(order, driverRef, driverLocation));
      return const DriverWalletGateResult(ok: true);
    }

    final cfCode = (cf['code'] ?? '').toString();
    // not-found / unavailable → local transactional claim (still race-safe).
    if (cfCode != 'not-found' &&
        cfCode != 'unavailable' &&
        cfCode != 'unimplemented' &&
        (cf['error'] != null || cf['ok'] == false)) {
      final code = (cf['errorCode'] ?? cfCode).toString();
      final errText = (cf['error'] ?? '').toString();
      if (code == 'DRIVER_WALLET_INSUFFICIENT' ||
          (code == 'failed-precondition' && errText.contains('محفظ'))) {
        return DriverWalletGateResult(
          ok: false,
          code: 'DRIVER_WALLET_INSUFFICIENT',
          message: errText.isNotEmpty
              ? errText
              : 'يجب أن يكون رصيد محفظتك 200 ريال على الأقل لقبول الطلبات النقدية.',
        );
      }
      final mapped = _messageForCode(
        (cf['errorCode'] ?? 'BOOKING_ASSIGNMENT_FAILED').toString(),
      );
      return DriverWalletGateResult(
        ok: false,
        code: (cf['errorCode'] ?? cfCode).toString(),
        message: (cf['error'] ?? mapped).toString(),
      );
    }

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(order.reference);
        if (!snap.exists) {
          throw StateError('BOOKING_NOT_FOUND');
        }
        final data = snap.data() as Map<String, dynamic>? ?? {};
        final statusCode = (data['status_code'] ?? '').toString();
        final halhText =
            (data['halh_text'] ?? data['halhText'] ?? '').toString();
        final halhOrder = (data['halh_order'] ?? '').toString();
        final existingDriver = data['mndob_user'];

        if (existingDriver != null) {
          final existingPath = existingDriver is DocumentReference
              ? existingDriver.path
              : existingDriver.toString();
          if (existingPath != driverRef.path) {
            throw StateError('BOOKING_ALREADY_ASSIGNED');
          }
        }

        if (!TourySystemStatusCodes.isAssignable(
          statusCode,
          halhText,
          halhOrder,
        )) {
          throw StateError('BOOKING_INVALID_STATE');
        }

        final deadline = data['acceptanceDeadline'];
        final deadlineMs = data['acceptance_deadline_ms'];
        DateTime? deadlineAt;
        if (deadline is Timestamp) {
          deadlineAt = deadline.toDate();
        } else if (deadlineMs is num) {
          deadlineAt = DateTime.fromMillisecondsSinceEpoch(deadlineMs.toInt());
        } else {
          final created = data['data_order'];
          if (created is Timestamp) {
            deadlineAt = created.toDate().add(const Duration(hours: 1));
          }
        }
        if (deadlineAt != null && DateTime.now().isAfter(deadlineAt)) {
          throw StateError('BOOKING_EXPIRED');
        }

        final claim = <String, dynamic>{
          'mndob_user': driverRef,
          'status_code': TourySystemStatusCodes.driverAssigned,
          'ActiveOrder': true,
          'ALLNOW': false,
          'halh_text': DriverTripHalh.accepted,
          'halhOrderMndob': 'Accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'START': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
          'naim_mndob_text': currentUserDisplayName,
          'phone_nu_mndob': valueOrDefault(currentUserDocument?.phoneN, 0),
          'carmndob':
              '${valueOrDefault(currentUserDocument?.textTypeCarMndob, '')}- ${valueOrDefault(currentUserDocument?.numberLohhCar, '')}',
          'NameCar': valueOrDefault(currentUserDocument?.nameCar, ''),
          'ModelCar': valueOrDefault(currentUserDocument?.modelCar, ''),
        };
        if (driverLocation != null &&
            (driverLocation.latitude != 0 || driverLocation.longitude != 0)) {
          claim['mapuser'] = GeoPoint(
            driverLocation.latitude,
            driverLocation.longitude,
          );
          claim['driver_accept_location'] = GeoPoint(
            driverLocation.latitude,
            driverLocation.longitude,
          );
        }
        tx.update(order.reference, claim);
      });
    } on StateError catch (e) {
      final code = e.message;
      return DriverWalletGateResult(
        ok: false,
        code: code,
        message: _messageForCode(code),
      );
    } on FirebaseException catch (e) {
      return DriverWalletGateResult(
        ok: false,
        code: e.code,
        message: e.code == 'permission-denied'
            ? _messageForCode('BOOKING_ASSIGNMENT_FAILED')
            : '${_messageForCode('BOOKING_ASSIGNMENT_FAILED')} (${e.code})',
      );
    } catch (e) {
      return DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_ASSIGNMENT_FAILED',
        message: _messageForCode('BOOKING_ASSIGNMENT_FAILED'),
      );
    }

    FFAppState().revOrder = order.reference;
    onStateChanged();
    unawaited(_postAcceptSideEffects(order, driverRef, driverLocation));
    return const DriverWalletGateResult(ok: true);
  }

  static Future<void> _postAcceptSideEffects(
    OrderRecord order,
    DocumentReference driverRef,
    LatLng? driverLocation,
  ) async {
    try {
      await driverRef.update({
        'mndonNewacc': true,
        if (driverLocation != null)
          'loceshnMndobNow': GeoPoint(
            driverLocation.latitude,
            driverLocation.longitude,
          ),
      });
    } catch (_) {}
    try {
      await actions.trackOrderLocation(order.reference);
      await actions.startTrackingAndUpdateFirebase(order.reference);
    } catch (_) {}
    try {
      if (order.user != null) {
        triggerPushNotification(
          notificationTitle: 'Order accepted',
          notificationText:
              'Your Touri Taxi request was accepted by: $currentUserDisplayName',
          userRefs: [order.user!],
          initialPageName: 'tfasel_order',
          parameterData: {
            'idorder': order.reference,
          },
        );
      }
    } catch (_) {}
  }

  static Future<void> startTrip({
    required OrderRecord order,
    LatLng? driverLocation,
  }) async {
    if (order.mndobUser?.path != currentUserReference?.path) {
      throw StateError('PERMISSION_DENIED');
    }
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    final allowed = code == TourySystemStatusCodes.driverArrived ||
        order.halhText == DriverTripHalh.driverArrived;
    if (!allowed) {
      throw StateError('BOOKING_INVALID_STATE');
    }

    await order.reference.update({
      ...createOrderRecordData(
        halhText: DriverTripHalh.inProgress,
        mapuser: driverLocation,
        timestamp: getCurrentTimestamp,
        start: getCurrentTimestamp,
        activeOrder: true,
      ),
      'status_code': TourySystemStatusCodes.tripInProgress,
      'trip_started_at': FieldValue.serverTimestamp(),
    });
  }

  /// Whether the driver may complete: in-progress + (near dropoff OR min duration).
  static bool canCompleteTrip({
    required OrderRecord order,
    LatLng? driverLocation,
    bool allowRemoteOverride = false,
  }) {
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    final canByStatus = code == TourySystemStatusCodes.tripInProgress ||
        code == TourySystemStatusCodes.tripStarted ||
        order.halhText == DriverTripHalh.inProgress;
    if (!canByStatus) return false;
    if (allowRemoteOverride) return true;

    final started = order.start ??
        _asDateTime(order.snapshotData['trip_started_at']);
    final elapsedOk = started != null &&
        DateTime.now().difference(started).inSeconds >=
            minTripSecondsBeforeComplete;

    final dropoff = order.tripDestination;
    if (driverLocation != null && dropoff != null) {
      final meters = haversineMeters(
        driverLocation.latitude,
        driverLocation.longitude,
        dropoff.latitude,
        dropoff.longitude,
      );
      if (meters <= dropoffRadiusMeters) return true;
    }

    // Soft override: after 5 minutes allow complete even if GPS says far.
    if (started != null &&
        DateTime.now().difference(started).inSeconds >= 300) {
      return true;
    }

    // Allow complete after minimum duration when GPS is weak / dropoff missing.
    return elapsedOk && (dropoff == null || driverLocation == null);
  }

  static Future<void> completeTrip({
    required OrderRecord order,
    required LatLng? driverLocation,
    bool allowRemoteOverride = false,
  }) async {
    if (order.mndobUser?.path != currentUserReference?.path) {
      throw StateError('PERMISSION_DENIED');
    }

    final net = await DriverAppLifecycleCoordinator.requireOnlineOrEnqueue(
      type: DriverOfflineOpType.completeTrip,
      orderPath: order.reference.path,
      allowQueue: false,
    );
    if (!net.ok) {
      throw StateError('OFFLINE');
    }

    if (!canCompleteTrip(
      order: order,
      driverLocation: driverLocation,
      allowRemoteOverride: allowRemoteOverride,
    )) {
      throw StateError('BOOKING_TOO_FAR_OR_TOO_EARLY');
    }

    final isCash = DriverPaymentLabels.isCash(order.paymentMethod);
    // Cash is NOT auto-collected on complete — driver must confirm separately.
    // Electronic payment_status is never written by the driver app.
    await order.reference.update({
      ...createOrderRecordData(
        halhText: DriverTripHalh.completed,
        mndobUser: currentUserReference,
        dateend: getCurrentTimestamp,
        activeOrder: false,
        halhOrderMndob: HalhOrder.Completed,
        endTime: getCurrentTimestamp,
        mapuser: driverLocation,
      ),
      'status_code': TourySystemStatusCodes.completed,
      'halh_text_completed_alias': DriverTripHalh.completedAlias,
      'completedAt': FieldValue.serverTimestamp(),
      if (isCash && !DriverPaymentStatusMapper.isCashCollected(order)) ...{
        'payment_status': TourySystemStatusCodes.pendingCash,
        'cash_collection_status': 'pending',
      },
    });

    final driverRef = currentUserReference;
    if (driverRef != null) {
      await driverRef.update(createUserRecordData(mndonNewacc: false));
    }
    if (FFAppState().revOrder?.path == order.reference.path) {
      FFAppState().revOrder = null;
    }
    try {
      await actions.stopTracking();
    } catch (_) {}
  }

  /// Explicit cash confirmation — idempotent; never mutates electronic payment.
  static Future<DriverWalletGateResult> confirmCashCollection({
    required OrderRecord order,
    String? operationId,
  }) async {
    if (order.mndobUser?.path != currentUserReference?.path) {
      return const DriverWalletGateResult(
        ok: false,
        code: 'PERMISSION_DENIED',
        message: 'You are not assigned to this trip.',
      );
    }
    if (!DriverPaymentLabels.isCash(order.paymentMethod)) {
      return const DriverWalletGateResult(
        ok: false,
        code: 'ELECTRONIC_PAYMENT',
        message: 'Electronic payment status comes from the payment backend only.',
      );
    }

    final net = await DriverAppLifecycleCoordinator.requireOnlineOrEnqueue(
      type: DriverOfflineOpType.cashConfirmation,
      orderPath: order.reference.path,
      allowQueue: false,
      payload: {'operationId': operationId ?? ''},
    );
    if (!net.ok) {
      return DriverWalletGateResult(
        ok: false,
        code: 'OFFLINE',
        message: net.message ?? 'Connection required to confirm cash.',
      );
    }

    // Re-read backend before write (idempotency).
    final fresh = await OrderRecord.getDocumentOnce(order.reference);
    if (DriverPaymentStatusMapper.isCashCollected(fresh)) {
      return const DriverWalletGateResult(
        ok: true,
        code: 'ALREADY_COLLECTED',
        message: 'Cash was already confirmed.',
      );
    }

    final code =
        (fresh.snapshotData['status_code'] ?? '').toString().trim();
    if (code != TourySystemStatusCodes.completed &&
        fresh.halhText != DriverTripHalh.completed) {
      return const DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_INVALID_STATE',
        message: 'Complete the trip before confirming cash.',
      );
    }

    await order.reference.update({
      'payment_status': TourySystemStatusCodes.cashCollected,
      'cashCollectedByDriver': true,
      'cashCollectedAt': FieldValue.serverTimestamp(),
      'cash_collection_status': 'collected',
      'halh': 'paid',
      'halh_order': 'Paid',
      if (operationId != null && operationId.isNotEmpty)
        'cash_confirm_operation_id': operationId,
    });

    return const DriverWalletGateResult(ok: true, code: 'COLLECTED');
  }

  static Future<DriverWalletGateResult> cancelTrip({
    required OrderRecord order,
    LatLng? driverLocation,
    String? reason,
  }) async {
    final driverRef = currentUserReference;
    if (driverRef == null) {
      return const DriverWalletGateResult(
        ok: false,
        code: 'AUTH_REQUIRED',
        message: 'Please sign in first.',
      );
    }
    if (order.mndobUser?.path != driverRef.path) {
      return DriverWalletGateResult(
        ok: false,
        code: 'PERMISSION_DENIED',
        message: _messageForCode('PERMISSION_DENIED'),
      );
    }

    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    final active = TourySystemStatusCodes.isActiveTripCode(code) ||
        DriverTripHalh.isActiveTrip(order.halhText);
    if (!active) {
      return DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_INVALID_STATE',
        message: _messageForCode('BOOKING_INVALID_STATE'),
      );
    }

    try {
      await order.reference.update({
        ...createOrderRecordData(
          halhText: DriverTripHalh.cancelled,
          mndobUser: driverRef,
          naimMndobText: currentUserDisplayName,
          phoneNuMndob: valueOrDefault(currentUserDocument?.phoneN, 0),
          activeOrder: false,
          mapuser: driverLocation,
          timestamp: getCurrentTimestamp,
        ),
        'status_code': TourySystemStatusCodes.cancelledByDriver,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'driver',
        if (reason != null && reason.trim().isNotEmpty)
          'cancelReason': reason.trim(),
      });

      await driverRef.update(createUserRecordData(mndonNewacc: false));
      try {
        await actions.stopTracking();
      } catch (_) {}

      if (FFAppState().revOrder?.path == order.reference.path) {
        FFAppState().revOrder = null;
      }

      if (order.user != null) {
        triggerPushNotification(
          notificationTitle: 'Order cancelled',
          notificationText:
              'Your Touri Taxi request was cancelled by the driver.',
          userRefs: [order.user!],
          initialPageName: 'tfasel_order',
          parameterData: {
            'idorder': order.reference,
          },
        );
      }

      return const DriverWalletGateResult(ok: true);
    } catch (e) {
      return DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_ASSIGNMENT_FAILED',
        message: _messageForCode('BOOKING_ASSIGNMENT_FAILED'),
      );
    }
  }

  static Future<void> markDriverArrived({
    required DocumentReference orderRef,
    LatLng? driverLocation,
  }) async {
    final now = getCurrentTimestamp;
    await orderRef.update({
      ...createOrderRecordData(
        halhText: DriverTripHalh.driverArrived,
        mapuser: driverLocation,
        timestamp: now,
        activeOrder: true,
      ),
      'driverArrivedAt': now,
      'waitingStartedAt': now,
      'customerWaitingTimeInSeconds': 0,
      'status_code': TourySystemStatusCodes.driverArrived,
    });

    final order = await OrderRecord.getDocumentOnce(orderRef);
    if (order.user != null) {
      triggerPushNotification(
        notificationTitle: 'Driver arrived',
        notificationText:
            'Driver $currentUserDisplayName has arrived at the pickup location.',
        userRefs: [order.user!],
        initialPageName: 'tfasel_order',
        parameterData: {
          'idorder': order.reference,
        },
      );
    }
  }

  static Future<void> maybeAutoMarkArrived({
    required OrderRecord order,
    required LatLng driverPosition,
  }) async {
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    final headingToPickup = code == TourySystemStatusCodes.driverAssigned ||
        code == TourySystemStatusCodes.driverArriving ||
        order.halhText == DriverTripHalh.accepted;
    if (!headingToPickup) return;
    if (order.mndobUser?.path != currentUserReference?.path) return;
    final pickup = order.lokeshn;
    if (pickup == null) return;
    final meters = haversineMeters(
      driverPosition.latitude,
      driverPosition.longitude,
      pickup.latitude,
      pickup.longitude,
    );
    if (meters <= arrivalRadiusMeters) {
      await markDriverArrived(
        orderRef: order.reference,
        driverLocation: driverPosition,
      );
    }
  }

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);

  static Future<double> waitingChargePerMinute() async {
    final settings = await querySettingsRecordOnce(
      queryBuilder: (q) => q.where('id', isEqualTo: 1),
      singleRecord: true,
    ).then((l) => l.firstOrNull);
    return settings?.waitingChargePerMinute ?? 0.0;
  }

  static Future<int> waitingFreeMinutes() async {
    final settings = await querySettingsRecordOnce(
      queryBuilder: (q) => q.where('id', isEqualTo: 1),
      singleRecord: true,
    ).then((l) => l.firstOrNull);
    return settings?.waitingFreeMinutes ?? 5;
  }

  static Future<void> updateTrackingMetrics({
    required DocumentReference orderRef,
    required LatLng driverPosition,
    LatLng? target,
  }) async {
    final orderUpdates = <String, dynamic>{
      'mapuser':
          GeoPoint(driverPosition.latitude, driverPosition.longitude),
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (target != null) {
      final meters = haversineMeters(
        driverPosition.latitude,
        driverPosition.longitude,
        target.latitude,
        target.longitude,
      );
      const avgSpeedMps = 8.33;
      orderUpdates['distanceRemainingMeters'] = meters;
      orderUpdates['etaSeconds'] = (meters / avgSpeedMps).round();
    }

    await orderRef.update(orderUpdates);

    // If accepted but driver starts moving toward customer, mark en route
    // so the customer cancel button hides.
    try {
      final snap = await orderRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      if (data != null) {
        final code = (data['status_code'] ?? '').toString().trim();
        if (code == TourySystemStatusCodes.driverAssigned) {
          await maybeMarkDriverEnRoute(
            orderRef: orderRef,
            orderData: data,
            driverPosition: driverPosition,
            target: target,
          );
        }
      }
    } catch (_) {}

    if (currentUserReference != null) {
      await currentUserReference!.update(createUserRecordData(
        loceshnMndobNow: driverPosition,
      ));
    }
  }

  /// Marks `driver_arriving` once the driver has left accept location
  /// toward the customer (or explicitly opens navigation).
  static Future<void> maybeMarkDriverEnRoute({
    required DocumentReference orderRef,
    required Map<String, dynamic> orderData,
    required LatLng driverPosition,
    LatLng? target,
    bool force = false,
  }) async {
    final code = (orderData['status_code'] ?? '').toString().trim();
    if (code != TourySystemStatusCodes.driverAssigned &&
        code != TourySystemStatusCodes.driverArriving) {
      return;
    }
    if (code == TourySystemStatusCodes.driverArriving && !force) return;

    var shouldMark = force;
    if (!shouldMark) {
      final accept = orderData['driver_accept_location'];
      double? acceptLat;
      double? acceptLng;
      if (accept is GeoPoint) {
        acceptLat = accept.latitude;
        acceptLng = accept.longitude;
      }
      if (acceptLat != null && acceptLng != null) {
        final moved = haversineMeters(
          driverPosition.latitude,
          driverPosition.longitude,
          acceptLat,
          acceptLng,
        );
        if (moved >= 120) {
          if (target != null) {
            final nowToPickup = haversineMeters(
              driverPosition.latitude,
              driverPosition.longitude,
              target.latitude,
              target.longitude,
            );
            final acceptToPickup = haversineMeters(
              acceptLat,
              acceptLng,
              target.latitude,
              target.longitude,
            );
            // Closer to customer by at least 50m after leaving accept spot.
            shouldMark = nowToPickup <= acceptToPickup - 50;
          } else {
            shouldMark = true;
          }
        }
      }
    }

    if (!shouldMark) return;

    try {
      await orderRef.update({
        'status_code': TourySystemStatusCodes.driverArriving,
        'driver_en_route_at': FieldValue.serverTimestamp(),
        'halh_text': DriverTripHalh.accepted,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('DriverTripService.maybeMarkDriverEnRoute: $e');
    }
  }

  /// Call when driver opens Google Maps toward the customer.
  static Future<void> markEnRouteIfAssigned(DocumentReference orderRef) async {
    try {
      final snap = await orderRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;
      final code = (data['status_code'] ?? '').toString().trim();
      if (code != TourySystemStatusCodes.driverAssigned) return;
      await orderRef.update({
        'status_code': TourySystemStatusCodes.driverArriving,
        'driver_en_route_at': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('DriverTripService.markEnRouteIfAssigned: $e');
    }
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static Duration waitingDuration(OrderRecord order) {
    final start = _asDateTime(order.snapshotData['waitingStartedAt']) ??
        _asDateTime(order.snapshotData['driverArrivedAt']);
    if (start == null) return Duration.zero;
    return DateTime.now().difference(start);
  }

  static Future<double> calculateWaitingCharges(OrderRecord order) async {
    final perMinute = await waitingChargePerMinute();
    if (perMinute <= 0) return 0;
    final free = await waitingFreeMinutes();
    final minutes = waitingDuration(order).inMinutes - free;
    if (minutes <= 0) return 0;
    return minutes * perMinute;
  }

  static Future<void> persistWaitingCharges(OrderRecord order) async {
    final charges = await calculateWaitingCharges(order);
    await order.reference.update({
      'waitingCharges': charges,
      'customerWaitingTimeInSeconds': waitingDuration(order).inSeconds,
    });
  }

  static bool isActiveTripForCurrentDriver(OrderRecord order) {
    if (order.mndobUser?.path != currentUserReference?.path) return false;
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    return TourySystemStatusCodes.isActiveTripCode(code) ||
        DriverTripHalh.isActiveTrip(order.halhText);
  }

  /// Restore active trip ref into FFAppState after cold start.
  static Future<DocumentReference?> restoreActiveTripRef() async {
    final driverRef = currentUserReference;
    if (driverRef == null) return null;
    if (FFAppState().revOrder != null) {
      try {
        final existing =
            await OrderRecord.getDocumentOnce(FFAppState().revOrder!);
        if (isActiveTripForCurrentDriver(existing)) {
          return existing.reference;
        }
      } catch (_) {}
    }

    final snap = await OrderRecord.collection
        .where('mndob_user', isEqualTo: driverRef)
        .where('ActiveOrder', isEqualTo: true)
        .limit(5)
        .get();

    for (final doc in snap.docs) {
      final order = OrderRecord.fromSnapshot(doc);
      if (isActiveTripForCurrentDriver(order)) {
        FFAppState().revOrder = order.reference;
        return order.reference;
      }
    }
    return null;
  }

  static String messageForCode(String code) => _messageForCode(code);

  static String _messageForCode(String code) {
    switch (code) {
      case 'BOOKING_NOT_FOUND':
        return 'Booking not found.';
      case 'BOOKING_ALREADY_ASSIGNED':
        return 'This request has already been accepted by another driver.';
      case 'BOOKING_INVALID_STATE':
        return 'This booking cannot be updated in its current state.';
      case 'BOOKING_EXPIRED':
        return 'انتهت مهلة قبول الطلب. لم يعد بإمكانك قبول هذا الطلب.';
      case 'DRIVER_WALLET_INSUFFICIENT':
        return 'يجب أن يكون رصيد محفظتك 200 ريال على الأقل لقبول الطلبات النقدية.';
      case 'BOOKING_TOO_FAR_OR_TOO_EARLY':
        return 'Move closer to the destination or wait a moment before completing.';
      case 'PERMISSION_DENIED':
        return 'You are not allowed to perform this action.';
      default:
        return 'Could not update the booking. Please try again.';
    }
  }
}

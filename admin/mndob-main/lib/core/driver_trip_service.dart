import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/amakn_coistm_struct.dart';
import '/core/driver_app_lifecycle_coordinator.dart';
import '/core/driver_directions_service.dart';
import '/core/driver_offline_queue.dart';
import '/core/driver_order_availability.dart';
import '/core/driver_order_meta.dart';
import '/core/driver_payment_labels.dart';
import '/core/driver_payment_status_mapper.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_wallet_service.dart';
import '/core/toury_maps_config.dart';
import '/core/toury_notification_localizer.dart';
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

  static String? _acceptInFlightOrderId;

  static const double arrivalRadiusMeters = 80.0;
  static const double dropoffRadiusMeters = 150.0;
  /// Minimum seconds after start before complete is allowed without dropoff proximity.
  static const int minTripSecondsBeforeComplete = 60;

  /// Throttle Google Routes ETA refresh (not every GPS tick).
  static const Duration _etaRefreshInterval = Duration(seconds: 25);
  static const double _etaMoveThresholdMeters = 60.0;
  static DateTime? _lastEtaFetchAt;
  static LatLng? _lastEtaOrigin;
  static LatLng? _lastEtaTarget;
  static int? _cachedEtaSeconds;
  static int? _cachedDistanceMeters;
  static bool _cachedEtaApproximate = true;

  static Future<double> minWalletFromSettings() async {
    try {
      final settings = await querySettingsRecordOnce(
        queryBuilder: (q) => q.where('id', isEqualTo: 1),
        singleRecord: true,
      ).timeout(const Duration(seconds: 4)).then((l) => l.firstOrNull);
      return settings?.minDriverWallet ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  static void _acceptLog(String stage, Stopwatch sw, [Object? detail]) {
    debugPrint(
      '[accept] $stage +${sw.elapsedMilliseconds}ms'
      '${detail == null ? '' : ' $detail'}',
    );
  }

  static Future<DriverWalletGateResult> validateWalletForAccept({
    OrderRecord? order,
    PaymentMethod? paymentMethod,
  }) async {
    final method = paymentMethod ?? order?.paymentMethod;
    final fallbackRaw = order == null
        ? null
        : [
            order.snapshotData['PaymentMethod'],
            order.snapshotData['paymentMethod'],
            order.snapshotData['payment_status'],
          ].whereType<Object>().map((e) => e.toString()).join(' ');
    if (!DriverPaymentLabels.isCash(method, fallbackRaw: fallbackRaw) &&
        (order == null ||
            (order.snapshotData['payment_status'] ?? '')
                    .toString()
                    .toLowerCase() !=
                'pending_cash')) {
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
      balance = await DriverWalletService.availableBalance()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Fail closed for cash: never treat unread wallet as zero and accept.
      return const DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_SERVICE_UNAVAILABLE',
        message:
            'تعذّر التحقق من رصيد المحفظة. تحقق من الاتصال ثم حاول مرة أخرى.',
      );
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

  static bool isCashOrder(OrderRecord order) {
    final payStatus =
        (order.snapshotData['payment_status'] ?? '').toString().toLowerCase();
    if (payStatus == 'pending_cash') return true;
    final fallbackRaw = [
      order.snapshotData['PaymentMethod'],
      order.snapshotData['paymentMethod'],
      payStatus,
    ].whereType<Object>().map((e) => e.toString()).join(' ');
    return DriverPaymentLabels.isCash(
      order.paymentMethod,
      fallbackRaw: fallbackRaw,
    );
  }

  /// Usable GPS only — never null-island (0,0).
  static LatLng? usableDriverLocation(LatLng? value) {
    return TouryMapsConfig.resolveLocationOrNull(value);
  }

  /// Accept with server CF when available; falls back to Firestore transaction.
  static Future<DriverWalletGateResult> acceptOrder({
    required OrderRecord order,
    required LatLng? driverLocation,
    required void Function() onStateChanged,
  }) async {
    final orderId = order.reference.id;
    if (_acceptInFlightOrderId == orderId) {
      return const DriverWalletGateResult(
        ok: false,
        code: 'ACCEPT_IN_PROGRESS',
        message: 'جاري قبول الطلب، يرجى الانتظار.',
      );
    }
    if (_acceptInFlightOrderId != null) {
      return const DriverWalletGateResult(
        ok: false,
        code: 'ACCEPT_IN_PROGRESS',
        message: 'عملية قبول أخرى قيد التنفيذ. حاول مرة أخرى.',
      );
    }
    _acceptInFlightOrderId = orderId;
    try {
      // Client-side gate using Firestore document timestamps (not device create time).
      if (DriverOrderAvailability.isAcceptanceExpiredOrder(order)) {
        return DriverWalletGateResult(
          ok: false,
          code: 'BOOKING_EXPIRED',
          message: _messageForCode('BOOKING_EXPIRED'),
        );
      }
      if (order.mndobUser != null &&
          order.mndobUser?.path != currentUserReference?.path) {
        return DriverWalletGateResult(
          ok: false,
          code: 'BOOKING_ALREADY_ASSIGNED',
          message: _messageForCode('BOOKING_ALREADY_ASSIGNED'),
        );
      }
      return await _acceptOrderBody(
        order: order,
        driverLocation: driverLocation,
        onStateChanged: onStateChanged,
      );
    } finally {
      if (_acceptInFlightOrderId == orderId) {
        _acceptInFlightOrderId = null;
      }
    }
  }

  static Future<DriverWalletGateResult> _acceptOrderBody({
    required OrderRecord order,
    required LatLng? driverLocation,
    required void Function() onStateChanged,
  }) async {
    final sw = Stopwatch()..start();
    _acceptLog('accept_start', sw, order.reference.id);

    final net = await DriverAppLifecycleCoordinator.requireOnlineOrEnqueue(
      type: DriverOfflineOpType.acceptOrder,
      orderPath: order.reference.path,
      allowQueue: false,
    );
    if (!net.ok) {
      _acceptLog('accept_failed', sw, 'OFFLINE');
      return DriverWalletGateResult(
        ok: false,
        code: 'OFFLINE',
        message: _messageForCode('OFFLINE'),
      );
    }

    final walletGate = await validateWalletForAccept(order: order);
    _acceptLog('wallet_loaded', sw, walletGate.ok);
    if (!walletGate.ok) {
      _acceptLog('accept_failed', sw, walletGate.code);
      return walletGate;
    }

    final driverRef = currentUserReference;
    if (driverRef == null) {
      _acceptLog('accept_failed', sw, 'AUTH_REQUIRED');
      return const DriverWalletGateResult(
        ok: false,
        code: 'AUTH_REQUIRED',
        message: 'Please sign in first.',
      );
    }
    _acceptLog('driver_loaded', sw, driverRef.id);

    // Prefer Admin SDK callable (wallet re-check + atomic claim).
    final safeLocForCf = usableDriverLocation(driverLocation);
    final cf = await makeCloudCall(
      'acceptDriverOrder',
      {
        'orderId': order.reference.id,
        'orderPath': order.reference.path,
        if (safeLocForCf != null) ...{
          'lat': safeLocForCf.latitude,
          'lng': safeLocForCf.longitude,
        },
        'displayName': currentUserDisplayName,
        'phone': valueOrDefault(currentUserDocument?.phoneN, 0),
        'carLabel':
            '${valueOrDefault(currentUserDocument?.textTypeCarMndob, '')}- ${valueOrDefault(currentUserDocument?.numberLohhCar, '')}',
        'NameCar': valueOrDefault(currentUserDocument?.nameCar, ''),
        'ModelCar': valueOrDefault(currentUserDocument?.modelCar, ''),
      },
      timeout: const Duration(seconds: 15),
    );
    _acceptLog('cf_done', sw, '${cf['ok']} ${cf['code']} ${cf['errorCode']}');

    if (cf['error'] == null && cf['ok'] == true) {
      FFAppState().revOrder = order.reference;
      onStateChanged();
      unawaited(_postAcceptSideEffects(order, driverRef, safeLocForCf));
      _acceptLog('accept_completed', sw, 'via_cf');
      return const DriverWalletGateResult(ok: true);
    }

    final cfCode = (cf['code'] ?? '').toString().toLowerCase();
    final errorCode = (cf['errorCode'] ?? '').toString();
    final errText = (cf['error'] ?? '').toString();

    // Hard business failures — do not fall back.
    final hardFail = errorCode == 'DRIVER_WALLET_INSUFFICIENT' ||
        errorCode == 'BOOKING_ALREADY_ASSIGNED' ||
        errorCode == 'BOOKING_EXPIRED' ||
        errorCode == 'BOOKING_INVALID_STATE' ||
        errorCode == 'BOOKING_NOT_FOUND' ||
        errorCode == 'DRIVER_DISABLED' ||
        errorCode == 'insufficient-wallet' ||
        errorCode == 'INTERNAL' ||
        (cfCode == 'failed-precondition' && errText.contains('محفظ')) ||
        (cfCode == 'already-exists');
    if (hardFail) {
      final code = errorCode.isNotEmpty
          ? errorCode
          : (cfCode == 'already-exists'
              ? 'BOOKING_ALREADY_ASSIGNED'
              : 'BOOKING_ASSIGNMENT_FAILED');
      final mappedCode = code == 'insufficient-wallet'
          ? 'DRIVER_WALLET_INSUFFICIENT'
          : (code == 'INTERNAL' || code == 'internal'
              ? 'INTERNAL'
              : code);
      _acceptLog('accept_failed', sw, mappedCode);
      return DriverWalletGateResult(
        ok: false,
        code: mappedCode,
        message: mappedCode == 'DRIVER_WALLET_INSUFFICIENT'
            ? _messageForCode('DRIVER_WALLET_INSUFFICIENT')
            : (errText.isNotEmpty &&
                    !_looksTechnicalError(errText)
                ? errText
                : _messageForCode(mappedCode)),
      );
    }

    // CF unavailable / IAM / timeout → client transactional claim (rules-gated).
    // Do not soft-fallback on opaque `internal` — that often hides a real server fault.
    final softFail = cfCode == 'not-found' ||
        cfCode == 'unavailable' ||
        cfCode == 'unimplemented' ||
        cfCode == 'deadline-exceeded' ||
        errorCode == 'BOOKING_SERVICE_UNAVAILABLE' ||
        cf.isEmpty;
    if (!softFail && (cf['error'] != null || cf['ok'] == false)) {
      _acceptLog('accept_failed', sw, errorCode.isEmpty ? cfCode : errorCode);
      return DriverWalletGateResult(
        ok: false,
        code: errorCode.isNotEmpty ? errorCode : cfCode,
        message: _messageForCode(
          errorCode.isNotEmpty ? errorCode : 'BOOKING_ASSIGNMENT_FAILED',
        ),
      );
    }

    // Cash must go through server accept (wallet enforced in Admin SDK).
    if (isCashOrder(order)) {
      _acceptLog('accept_failed', sw, 'CASH_REQUIRES_CF');
      return DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_SERVICE_UNAVAILABLE',
        message: _messageForCode('BOOKING_SERVICE_UNAVAILABLE'),
      );
    }

    // Re-check wallet right before any non-cash fallback is unnecessary;
    // still re-validate for safety if payment classification was ambiguous.
    final walletAgain = await validateWalletForAccept(order: order);
    if (!walletAgain.ok) {
      _acceptLog('accept_failed', sw, walletAgain.code);
      return walletAgain;
    }

    final safeDriverLoc = usableDriverLocation(driverLocation);

    _acceptLog('transaction_started', sw, 'client_fallback');
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

        final deadlineAt = DriverOrderAvailability.acceptanceDeadlineAt(data);
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
        if (safeDriverLoc != null) {
          claim['mapuser'] = GeoPoint(
            safeDriverLoc.latitude,
            safeDriverLoc.longitude,
          );
          claim['driver_accept_location'] = GeoPoint(
            safeDriverLoc.latitude,
            safeDriverLoc.longitude,
          );
        }
        tx.update(order.reference, claim);
      }).timeout(const Duration(seconds: 12));
      _acceptLog('transaction_committed', sw, 'client_fallback');
    } on StateError catch (e) {
      final code = e.message;
      _acceptLog('accept_failed', sw, code);
      return DriverWalletGateResult(
        ok: false,
        code: code,
        message: _messageForCode(code),
      );
    } on FirebaseException catch (e) {
      _acceptLog('accept_failed', sw, e.code);
      return DriverWalletGateResult(
        ok: false,
        code: e.code,
        message: e.code == 'permission-denied'
            ? _messageForCode('PERMISSION_DENIED')
            : _messageForCode('BOOKING_ASSIGNMENT_FAILED'),
      );
    } catch (e) {
      _acceptLog('accept_failed', sw, e);
      return DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_ASSIGNMENT_FAILED',
        message: _messageForCode('BOOKING_ASSIGNMENT_FAILED'),
      );
    }

    FFAppState().revOrder = order.reference;
    onStateChanged();
    unawaited(_postAcceptSideEffects(order, driverRef, safeDriverLoc));
    _acceptLog('accept_completed', sw, 'via_client_txn');
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
      await actions.startTrackingAndUpdateFirebase(order.reference);
    } catch (_) {}
    try {
      final userRef = order.user;
      if (userRef != null) {
        final locale =
            await TouryNotificationLocalizer.localeForUserRef(userRef);
        final driverName = currentUserDisplayName.trim().isEmpty
            ? 'Touri'
            : currentUserDisplayName.trim();
        triggerPushNotification(
          notificationTitle: await TouryNotificationLocalizer.text(
            locale,
            'notification_order_accepted_title',
          ),
          notificationText: await TouryNotificationLocalizer.text(
            locale,
            'notification_order_accepted_body',
            args: {'driver': driverName},
          ),
          userRefs: [userRef],
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

    final startAt = getCurrentTimestamp;
    final hours = order.totalTaim;
    final endAt = hours > 0 ? startAt.add(Duration(hours: hours)) : null;
    final safeLoc = usableDriverLocation(driverLocation);

    await order.reference.update({
      ...createOrderRecordData(
        halhText: DriverTripHalh.inProgress,
        mapuser: safeLoc,
        timestamp: startAt,
        start: startAt,
        endTime: endAt,
        activeOrder: true,
      ),
      'status_code': TourySystemStatusCodes.tripInProgress,
      'trip_started_at': FieldValue.serverTimestamp(),
    });

    FFAppState().startTime = startAt;
    if (endAt != null) {
      FFAppState().EndDate = endAt;
    }
    FFAppState().update(() {});
  }

  /// Whether the driver may complete:
  /// 1) trip in progress
  /// 2) booked duration fully elapsed
  /// 3) near dropoff (نقطة التسليم) when destination + GPS are known
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

    final started = tripStartedAt(order);
    if (started == null) return false;

    final elapsed = DateTime.now().difference(started);
    final required = bookedTripDuration(order);
    if (elapsed < required) return false;

    if (allowRemoteOverride) return true;

    final dropoff = order.tripDestination;
    final driver = usableDriverLocation(driverLocation) ??
        usableDriverLocation(order.mapuser) ??
        usableDriverLocation(currentUserDocument?.loceshnMndobNow);

    // No known dropoff → time gate only (cannot prove proximity).
    if (dropoff == null) return true;

    // Dropoff known but GPS missing/invalid → block complete.
    if (driver == null) return false;

    final meters = haversineMeters(
      driver.latitude,
      driver.longitude,
      dropoff.latitude,
      dropoff.longitude,
    );
    return meters <= dropoffRadiusMeters;
  }

  /// Why complete is blocked (for UI). Null when allowed.
  static String? completeBlockReason({
    required OrderRecord order,
    LatLng? driverLocation,
  }) {
    if (!isTripInProgress(order)) return 'BOOKING_INVALID_STATE';
    final left = remainingBeforeComplete(order);
    if (left == null) return 'BOOKING_INVALID_STATE';
    if (left > Duration.zero) return 'BOOKING_TOO_FAR_OR_TOO_EARLY';

    final dropoff = order.tripDestination;
    if (dropoff == null) return null;

    final driver = usableDriverLocation(driverLocation) ??
        usableDriverLocation(order.mapuser) ??
        usableDriverLocation(currentUserDocument?.loceshnMndobNow);
    if (driver == null) return 'LOCATION_REQUIRED';

    final meters = haversineMeters(
      driver.latitude,
      driver.longitude,
      dropoff.latitude,
      dropoff.longitude,
    );
    if (meters > dropoffRadiusMeters) return 'TOO_FAR_FROM_DROPOFF';
    return null;
  }

  /// Booked length from `total_taim` (hours). Falls back to a short minimum.
  static Duration bookedTripDuration(OrderRecord order) {
    final hours = order.totalTaim;
    if (hours > 0) return Duration(hours: hours);
    return const Duration(seconds: minTripSecondsBeforeComplete);
  }

  static DateTime? tripStartedAt(OrderRecord order) {
    return order.start ??
        _asDateTime(order.snapshotData['trip_started_at']);
  }

  /// Booked trip end: prefer Firestore `endTime`, else start + total_taim.
  static DateTime? tripEndsAt(OrderRecord order) {
    if (order.endTime != null) return order.endTime;
    final started = tripStartedAt(order);
    if (started == null) return null;
    return started.add(bookedTripDuration(order));
  }

  static bool isTripInProgress(OrderRecord order) {
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    return code == TourySystemStatusCodes.tripInProgress ||
        code == TourySystemStatusCodes.tripStarted ||
        order.halhText == DriverTripHalh.inProgress;
  }

  /// Remaining countdown ms for the trip timer UI (0 when elapsed/unknown).
  static int remainingTripCountdownMs(
    OrderRecord order, {
    DateTime? now,
  }) {
    final left = remainingBeforeComplete(order, now: now);
    if (left == null) return 0;
    return left.inMilliseconds;
  }

  /// Sync local AppState timer anchors from the order document.
  static void syncLocalTripTimerState(OrderRecord order) {
    final started = tripStartedAt(order);
    final ends = tripEndsAt(order);
    if (started != null) {
      FFAppState().startTime = started;
    }
    if (ends != null) {
      FFAppState().EndDate = ends;
    }
  }

  /// Remaining time before complete is allowed; `Duration.zero` when ready.
  static Duration? remainingBeforeComplete(
    OrderRecord order, {
    DateTime? now,
  }) {
    final started = tripStartedAt(order);
    if (started == null) return null;
    final left =
        bookedTripDuration(order) - (now ?? DateTime.now()).difference(started);
    return left.isNegative ? Duration.zero : left;
  }

  static String formatRemainingTripTime(Duration remaining) {
    final totalMinutes = remaining.inMinutes;
    if (totalMinutes <= 0) return '0';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h <= 0) return '${m}د';
    if (m <= 0) return '${h}س';
    return '${h}س ${m}د';
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
      final reason = completeBlockReason(
            order: order,
            driverLocation: driverLocation,
          ) ??
          'BOOKING_TOO_FAR_OR_TOO_EARLY';
      throw StateError(reason);
    }

    final isCash = isCashOrder(order);
    final safeLoc = usableDriverLocation(driverLocation);
    // Cash is NOT auto-collected on complete — driver must confirm separately.
    // Electronic payment_status is never written by the driver app.
    // Preserve booked endTime; completion instant lives in completedAt/dateend.
    await order.reference.update({
      ...createOrderRecordData(
        halhText: DriverTripHalh.completed,
        mndobUser: currentUserReference,
        dateend: getCurrentTimestamp,
        activeOrder: false,
        halhOrderMndob: HalhOrder.Completed,
        mapuser: safeLoc,
      ),
      'status_code': TourySystemStatusCodes.completed,
      'halh_text_completed_alias': DriverTripHalh.completedAlias,
      'completedAt': FieldValue.serverTimestamp(),
      if (isCash && !DriverPaymentStatusMapper.isCashCollected(order)) ...{
        'payment_status': TourySystemStatusCodes.pendingCash,
        'cash_collection_status': 'pending',
      },
    });

    FFAppState().EndDate = null;
    FFAppState().startTime = null;
    FFAppState().update(() {});

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
    unawaited(_releaseCustomerActiveOrderLock(order));
  }

  /// Best-effort: clear customer `active_order_id` when this order ends.
  static Future<void> _releaseCustomerActiveOrderLock(OrderRecord order) async {
    final userRef = order.user;
    if (userRef == null) return;
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final userSnap = await txn.get(userRef);
        if (!userSnap.exists) return;
        final data = userSnap.data() as Map<String, dynamic>? ?? {};
        final currentId = (data['active_order_id'] ?? '').toString().trim();
        if (currentId.isEmpty || currentId != order.reference.id) return;
        txn.set(
          userRef,
          {
            'active_order_id': FieldValue.delete(),
            'active_order_updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
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
        final locale =
            await TouryNotificationLocalizer.localeForUserRef(order.user);
        triggerPushNotification(
          notificationTitle: await TouryNotificationLocalizer.text(
            locale,
            'notification_order_cancelled_by_driver_title',
          ),
          notificationText: await TouryNotificationLocalizer.text(
            locale,
            'notification_order_cancelled_by_driver_body',
          ),
          userRefs: [order.user!],
          initialPageName: 'tfasel_order',
          parameterData: {
            'idorder': order.reference,
          },
        );
      }

      unawaited(_releaseCustomerActiveOrderLock(order));

      return const DriverWalletGateResult(ok: true);
    } catch (e) {
      return DriverWalletGateResult(
        ok: false,
        code: 'BOOKING_ASSIGNMENT_FAILED',
        message: _messageForCode('BOOKING_ASSIGNMENT_FAILED'),
      );
    }
  }

  static Future<void> markStopVisited({
    required OrderRecord order,
    required int stopIndex,
  }) async {
    final stops = order.listAmakn.toList();
    if (stopIndex < 0 || stopIndex >= stops.length) {
      throw StateError('BOOKING_INVALID_STATE');
    }
    if (stops[stopIndex].okdone) return;

    final updated = <Map<String, dynamic>>[];
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      updated.add(
        mapToFirestore(
          AmaknCoistmStruct(
            naim: s.hasNaim() ? s.naim : null,
            address: s.hasAddress() ? s.address : null,
            loceshn: s.loceshn,
            okdone: i == stopIndex ? true : (s.hasOkdone() ? s.okdone : null),
            revmkan: s.hasRevmkan() ? s.revmkan : null,
          ).toMap(),
        ),
      );
    }

    await order.reference.update({
      'listAmakn': updated,
    }).timeout(const Duration(seconds: 12));
  }

  static Future<void> markDriverArrived({
    required DocumentReference orderRef,
    LatLng? driverLocation,
    DocumentReference? customerRef,
    OrderRecord? order,
  }) async {
    final now = getCurrentTimestamp;
    final safeLoc = usableDriverLocation(driverLocation);

    // Soft proximity check when we have pickup + GPS.
    final pickup = order?.lokeshn ?? order?.customerPickup;
    if (pickup != null && safeLoc != null) {
      final meters = haversineMeters(
        safeLoc.latitude,
        safeLoc.longitude,
        pickup.latitude,
        pickup.longitude,
      );
      if (meters > arrivalRadiusMeters * 3) {
        // Allow with warning path — still mark arrived but require being
        // reasonably near pickup (3x radius soft gate for manual button).
        throw StateError('TOO_FAR_FROM_PICKUP');
      }
    }

    await orderRef.update({
      ...createOrderRecordData(
        halhText: DriverTripHalh.driverArrived,
        mapuser: safeLoc,
        timestamp: now,
        activeOrder: true,
      ),
      'driverArrivedAt': now,
      'waitingStartedAt': now,
      'customerWaitingTimeInSeconds': 0,
      'status_code': TourySystemStatusCodes.driverArrived,
    }).timeout(const Duration(seconds: 12));

    // Never block the driver UI on push / re-fetch (can hang on flaky network).
    unawaited(_notifyDriverArrived(
      orderRef: orderRef,
      customerRef: customerRef,
    ));
  }

  static Future<void> _notifyDriverArrived({
    required DocumentReference orderRef,
    DocumentReference? customerRef,
  }) async {
    try {
      DocumentReference? user = customerRef;
      if (user == null) {
        final order = await OrderRecord.getDocumentOnce(orderRef)
            .timeout(const Duration(seconds: 8));
        user = order.user;
      }
      if (user == null) return;
      final locale = await TouryNotificationLocalizer.localeForUserRef(user);
      final driverName = currentUserDisplayName.trim().isEmpty
          ? 'Touri'
          : currentUserDisplayName.trim();
      triggerPushNotification(
        notificationTitle: await TouryNotificationLocalizer.text(
          locale,
          'notification_driver_arrived_title',
        ),
        notificationText: await TouryNotificationLocalizer.text(
          locale,
          'notification_driver_arrived_body',
          args: {'driver': driverName},
        ),
        userRefs: [user],
        initialPageName: 'tfasel_order',
        parameterData: {
          'idorder': orderRef,
        },
      );
    } catch (_) {}
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
        driverLocation: usableDriverLocation(driverPosition),
        order: order,
        customerRef: order.user,
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
    double? heading,
    double? speed,
  }) async {
    final orderUpdates = <String, dynamic>{
      'mapuser':
          GeoPoint(driverPosition.latitude, driverPosition.longitude),
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (heading != null && heading.isFinite) {
      orderUpdates['driverHeading'] = heading;
    }
    if (speed != null && speed.isFinite && speed >= 0) {
      orderUpdates['speed'] = speed;
    }

    if (target != null) {
      final shouldRefreshEta = _shouldRefreshRoadEta(
        origin: driverPosition,
        target: target,
      );
      if (shouldRefreshEta) {
        try {
          final route = await DriverDirectionsService.fetchRoadRouteResult(
            [driverPosition, target],
            optimal: true,
          );
          _lastEtaFetchAt = DateTime.now();
          _lastEtaOrigin = driverPosition;
          _lastEtaTarget = target;
          if (route != null &&
              (route.durationSeconds > 0 || route.distanceMeters > 0)) {
            _cachedEtaSeconds = route.durationSeconds;
            _cachedDistanceMeters = route.distanceMeters;
            _cachedEtaApproximate = route.approximate || !route.trafficAware;
          } else {
            // Safe temporary fallback — never crash tracking.
            final meters = haversineMeters(
              driverPosition.latitude,
              driverPosition.longitude,
              target.latitude,
              target.longitude,
            );
            _cachedDistanceMeters = meters.round();
            _cachedEtaSeconds = (meters / 8.33).round();
            _cachedEtaApproximate = true;
          }
        } catch (e) {
          debugPrint('updateTrackingMetrics route ETA: $e');
          final meters = haversineMeters(
            driverPosition.latitude,
            driverPosition.longitude,
            target.latitude,
            target.longitude,
          );
          _cachedDistanceMeters = meters.round();
          _cachedEtaSeconds = (meters / 8.33).round();
          _cachedEtaApproximate = true;
        }
      }

      if (_cachedDistanceMeters != null) {
        orderUpdates['distanceRemainingMeters'] = _cachedDistanceMeters;
      }
      if (_cachedEtaSeconds != null) {
        orderUpdates['etaSeconds'] = _cachedEtaSeconds;
      }
      orderUpdates['etaApproximate'] = _cachedEtaApproximate;
      orderUpdates['etaUpdatedAt'] = FieldValue.serverTimestamp();
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

  static bool _shouldRefreshRoadEta({
    required LatLng origin,
    required LatLng target,
  }) {
    if (_lastEtaFetchAt == null ||
        _cachedEtaSeconds == null ||
        _lastEtaOrigin == null ||
        _lastEtaTarget == null) {
      return true;
    }
    final age = DateTime.now().difference(_lastEtaFetchAt!);
    if (age >= _etaRefreshInterval) return true;

    final originMoved = haversineMeters(
      _lastEtaOrigin!.latitude,
      _lastEtaOrigin!.longitude,
      origin.latitude,
      origin.longitude,
    );
    if (originMoved >= _etaMoveThresholdMeters) return true;

    final targetMoved = haversineMeters(
      _lastEtaTarget!.latitude,
      _lastEtaTarget!.longitude,
      target.latitude,
      target.longitude,
    );
    return targetMoved >= 30;
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

  static bool _looksTechnicalError(String msg) {
    final t = msg.trim();
    if (t.isEmpty) return true;
    final upper = t.toUpperCase();
    return upper == 'INTERNAL' ||
        upper.contains('STACK') ||
        upper.contains('EXCEPTION') ||
        upper.contains('FIREBASE') ||
        RegExp(r'^[A-Z0-9_:-]+$').hasMatch(t);
  }

  static String _messageForCode(String code) {
    switch (code) {
      case 'BOOKING_NOT_FOUND':
        return 'الطلب غير موجود.';
      case 'BOOKING_ALREADY_ASSIGNED':
        return 'تم قبول هذه الرحلة بواسطة مندوب آخر.';
      case 'BOOKING_INVALID_STATE':
        return 'لا يمكن تحديث هذا الطلب في حالته الحالية.';
      case 'BOOKING_EXPIRED':
        return 'انتهت مهلة قبول الطلب. لم يعد بإمكانك قبول هذا الطلب.';
      case 'DRIVER_WALLET_INSUFFICIENT':
      case 'insufficient-wallet':
        return 'يجب أن يكون رصيد محفظتك 200 ريال على الأقل لقبول الطلبات النقدية.';
      case 'DRIVER_DISABLED':
      case 'driver-disabled':
        return 'حساب المندوب غير مفعّل أو موقوف.';
      case 'BOOKING_SERVICE_UNAVAILABLE':
        return 'خدمة القبول غير متاحة مؤقتًا. حاول مرة أخرى.';
      case 'BOOKING_TOO_FAR_OR_TOO_EARLY':
        return 'لا يمكن إنهاء الرحلة قبل انتهاء وقتها المحجوز.';
      case 'TOO_FAR_FROM_DROPOFF':
        return 'يجب أن تكون قريبًا من نقطة التسليم لإنهاء الرحلة.';
      case 'TOO_FAR_FROM_PICKUP':
        return 'يجب أن تكون قريبًا من موقع العميل لتأكيد الوصول.';
      case 'LOCATION_REQUIRED':
        return 'تعذّر تحديد موقعك. فعّل GPS ثم حاول مرة أخرى.';
      case 'PERMISSION_DENIED':
        return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
      case 'OFFLINE':
        return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم حاول مرة أخرى.';
      case 'ACCEPT_IN_PROGRESS':
        return 'جاري قبول الطلب، يرجى الانتظار.';
      case 'INTERNAL':
      case 'internal':
        return 'تعذّر القبول بسبب خطأ في الخادم. حاول مرة أخرى.';
      default:
        return 'تعذّر القبول. حاول مرة أخرى.';
    }
  }
}

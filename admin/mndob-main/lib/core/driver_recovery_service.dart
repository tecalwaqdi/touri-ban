import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_legacy_field_compat.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_live_location_service.dart';
import '/core/driver_offline_queue.dart';
import '/core/driver_online_state.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_trip_service.dart';
import '/core/toury_system_status_codes.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/flutter_flow_util.dart';

/// Snapshot rebuilt from Firestore — never local-cache-only.
class DriverRecoveredTrip {
  const DriverRecoveredTrip({
    required this.orderRef,
    required this.order,
    required this.statusCode,
    required this.halhText,
    required this.paymentMethod,
    required this.nextAction,
  });

  final DocumentReference orderRef;
  final OrderRecord order;
  final String statusCode;
  final String halhText;
  final String paymentMethod;
  final String nextAction;

  String get orderId => orderRef.id;
  String? get driverId => currentUserUid;
  String get customerName => order.naimUserText;
}

abstract final class DriverRecoveryService {
  DriverRecoveryService._();

  /// Force Auth token refresh + reload user document from server.
  static Future<bool> refreshSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      await user.getIdToken(true);
      await user.reload();
      if (currentUserReference != null) {
        currentUserDocument =
            await UserRecord.getDocumentOnce(currentUserReference!);
      }
      DriverRuntimeDiagnostics.note('session', 'refreshed');
      return true;
    } catch (e) {
      DriverRuntimeDiagnostics.note('session', 'refresh_failed');
      debugPrint('DriverRecoveryService.refreshSession: $e');
      return false;
    }
  }

  static DriverLifecycle readLifecycle() => DriverLifecycleState.resolve();

  static String? readOperationalStatus() {
    final doc = currentUserDocument;
    if (doc == null) return null;
    return (doc.snapshotData['operational_status'] as String?) ??
        (DriverLegacyFieldCompat.isOnline(readLifecycle())
            ? 'online'
            : 'offline');
  }

  /// Backend-first active trip restore.
  static Future<DriverRecoveredTrip?> recoverActiveTrip() async {
    final ref = await DriverTripService.restoreActiveTripRef();
    if (ref == null) {
      FFAppState().revOrder = null;
      DriverRuntimeDiagnostics.currentOrderPath = null;
      return null;
    }
    final order = await OrderRecord.getDocumentOnce(ref);
    if (!DriverTripService.isActiveTripForCurrentDriver(order)) {
      FFAppState().revOrder = null;
      DriverRuntimeDiagnostics.currentOrderPath = null;
      try {
        await actions.stopTracking();
      } catch (_) {}
      return null;
    }

    FFAppState().revOrder = ref;
    DriverRuntimeDiagnostics.currentOrderPath = ref.path;
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();
    final next = _nextAction(code, order.halhText);
    return DriverRecoveredTrip(
      orderRef: ref,
      order: order,
      statusCode: code,
      halhText: order.halhText,
      paymentMethod: order.paymentMethod?.name ?? '',
      nextAction: next,
    );
  }

  static String _nextAction(String code, String halh) {
    if (code == TourySystemStatusCodes.driverAssigned ||
        code == TourySystemStatusCodes.driverArriving ||
        halh == DriverTripHalh.accepted) {
      return 'arrive';
    }
    if (code == TourySystemStatusCodes.driverArrived ||
        halh == DriverTripHalh.driverArrived) {
      return 'start';
    }
    if (code == TourySystemStatusCodes.tripInProgress ||
        code == TourySystemStatusCodes.tripStarted ||
        halh == DriverTripHalh.inProgress) {
      return 'complete';
    }
    return 'none';
  }

  static Future<void> syncTrackingForState({
    required bool online,
    required bool hasActiveTrip,
  }) async {
    if (!loggedIn) {
      DriverLiveLocationService.stopIdleSync(force: true);
      DriverRuntimeDiagnostics.locationSyncActive = false;
      try {
        await actions.stopTracking();
      } catch (_) {}
      return;
    }
    if (online || hasActiveTrip) {
      DriverLiveLocationService.startIdleSync(isOnline: online || hasActiveTrip);
      DriverRuntimeDiagnostics.locationSyncActive = true;
      if (hasActiveTrip && FFAppState().revOrder != null) {
        try {
          await actions.trackOrderLocation(FFAppState().revOrder!);
          await actions.startTrackingAndUpdateFirebase(FFAppState().revOrder!);
        } catch (e) {
          debugPrint('DriverRecoveryService tracking: $e');
        }
      }
    } else {
      DriverLiveLocationService.stopIdleSync(force: true);
      DriverRuntimeDiagnostics.locationSyncActive = false;
      try {
        await actions.stopTracking();
      } catch (_) {}
    }
  }

  /// Reconcile one queued op against live backend state — never blind replay.
  static Future<DriverOfflineReconcileResult> reconcileOfflineOp(
    DriverOfflineAction op,
  ) async {
    switch (op.type) {
      case DriverOfflineOpType.setOnline:
        if (DriverOnlineState.isMarkedOnline) {
          return const DriverOfflineReconcileResult(
            alreadyDone: true,
            message: 'already_online',
          );
        }
        final r = await DriverOnlineState.goOnline();
        return DriverOfflineReconcileResult(
          applied: r.ok,
          requiresOnlineUi: !r.ok,
          message: r.message ?? (r.ok ? 'online' : 'go_online_failed'),
        );
      case DriverOfflineOpType.setOffline:
        if (!DriverOnlineState.isMarkedOnline) {
          return const DriverOfflineReconcileResult(
            alreadyDone: true,
            message: 'already_offline',
          );
        }
        final r = await DriverOnlineState.goOffline(
          hasActiveTrip: FFAppState().revOrder != null,
        );
        return DriverOfflineReconcileResult(
          applied: r.ok,
          requiresOnlineUi: !r.ok,
          message: r.message ?? (r.ok ? 'offline' : 'go_offline_failed'),
        );
      case DriverOfflineOpType.acceptOrder:
        return _reconcileAccept(op);
      case DriverOfflineOpType.driverArrived:
      case DriverOfflineOpType.startTrip:
      case DriverOfflineOpType.completeTrip:
      case DriverOfflineOpType.cancelTrip:
      case DriverOfflineOpType.cashConfirmation:
        return _reconcileTripMutation(op);
    }
  }

  static Future<DriverOfflineReconcileResult> _reconcileAccept(
    DriverOfflineAction op,
  ) async {
    final path = op.orderPath;
    if (path == null || path.isEmpty) {
      return const DriverOfflineReconcileResult(
        requiresOnlineUi: true,
        message: 'missing_order',
      );
    }
    final ref = FirebaseFirestore.instance.doc(path);
    final order = await OrderRecord.getDocumentOnce(ref);
    if (order.mndobUser?.path == currentUserReference?.path) {
      FFAppState().revOrder = ref;
      return const DriverOfflineReconcileResult(
        alreadyDone: true,
        message: 'already_assigned_self',
      );
    }
    if (order.mndobUser != null) {
      return const DriverOfflineReconcileResult(
        requiresOnlineUi: true,
        message: 'BOOKING_ALREADY_ASSIGNED',
      );
    }
    // Safe path: require online interactive accept — do not auto-accept offline.
    return const DriverOfflineReconcileResult(
      requiresOnlineUi: true,
      message: 'Connection required to accept. Order not auto-accepted.',
    );
  }

  static Future<DriverOfflineReconcileResult> _reconcileTripMutation(
    DriverOfflineAction op,
  ) async {
    final path = op.orderPath;
    if (path == null) {
      return const DriverOfflineReconcileResult(
        requiresOnlineUi: true,
        message: 'missing_order',
      );
    }
    final order = await OrderRecord.getDocumentOnce(
      FirebaseFirestore.instance.doc(path),
    );
    final code =
        (order.snapshotData['status_code'] ?? '').toString().trim();

    if (op.type == DriverOfflineOpType.completeTrip ||
        op.type == DriverOfflineOpType.cashConfirmation) {
      if (code == TourySystemStatusCodes.completed ||
          order.halhText == DriverTripHalh.completed) {
        return const DriverOfflineReconcileResult(
          alreadyDone: true,
          message: 'already_completed',
        );
      }
      return const DriverOfflineReconcileResult(
        requiresOnlineUi: true,
        message: 'Connection required to complete trip safely.',
      );
    }
    if (op.type == DriverOfflineOpType.cancelTrip) {
      if (TourySystemStatusCodes.isTerminalBooking(code)) {
        return const DriverOfflineReconcileResult(
          alreadyDone: true,
          message: 'already_terminal',
        );
      }
      return const DriverOfflineReconcileResult(
        requiresOnlineUi: true,
        message: 'Connection required to cancel trip.',
      );
    }
    if (op.type == DriverOfflineOpType.startTrip) {
      if (code == TourySystemStatusCodes.tripInProgress ||
          code == TourySystemStatusCodes.tripStarted) {
        return const DriverOfflineReconcileResult(
          alreadyDone: true,
          message: 'already_started',
        );
      }
      return const DriverOfflineReconcileResult(
        requiresOnlineUi: true,
        message: 'Connection required to start trip.',
      );
    }
    if (op.type == DriverOfflineOpType.driverArrived) {
      if (code == TourySystemStatusCodes.driverArrived ||
          code == TourySystemStatusCodes.tripInProgress) {
        return const DriverOfflineReconcileResult(
          alreadyDone: true,
          message: 'already_arrived_or_beyond',
        );
      }
      return const DriverOfflineReconcileResult(
        requiresOnlineUi: true,
        message: 'Connection required to mark arrived.',
      );
    }
    return const DriverOfflineReconcileResult(
      requiresOnlineUi: true,
      message: 'unsupported_op',
    );
  }
}

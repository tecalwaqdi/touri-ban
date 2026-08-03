import 'dart:async';

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/driver_offline_queue.dart';
import '/core/driver_recovery_service.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Central app lifecycle + recovery + offline flush coordinator.
abstract final class DriverAppLifecycleCoordinator {
  DriverAppLifecycleCoordinator._();

  static bool _bootstrapped = false;
  static bool _recovering = false;
  static StreamSubscription<bool>? _connectivitySub;
  static AppLifecycleState? lastState;

  static Future<void> bootstrap({
    required BuildContext? context,
    bool navigateToTrip = false,
  }) async {
    if (_bootstrapped) {
      await onResume(context: context, navigateToTrip: navigateToTrip);
      return;
    }
    _bootstrapped = true;
    await DriverConnectivityService.start();
    _connectivitySub?.cancel();
    _connectivitySub = DriverConnectivityService.onChanged.listen((online) {
      DriverRuntimeDiagnostics.note(
        'lifecycle',
        online ? 'network_restored' : 'network_disconnected',
      );
      if (online) {
        unawaited(_flushQueue());
        unawaited(onResume(context: null, navigateToTrip: false));
      }
    });
    final navContext = context;
    final canNavigate =
        navigateToTrip && navContext != null && navContext.mounted;
    await onResume(
      context: canNavigate ? navContext : null,
      navigateToTrip: canNavigate,
    );
  }

  static Future<void> disposeAll() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await DriverConnectivityService.stop();
    _bootstrapped = false;
  }

  static Future<void> handleLifecycle(
    AppLifecycleState state, {
    BuildContext? context,
  }) async {
    lastState = state;
    DriverRuntimeDiagnostics.note('lifecycle', state.name);
    switch (state) {
      case AppLifecycleState.resumed:
        await onResume(context: context, navigateToTrip: true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Keep trip tracking; do not tear down unless logged out.
        break;
    }
  }

  static Future<void> onResume({
    BuildContext? context,
    required bool navigateToTrip,
  }) async {
    if (_recovering) return;
    _recovering = true;
    try {
      if (!loggedIn) {
        await DriverRecoveryService.syncTrackingForState(
          online: false,
          hasActiveTrip: false,
        );
        return;
      }

      await DriverConnectivityService.probe();
      await DriverRecoveryService.refreshSession();

      final life = DriverRecoveryService.readLifecycle();
      final ops = DriverRecoveryService.readOperationalStatus();
      DriverRuntimeDiagnostics.note(
        'recovery',
        'lifecycle=${life.name} operational=$ops',
      );

      final trip = await DriverRecoveryService.recoverActiveTrip();
      final online = ops == 'online' ||
          (currentUserDocument?.ngl == true);
      await DriverRecoveryService.syncTrackingForState(
        online: online,
        hasActiveTrip: trip != null,
      );

      if (DriverConnectivityService.isOnline) {
        await _flushQueue();
      }

      if (trip != null &&
          navigateToTrip &&
          context != null &&
          context.mounted) {
        final loc = GoRouterState.of(context).uri.path;
        if (!loc.contains('tfaselOrser') && !loc.contains('tfasel')) {
          context.pushNamed(
            TfaselOrserWidget.routeName,
            queryParameters: {
              'id': serializeParam(
                trip.orderRef,
                ParamType.DocumentReference,
              ),
            }.withoutNulls,
          );
        }
      }
    } catch (e) {
      debugPrint('DriverAppLifecycleCoordinator.onResume: $e');
    } finally {
      _recovering = false;
    }
  }

  static Future<void> _flushQueue() async {
    await DriverOfflineActionQueue.flush(
      DriverRecoveryService.reconcileOfflineOp,
    );
  }

  /// Gate sensitive ops: if offline, enqueue and return false with message.
  static Future<DriverLifecycleGateResult> requireOnlineOrEnqueue({
    required DriverOfflineOpType type,
    String? orderPath,
    Map<String, dynamic> payload = const {},
    bool allowQueue = true,
  }) async {
    final online = await DriverConnectivityService.probe();
    if (online) {
      return const DriverLifecycleGateResult(ok: true);
    }
    if (allowQueue) {
      final id = await DriverOfflineActionQueue.enqueue(
        type: type,
        orderPath: orderPath,
        payload: payload,
      );
      return DriverLifecycleGateResult(
        ok: false,
        queued: true,
        operationId: id,
        message:
            'No connection. Action queued and will be reconciled when online.',
      );
    }
    return const DriverLifecycleGateResult(
      ok: false,
      queued: false,
      message: 'Connection required. Please try again when online.',
    );
  }
}

class DriverLifecycleGateResult {
  const DriverLifecycleGateResult({
    required this.ok,
    this.queued = false,
    this.operationId,
    this.message,
  });

  final bool ok;
  final bool queued;
  final String? operationId;
  final String? message;
}

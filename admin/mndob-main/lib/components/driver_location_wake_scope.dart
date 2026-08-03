import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/driver_app_lifecycle_coordinator.dart';
import '/core/driver_live_location_service.dart';
import '/core/driver_offline_queue.dart';
import '/core/driver_recovery_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// App resume / cold-start recovery scope (backend-first, no duplicate timers).
class DriverLocationWakeScope extends StatefulWidget {
  const DriverLocationWakeScope({super.key, required this.child});

  final Widget child;

  @override
  State<DriverLocationWakeScope> createState() =>
      _DriverLocationWakeScopeState();
}

class _DriverLocationWakeScopeState extends State<DriverLocationWakeScope>
    with WidgetsBindingObserver {
  bool? _lastOnline;
  String? _lastOrderPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DriverAppLifecycleCoordinator.bootstrap(
        context: context,
        navigateToTrip: false,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DriverAppLifecycleCoordinator.handleLifecycle(state, context: context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncFromAuthDoc() {
    if (!loggedIn) {
      DriverLiveLocationService.stopIdleSync(force: true);
      return;
    }
    final online = valueOrDefault(currentUserDocument?.ngl, false);
    final orderPath = FFAppState().revOrder?.path;
    if (_lastOnline == online && _lastOrderPath == orderPath) return;
    _lastOnline = online;
    _lastOrderPath = orderPath;
    DriverRuntimeDiagnostics.note(
      'auth_doc',
      'online=$online trip=${orderPath != null}',
    );
    unawaited(DriverRecoveryService.syncTrackingForState(
      online: online,
      hasActiveTrip: orderPath != null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromAuthDoc());
        return widget.child;
      },
    );
  }
}

void unawaited(Future<void> future) {
  future.then((_) {}, onError: (Object e, StackTrace st) {
    debugPrint('unawaited error: $e');
  });
}

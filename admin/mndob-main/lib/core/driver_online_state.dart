import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_app_lifecycle_coordinator.dart';
import '/core/driver_eligibility_service.dart';
import '/core/driver_legacy_field_compat.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_live_location_service.dart';
import '/core/driver_offline_queue.dart';

/// Single definition of "driver is online and can receive work".
abstract final class DriverOnlineState {
  DriverOnlineState._();

  static DriverLifecycle get lifecycle => DriverLifecycleState.resolve();

  static bool get isApproved =>
      DriverLegacyFieldCompat.isOperationallyApproved(lifecycle);

  static bool get isMarkedOnline => DriverLegacyFieldCompat.isOnline(lifecycle);

  /// Driver can see/accept new orders when approved + online + not busy.
  static bool get canReceiveOrders {
    final life = lifecycle;
    if (!DriverLegacyFieldCompat.isOperationallyApproved(life)) return false;
    if (life != DriverLifecycle.activeOnline) return false;
    return true;
  }

  /// Banner "inactive" should only show when not approved OR explicitly offline.
  static bool get showInactiveBanner =>
      !isApproved || lifecycle == DriverLifecycle.activeOffline;

  static Map<String, dynamic> _onlinePatch(LatLng loc) {
    final geo = GeoPoint(loc.latitude, loc.longitude);
    return <String, dynamic>{
      'ngl': true,
      'loceshnMndobNow': geo,
      'operational_status': 'online',
      'is_online': true,
      'last_online_at': FieldValue.serverTimestamp(),
      'last_seen_at': FieldValue.serverTimestamp(),
    };
  }

  static Future<DriverOnlineGateResult> goOnline() async {
    if (!loggedIn || currentUserReference == null) {
      return const DriverOnlineGateResult(
        ok: false,
        code: 'AUTH_REQUIRED',
        message: 'Please sign in first.',
      );
    }

    final net = await DriverAppLifecycleCoordinator.requireOnlineOrEnqueue(
      type: DriverOfflineOpType.setOnline,
      allowQueue: true,
    );
    if (!net.ok) {
      return DriverOnlineGateResult(
        ok: false,
        code: net.queued ? 'QUEUED_OFFLINE' : 'OFFLINE',
        message: net.message,
      );
    }

    final eligibility = await DriverEligibilityService.evaluateForOnline();
    if (!eligibility.isEligible) {
      return DriverOnlineGateResult(
        ok: false,
        code: eligibility.reason.name,
        message: eligibility.messageKey.isNotEmpty
            ? eligibility.messageKey
            : 'Your account is waiting for admin approval before going online.',
      );
    }

    final loc = await DriverLiveLocationService.currentPosition();
    if (loc == null) {
      return const DriverOnlineGateResult(
        ok: false,
        code: 'LOCATION_UNAVAILABLE',
        message: 'Could not read your current location. Try again.',
      );
    }

    // Never self-activate — only approved drivers (actev_mndob) may go online.
    if (currentUserDocument?.actevMndob != true) {
      return const DriverOnlineGateResult(
        ok: false,
        code: 'NOT_APPROVED',
        message:
            'Your account needs admin approval before going online.',
      );
    }

    try {
      await currentUserReference!.update(_onlinePatch(loc));
    } catch (e) {
      // ignore: avoid_print
      print('DriverOnlineState.goOnline failed: $e');
      return DriverOnlineGateResult(
        ok: false,
        code: 'UPDATE_FAILED',
        message: e.toString().contains('permission-denied')
            ? 'Your account needs activation. Wait for admin approval, then try again.'
            : 'Could not go online. Check GPS and try again.',
      );
    }

    try {
      currentUserDocument =
          await UserRecord.getDocumentOnce(currentUserReference!);
    } catch (_) {}
    DriverLiveLocationService.startIdleSync(isOnline: true);
    return const DriverOnlineGateResult(ok: true);
  }

  static Future<DriverOnlineGateResult> goOffline({
    bool hasActiveTrip = false,
  }) async {
    if (!loggedIn || currentUserReference == null) {
      return const DriverOnlineGateResult(
        ok: false,
        code: 'AUTH_REQUIRED',
        message: 'Please sign in first.',
      );
    }

    if (hasActiveTrip) {
      return const DriverOnlineGateResult(
        ok: false,
        code: 'ACTIVE_TRIP',
        message: 'Trip in progress',
      );
    }

    final net = await DriverAppLifecycleCoordinator.requireOnlineOrEnqueue(
      type: DriverOfflineOpType.setOffline,
      allowQueue: true,
    );
    if (!net.ok) {
      return DriverOnlineGateResult(
        ok: false,
        code: net.queued ? 'QUEUED_OFFLINE' : 'OFFLINE',
        message: net.message,
      );
    }

    try {
      await currentUserReference!.update({
        'ngl': false,
        'operational_status': 'offline',
        'is_online': false,
        'last_offline_at': FieldValue.serverTimestamp(),
        'last_seen_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('DriverOnlineState.goOffline failed: $e');
      return const DriverOnlineGateResult(
        ok: false,
        code: 'UPDATE_FAILED',
        message: 'Could not go offline. Try again.',
      );
    }

    try {
      currentUserDocument =
          await UserRecord.getDocumentOnce(currentUserReference!);
    } catch (_) {}
    DriverLiveLocationService.stopIdleSync(force: true);
    return const DriverOnlineGateResult(ok: true);
  }

  static Future<void> setOnline(bool online) async {
    if (online) {
      await goOnline();
    } else {
      await goOffline(hasActiveTrip: FFAppState().revOrder != null);
    }
  }
}

class DriverOnlineGateResult {
  const DriverOnlineGateResult({
    required this.ok,
    this.message,
    this.code,
  });

  final bool ok;
  final String? message;
  final String? code;
}

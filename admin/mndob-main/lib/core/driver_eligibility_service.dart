import 'package:geolocator/geolocator.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/driver_legacy_field_compat.dart';
import '/core/driver_lifecycle_state.dart';
import '/flutter_flow/flutter_flow_util.dart';

enum DriverEligibilityReason {
  eligible,
  accountPending,
  accountRejected,
  accountSuspended,
  accountBlocked,
  profileIncomplete,
  vehicleIncomplete,
  vehicleNotApproved,
  documentsIncomplete,
  documentsExpired,
  gpsDisabled,
  permissionDenied,
  networkUnavailable,
  unsupportedCity,
  fcmUnavailable,
  activeTripExists,
  authRequired,
  offline,
  // Legacy aliases kept for callers/tests
  accountNotApproved,
  locationPermissionDenied,
  cityNotSupported,
}

class DriverEligibilityResult {
  const DriverEligibilityResult({
    required this.reason,
    this.messageKey = '',
  });

  final DriverEligibilityReason reason;
  final String messageKey;

  bool get isEligible => reason == DriverEligibilityReason.eligible;
}

/// Gates for Home / Go Online / Ready to Receive Orders.
abstract final class DriverEligibilityService {
  DriverEligibilityService._();

  static DriverEligibilityResult evaluateAccount() {
    if (!loggedIn || currentUser == null) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.authRequired,
        messageKey: 'Please sign in first.',
      );
    }

    final life = DriverLifecycleState.resolve();
    switch (life) {
      case DriverLifecycle.loggedOut:
        return const DriverEligibilityResult(
          reason: DriverEligibilityReason.authRequired,
          messageKey: 'Please sign in first.',
        );
      case DriverLifecycle.loading:
        return const DriverEligibilityResult(
          reason: DriverEligibilityReason.profileIncomplete,
          messageKey: 'Loading your account…',
        );
      case DriverLifecycle.incompleteProfile:
        return const DriverEligibilityResult(
          reason: DriverEligibilityReason.profileIncomplete,
          messageKey: 'Please complete your profile.',
        );
      case DriverLifecycle.pendingApproval:
      case DriverLifecycle.changesRequested:
        return const DriverEligibilityResult(
          reason: DriverEligibilityReason.accountPending,
          messageKey:
              'Your account is waiting for admin approval before going online.',
        );
      case DriverLifecycle.rejected:
        return const DriverEligibilityResult(
          reason: DriverEligibilityReason.accountRejected,
          messageKey: 'Your application was rejected.',
        );
      case DriverLifecycle.suspended:
        return const DriverEligibilityResult(
          reason: DriverEligibilityReason.accountSuspended,
          messageKey: 'This account has been disabled.',
        );
      case DriverLifecycle.activeOffline:
      case DriverLifecycle.activeOnline:
      case DriverLifecycle.onTrip:
        break;
    }

    final doc = currentUserDocument;
    if (doc == null) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.profileIncomplete,
        messageKey: 'Please complete your profile.',
      );
    }
    if (doc.displayName.trim().isEmpty) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.profileIncomplete,
        messageKey: 'Please complete your profile.',
      );
    }
    if (doc.mndobVill == null) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.unsupportedCity,
        messageKey: 'Please select a city',
      );
    }
    if (doc.mndobTypeCar == null) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.vehicleIncomplete,
        messageKey: 'Please select vehicle type',
      );
    }
    // Cash-wave / no-billing: profile photo and ID are optional for going online.
    // Drivers can still upload them from Profile when Storage works.

    final accountStatus =
        (doc.snapshotData['account_status'] as String?)?.toLowerCase() ?? '';
    if (accountStatus == 'blocked') {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.accountBlocked,
        messageKey: 'This account has been disabled.',
      );
    }

    final vehicleReview =
        (doc.snapshotData['vehicle_review_status'] as String?) ?? '';
    if (vehicleReview == 'rejected' || vehicleReview == 'suspended') {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.vehicleNotApproved,
        messageKey: 'Please select vehicle type',
      );
    }

    return const DriverEligibilityResult(
      reason: DriverEligibilityReason.eligible,
    );
  }

  static Future<DriverEligibilityResult> evaluateForOnline() async {
    final account = evaluateAccount();
    if (!account.isEligible) return account;

    if (DriverLifecycleState.resolve() == DriverLifecycle.onTrip ||
        valueOrDefault<bool>(currentUserDocument?.mndonNewacc, false)) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.activeTripExists,
        messageKey: 'Trip in progress',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.gpsDisabled,
        messageKey: 'Turn on GPS to go online.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.permissionDenied,
        messageKey: 'Location permission is required to go online.',
      );
    }

    return const DriverEligibilityResult(
      reason: DriverEligibilityReason.eligible,
    );
  }

  static DriverEligibilityResult evaluateReadyForOrders() {
    final account = evaluateAccount();
    if (!account.isEligible) return account;
    final life = DriverLifecycleState.resolve();
    if (!DriverLegacyFieldCompat.isOnline(life)) {
      return const DriverEligibilityResult(
        reason: DriverEligibilityReason.offline,
        messageKey: 'Go online to receive requests.',
      );
    }
    return const DriverEligibilityResult(
      reason: DriverEligibilityReason.eligible,
    );
  }
}

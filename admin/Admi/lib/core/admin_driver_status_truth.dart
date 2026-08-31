import '/core/admin_driver_profile_view.dart';

/// Operational connection (online/offline) — orthogonal to registration.
enum AdminDriverConnectionStatus {
  online,
  offline,
  unknown,
}

/// Trip availability — orthogonal to account activation.
enum AdminDriverAvailabilityStatus {
  available,
  busy,
  unavailable,
  unknown,
}

/// Five orthogonal status axes for Admin Drivers (must never collapse).
///
/// ACCOUNT ≠ REGISTRATION ≠ ONLINE ≠ AVAILABILITY ≠ ACTIVE TRIP
///
/// Source of truth mirrors Driver App gate + Cloud Functions V2:
/// - Registration: `registration_status` (fallback `submission_status`)
/// - Account: `actev_mndob` (+ optional `account_status` for display)
/// - Online: `is_online` / `ngl` / operational online
/// - Availability: derived from account + online + busy flags
/// - Active trip: `mndon_newacc` / operational `on_trip`|`busy`
class AdminDriverStatusTruth {
  const AdminDriverStatusTruth({
    required this.registration,
    required this.registrationRaw,
    required this.accountActive,
    required this.accountStatusRaw,
    required this.connection,
    required this.availability,
    required this.onActiveTrip,
    required this.isRegistrationV2,
    required this.authDisabled,
    required this.firestorePresent,
  });

  final AdminDriverReviewBucket registration;
  final String registrationRaw;
  final bool accountActive;
  final String accountStatusRaw;
  final AdminDriverConnectionStatus connection;
  final AdminDriverAvailabilityStatus availability;
  final bool onActiveTrip;
  final bool isRegistrationV2;
  final bool? authDisabled;
  final bool firestorePresent;

  /// True when registration is pending/draft/rejected but account flag is on.
  /// Display both axes — never treat as Approved solely from [accountActive].
  bool get registrationPendingWithActiveAccount =>
      accountActive &&
      (registration == AdminDriverReviewBucket.pendingReview ||
          registration == AdminDriverReviewBucket.draft ||
          registration == AdminDriverReviewBucket.needsChanges ||
          registration == AdminDriverReviewBucket.rejected);

  /// Auth disabled while Firestore still shows active/approved.
  bool get authFirestoreMismatch =>
      authDisabled == true &&
      (accountActive || registration == AdminDriverReviewBucket.approved);

  static AdminDriverStatusTruth fromMap(
    Map<String, dynamic> data, {
    bool firestorePresent = true,
    bool? authDisabled,
  }) {
    final regRaw = AdminDriverProfileView.rawRegistrationStatusFromMap(data);
    final registration = AdminDriverProfileView.reviewBucketFromRaw(regRaw);

    final accountActive = _bool(data, 'actev_mndob') == true;
    final accountStatusRaw = _str(data, 'account_status');

    final online = _bool(data, 'is_online') ?? _bool(data, 'ngl');
    final ops = _str(data, 'operational_status').toLowerCase();
    final onTrip = _bool(data, 'mndon_newacc') == true ||
        ops == 'on_trip' ||
        ops == 'busy';

    AdminDriverConnectionStatus connection;
    if (online == true) {
      connection = AdminDriverConnectionStatus.online;
    } else if (online == false) {
      connection = AdminDriverConnectionStatus.offline;
    } else if (ops == 'online') {
      connection = AdminDriverConnectionStatus.online;
    } else if (ops == 'offline') {
      connection = AdminDriverConnectionStatus.offline;
    } else {
      connection = AdminDriverConnectionStatus.unknown;
    }

    // Offline GPS freshness must not imply Online — only explicit flags above.
    AdminDriverAvailabilityStatus availability;
    if (!accountActive) {
      availability = AdminDriverAvailabilityStatus.unavailable;
    } else if (onTrip) {
      availability = AdminDriverAvailabilityStatus.busy;
    } else if (connection == AdminDriverConnectionStatus.online) {
      availability = AdminDriverAvailabilityStatus.available;
    } else if (connection == AdminDriverConnectionStatus.offline) {
      availability = AdminDriverAvailabilityStatus.unavailable;
    } else {
      availability = AdminDriverAvailabilityStatus.unknown;
    }

    final flow = data['registration_flow_version'];
    final isV2 = flow is num
        ? flow.toInt() == 2
        : int.tryParse('$flow') == 2;

    return AdminDriverStatusTruth(
      registration: registration,
      registrationRaw: regRaw,
      accountActive: accountActive,
      accountStatusRaw: accountStatusRaw,
      connection: connection,
      availability: availability,
      onActiveTrip: onTrip,
      isRegistrationV2: isV2,
      authDisabled: authDisabled,
      firestorePresent: firestorePresent,
    );
  }

  static String _str(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return '';
    return v.toString().trim();
  }

  static bool? _bool(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is bool) return v;
    return null;
  }
}

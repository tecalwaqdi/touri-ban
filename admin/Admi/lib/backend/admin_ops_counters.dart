import '/core/toury_system_status_codes.dart';

/// Canonical **operational** counter definitions for the admin panel.
///
/// Finance totals (VAT, commission, settlements, wallet math) are intentionally
/// out of scope — see Phase 1 Data Map / Phase 5+.
///
/// Every dashboard / list total must go through [loadDashboardStats] /
/// [DashboardStats] rather than `.length` on a capped page query.
abstract final class AdminOpsCounters {
  AdminOpsCounters._();

  /// Lifecycle codes treated as cancelled for ops counts (sum of aggregates).
  static const cancelledStatusCodes = <String>[
    TourySystemStatusCodes.cancelledByCustomer,
    TourySystemStatusCodes.cancelledByDriver,
    TourySystemStatusCodes.cancelledByAdmin,
    TourySystemStatusCodes.legacyCancelled,
    TourySystemStatusCodes.legacyCanceled,
  ];

  static const completedStatusCodes = <String>[
    TourySystemStatusCodes.completed,
    TourySystemStatusCodes.legacyTripCompleted,
  ];

  static const pendingStatusCodes = <String>[
    TourySystemStatusCodes.pendingDriver,
    TourySystemStatusCodes.legacyAwaitingDriver,
  ];

  static const activeStatusCodes = <String>[
    TourySystemStatusCodes.driverAssigned,
    TourySystemStatusCodes.driverArriving,
    TourySystemStatusCodes.driverArrived,
    TourySystemStatusCodes.tripStarted,
    TourySystemStatusCodes.tripInProgress,
  ];

  /// Firestore string for open support tickets (`HalhSupport.Open`).
  static const supportOpenHalh = 'Open';

  /// Inclusion-exclusion: customers who are neither agent nor driver.
  static int appUsersFromParts({
    required int totalUsers,
    required int agents,
    required int drivers,
    required int agentAndDriver,
  }) =>
      (totalUsers - agents - drivers + agentAndDriver).clamp(0, 1 << 30);

  /// Drivers with missing / null `actev_mndob` (not true and not false).
  ///
  /// Do **not** treat these as inactive — no backfill assumed.
  static int driversUnknown({
    required int totalDrivers,
    required int active,
    required int inactive,
  }) =>
      (totalDrivers - active - inactive).clamp(0, 1 << 30);

  /// Sum of parallel status_code counts (avoids loading docs).
  static Future<int> sumStatusCodeCounts({
    required Future<int> Function(String statusCode) countForCode,
    required Iterable<String> codes,
  }) async {
    var sum = 0;
    for (final code in codes) {
      sum += await countForCode(code);
    }
    return sum.clamp(0, 1 << 30);
  }
}

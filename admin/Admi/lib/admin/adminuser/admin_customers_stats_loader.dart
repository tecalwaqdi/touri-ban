import '/backend/admin_ops_filters.dart';
import '/backend/backend.dart';
import '/backend/dashboard_stats_loader.dart';
import '/admin/adminuser/admin_customers_adapter.dart';

/// Compact page-level + aggregate customer counters (no N+1 order history).
class AdminCustomerStats {
  const AdminCustomerStats({
    required this.total,
    required this.active,
    required this.suspended,
    required this.withLiveTripHint,
    required this.withLockHint,
    required this.newToday,
    required this.newThisMonth,
  });

  const AdminCustomerStats.empty()
      : total = 0,
        active = 0,
        suspended = 0,
        withLiveTripHint = 0,
        withLockHint = 0,
        newToday = 0,
        newThisMonth = 0;

  final int total;
  final int active;
  final int suspended;
  final int withLiveTripHint;
  final int withLockHint;
  final int newToday;
  final int newThisMonth;
}

abstract final class AdminCustomerStatsLoader {
  AdminCustomerStatsLoader._();

  /// [total] from aggregate; other chips from a capped newest sample.
  static Future<AdminCustomerStats> load({
    required AdminOpsFilterState filters,
  }) async {
    final country = filters.effectiveCountryRef;
    var total = 0;
    try {
      total = await queryScopedAppUserCount(country);
      if (total < 0) total = 0;
    } catch (_) {
      total = 0;
    }

    List<UserRecord> sample = const [];
    try {
      sample = await queryUserRecordOnce(
        queryBuilder: (q) => AdminOpsQueryBuilder.applyUserFilters(q, filters),
        limit: 120,
      );
    } catch (_) {
      sample = const [];
    }

    final customers = sample.where(adminIsAppCustomer).toList(growable: false);
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    var active = 0;
    var suspended = 0;
    var withLock = 0;
    var newToday = 0;
    var newMonth = 0;
    for (final u in customers) {
      final row = AdminCustomerRow.fromUser(u);
      if (row.accountStatus == AdminCustomerAccountStatus.active) active++;
      if (row.accountStatus == AdminCustomerAccountStatus.suspended) {
        suspended++;
      }
      if (row.activeOrderId.isNotEmpty) withLock++;
      final c = row.createdAt;
      if (c != null && !c.isBefore(dayStart)) newToday++;
      if (c != null && !c.isBefore(monthStart)) newMonth++;
    }

    return AdminCustomerStats(
      total: total > 0 ? total : customers.length,
      active: active,
      suspended: suspended,
      withLiveTripHint: withLock,
      withLockHint: withLock,
      newToday: newToday,
      newThisMonth: newMonth,
    );
  }
}

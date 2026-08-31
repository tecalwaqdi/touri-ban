import '/admin/admin_suport/admin_support_adapter.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_ops_counters.dart';
import '/backend/backend.dart';

class AdminSupportStats {
  const AdminSupportStats({
    required this.open,
    required this.newTickets,
    required this.inProgress,
    required this.waitingUser,
    required this.resolved,
    required this.closed,
  });

  const AdminSupportStats.empty()
      : open = 0,
        newTickets = 0,
        inProgress = 0,
        waitingUser = 0,
        resolved = 0,
        closed = 0;

  final int open;
  final int newTickets;
  final int inProgress;
  final int waitingUser;
  final int resolved;
  final int closed;

  int get totalOpenish => open + newTickets + inProgress + waitingUser;
}

abstract final class AdminSupportStatsLoader {
  AdminSupportStatsLoader._();

  static Future<AdminSupportStats> load({
    required AdminOpsFilterState filters,
  }) async {
    try {
      final sample = await querySupportRecordOnce(
        queryBuilder: (q) => AdminOpsQueryBuilder.applySupportFilters(q, filters),
        limit: 150,
      );
      var open = 0;
      var fresh = 0;
      var progress = 0;
      var waiting = 0;
      var resolved = 0;
      var closed = 0;
      for (final t in sample) {
        final row = AdminSupportRow.fromTicket(t);
        switch (row.displayStatus) {
          case AdminSupportDisplayStatus.open:
            open++;
            break;
          case AdminSupportDisplayStatus.newTicket:
            fresh++;
            break;
          case AdminSupportDisplayStatus.inProgress:
            progress++;
            break;
          case AdminSupportDisplayStatus.waitingUser:
            waiting++;
            break;
          case AdminSupportDisplayStatus.resolved:
            resolved++;
            break;
          case AdminSupportDisplayStatus.closed:
            closed++;
            break;
          case AdminSupportDisplayStatus.unknown:
            open++;
            break;
        }
      }
      return AdminSupportStats(
        open: open,
        newTickets: fresh,
        inProgress: progress,
        waitingUser: waiting,
        resolved: resolved,
        closed: closed,
      );
    } catch (_) {
      return const AdminSupportStats.empty();
    }
  }

  /// Aggregate open count via existing counter field when possible.
  static Future<int> aggregateOpenCount(DocumentReference? country) async {
    try {
      return await querySupportRecordCount(
        queryBuilder: (q) {
          var x = q.where('halh', isEqualTo: AdminOpsCounters.supportOpenHalh);
          if (country != null) x = x.where('Rev_dolh', isEqualTo: country);
          return x;
        },
      );
    } catch (_) {
      return -1;
    }
  }
}

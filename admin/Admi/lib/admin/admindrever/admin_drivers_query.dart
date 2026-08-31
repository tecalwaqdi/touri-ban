import '/admin/admindrever/admin_drivers_adapter.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/backend.dart';
import '/core/admin_driver_profile_view.dart';

/// Drivers-only operational filters (not shared AdminOpsFilterState fields).
class AdminDriversExtraFilters {
  const AdminDriversExtraFilters({
    this.connection = AdminDriversConnectionFilter.all,
    this.availability = AdminDriversAvailabilityFilter.all,
  });

  final AdminDriversConnectionFilter connection;
  final AdminDriversAvailabilityFilter availability;

  static const empty = AdminDriversExtraFilters();

  bool get hasAny =>
      connection != AdminDriversConnectionFilter.all ||
      availability != AdminDriversAvailabilityFilter.all;

  int get activeCount =>
      (connection != AdminDriversConnectionFilter.all ? 1 : 0) +
      (availability != AdminDriversAvailabilityFilter.all ? 1 : 0);

  String get signature => '${connection.name}|${availability.name}';

  AdminDriversExtraFilters copyWith({
    AdminDriversConnectionFilter? connection,
    AdminDriversAvailabilityFilter? availability,
  }) =>
      AdminDriversExtraFilters(
        connection: connection ?? this.connection,
        availability: availability ?? this.availability,
      );
}

enum AdminDriversConnectionFilter { all, online, offline }

enum AdminDriversAvailabilityFilter { all, available, busy }

/// Apply list-page client filters that are unsafe/compound for Firestore.
List<UserRecord> applyAdminDriversClientFilters(
  List<UserRecord> list, {
  required String searchQuery,
  required AdminDriversExtraFilters extra,
  AdminDriverReviewFilter? unknownLegacyReview,
}) {
  var out = list;

  if (unknownLegacyReview == AdminDriverReviewFilter.unknownLegacy) {
    out = out
        .where(
          (r) =>
              AdminDriverRow.fromUser(r).review ==
              AdminDriverReviewBucket.unknownLegacy,
        )
        .toList(growable: false);
  }

  if (extra.connection != AdminDriversConnectionFilter.all) {
    out = out.where((r) {
      final row = AdminDriverRow.fromUser(r);
      return switch (extra.connection) {
        AdminDriversConnectionFilter.online =>
          row.connection == AdminDriverConnectionStatus.online,
        AdminDriversConnectionFilter.offline =>
          row.connection == AdminDriverConnectionStatus.offline,
        AdminDriversConnectionFilter.all => true,
      };
    }).toList(growable: false);
  }

  if (extra.availability != AdminDriversAvailabilityFilter.all) {
    out = out.where((r) {
      final row = AdminDriverRow.fromUser(r);
      return switch (extra.availability) {
        AdminDriversAvailabilityFilter.available =>
          row.availability == AdminDriverAvailabilityStatus.available,
        AdminDriversAvailabilityFilter.busy =>
          row.availability == AdminDriverAvailabilityStatus.busy,
        AdminDriversAvailabilityFilter.all => true,
      };
    }).toList(growable: false);
  }

  final q = searchQuery.trim();
  if (q.isEmpty) return out;
  return out
      .where((r) => AdminDriverRow.fromUser(r).matchesSearch(q))
      .toList(growable: false);
}

/// Newest-first within the loaded page (server order stays index-safe).
List<UserRecord> sortDriversNewestFirst(List<UserRecord> list) {
  final copy = List<UserRecord>.from(list);
  copy.sort((a, b) {
    final at = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  });
  return copy;
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_ops_counters.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/backend/dashboard_stats_loader.dart';

/// Paginated loader for drivers with **missing** `actev_mndob`.
///
/// Firestore cannot query "field missing" directly. Strategy (no backfill):
/// 1. Counter = `total(ismndob) − active − inactive` (Aggregate, verified).
/// 2. List = scan `ismndob==true` pages server-side, keep docs where
///    `actev_mndob` is absent, until one UI page is filled.
///
/// Caps scan depth to avoid runaway reads ([kAdminUnknownDriverScanMaxDocs]).
class AdminUnknownDriversPage {
  const AdminUnknownDriversPage({
    required this.drivers,
    required this.totalUnknown,
    required this.hasMore,
    required this.scanCursor,
    required this.docsScanned,
    required this.hitScanCap,
  });

  final List<UserRecord> drivers;
  final int totalUnknown;
  final bool hasMore;
  final DocumentSnapshot? scanCursor;
  final int docsScanned;
  final bool hitScanCap;
}

const int kAdminUnknownDriverScanMaxDocs = 800;

abstract final class AdminUnknownDriversLoader {
  AdminUnknownDriversLoader._();

  static Future<int> resolveTotalUnknown({
    DocumentReference? country,
  }) async {
    // Prefer dashboard cache when scope matches.
    final peek = peekDashboardStats();
    if (peek != null &&
        peek.loadComplete &&
        !peek.isExpired &&
        peek.driversActivationBalanced) {
      return peek.driversUnknown;
    }

    final total = await queryUserRecordCount(
      queryBuilder: (q) {
        var qq = q.where('ismndob', isEqualTo: true);
        if (country != null) qq = qq.where('Rev_dolh', isEqualTo: country);
        return qq;
      },
    );
    final active = await queryUserRecordCount(
      queryBuilder: (q) {
        var qq = q
            .where('ismndob', isEqualTo: true)
            .where('actev_mndob', isEqualTo: true);
        if (country != null) qq = qq.where('Rev_dolh', isEqualTo: country);
        return qq;
      },
    );
    final inactive = await queryUserRecordCount(
      queryBuilder: (q) {
        var qq = q
            .where('ismndob', isEqualTo: true)
            .where('actev_mndob', isEqualTo: false);
        if (country != null) qq = qq.where('Rev_dolh', isEqualTo: country);
        return qq;
      },
    );
    return AdminOpsCounters.driversUnknown(
      totalDrivers: total,
      active: active,
      inactive: inactive,
    );
  }

  /// Loads the next UI page of unknown-activation drivers.
  static Future<AdminUnknownDriversPage> loadPage({
    required AdminOpsFilterState filters,
    DocumentSnapshot? after,
    int pageSize = kAdminPageSize,
    int alreadyScanned = 0,
  }) async {
    final country = filters.effectiveCountryRef;
    final totalUnknown = await resolveTotalUnknown(country: country);

    final collected = <UserRecord>[];
    DocumentSnapshot? cursor = after;
    var scanned = alreadyScanned;
    var hasMoreServer = true;
    var hitCap = false;

    while (collected.length < pageSize && hasMoreServer) {
      if (scanned >= kAdminUnknownDriverScanMaxDocs) {
        hitCap = true;
        break;
      }

      Query q = UserRecord.collection
          .where('ismndob', isEqualTo: true)
          .orderBy(FieldPath.documentId)
          .limit(kAdminPageSizeLarge);
      if (country != null) {
        q = UserRecord.collection
            .where('ismndob', isEqualTo: true)
            .where('Rev_dolh', isEqualTo: country)
            .orderBy(FieldPath.documentId)
            .limit(kAdminPageSizeLarge);
      }
      if (cursor != null) {
        q = q.startAfterDocument(cursor);
      }

      final snap = await q.get();
      if (snap.docs.isEmpty) {
        hasMoreServer = false;
        break;
      }

      scanned += snap.docs.length;
      cursor = snap.docs.last;
      hasMoreServer = snap.docs.length >= kAdminPageSizeLarge;

      for (final doc in snap.docs) {
        final rec = UserRecord.fromSnapshot(doc);
        if (!rec.hasActevMndob()) {
          collected.add(rec);
          if (collected.length >= pageSize) break;
        }
      }
    }

    final search = filters.searchQuery.trim().toLowerCase();
    final filtered = search.isEmpty
        ? collected
        : collected
            .where(
              (r) =>
                  r.displayName.toLowerCase().contains(search) ||
                  r.phoneNumber.toLowerCase().contains(search) ||
                  r.email.toLowerCase().contains(search) ||
                  r.reference.id.toLowerCase().contains(search),
            )
            .toList();

    final moreUnknownsLikely =
        hasMoreServer && !hitCap && collected.length >= pageSize;

    return AdminUnknownDriversPage(
      drivers: filtered,
      totalUnknown: totalUnknown,
      hasMore: moreUnknownsLikely || (hasMoreServer && !hitCap),
      scanCursor: cursor,
      docsScanned: scanned,
      hitScanCap: hitCap,
    );
  }
}

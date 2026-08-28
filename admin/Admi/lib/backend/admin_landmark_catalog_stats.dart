import 'dart:async';

import '/backend/admin_country_scope.dart';
import '/backend/admin_landmark_count.dart';
import '/backend/admin_legacy_alias_filter.dart';
import '/backend/admin_reports_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Landmark totals aligned with Admin list/search (excludes legacy alias docs).
abstract final class AdminLandmarkCatalogStats {
  AdminLandmarkCatalogStats._();

  static const _pageSize = 400;
  static const _maxDuration = Duration(seconds: 40);

  static final Map<String, _CachedCatalogCount> _cache = {};

  static void invalidateCache() => _cache.clear();

  /// In-memory count after the same filters as [AdminM3almWidget._filterLandmarks].
  static int countVisibleInMemory(
    List<MkanRecord> items, {
    bool partnersOnly = false,
  }) {
    var list = AdminLegacyAliasFilter.keepWhereId(
      items,
      (m) => m.reference.id,
    );
    if (partnersOnly) {
      list = list.where((m) => m.isShrek).toList(growable: false);
    }
    return list.length;
  }

  /// Dashboard + list header count (country scope + alias filter).
  static Future<int> countCatalog({bool partnersOnly = false}) async {
    if (AdminRoleService.isCountryAgent || AdminReportsCountryScope.isActive) {
      return AdminLandmarkCount.countForAgent(partnersOnly: partnersOnly);
    }
    return _countSuperAdminCatalog(partnersOnly: partnersOnly);
  }

  static Future<int> _countSuperAdminCatalog({
    required bool partnersOnly,
  }) async {
    final key = 'super_${partnersOnly ? 'p' : 'l'}';
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.count;

    final deadline = DateTime.now().add(_maxDuration);
    var count = 0;
    String? lastDocId;

    while (DateTime.now().isBefore(deadline)) {
      final batch = await queryMkanRecordOnce(
        queryBuilder: (q) {
          var query = q as Query<Map<String, dynamic>>;
          if (partnersOnly) {
            query = query.where('isShrek', isEqualTo: true);
          }
          query = query.orderBy(FieldPath.documentId);
          if (lastDocId != null) {
            query = query.startAfter([lastDocId]);
          }
          return query;
        },
        limit: _pageSize,
      );

      if (batch.isEmpty) break;

      for (final record in batch) {
        if (!AdminLegacyAliasFilter.keepDocumentId(record.reference.id)) {
          continue;
        }
        if (partnersOnly && !record.isShrek) continue;
        count++;
      }

      lastDocId = batch.last.reference.id;
      if (batch.length < _pageSize) break;
    }

    if (count > 0) {
      _cache[key] = _CachedCatalogCount(count, DateTime.now());
    }
    return count;
  }

  /// Human-readable scope label for landmark list headers.
  static String scopeLabelForUi() {
    if (AdminReportsCountryScope.isActive) {
      final label = AdminReportsCountryScope.countryLabel;
      if (label.isNotEmpty) {
        return label;
      }
    }
    if (AdminRoleService.isCountryAgent) {
      final label = AdminCountryScope.activeCountryLabel;
      if (label.isNotEmpty) return label;
      return AdminRoleService.scopedCountryName;
    }
    return '';
  }

  static bool get isCountryScoped =>
      AdminRoleService.isCountryAgent || AdminReportsCountryScope.isActive;
}

class _CachedCatalogCount {
  _CachedCatalogCount(this.count, this.at);

  final int count;
  final DateTime at;

  bool get isExpired =>
      DateTime.now().difference(at) > const Duration(minutes: 5);
}

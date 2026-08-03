
import '/backend/admin_country_scope.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';

/// Fast landmark/partner counts — same Firestore filter as the landmarks list page.
class AdminAgentLandmarkStats {
  AdminAgentLandmarkStats._();

  static final Map<String, _CountEntry> _cache = {};

  static Future<int> countLandmarks() =>
      _countAggregated(partnersOnly: false);

  static Future<int> countPartners() => _countAggregated(partnersOnly: true);

  static void invalidateCache() => _cache.clear();

  static Future<int> _countAggregated({required bool partnersOnly}) async {
    if (!AdminRoleService.isCountryAgent) return 0;

    final key =
        '${AdminCountryScope.activeCountryRef?.path ?? 'sa'}_${partnersOnly ? 'p' : 'l'}';
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.count;

    try {
      await AdminPanelDataBootstrap.ensureReady();
      final count = await queryMkanRecordCount(
        queryBuilder: (collection) {
          var q = collection as Query<Map<String, dynamic>>;
          if (partnersOnly) {
            q = q.where('isShrek', isEqualTo: true);
          }
          return AdminCountryScope.applyLandmarkCountryFilter(q);
        },
      ).timeout(const Duration(seconds: 15));

      _cache[key] = _CountEntry(count, DateTime.now());
      return count;
    } catch (_) {
      return cached?.count ?? 0;
    }
  }
}

class _CountEntry {
  _CountEntry(this.count, this.at);

  final int count;
  final DateTime at;

  bool get isExpired =>
      DateTime.now().difference(at) > const Duration(minutes: 5);
}

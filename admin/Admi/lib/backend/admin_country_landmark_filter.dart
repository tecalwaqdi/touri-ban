import 'dart:async';
import 'dart:math';


import '/backend/admin_agent_data_bootstrap.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_landmark_count.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_landmark_loader.dart';
import '/backend/backend.dart';

/// Country-scoped landmark lists + counts for country agents.
class AdminCountryLandmarkFilter {
  AdminCountryLandmarkFilter._();

  static const _whereInChunk = 10;

  static final Map<String, List<MkanRecord>> _landmarkCache = {};
  static final Map<String, List<MkanRecord>> _partnerCache = {};
  static final Map<String, _CountEntry> _countCache = {};
  static Future<void>? _warmInFlight;
  static Future<List<MkanRecord>>? _loadInFlight;
  static String? _loadInFlightKey;

  static String _cacheKey({required bool partnersOnly}) {
    final country = AdminCountryScope.activeCountryRef?.path ?? 'no-country';
    return '${country}_${partnersOnly ? 'p' : 'l'}';
  }

  /// Heavy merged landmark loader — country agents only (not super-admin reports filter).
  static bool get appliesToCurrentUser => AdminRoleService.isCountryAgent;

  static List<MkanRecord> cachedItems({required bool partnersOnly}) {
    if (AdminCountryScope.isSaudiCountryAgent) {
      return AdminSaudiLandmarkLoader.cachedItems(partnersOnly: partnersOnly);
    }

    final key = _cacheKey(partnersOnly: partnersOnly);
    final map = partnersOnly ? _partnerCache : _landmarkCache;
    final cached = map[key];
    if (cached == null || cached.isEmpty) return const [];
    return List<MkanRecord>.from(cached);
  }

  static void invalidateCache() {
    _landmarkCache.clear();
    _partnerCache.clear();
    _countCache.clear();
    _warmInFlight = null;
    _loadInFlight = null;
    _loadInFlightKey = null;
    _loadGeneration++;
    AdminLandmarkCount.invalidateCache();
    AdminSaudiLandmarkLoader.invalidateCountCache();
  }

  static int _loadGeneration = 0;

  static void scheduleWarmCache() {
    if (!appliesToCurrentUser) return;
    if (_warmInFlight != null) return;
    _warmInFlight = warmCache().whenComplete(() => _warmInFlight = null);
  }

  static Future<void> warmCache() async {
    if (!appliesToCurrentUser) return;
    try {
      await AdminAgentDataBootstrap.ensureReady();
      await queryListCacheFirst<MkanRecord>(
        MkanRecord.collection,
        MkanRecord.fromSnapshot,
        queryBuilder: (q) => AdminCountryScope.applyMkanQuery(q),
        limit: kAdminPageSize,
      );
    } catch (_) {}
  }

  static Future<List<MkanRecord>> loadAll({
    required bool partnersOnly,
    bool forceRefresh = false,
  }) async {
    if (!appliesToCurrentUser) return const [];

    await AdminAgentDataBootstrap.ensureReady(force: forceRefresh);

    if (AdminCountryScope.isSaudiCountryAgent) {
      return AdminSaudiLandmarkLoader.loadAll(
        partnersOnly: partnersOnly,
        forceRefresh: forceRefresh,
      );
    }

    final key = _cacheKey(partnersOnly: partnersOnly);
    final map = partnersOnly ? _partnerCache : _landmarkCache;
    if (!forceRefresh && map[key] != null && map[key]!.isNotEmpty) {
      return List<MkanRecord>.from(map[key]!);
    }

    if (!forceRefresh &&
        _loadInFlight != null &&
        _loadInFlightKey == key) {
      return List<MkanRecord>.from(await _loadInFlight!);
    }

    final loader = _loadForCountry(partnersOnly: partnersOnly);
    _loadInFlightKey = key;
    final generation = _loadGeneration;
    _loadInFlight = loader;
    try {
      final items = await loader;
      if (generation != _loadGeneration) return const [];
      if (items.isNotEmpty) {
        map[key] = items;
        _countCache[key] = _CountEntry(items.length, DateTime.now());
      }
      return items;
    } finally {
      if (_loadInFlightKey == key) {
        _loadInFlight = null;
        _loadInFlightKey = null;
      }
    }
  }

  static Future<int> countForAgent({required bool partnersOnly}) async {
    if (!appliesToCurrentUser) return 0;

    await AdminAgentDataBootstrap.ensureReady();

    final key = _cacheKey(partnersOnly: partnersOnly);
    final cached = _countCache[key];
    if (cached != null && !cached.isExpired) return cached.count;

    try {
      final count = await AdminLandmarkCount.countForAgent(
        partnersOnly: partnersOnly,
      );
      _countCache[key] = _CountEntry(count, DateTime.now());
      return count;
    } catch (_) {
      return cached?.count ?? 0;
    }
  }

  static Future<List<MkanRecord>> _loadForCountry({
    required bool partnersOnly,
  }) async {
    final country = AdminCountryScope.activeCountryRef;
    if (country == null) return const [];

    await AdminCountryScope.ensureGeoCacheReady();
    final merged = <String, MkanRecord>{};

    await _mergeQuery(
      () {
        var q = MkanRecord.collection as Query<Map<String, dynamic>>;
        if (partnersOnly) {
          q = q.where('isShrek', isEqualTo: true);
        }
        return AdminCountryScope.applyLandmarkCountryFilter(q);
      }(),
      partnersOnly: partnersOnly,
      merged: merged,
      country: country,
    );

    if (merged.length < kAdminLandmarkMergeTotalCap) {
      await _mergeQuery(
        MkanRecord.collection
                .where('Rev_dolh', isEqualTo: country)
            as Query<Map<String, dynamic>>,
        partnersOnly: partnersOnly,
        merged: merged,
        country: country,
      );
    }

    final regionRefs = await AdminCountryScope.regionRefsForActiveCountry();
    for (var i = 0;
        i < regionRefs.length && merged.length < kAdminLandmarkMergeTotalCap;
        i += _whereInChunk) {
      final chunk = regionRefs.sublist(
        i,
        min(i + _whereInChunk, regionRefs.length),
      );
      await _mergeQuery(
        MkanRecord.collection
                .where('id_cit', whereIn: chunk) as Query<Map<String, dynamic>>,
        partnersOnly: partnersOnly,
        merged: merged,
        country: country,
      );
      await Future<void>.delayed(Duration.zero);
    }

    final villageRefs = await AdminCountryScope.villageRefsForActiveCountry();
    for (var i = 0;
        i < villageRefs.length && merged.length < kAdminLandmarkMergeTotalCap;
        i += _whereInChunk) {
      final chunk = villageRefs.sublist(
        i,
        min(i + _whereInChunk, villageRefs.length),
      );
      await _mergeQuery(
        MkanRecord.collection
                .where('id_vill', whereIn: chunk) as Query<Map<String, dynamic>>,
        partnersOnly: partnersOnly,
        merged: merged,
        country: country,
      );
      await Future<void>.delayed(Duration.zero);
    }

    return merged.values.toList(growable: false)
      ..sort((a, b) => a.reference.id.compareTo(b.reference.id));
  }

  static Future<void> _mergeQuery(
    Query<Map<String, dynamic>> query, {
    required bool partnersOnly,
    required Map<String, MkanRecord> merged,
    required DocumentReference country,
  }) async {
    if (merged.length >= kAdminLandmarkMergeTotalCap) return;

    try {
      await mergeMkanQueryPaginated(
        query,
        maxDocs: min(
          kAdminLandmarkMergeMaxPerQuery,
          kAdminLandmarkMergeTotalCap - merged.length,
        ),
        onRecord: (record) {
          if (merged.length >= kAdminLandmarkMergeTotalCap) return;
          if (!AdminCountryScope.isLandmarkInAgentCountry(record)) return;
          if (partnersOnly && !record.isShrek) return;
          merged[record.reference.path] = record;
        },
      );
    } catch (_) {}
  }
}

class _CountEntry {
  _CountEntry(this.count, this.at);

  final int count;
  final DateTime at;

  bool get isExpired =>
      DateTime.now().difference(at) > const Duration(minutes: 5);
}

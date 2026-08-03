import 'dart:async';
import 'dart:math';


import '/backend/admin_agent_data_bootstrap.dart';
import '/backend/admin_landmark_count.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';

/// Saudi landmark lists + counts for country agents only.
class AdminSaudiLandmarkLoader {
  AdminSaudiLandmarkLoader._();

  static const _whereInChunk = 10;

  static List<MkanRecord>? _cachedLandmarks;
  static List<MkanRecord>? _cachedPartners;
  static Map<String, _VisibleCountCache>? _visibleCountCache;
  static Future<void>? _warmInFlight;

  static List<MkanRecord> cachedItems({required bool partnersOnly}) {
    final cached = partnersOnly ? _cachedPartners : _cachedLandmarks;
    if (cached == null || cached.isEmpty) return const [];
    return List<MkanRecord>.from(cached);
  }

  static void invalidateCountCache() {
    _visibleCountCache = null;
    _cachedLandmarks = null;
    _cachedPartners = null;
    _warmInFlight = null;
  }

  static void scheduleWarmCache() {
    if (_warmInFlight != null) return;
    _warmInFlight = warmCache().whenComplete(() => _warmInFlight = null);
  }

  static Future<void> warmCache() async {
    if (!AdminCountryScope.isSaudiCountryAgent) return;
    try {
      await AdminAgentDataBootstrap.ensureReady();
      await queryListCacheFirst<MkanRecord>(
        MkanRecord.collection,
        MkanRecord.fromSnapshot,
        queryBuilder: (collection) {
          var q = collection as Query<Map<String, dynamic>>;
          return AdminCountryScope.applyLandmarkCountryFilter(q);
        },
        limit: kAdminPageSize,
      );
    } catch (_) {}
  }

  static Future<void> _ensureSaudiScopeReady() async {
    await AdminSaudiCountry.ensureQueryRefsLoaded();
    await AdminSaudiCountry.regionPaths();
    await AdminSaudiCountry.villagePaths();
  }

  static Future<List<MkanRecord>> loadAll({
    bool partnersOnly = false,
    bool forceRefresh = false,
  }) async {
    await AdminAgentDataBootstrap.ensureReady(force: forceRefresh);

    if (!forceRefresh) {
      final cached = partnersOnly ? _cachedPartners : _cachedLandmarks;
      if (cached != null && cached.isNotEmpty) {
        return List<MkanRecord>.from(cached);
      }
    }

    await _ensureSaudiScopeReady();
    final merged = <String, MkanRecord>{};

    await _mergePrimaryQuery(merged: merged, partnersOnly: partnersOnly);

    final countryRefs = _countryRefsForWhereIn();
    for (final countryRef in countryRefs) {
      if (merged.length >= kAdminLandmarkMergeTotalCap) break;
      await _mergeQuery(
        MkanRecord.collection
            .where('Rev_dolh', isEqualTo: countryRef) as Query<Map<String, dynamic>>,
        partnersOnly: partnersOnly,
        merged: merged,
      );
    }

    final regionRefs = await _regionRefsForWhereIn();
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
      );
      await Future<void>.delayed(Duration.zero);
    }

    final villageRefs = await _villageRefsForWhereIn();
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
      );
      await Future<void>.delayed(Duration.zero);
    }

    if (merged.isEmpty) {
      await _mergeLegacyBatch(merged: merged, partnersOnly: partnersOnly);
    }

    final items = merged.values.toList(growable: false)
      ..sort((a, b) => a.reference.id.compareTo(b.reference.id));

    _storeCache(partnersOnly: partnersOnly, items: items);
    return items;
  }

  static Future<void> _mergePrimaryQuery({
    required Map<String, MkanRecord> merged,
    required bool partnersOnly,
  }) async {
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
    );
  }

  static Future<void> _mergeLegacyBatch({
    required Map<String, MkanRecord> merged,
    required bool partnersOnly,
  }) async {
    await mergeMkanQueryPaginated(
      MkanRecord.collection.orderBy(FieldPath.documentId)
          as Query<Map<String, dynamic>>,
      onRecord: (record) {
        if (!AdminSaudiCountry.belongsToSaudiSync(record)) return;
        if (partnersOnly && !record.isShrek) return;
        merged[record.reference.path] = record;
      },
      maxDocs: min(
        kAdminLandmarkMergeMaxPerQuery,
        kAdminLandmarkMergeTotalCap - merged.length,
      ),
    );
  }

  static Future<void> _mergeQuery(
    Query<Map<String, dynamic>> query, {
    required bool partnersOnly,
    required Map<String, MkanRecord> merged,
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
          if (partnersOnly && !record.isShrek) return;
          merged[record.reference.path] = record;
        },
      );
    } catch (_) {}
  }

  static void _storeCache({
    required bool partnersOnly,
    required List<MkanRecord> items,
  }) {
    if (items.isEmpty) return;

    if (partnersOnly) {
      _cachedPartners = items;
    } else {
      _cachedLandmarks = items;
    }

    _visibleCountCache ??= {};
    final key = partnersOnly ? 'partners' : 'landmarks';
    _visibleCountCache![key] = _VisibleCountCache(items.length, DateTime.now());
  }

  static List<DocumentReference> _countryRefsForWhereIn() {
    final refs = <DocumentReference>[
      ...AdminSaudiCountry.countryRefsForQuery(),
    ];
    final active = AdminCountryScope.activeCountryRef;
    if (active != null && !refs.any((r) => r.path == active.path)) {
      refs.add(active);
    }
    return refs.take(30).toList(growable: false);
  }

  static Future<List<DocumentReference>> _regionRefsForWhereIn() async {
    final paths = await AdminSaudiCountry.regionPaths();
    return paths
        .map((path) => FirebaseFirestore.instance.doc(path))
        .toList(growable: false);
  }

  static Future<List<DocumentReference>> _villageRefsForWhereIn() async {
    final paths = await AdminSaudiCountry.villagePaths();
    return paths
        .map((path) => FirebaseFirestore.instance.doc(path))
        .toList(growable: false);
  }

  static Future<int> countVisible({required bool partnersOnly}) async {
    return AdminLandmarkCount.countForAgent(partnersOnly: partnersOnly);
  }
}

class _VisibleCountCache {
  _VisibleCountCache(this.count, this.at);

  final int count;
  final DateTime at;

  bool get isExpired =>
      DateTime.now().difference(at) > const Duration(minutes: 5);
}

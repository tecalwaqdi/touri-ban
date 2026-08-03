import 'dart:async';
import 'dart:math';


import '/backend/admin_country_scope.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';

/// Accurate landmark/partner totals for country agents (deduped, geo-aware).
class AdminLandmarkCount {
  AdminLandmarkCount._();

  static const _pageSize = 400;
  static const _whereInChunk = 10;
  static const _maxDuration = Duration(seconds: 22);

  static final Map<String, _CountEntry> _cache = {};

  static void invalidateCache() => _cache.clear();

  static Future<int> countForAgent({required bool partnersOnly}) async {
    if (!AdminRoleService.isCountryAgent) return 0;

    await AdminPanelDataBootstrap.ensureReady();
    await AdminCountryScope.ensureGeoCacheReady();

    final key =
        '${AdminCountryScope.activeCountryRef?.path ?? 'sa'}_${partnersOnly ? 'p' : 'l'}';
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.count;

    final deadline = DateTime.now().add(_maxDuration);
    int count;
    try {
      count = AdminCountryScope.isSaudiCountryAgent
          ? await _countSaudi(partnersOnly: partnersOnly, deadline: deadline)
          : await _countNonSaudi(
              partnersOnly: partnersOnly,
              deadline: deadline,
            );
    } catch (_) {
      return cached?.count ?? 0;
    }

    if (count > 0) {
      _cache[key] = _CountEntry(count, DateTime.now());
    }
    return count;
  }

  static Future<int> _countNonSaudi({
    required bool partnersOnly,
    required DateTime deadline,
  }) async {
    final country = AdminCountryScope.activeCountryRef;
    if (country == null) return 0;

    final ids = <String>{};

    await _collect(
      deadline: deadline,
      partnersOnly: partnersOnly,
      ids: ids,
      buildQuery: (q) {
        var query = q as Query<Map<String, dynamic>>;
        if (partnersOnly) {
          query = query.where('isShrek', isEqualTo: true);
        }
        return AdminCountryScope.applyLandmarkCountryFilter(query);
      },
      validate: AdminCountryScope.isLandmarkInAgentCountry,
    );

    await _collect(
      deadline: deadline,
      partnersOnly: partnersOnly,
      ids: ids,
      buildQuery: (q) {
        var query =
            (q as Query<Map<String, dynamic>>).where('Rev_dolh', isEqualTo: country);
        if (partnersOnly) {
          query = query.where('isShrek', isEqualTo: true);
        }
        return query;
      },
      validate: AdminCountryScope.isLandmarkInAgentCountry,
    );

    final regionRefs = await AdminCountryScope.regionRefsForActiveCountry();
    for (var i = 0; i < regionRefs.length; i += _whereInChunk) {
      if (DateTime.now().isAfter(deadline)) break;
      final chunk = regionRefs.sublist(
        i,
        min(i + _whereInChunk, regionRefs.length),
      );
      await _collect(
        deadline: deadline,
        partnersOnly: partnersOnly,
        ids: ids,
        buildQuery: (q) =>
            (q as Query<Map<String, dynamic>>).where('id_cit', whereIn: chunk),
        validate: AdminCountryScope.isLandmarkInAgentCountry,
      );
    }

    final villageRefs = await AdminCountryScope.villageRefsForActiveCountry();
    for (var i = 0; i < villageRefs.length; i += _whereInChunk) {
      if (DateTime.now().isAfter(deadline)) break;
      final chunk = villageRefs.sublist(
        i,
        min(i + _whereInChunk, villageRefs.length),
      );
      await _collect(
        deadline: deadline,
        partnersOnly: partnersOnly,
        ids: ids,
        buildQuery: (q) =>
            (q as Query<Map<String, dynamic>>).where('id_vill', whereIn: chunk),
        validate: AdminCountryScope.isLandmarkInAgentCountry,
      );
    }

    return ids.length;
  }

  static Future<int> _countSaudi({
    required bool partnersOnly,
    required DateTime deadline,
  }) async {
    await AdminSaudiCountry.ensureQueryRefsLoaded();
    await AdminSaudiCountry.regionPaths();
    await AdminSaudiCountry.villagePaths();

    final ids = <String>{};

    await _collect(
      deadline: deadline,
      partnersOnly: partnersOnly,
      ids: ids,
      buildQuery: (q) {
        var query = q as Query<Map<String, dynamic>>;
        if (partnersOnly) {
          query = query.where('isShrek', isEqualTo: true);
        }
        return AdminCountryScope.applyLandmarkCountryFilter(query);
      },
      validate: (m) => AdminSaudiCountry.belongsToSaudiSync(m),
    );

    final countryRefs = <DocumentReference>[
      ...AdminSaudiCountry.countryRefsForQuery(),
    ];
    final active = AdminCountryScope.activeCountryRef;
    if (active != null && !countryRefs.any((r) => r.path == active.path)) {
      countryRefs.add(active);
    }

    for (final countryRef in countryRefs.take(30)) {
      if (DateTime.now().isAfter(deadline)) break;
      await _collect(
        deadline: deadline,
        partnersOnly: partnersOnly,
        ids: ids,
        buildQuery: (q) {
          var query = (q as Query<Map<String, dynamic>>)
              .where('Rev_dolh', isEqualTo: countryRef);
          if (partnersOnly) {
            query = query.where('isShrek', isEqualTo: true);
          }
          return query;
        },
        validate: (m) => AdminSaudiCountry.belongsToSaudiSync(m),
      );
    }

    final regionPaths = await AdminSaudiCountry.regionPaths();
    final regionRefs = regionPaths
        .map((path) => FirebaseFirestore.instance.doc(path))
        .toList(growable: false);
    for (var i = 0; i < regionRefs.length; i += _whereInChunk) {
      if (DateTime.now().isAfter(deadline)) break;
      final chunk = regionRefs.sublist(
        i,
        min(i + _whereInChunk, regionRefs.length),
      );
      await _collect(
        deadline: deadline,
        partnersOnly: partnersOnly,
        ids: ids,
        buildQuery: (q) =>
            (q as Query<Map<String, dynamic>>).where('id_cit', whereIn: chunk),
        validate: (m) => AdminSaudiCountry.belongsToSaudiSync(m),
      );
    }

    final villagePaths = await AdminSaudiCountry.villagePaths();
    final villageRefs = villagePaths
        .map((path) => FirebaseFirestore.instance.doc(path))
        .toList(growable: false);
    for (var i = 0; i < villageRefs.length; i += _whereInChunk) {
      if (DateTime.now().isAfter(deadline)) break;
      final chunk = villageRefs.sublist(
        i,
        min(i + _whereInChunk, villageRefs.length),
      );
      await _collect(
        deadline: deadline,
        partnersOnly: partnersOnly,
        ids: ids,
        buildQuery: (q) =>
            (q as Query<Map<String, dynamic>>).where('id_vill', whereIn: chunk),
        validate: (m) => AdminSaudiCountry.belongsToSaudiSync(m),
      );
    }

    return ids.length;
  }

  static Future<void> _collect({
    required DateTime deadline,
    required bool partnersOnly,
    required Set<String> ids,
    required Query<Map<String, dynamic>> Function(Query query) buildQuery,
    required bool Function(MkanRecord record) validate,
  }) async {
    DocumentSnapshot? last;

    while (DateTime.now().isBefore(deadline)) {
      final batch = await queryMkanRecordOnce(
        queryBuilder: (q) {
          var query = buildQuery(q);
          query = query.orderBy(FieldPath.documentId);
          if (last != null) {
            query = query.startAfterDocument(last);
          }
          return query;
        },
        limit: _pageSize,
      );

      if (batch.isEmpty) break;

      for (final record in batch) {
        if (partnersOnly && !record.isShrek) continue;
        if (!validate(record)) continue;
        ids.add(record.reference.path);
      }

      last = await batch.last.reference.get();
      if (batch.length < _pageSize) break;
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

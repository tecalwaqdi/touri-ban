
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_country_sync.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_production_seed_data.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/admin_saudi_landmark_loader.dart';
import '/backend/backend.dart';

class LandmarkCountryBackfillResult {
  const LandmarkCountryBackfillResult({
    required this.success,
    this.error,
    this.landmarks = 0,
    this.agents = 0,
    this.skipped = 0,
  });

  final bool success;
  final String? error;
  final int landmarks;
  final int agents;
  final int skipped;
}

/// Links Saudi landmarks (and agents) to a canonical country via `Rev_dolh`.
class AdminLandmarkCountryBackfill {
  AdminLandmarkCountryBackfill._();

  static Future<LandmarkCountryBackfillResult> run({
    DocumentReference? countryRef,
  }) async {
    try {
      final country = countryRef ?? await AdminSaudiCountry.resolveRef();
      if (country == null) {
        return const LandmarkCountryBackfillResult(
          success: false,
          error: 'تعذر العثور على دولة السعودية في قاعدة البيانات',
        );
      }

      final saudiRefs = await AdminSaudiCountry.resolveAllRefs();
      final regionPaths = await _loadSaudiRegionPaths(saudiRefs);
      final villagePaths = await _loadSaudiVillagePaths(saudiRefs);
      final regionCache = <String, DocumentReference?>{};
      final villageCache = <String, DocumentReference?>{};

      var landmarks = 0;
      var skipped = 0;
      DocumentSnapshot? last;

      while (true) {
        final batch = await queryMkanRecordOnce(
          queryBuilder: (q) {
            var query = q.orderBy(FieldPath.documentId);
            if (last != null) {
              query = query.startAfterDocument(last);
            }
            return query;
          },
          limit: 120,
        );
        if (batch.isEmpty) break;

        for (final mkan in batch) {
          final belongs = await _belongsToSaudi(
            mkan,
            saudiRefs: saudiRefs,
            regionPaths: regionPaths,
            villagePaths: villagePaths,
            regionCache: regionCache,
            villageCache: villageCache,
          );
          if (!belongs) {
            skipped++;
            continue;
          }

          if (mkan.hasRevDolh() &&
              AdminSaudiCountry.sameCountryScope(mkan.revDolh, country) &&
              mkan.revDolh!.path == country.path) {
            skipped++;
            continue;
          }

          await mkan.reference.update({'Rev_dolh': country});
          landmarks++;
        }

        last = await batch.last.reference.get();
        if (batch.length < 120) break;
      }

      final agents = await _syncSaudiAgents(country);
      AdminLandmarkCountCache.invalidate();
      AdminSaudiLandmarkLoader.invalidateCountCache();

      return LandmarkCountryBackfillResult(
        success: true,
        landmarks: landmarks,
        agents: agents,
        skipped: skipped,
      );
    } catch (e) {
      return LandmarkCountryBackfillResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Saudi agent: sync profile + link landmarks under Saudi regions.
  static Future<LandmarkCountryBackfillResult> runForSaudiAgent() async {
    if (!AdminRoleService.isCountryAgent) {
      return const LandmarkCountryBackfillResult(
        success: false,
        error: 'يتطلب حساب وكيل دولة',
      );
    }

    var country = AdminCountryScope.activeCountryRef;
    country ??= currentUserDocument?.revDlohAgent;
    if (country == null && AdminSaudiCountry.isSaudiAgent(currentUserDocument!)) {
      country = await AdminSaudiCountry.resolveRef();
    }
    if (country == null) {
      return const LandmarkCountryBackfillResult(
        success: false,
        error: 'الوكيل غير مربوط بدولة',
      );
    }

    final result = await run(countryRef: country);
    if (result.success) {
      await ensureCurrentUserDocument(forceRefresh: true);
      AdminAgentCountryLock.applyToAppState();
    }
    return result;
  }

  static Future<LandmarkCountryBackfillResult> syncCurrentAgentCountry() async {
    if (!AdminRoleService.isCountryAgent) {
      return const LandmarkCountryBackfillResult(
        success: false,
        error: 'يتطلب حساب وكيل دولة',
      );
    }

    if (AdminSaudiCountry.isSaudiAgent(currentUserDocument!)) {
      return runForSaudiAgent();
    }

    var country = AdminCountryScope.activeCountryRef;
    country ??= currentUserDocument?.revDlohAgent;
    if (country == null) {
      return const LandmarkCountryBackfillResult(
        success: false,
        error: 'الوكيل غير مربوط بدولة',
      );
    }

    final agents = await _syncSaudiAgents(country);
    await ensureCurrentUserDocument(forceRefresh: true);
    AdminAgentCountryLock.applyToAppState();

    return LandmarkCountryBackfillResult(
      success: true,
      agents: agents,
    );
  }

  static Future<Set<String>> _loadSaudiRegionPaths(
    List<DocumentReference> saudiRefs,
  ) async {
    final paths = <String>{
      for (final region in AdminProductionSeedCatalog.geo.regions)
        CitiesRecord.collection.doc(region.id).path,
    };

    for (final country in saudiRefs) {
      DocumentSnapshot? last;
      while (true) {
        final batch = await queryCitiesRecordOnce(
          queryBuilder: (q) {
            var query = q.where('dolh', isEqualTo: country);
            if (last != null) {
              query = query.startAfterDocument(last);
            }
            return query;
          },
          limit: 200,
        );
        if (batch.isEmpty) break;
        paths.addAll(batch.map((r) => r.reference.path));
        last = await batch.last.reference.get();
        if (batch.length < 200) break;
      }
    }

    return paths;
  }

  static Future<Set<String>> _loadSaudiVillagePaths(
    List<DocumentReference> saudiRefs,
  ) async {
    final paths = <String>{};
    for (final region in AdminProductionSeedCatalog.geo.regions) {
      for (final city in region.cities) {
        paths.add(VillagesRecord.collection.doc(city.id).path);
      }
    }

    for (final country in saudiRefs) {
      DocumentSnapshot? last;
      while (true) {
        final batch = await queryVillagesRecordOnce(
          queryBuilder: (q) {
            var query = q.where('dolh', isEqualTo: country);
            if (last != null) {
              query = query.startAfterDocument(last);
            }
            return query;
          },
          limit: 200,
        );
        if (batch.isEmpty) break;
        paths.addAll(batch.map((v) => v.reference.path));
        last = await batch.last.reference.get();
        if (batch.length < 200) break;
      }
    }

    return paths;
  }

  static Future<bool> _belongsToSaudi(
    MkanRecord mkan, {
    required List<DocumentReference> saudiRefs,
    required Set<String> regionPaths,
    required Set<String> villagePaths,
    required Map<String, DocumentReference?> regionCache,
    required Map<String, DocumentReference?> villageCache,
  }) async {
    if (mkan.hasRevDolh()) {
      for (final ref in saudiRefs) {
        if (mkan.revDolh!.path == ref.path) return true;
      }
      return AdminSaudiCountry.sameCountryScope(mkan.revDolh, saudiRefs.first);
    }

    if (mkan.hasIdCit() && regionPaths.contains(mkan.idCit!.path)) {
      return true;
    }
    if (mkan.hasIdVill() && villagePaths.contains(mkan.idVill!.path)) {
      return true;
    }

    final inferred = await _inferCountryFromGeo(
      mkan,
      regionCache: regionCache,
      villageCache: villageCache,
    );
    if (inferred == null) return false;

    for (final ref in saudiRefs) {
      if (inferred.path == ref.path) return true;
    }
    return AdminSaudiCountry.sameCountryScope(inferred, saudiRefs.first);
  }

  static Future<DocumentReference?> _inferCountryFromGeo(
    MkanRecord mkan, {
    required Map<String, DocumentReference?> regionCache,
    required Map<String, DocumentReference?> villageCache,
  }) async {
    if (mkan.hasIdVill()) {
      final path = mkan.idVill!.path;
      if (villageCache.containsKey(path)) {
        return villageCache[path];
      }
      final country = await AdminCountrySync.countryFromVillage(mkan.idVill);
      villageCache[path] = country;
      if (country != null) return country;
    }

    if (mkan.hasIdCit()) {
      final path = mkan.idCit!.path;
      if (regionCache.containsKey(path)) {
        return regionCache[path];
      }
      final country = await AdminCountrySync.countryFromRegion(mkan.idCit);
      regionCache[path] = country;
      if (country != null) return country;
    }

    return null;
  }

  static Future<int> _syncSaudiAgents(DocumentReference country) async {
    if (!AdminSaudiCountry.isSaudiRef(country)) return 0;

    var updated = 0;
    final agents = await queryUserRecordOnce(
      queryBuilder: (q) => q.where('Isagent', isEqualTo: true),
      limit: 200,
    );

    CountriesRecord? countryRecord;
    try {
      countryRecord = await CountriesRecord.getDocumentOnce(country);
    } catch (_) {}

    for (final agent in agents) {
      if (!AdminSaudiCountry.isSaudiAgent(agent)) continue;
      if (agent.revDlohAgent?.path == country.path) continue;

      await agent.reference.update({
        'Rev_dloh_agent': country,
        if (countryRecord != null && countryRecord.naim.isNotEmpty)
          'dolh_agent': countryRecord.naim,
      });
      updated++;
    }

    return updated;
  }
}

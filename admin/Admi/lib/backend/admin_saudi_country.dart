
import '/backend/admin_production_seed_data.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/core/country/country_resolver.dart';

/// Resolves Saudi Arabia country document(s) in Firestore.
class AdminSaudiCountry {
  AdminSaudiCountry._();

  static const knownDocIds = ['saudi_arabia', 'demo_saudi'];

  static List<DocumentReference>? _cachedQueryRefs;
  static Set<String>? _cachedQueryPaths;
  static Set<String>? _cachedRegionPaths;
  static Set<String>? _cachedVillagePaths;

  /// Stable refs for Firestore `whereIn` — canonical Saudi ref when resolved.
  static List<DocumentReference> countryRefsForQuery() {
    if (_cachedQueryRefs != null && _cachedQueryRefs!.isNotEmpty) {
      return List<DocumentReference>.from(_cachedQueryRefs!);
    }
    return [CountriesRecord.collection.doc(CountryResolver.canonicalSaudiId)];
  }

  /// Loads every Saudi country doc (known ids + `saudi=true`).
  static Future<void> ensureQueryRefsLoaded() async {
    if (_cachedQueryRefs != null && _cachedQueryRefs!.isNotEmpty) return;
    await CountryResolver.ensureLoaded();
    final saudi = await CountryResolver.saudiCanonical();
    if (saudi != null) {
      _cachedQueryRefs = [saudi.canonicalRef];
      _cachedQueryPaths = {saudi.canonicalRef.path};
      return;
    }
    final all = await resolveAllRefs();
    if (all.isNotEmpty) {
      _cachedQueryRefs = [all.first];
      _cachedQueryPaths = {all.first.path};
    }
  }

  static Set<String>? get cachedRegionPathsSync => _cachedRegionPaths;

  static Set<String>? get cachedVillagePathsSync => _cachedVillagePaths;

  static void clearCache() {
    _cachedQueryRefs = null;
    _cachedQueryPaths = null;
    _cachedRegionPaths = null;
    _cachedVillagePaths = null;
  }

  static bool isKnownQueryPath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (_cachedQueryPaths != null) {
      return _cachedQueryPaths!.contains(path);
    }
    return knownDocIds.any((id) => path.endsWith('/$id'));
  }

  static Future<DocumentReference?> resolveRef() async {
    final all = await resolveAllRefs();
    if (all.isEmpty) return null;
    for (final id in knownDocIds) {
      final match = all.where((r) => r.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return all.first;
  }

  static Future<List<DocumentReference>> resolveAllRefs() async {
    final refs = <DocumentReference>[];
    final seen = <String>{};

    for (final id in knownDocIds) {
      final ref = CountriesRecord.collection.doc(id);
      if ((await ref.get()).exists) {
        refs.add(ref);
        seen.add(ref.path);
      }
    }

    final byFlag = await queryCountriesRecordOnce(
      queryBuilder: (q) => q.where('saudi', isEqualTo: true),
      limit: 30,
    );
    for (final country in byFlag) {
      if (seen.add(country.reference.path)) {
        refs.add(country.reference);
      }
    }

    return refs;
  }

  /// Region document paths under Saudi countries (cached).
  static Future<Set<String>> regionPaths() async {
    if (_cachedRegionPaths != null) return _cachedRegionPaths!;

    await ensureQueryRefsLoaded();
    final paths = <String>{
      for (final region in AdminProductionSeedCatalog.geo.regions)
        CitiesRecord.collection.doc(region.id).path,
    };
    final countries = countryRefsForQuery();

    for (final country in countries) {
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

    _cachedRegionPaths = paths;
    return paths;
  }

  /// Village document paths under Saudi countries (cached).
  static Future<Set<String>> villagePaths() async {
    if (_cachedVillagePaths != null) return _cachedVillagePaths!;

    await ensureQueryRefsLoaded();
    final paths = <String>{
      for (final region in AdminProductionSeedCatalog.geo.regions)
        for (final city in region.cities)
          VillagesRecord.collection.doc(city.id).path,
    };
    final countries = countryRefsForQuery();

    for (final country in countries) {
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

    _cachedVillagePaths = paths;
    return paths;
  }

  static bool isSaudiRef(DocumentReference? ref) {
    if (ref == null) return false;
    if (isKnownQueryPath(ref.path)) return true;
    return knownDocIds.contains(ref.id);
  }

  /// Treats all resolved Saudi country docs as the same scope.
  static bool sameCountryScope(
    DocumentReference? a,
    DocumentReference? b,
  ) {
    if (a == null || b == null) return false;
    if (a.path == b.path) return true;
    return isSaudiRef(a) && isSaudiRef(b);
  }

  static bool isSaudiAgent(UserRecord user) {
    final isPanelAgent =
        user.adminRuleValue == AdminRoleService.ruleCountryAgent || user.isagent;
    if (!isPanelAgent) return false;
    if (isSaudiRef(user.revDlohAgent)) return true;
    final label = user.dolhAgent.toLowerCase();
    return label.contains('سعود') || label.contains('saudi');
  }

  /// Fast in-memory Saudi scope check (after region/village paths are cached).
  static bool belongsToSaudiSync(MkanRecord mkan) {
    if (mkan.hasRevDolh()) {
      for (final ref in countryRefsForQuery()) {
        if (mkan.revDolh!.path == ref.path) return true;
      }
      if (countryRefsForQuery().isNotEmpty) {
        return sameCountryScope(mkan.revDolh, countryRefsForQuery().first);
      }
    }

    final regions = _cachedRegionPaths;
    if (mkan.hasIdCit() &&
        regions != null &&
        regions.contains(mkan.idCit!.path)) {
      return true;
    }

    final villages = _cachedVillagePaths;
    if (mkan.hasIdVill() &&
        villages != null &&
        villages.contains(mkan.idVill!.path)) {
      return true;
    }

    return false;
  }

  /// In-memory geo check when `Rev_dolh` is missing on a landmark.
  static Future<bool> landmarkBelongsToSaudi(MkanRecord mkan) async {
    if (mkan.hasRevDolh()) {
      for (final ref in countryRefsForQuery()) {
        if (mkan.revDolh!.path == ref.path) return true;
      }
      return sameCountryScope(mkan.revDolh, countryRefsForQuery().firstOrNull);
    }

    final regions = await regionPaths();
    if (mkan.hasIdCit() && regions.contains(mkan.idCit!.path)) {
      return true;
    }

    final villages = await villagePaths();
    if (mkan.hasIdVill() && villages.contains(mkan.idVill!.path)) {
      return true;
    }

    return false;
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

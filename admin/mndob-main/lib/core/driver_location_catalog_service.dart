import '/backend/backend.dart';
import '/core/toury_country_registry.dart';

/// Load regions (`cities`) and work areas (`villages`) for a country.
/// Naming mirrors Admin seed: regions live in `cities`, cities/areas in `villages`.
abstract final class DriverLocationCatalogService {
  DriverLocationCatalogService._();

  static List<DocumentReference> countryRefsForQuery(
      DocumentReference country) {
    final refs = TouryCountryRegistry.regionCountryRefs(country);
    final out = <DocumentReference>[
      ...refs,
      if (!refs.any((r) => r.path == country.path)) country,
    ];
    // Firestore whereIn limit is 10.
    return out.take(10).toList();
  }

  static Future<List<CitiesRecord>> listRegions(
      DocumentReference country) async {
    final dolhRefs = countryRefsForQuery(country);
    final rows = await queryCitiesRecordOnce(
      queryBuilder: (q) =>
          q.whereIn('dolh', dolhRefs).where('acctev', isEqualTo: true),
    );
    rows.sort((a, b) => a.naim.compareTo(b.naim));
    final seen = <String>{};
    return rows.where((row) => seen.add(row.naim.trim().toLowerCase())).toList();
  }

  static Future<List<VillagesRecord>> listCities({
    required DocumentReference country,
    DocumentReference? region,
  }) async {
    final dolhRefs = countryRefsForQuery(country);
    final rows = await queryVillagesRecordOnce(
      queryBuilder: (q) {
        var query = q.where('acctev', isEqualTo: true);
        if (region != null) {
          query = query.where('cities', isEqualTo: region);
        } else {
          query = query.whereIn('dolh', dolhRefs);
        }
        return query;
      },
    );
    rows.sort((a, b) => a.naim.compareTo(b.naim));
    final seen = <String>{};
    return rows.where((row) => seen.add(row.naim.trim().toLowerCase())).toList();
  }

  static DocumentReference? refFromPath(String? path) {
    final p = (path ?? '').trim();
    if (p.isEmpty || !p.contains('/')) return null;
    try {
      return FirebaseFirestore.instance.doc(p);
    } catch (_) {
      return null;
    }
  }
}

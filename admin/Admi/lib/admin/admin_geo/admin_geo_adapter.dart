import '/backend/admin_legacy_alias_filter.dart';
import '/backend/backend.dart';

/// Canonical geo contract (Admin + Mobile):
/// Country = `countries`
/// Region  = `cities`  (parent: `dolh` → countries)
/// City    = `villages` (parent: `cities` → region, `dolh` → country)
abstract final class AdminGeoContract {
  AdminGeoContract._();

  static const countryCollection = 'countries';
  static const regionCollection = 'cities';
  static const cityCollection = 'villages';

  static const nameField = 'naim';
  static const namesI18nField = 'names_i18n';
  static const activeField = 'acctev';
  static const countrySortField = 'num_trteb';
  static const regionSortField = 'sorting';
  static const regionParentField = 'dolh';
  static const cityRegionParentField = 'cities';
  static const cityCountryParentField = 'dolh';

  /// Legacy / alias field names observed across Admin + Mobile (do not rename).
  static const legacyAliases = <String, List<String>>{
    'country': ['dolh', 'Rev_dolh', 'RevDolh', 'iso_code', 'naimEnglesh'],
    'region': ['id_cit', 'cities', 'Revreg', 'vil'],
    'city': ['id_vill', 'vill', 'vill_text', 'textivill', 'cities_user_now'],
  };
}

enum AdminGeoTab { countries, regions, cities }

enum AdminGeoActiveFilter { all, active, inactive }

/// Presentation row for Countries tab.
class AdminGeoCountryRow {
  const AdminGeoCountryRow({
    required this.record,
    required this.regionCount,
    required this.cityCount,
  });

  final CountriesRecord record;
  final int regionCount;
  final int cityCount;

  String get id => record.reference.id;
  String get nameAr => record.naim.trim();
  String get nameEn {
    final eng = record.naimEnglesh.trim();
    if (eng.isNotEmpty) return eng;
    return (record.namesI18n['en'] ?? '').trim();
  }

  String get iso => record.isoCode.trim().toUpperCase();
  bool get active => record.acctev;
  int get sort => record.numTrteb;
  String get displayName => nameAr.isNotEmpty ? nameAr : id;
}

/// Presentation row for Regions tab.
class AdminGeoRegionRow {
  const AdminGeoRegionRow({
    required this.record,
    required this.countryName,
    required this.cityCount,
    required this.orphanParent,
  });

  final CitiesRecord record;
  final String countryName;
  final int cityCount;
  final bool orphanParent;

  String get id => record.reference.id;
  String get nameAr => record.naim.trim();
  String get nameEn => (record.namesI18n['en'] ?? '').trim();
  bool get active => record.acctev;
  int get sort => record.sorting;
  String get displayName => nameAr.isNotEmpty ? nameAr : id;
  bool get isLegacyAlias => AdminLegacyAliasFilter.isLegacyIntlAliasId(id);
}

/// Presentation row for Cities tab.
class AdminGeoCityRow {
  const AdminGeoCityRow({
    required this.record,
    required this.regionName,
    required this.countryName,
    required this.orphanRegion,
    required this.countryMismatch,
  });

  final VillagesRecord record;
  final String regionName;
  final String countryName;
  final bool orphanRegion;
  final bool countryMismatch;

  String get id => record.reference.id;
  String get nameAr => record.naim.trim();
  String get nameEn => (record.namesI18n['en'] ?? '').trim();
  bool get active => record.acctev;
  String get displayName => nameAr.isNotEmpty ? nameAr : id;
  bool get isLegacyAlias => AdminLegacyAliasFilter.isLegacyIntlAliasId(id);
}

class AdminGeoSummaryCounts {
  const AdminGeoSummaryCounts({
    required this.countries,
    required this.regions,
    required this.cities,
    required this.active,
    required this.inactive,
  });

  final int countries;
  final int regions;
  final int cities;
  final int active;
  final int inactive;
}

/// In-memory geo presentation helpers (no extra Firestore reads).
abstract final class AdminGeoAdapter {
  AdminGeoAdapter._();

  static String displayName(String naim, String id) {
    final t = naim.trim();
    return t.isNotEmpty ? t : id;
  }

  static String i18nName(Map<String, String> names, String locale) {
    final direct = (names[locale] ?? '').trim();
    if (direct.isNotEmpty) return direct;
    final ar = (names['ar'] ?? '').trim();
    if (ar.isNotEmpty) return ar;
    final en = (names['en'] ?? '').trim();
    return en;
  }

  static List<CountriesRecord> logicalCountries(List<CountriesRecord> all) =>
      List<CountriesRecord>.from(all);

  static List<CitiesRecord> logicalRegions(List<CitiesRecord> all) =>
      AdminLegacyAliasFilter.keepWhereId(all, (r) => r.reference.id);

  static List<VillagesRecord> logicalCities(List<VillagesRecord> all) =>
      AdminLegacyAliasFilter.keepWhereId(all, (c) => c.reference.id);

  static AdminGeoSummaryCounts summary({
    required List<CountriesRecord> countries,
    required List<CitiesRecord> regions,
    required List<VillagesRecord> cities,
  }) {
    final c = logicalCountries(countries);
    final r = logicalRegions(regions);
    final v = logicalCities(cities);
    final active = c.where((e) => e.acctev).length +
        r.where((e) => e.acctev).length +
        v.where((e) => e.acctev).length;
    final total = c.length + r.length + v.length;
    return AdminGeoSummaryCounts(
      countries: c.length,
      regions: r.length,
      cities: v.length,
      active: active,
      inactive: total - active,
    );
  }

  static Map<String, int> regionCountsByCountry(List<CitiesRecord> regions) {
    final out = <String, int>{};
    for (final r in logicalRegions(regions)) {
      final id = r.dolh?.id;
      if (id == null || id.isEmpty) continue;
      out[id] = (out[id] ?? 0) + 1;
    }
    return out;
  }

  static Map<String, int> cityCountsByRegion(List<VillagesRecord> cities) {
    final out = <String, int>{};
    for (final c in logicalCities(cities)) {
      final id = c.cities?.id;
      if (id == null || id.isEmpty) continue;
      out[id] = (out[id] ?? 0) + 1;
    }
    return out;
  }

  static Map<String, int> cityCountsByCountry(List<VillagesRecord> cities) {
    final out = <String, int>{};
    for (final c in logicalCities(cities)) {
      final id = c.dolh?.id;
      if (id == null || id.isEmpty) continue;
      out[id] = (out[id] ?? 0) + 1;
    }
    return out;
  }

  static List<AdminGeoCountryRow> countryRows({
    required List<CountriesRecord> countries,
    required List<CitiesRecord> regions,
    required List<VillagesRecord> cities,
    String search = '',
    AdminGeoActiveFilter activeFilter = AdminGeoActiveFilter.all,
  }) {
    final regionCounts = regionCountsByCountry(regions);
    final cityCounts = cityCountsByCountry(cities);
    final q = search.trim().toLowerCase();
    final rows = logicalCountries(countries).map((c) {
      return AdminGeoCountryRow(
        record: c,
        regionCount: regionCounts[c.reference.id] ?? 0,
        cityCount: cityCounts[c.reference.id] ?? 0,
      );
    }).where((row) {
      if (activeFilter == AdminGeoActiveFilter.active && !row.active) {
        return false;
      }
      if (activeFilter == AdminGeoActiveFilter.inactive && row.active) {
        return false;
      }
      if (q.isEmpty) return true;
      return row.nameAr.toLowerCase().contains(q) ||
          row.nameEn.toLowerCase().contains(q) ||
          row.iso.toLowerCase().contains(q) ||
          row.id.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final bySort = a.sort.compareTo(b.sort);
        if (bySort != 0) return bySort;
        return a.displayName.compareTo(b.displayName);
      });
    return rows;
  }

  static List<AdminGeoRegionRow> regionRows({
    required List<CitiesRecord> regions,
    required List<CountriesRecord> countries,
    required List<VillagesRecord> cities,
    String search = '',
    AdminGeoActiveFilter activeFilter = AdminGeoActiveFilter.all,
    DocumentReference? countryFilter,
    bool includeAliases = false,
  }) {
    final countryNames = <String, String>{
      for (final c in countries)
        c.reference.id: displayName(c.naim, c.reference.id),
    };
    final cityCounts = cityCountsByRegion(cities);
    final q = search.trim().toLowerCase();
    final source = includeAliases ? regions : logicalRegions(regions);
    final rows = source.map((r) {
      final parentId = r.dolh?.id;
      final orphan = parentId == null || !countryNames.containsKey(parentId);
      return AdminGeoRegionRow(
        record: r,
        countryName: orphan ? '—' : (countryNames[parentId] ?? parentId),
        cityCount: cityCounts[r.reference.id] ?? 0,
        orphanParent: orphan,
      );
    }).where((row) {
      if (countryFilter != null &&
          row.record.dolh?.path != countryFilter.path) {
        return false;
      }
      if (activeFilter == AdminGeoActiveFilter.active && !row.active) {
        return false;
      }
      if (activeFilter == AdminGeoActiveFilter.inactive && row.active) {
        return false;
      }
      if (q.isEmpty) return true;
      return row.nameAr.toLowerCase().contains(q) ||
          row.nameEn.toLowerCase().contains(q) ||
          row.countryName.toLowerCase().contains(q) ||
          row.id.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final bySort = a.sort.compareTo(b.sort);
        if (bySort != 0) return bySort;
        return a.displayName.compareTo(b.displayName);
      });
    return rows;
  }

  static List<AdminGeoCityRow> cityRows({
    required List<VillagesRecord> cities,
    required List<CitiesRecord> regions,
    required List<CountriesRecord> countries,
    String search = '',
    AdminGeoActiveFilter activeFilter = AdminGeoActiveFilter.all,
    DocumentReference? countryFilter,
    DocumentReference? regionFilter,
    bool includeAliases = false,
  }) {
    final countryNames = <String, String>{
      for (final c in countries)
        c.reference.id: displayName(c.naim, c.reference.id),
    };
    final regionById = <String, CitiesRecord>{
      for (final r in regions) r.reference.id: r,
    };
    final q = search.trim().toLowerCase();
    final source = includeAliases ? cities : logicalCities(cities);
    final rows = source.map((c) {
      final regionId = c.cities?.id;
      final countryId = c.dolh?.id;
      final region = regionId != null ? regionById[regionId] : null;
      final orphanRegion = region == null;
      final regionCountryId = region?.dolh?.id;
      final mismatch = !orphanRegion &&
          countryId != null &&
          regionCountryId != null &&
          countryId != regionCountryId;
      return AdminGeoCityRow(
        record: c,
        regionName: region == null
            ? '—'
            : displayName(region.naim, region.reference.id),
        countryName:
            countryId == null ? '—' : (countryNames[countryId] ?? countryId),
        orphanRegion: orphanRegion,
        countryMismatch: mismatch,
      );
    }).where((row) {
      if (countryFilter != null &&
          row.record.dolh?.path != countryFilter.path) {
        return false;
      }
      if (regionFilter != null &&
          row.record.cities?.path != regionFilter.path) {
        return false;
      }
      if (activeFilter == AdminGeoActiveFilter.active && !row.active) {
        return false;
      }
      if (activeFilter == AdminGeoActiveFilter.inactive && row.active) {
        return false;
      }
      if (q.isEmpty) return true;
      return row.nameAr.toLowerCase().contains(q) ||
          row.nameEn.toLowerCase().contains(q) ||
          row.regionName.toLowerCase().contains(q) ||
          row.countryName.toLowerCase().contains(q) ||
          row.id.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return rows;
  }

  /// Integrity dry-run over already loaded docs (no writes).
  static Map<String, int> integrityCounts({
    required List<CountriesRecord> countries,
    required List<CitiesRecord> regions,
    required List<VillagesRecord> cities,
  }) {
    final countryIds = {for (final c in countries) c.reference.id};
    final regionIds = {for (final r in regions) r.reference.id};
    var orphanRegions = 0;
    var orphanCities = 0;
    var invalidRelations = 0;
    var missingAr = 0;
    var missingEn = 0;

    for (final r in logicalRegions(regions)) {
      final parent = r.dolh?.id;
      if (parent == null || !countryIds.contains(parent)) orphanRegions++;
      if (r.naim.trim().isEmpty) missingAr++;
      if ((r.namesI18n['en'] ?? '').trim().isEmpty) missingEn++;
    }
    for (final c in logicalCities(cities)) {
      final regionId = c.cities?.id;
      final countryId = c.dolh?.id;
      if (regionId == null || !regionIds.contains(regionId)) {
        orphanCities++;
      } else {
        CitiesRecord? region;
        for (final r in regions) {
          if (r.reference.id == regionId) {
            region = r;
            break;
          }
        }
        if (region == null) {
          invalidRelations++;
          continue;
        }
        final regionCountry = region.dolh?.id;
        if (countryId != null &&
            regionCountry != null &&
            countryId != regionCountry) {
          invalidRelations++;
        }
      }
      if (c.naim.trim().isEmpty) missingAr++;
      if ((c.namesI18n['en'] ?? '').trim().isEmpty) missingEn++;
    }
    for (final c in countries) {
      if (c.naim.trim().isEmpty) missingAr++;
      final en = c.naimEnglesh.trim().isNotEmpty
          ? c.naimEnglesh.trim()
          : (c.namesI18n['en'] ?? '').trim();
      if (en.isEmpty) missingEn++;
    }

    final nameCounts = <String, int>{};
    for (final c in countries) {
      final n = c.naim.trim();
      if (n.isEmpty) continue;
      nameCounts[n] = (nameCounts[n] ?? 0) + 1;
    }
    final duplicateNames = nameCounts.values.where((count) => count > 1).length;

    return {
      'orphanRegions': orphanRegions,
      'orphanCities': orphanCities,
      'invalidRelations': invalidRelations,
      'duplicateNames': duplicateNames,
      'missingAr': missingAr,
      'missingEn': missingEn,
    };
  }
}

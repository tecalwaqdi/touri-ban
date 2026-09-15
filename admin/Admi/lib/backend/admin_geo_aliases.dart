import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors customer `touryCanonicalVillageRef` / `touryCanonicalRegionRef`.
/// Admin must write the same ids the user app queries, or new landmarks never appear.
abstract final class AdminGeoAliases {
  AdminGeoAliases._();

  static const _saudiLegacyVillageSlugs = {
    'makkah',
    'mecca',
    'jeddah',
    'riyadh',
    'madinah',
    'medina',
    'dammam',
    'taif',
    'abha',
    'khobar',
    'jubail',
    'yanbu',
    'tabuk',
    'hail',
    'najran',
    'jazan',
    'buraidah',
    'khamis',
  };

  static const _intlVillagePrefixes = {
    'city_es_',
    'city_ma_',
    'city_pt_',
    'city_tn_',
    'city_id_',
    'city_my_',
    'city_in_',
  };

  static const _intlRegionPrefixes = {
    'region_es_',
    'region_ma_',
    'region_pt_',
    'region_tn_',
    'region_id_',
    'region_my_',
    'region_in_',
  };

  static bool _startsWithAny(String id, Set<String> prefixes) {
    for (final p in prefixes) {
      if (id.startsWith(p)) return true;
    }
    return false;
  }

  /// Pure id remap — safe in unit tests without Firebase.
  static String canonicalVillageId(String id) {
    if (id.startsWith('city_sa_') ||
        id.startsWith('city_kg_') ||
        id.startsWith('city_uz_') ||
        id.startsWith('city_ru_') ||
        _startsWithAny(id, _intlVillagePrefixes)) {
      return id;
    }
    if (id == 'city_alkhobar') return 'city_sa_khobar';
    final legacyCity = RegExp(r'^city_(.+)$').firstMatch(id);
    if (legacyCity != null) {
      final slug = legacyCity.group(1)!.toLowerCase();
      if (!_saudiLegacyVillageSlugs.contains(slug)) return id;
      return 'city_sa_$slug';
    }
    return id;
  }

  static String canonicalRegionId(String id) {
    if (id.startsWith('region_sa_') ||
        id.startsWith('region_kg_') ||
        id.startsWith('region_uz_') ||
        id.startsWith('region_ru_') ||
        _startsWithAny(id, _intlRegionPrefixes) ||
        id.startsWith('kg-') ||
        id.startsWith('uz-') ||
        id.startsWith('ru-')) {
      return id;
    }
    final legacy = RegExp(r'^region_(.+)$').firstMatch(id);
    if (legacy != null) {
      final slug = legacy.group(1)!.toLowerCase();
      if (slug.startsWith('kg_') ||
          slug.startsWith('uz_') ||
          slug.startsWith('ru_') ||
          slug.startsWith('sa_') ||
          slug.startsWith('es_') ||
          slug.startsWith('ma_') ||
          slug.startsWith('pt_') ||
          slug.startsWith('tn_') ||
          slug.startsWith('id_') ||
          slug.startsWith('my_') ||
          slug.startsWith('in_')) {
        return id;
      }
      return 'region_sa_$slug';
    }
    return id;
  }

  /// villages/city_makkah → villages/city_sa_makkah (Saudi hubs only).
  static DocumentReference? canonicalVillageRef(DocumentReference? village) {
    if (village == null) return null;
    final nextId = canonicalVillageId(village.id);
    if (nextId == village.id) return village;
    return FirebaseFirestore.instance.collection('villages').doc(nextId);
  }

  /// cities/region_makkah → cities/region_sa_makkah (Saudi hubs only).
  static DocumentReference? canonicalRegionRef(DocumentReference? region) {
    if (region == null) return null;
    final nextId = canonicalRegionId(region.id);
    if (nextId == region.id) return region;
    return FirebaseFirestore.instance.collection('cities').doc(nextId);
  }

  /// Default category so customer chips / whereIn('tsnef') can match.
  static const defaultLandmarkCategory = 'معالم سياحية';
}

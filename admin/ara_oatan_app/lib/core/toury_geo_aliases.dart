import 'package:cloud_firestore/cloud_firestore.dart';

/// ISO prefixes used by curated international-seven imports (region_es_madrid, etc.).
const Set<String> _internationalRegionPrefixes = {
  'region_es_',
  'region_ma_',
  'region_pt_',
  'region_tn_',
  'region_id_',
  'region_my_',
  'region_in_',
};

const Set<String> _internationalVillagePrefixes = {
  'city_es_',
  'city_ma_',
  'city_pt_',
  'city_tn_',
  'city_id_',
  'city_my_',
  'city_in_',
};

bool _startsWithAny(String id, Set<String> prefixes) {
  for (final p in prefixes) {
    if (id.startsWith(p)) return true;
  }
  return false;
}

/// Never remap Kyrgyz/Uzbek/Russian hubs (e.g. city_bishkek) to Saudi.
const Set<String> _saudiLegacyVillageSlugs = {
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

/// يحوّل مراجع القرى/المناطق القديمة في السعودية إلى المعرفات الـ canonical.
/// مثال: villages/city_makkah → villages/city_sa_makkah
/// لا يحوّل city_bishkek أو أي مدينة غير سعودية إلى city_sa_*.
DocumentReference touryCanonicalVillageRef(DocumentReference village) {
  final id = village.id;
  if (id.startsWith('city_sa_') ||
      id.startsWith('city_kg_') ||
      id.startsWith('city_uz_') ||
      id.startsWith('city_ru_') ||
      _startsWithAny(id, _internationalVillagePrefixes)) {
    return village;
  }
  // Curated eastern hub uses city_alkhobar; canonical id is city_sa_khobar.
  if (id == 'city_alkhobar') {
    return FirebaseFirestore.instance.collection('villages').doc('city_sa_khobar');
  }
  final legacyCity = RegExp(r'^city_(.+)$').firstMatch(id);
  if (legacyCity != null) {
    final slug = legacyCity.group(1)!.toLowerCase();
    if (!_saudiLegacyVillageSlugs.contains(slug)) {
      return village;
    }
    return FirebaseFirestore.instance
        .collection('villages')
        .doc('city_sa_$slug');
  }
  return village;
}

DocumentReference touryCanonicalRegionRef(DocumentReference region) {
  final id = region.id;
  if (id.startsWith('region_sa_') ||
      id.startsWith('region_kg_') ||
      id.startsWith('region_uz_') ||
      id.startsWith('region_ru_') ||
      _startsWithAny(id, _internationalRegionPrefixes) ||
      id.startsWith('kg-') ||
      id.startsWith('uz-') ||
      id.startsWith('ru-')) {
    return region;
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
      return region;
    }
    return FirebaseFirestore.instance
        .collection('cities')
        .doc('region_sa_$slug');
  }
  return region;
}

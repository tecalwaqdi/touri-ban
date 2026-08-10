import 'package:cloud_firestore/cloud_firestore.dart';

/// Known legacy Saudi village hub IDs that should map to city_sa_*.
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
      id.startsWith('city_ru_')) {
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
        slug.startsWith('sa_')) {
      return region;
    }
    return FirebaseFirestore.instance
        .collection('cities')
        .doc('region_sa_$slug');
  }
  return region;
}

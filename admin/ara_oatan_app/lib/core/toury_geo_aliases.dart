import 'package:cloud_firestore/cloud_firestore.dart';

/// ISO-prefixed curated hubs: region_es_madrid, city_tm_ashgabat, etc.
final RegExp _isoPrefixedRegionId = RegExp(
  r'^region_[a-z]{2}_',
  caseSensitive: false,
);
final RegExp _isoPrefixedVillageId = RegExp(
  r'^city_[a-z]{2}_',
  caseSensitive: false,
);

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

/// Bare Saudi region ids that still need `region_sa_*` remapping.
const Set<String> _saudiLegacyRegionSlugs = {
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
  'eastern',
  'asir',
  'tabuk',
  'hail',
  'najran',
  'jazan',
  'qassim',
  'jouf',
  'northern',
};

/// يحوّل مراجع القرى/المناطق القديمة في السعودية إلى المعرفات الـ canonical.
/// مثال: villages/city_makkah → villages/city_sa_makkah
/// لا يحوّل city_tm_ashgabat / city_eg_cairo أو أي مدينة غير سعودية.
DocumentReference touryCanonicalVillageRef(DocumentReference village) {
  final id = village.id;
  // Any city_{ISO2}_* is already international/canonical.
  if (_isoPrefixedVillageId.hasMatch(id)) {
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
  // region_tm_ashgabat / region_eg_cairo / region_tr_* must NEVER become
  // region_sa_* — that emptied village queries and hid landmarks.
  if (_isoPrefixedRegionId.hasMatch(id) ||
      id.startsWith('kg-') ||
      id.startsWith('uz-') ||
      id.startsWith('ru-')) {
    return region;
  }
  final legacy = RegExp(r'^region_(.+)$').firstMatch(id);
  if (legacy != null) {
    final slug = legacy.group(1)!.toLowerCase();
    if (!_saudiLegacyRegionSlugs.contains(slug)) {
      return region;
    }
    return FirebaseFirestore.instance
        .collection('cities')
        .doc('region_sa_$slug');
  }
  return region;
}

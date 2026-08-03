import 'dart:math' as math;

import '/flutter_flow/lat_lng.dart';

/// مفاتيح المدن الرئيسية المدعومة في التطبيق.
enum SaudiCityKey {
  makkah,
  jeddah,
  madinah,
  taif,
  riyadh,
}

/// تعريف جغرافي لمدينة سعودية مع أسماء بديلة ومربع حدود تقريبي.
class SaudiCityDefinition {
  const SaudiCityDefinition({
    required this.key,
    required this.displayNameAr,
    required this.center,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.aliases,
  });

  final SaudiCityKey key;
  final String displayNameAr;
  final LatLng center;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final List<String> aliases;

  bool contains(LatLng point) =>
      point.latitude >= minLat &&
      point.latitude <= maxLat &&
      point.longitude >= minLng &&
      point.longitude <= maxLng;
}

/// سجل المدن السعودية الأساسية مع حدود جغرافية دقيقة نسبياً.
abstract final class SaudiCityRegistry {
  static final List<SaudiCityDefinition> cities = [
    SaudiCityDefinition(
      key: SaudiCityKey.taif,
      displayNameAr: 'الطائف',
      center: LatLng(21.2703, 40.4158),
      minLat: 21.15,
      maxLat: 21.45,
      minLng: 40.25,
      maxLng: 40.62,
      aliases: [
        'الطائف',
        'طائف',
        'Taif',
        'At Taif',
        'At-Taif',
        'Taif City',
        'محافظة الطائف',
      ],
    ),
    SaudiCityDefinition(
      key: SaudiCityKey.makkah,
      displayNameAr: 'مكة',
      center: LatLng(21.4225, 39.8262),
      minLat: 21.30,
      maxLat: 21.55,
      minLng: 39.72,
      maxLng: 40.02,
      aliases: [
        'مكة',
        'مكه',
        'مكة المكرمة',
        'مكه المكرمه',
        'Makkah',
        'Mecca',
        'Makkah Al Mukarramah',
        'Makkah al Mukarramah',
        'محافظة مكة',
        'مكة المكرمه',
      ],
    ),
    SaudiCityDefinition(
      key: SaudiCityKey.jeddah,
      displayNameAr: 'جدة',
      center: LatLng(21.5433, 39.1728),
      minLat: 21.45,
      maxLat: 21.78,
      minLng: 39.02,
      maxLng: 39.38,
      aliases: [
        'جدة',
        'جده',
        'Jeddah',
        'Jiddah',
        'Jedda',
        'محافظة جدة',
      ],
    ),
    SaudiCityDefinition(
      key: SaudiCityKey.madinah,
      displayNameAr: 'المدينة المنورة',
      center: LatLng(24.4686, 39.6142),
      minLat: 24.38,
      maxLat: 24.58,
      minLng: 39.48,
      maxLng: 39.72,
      aliases: [
        'المدينة المنورة',
        'المدينة',
        'المدينه',
        'المدينه المنوره',
        'Medina',
        'Madinah',
        'Al Madinah',
        'Al Madinah Al Munawwarah',
        'Madinah Munawwarah',
        'محافظة المدينة المنورة',
      ],
    ),
    SaudiCityDefinition(
      key: SaudiCityKey.riyadh,
      displayNameAr: 'الرياض',
      center: LatLng(24.7136, 46.6753),
      minLat: 24.45,
      maxLat: 25.05,
      minLng: 46.35,
      maxLng: 47.05,
      aliases: [
        'الرياض',
        'رياض',
        'Riyadh',
        'Ar Riyadh',
        'Ar-Riyadh',
        'Riyadh Region',
        'منطقة الرياض',
        'محافظة الرياض',
      ],
    ),
  ];

  /// يحدد المدينة من الإحداثيات — عند التقاطع يُختار الأقرب لمركز المدينة.
  static SaudiCityDefinition? cityFromCoordinates(LatLng point) {
    SaudiCityDefinition? best;
    double bestKm = double.infinity;
    for (final city in cities) {
      if (!city.contains(point)) continue;
      final km = _distanceKm(point, city.center);
      if (km < bestKm) {
        bestKm = km;
        best = city;
      }
    }
    return best;
  }

  static double _distanceKm(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final lat1 = a.latitude * p;
    final lat2 = b.latitude * p;
    final dLat = (b.latitude - a.latitude) * p;
    final dLng = (b.longitude - a.longitude) * p;
    final h = (1 - math.cos(dLat) / 2) / 2 +
        math.cos(lat1) * math.cos(lat2) * (1 - math.cos(dLng) / 2) / 2;
    return 12742 * math.asin(math.sqrt(h));
  }

  /// Public distance helper for landmark city soft edges.
  static double distanceKm(LatLng a, LatLng b) => _distanceKm(a, b);

  static SaudiCityDefinition? cityFromName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = normalizePlaceName(raw);
    SaudiCityDefinition? best;
    var bestScore = 0;
    for (final city in cities) {
      for (final alias in city.aliases) {
        final score = nameMatchScore(normalized, normalizePlaceName(alias));
        if (score > bestScore) {
          bestScore = score;
          best = city;
        }
      }
    }
    return bestScore > 0 ? best : null;
  }

  /// مطابقة آمنة بين اسمين بعد التطبيع — تتجنب المطابقة الجزئية القصيرة الخاطئة.
  static bool namesMatch(String a, String b) {
    final na = normalizePlaceName(a);
    final nb = normalizePlaceName(b);
    return nameMatchScore(na, nb) > 0;
  }

  /// 3 = تطابق تام، 2 = تطابق قوي (بادئة/مركّب)، 0 = لا تطابق.
  static int nameMatchScore(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 3;

    final shorter = a.length <= b.length ? a : b;
    final longer = a.length > b.length ? a : b;

    if (shorter.length < 3) return 0;

    if (longer.startsWith('$shorter ') || longer.endsWith(' $shorter')) {
      return 2;
    }

    if (longer.startsWith(shorter) &&
        shorter.length >= (longer.length * 0.45).ceil()) {
      return 2;
    }

    return 0;
  }

  /// تطبيع الأسماء العربية والإنجليزية للمقارنة.
  static String normalizePlaceName(String input) {
    var s = input.trim().toLowerCase();
    final arabicDiacritics = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
    s = s.replaceAll(arabicDiacritics, '');
    s = s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    s = s.replaceAll(RegExp(r'^ال'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static List<String> allSearchTermsFor(SaudiCityDefinition city) => [
        city.displayNameAr,
        ...city.aliases,
      ];

  /// حدود تقريبية للمملكة العربية السعودية.
  static bool isWithinSaudiArabia(LatLng point) =>
      point.latitude >= 16.0 &&
      point.latitude <= 32.6 &&
      point.longitude >= 34.4 &&
      point.longitude <= 55.7;

  /// يحوّل معرّف قرية/مدينة Firestore (city_sa_makkah) إلى تعريف المدينة.
  static SaudiCityDefinition? cityFromVillageDocId(String? docId) {
    if (docId == null || docId.trim().isEmpty) return null;
    var slug = docId.trim().toLowerCase();
    if (slug.startsWith('city_sa_')) {
      slug = slug.substring('city_sa_'.length);
    } else if (slug.startsWith('city_')) {
      slug = slug.substring('city_'.length);
    }
    switch (slug) {
      case 'makkah':
      case 'mecca':
        return byKey(SaudiCityKey.makkah);
      case 'jeddah':
      case 'jiddah':
        return byKey(SaudiCityKey.jeddah);
      case 'taif':
        return byKey(SaudiCityKey.taif);
      case 'madinah':
      case 'medina':
        return byKey(SaudiCityKey.madinah);
      case 'riyadh':
        return byKey(SaudiCityKey.riyadh);
      default:
        return null;
    }
  }

  static SaudiCityDefinition? byKey(SaudiCityKey key) {
    for (final city in cities) {
      if (city.key == key) return city;
    }
    return null;
  }
}

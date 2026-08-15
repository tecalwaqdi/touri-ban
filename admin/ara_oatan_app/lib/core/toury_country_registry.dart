import 'package:cloud_firestore/cloud_firestore.dart';

import '/flutter_flow/lat_lng.dart';

/// Canonical multi-country geo metadata — ISO-first, never SA-as-global-default.
abstract final class TouryCountryRegistry {
  TouryCountryRegistry._();

  /// Known Firestore country document IDs that share one ISO.
  static const Map<String, Set<String>> _aliasesByIso = {
    'SA': {
      'country_sa',
      'saudi_arabia',
      'saudi-arabia',
      'saudiarabia',
    },
    'KG': {
      'country_kg',
      'kyrgyzstan',
    },
    'RU': {
      'country_ru',
      'russia',
    },
    'UZ': {
      'country_uz',
      'uzbekistan',
    },
    'AE': {'country_ae', 'united-arab-emirates', 'uae'},
    'EG': {'country_eg', 'egypt'},
    'TR': {'country_tr', 'turkey'},
    'AZ': {'country_az', 'azerbaijan'},
    'BH': {'country_bh', 'bahrain'},
    'JO': {'country_jo', 'jordan'},
    'IQ': {'country_iq', 'iraq'},
    'KW': {'country_kw', 'kuwait'},
    'OM': {'country_om', 'oman'},
    'QA': {'country_qa', 'qatar'},
    'PK': {'country_pk', 'pakistan'},
    'ID': {'country_id', 'indonesia'},
    'MY': {'country_my', 'malaysia'},
    'IN': {'country_in', 'india'},
    'ES': {'country_es', 'spain'},
    'PT': {'country_pt', 'portugal'},
    'MA': {'country_ma', 'morocco'},
    'TN': {'country_tn', 'tunisia'},
    'CN': {'country_cn'},
    'FR': {'country_fr'},
    'GE': {'country_ge', 'georgia'},
  };

  /// Preferred Firestore doc id used when writing new child refs.
  static const Map<String, String> preferredCountryIdByIso = {
    'SA': 'saudi_arabia',
    'KG': 'kyrgyzstan',
    'RU': 'russia',
    'UZ': 'uzbekistan',
    'ES': 'spain',
    'MA': 'morocco',
    'PT': 'portugal',
    'TN': 'tunisia',
    'ID': 'indonesia',
    'MY': 'malaysia',
    'IN': 'india',
  };

  static const Map<String, LatLng> mapCenterByIso = {
    'SA': LatLng(24.7136, 46.6753),
    'KG': LatLng(41.2044, 74.7661),
    'RU': LatLng(61.5240, 105.3188),
    'UZ': LatLng(41.3775, 64.5853),
    'AE': LatLng(23.4241, 53.8478),
    'EG': LatLng(26.8206, 30.8025),
    'TR': LatLng(38.9637, 35.2433),
    'ES': LatLng(40.4168, -3.7038),
    'MA': LatLng(34.0209, -6.8416),
    'PT': LatLng(38.7223, -9.1393),
    'TN': LatLng(36.8065, 10.1815),
    'ID': LatLng(-6.2088, 106.8456),
    'MY': LatLng(3.139, 101.6869),
    'IN': LatLng(28.6139, 77.209),
  };

  static const Map<String, double> mapZoomByIso = {
    'SA': 5.2,
    'KG': 6.0,
    'RU': 3.2,
    'UZ': 5.5,
    'AE': 6.5,
    'EG': 5.5,
    'TR': 5.5,
    'ES': 6.0,
    'MA': 6.0,
    'PT': 6.5,
    'TN': 6.5,
    'ID': 5.0,
    'MY': 6.0,
    'IN': 5.0,
  };

  static const Map<String, ({LatLng sw, LatLng ne})> boundsByIso = {
    'SA': (
      sw: LatLng(16.0, 34.5),
      ne: LatLng(32.2, 55.7),
    ),
    'KG': (
      sw: LatLng(39.1, 69.2),
      ne: LatLng(43.3, 80.3),
    ),
    'RU': (
      sw: LatLng(41.1, 19.6),
      ne: LatLng(81.9, 180.0),
    ),
    'UZ': (
      sw: LatLng(37.1, 55.9),
      ne: LatLng(45.6, 73.2),
    ),
    'ES': (
      sw: LatLng(36.0, -9.5),
      ne: LatLng(43.8, 4.5),
    ),
    'MA': (
      sw: LatLng(21.0, -17.0),
      ne: LatLng(36.0, -1.0),
    ),
    'PT': (
      sw: LatLng(36.9, -9.5),
      ne: LatLng(42.2, -6.2),
    ),
    'TN': (
      sw: LatLng(30.2, 7.5),
      ne: LatLng(37.5, 11.6),
    ),
    'ID': (
      sw: LatLng(-11.0, 95.0),
      ne: LatLng(6.0, 141.0),
    ),
    'MY': (
      sw: LatLng(0.8, 99.6),
      ne: LatLng(7.4, 119.3),
    ),
    'IN': (
      sw: LatLng(8.0, 68.0),
      ne: LatLng(35.5, 97.5),
    ),
  };

  /// Normalize any country label / ISO / alias → ISO-3166 alpha-2 upper.
  static String? normalizeIso(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;

    final upper = t.toUpperCase();
    if (RegExp(r'^[A-Z]{2}$').hasMatch(upper)) {
      return upper;
    }

    final lower = t.toLowerCase();
    final compact = lower
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    const aliases = <String, String>{
      'sa': 'SA',
      'ksa': 'SA',
      'saudi': 'SA',
      'saudi arabia': 'SA',
      'kingdom of saudi arabia': 'SA',
      'السعودية': 'SA',
      'المملكة العربية السعودية': 'SA',
      'سعودية': 'SA',
      'kg': 'KG',
      'kyrgyzstan': 'KG',
      'kyrgyz republic': 'KG',
      'кыргызстан': 'KG',
      'кыргыз республикасы': 'KG',
      'киргизия': 'KG',
      'قيرغيزستان': 'KG',
      'ru': 'RU',
      'russia': 'RU',
      'russian federation': 'RU',
      'россия': 'RU',
      'российская федерация': 'RU',
      'روسيا': 'RU',
      'uz': 'UZ',
      'uzbekistan': 'UZ',
      'ўзбекистон': 'UZ',
      'узбекистан': 'UZ',
      'أوزبكستان': 'UZ',
      'اوزبكستان': 'UZ',
    };

    if (aliases.containsKey(lower)) return aliases[lower];
    if (aliases.containsKey(compact)) return aliases[compact];

    for (final entry in aliases.entries) {
      if (compact.contains(entry.key) || entry.key.contains(compact)) {
        if (entry.key.length >= 4 || compact.length <= 3) {
          return entry.value;
        }
      }
    }

    // Doc id patterns: country_kg, region_kg_*, saudi_arabia
    final countryDoc = RegExp(r'^country_([a-z]{2})$', caseSensitive: false)
        .firstMatch(t);
    if (countryDoc != null) {
      return countryDoc.group(1)!.toUpperCase();
    }

    for (final entry in _aliasesByIso.entries) {
      if (entry.value.contains(lower) || entry.value.contains(t)) {
        return entry.key;
      }
    }
    return null;
  }

  static Set<String> aliasDocIdsForIso(String iso) {
    final key = iso.toUpperCase();
    final set = <String>{
      ...?_aliasesByIso[key],
      if (preferredCountryIdByIso[key] != null) preferredCountryIdByIso[key]!,
      'country_${key.toLowerCase()}',
    };
    return set;
  }

  static Set<String> aliasDocIdsForCountryId(String countryDocId) {
    final iso = normalizeIso(countryDocId);
    if (iso == null) return {countryDocId};
    return {...aliasDocIdsForIso(iso), countryDocId};
  }

  /// Firestore refs to use in `whereIn('dolh', …)` region queries.
  static List<DocumentReference> regionCountryRefs(
    DocumentReference countryRef,
  ) {
    final ids = aliasDocIdsForCountryId(countryRef.id).toList()..sort();
    // Firestore whereIn max = 10
    final limited = ids.take(10).toList();
    return limited
        .map((id) => FirebaseFirestore.instance.collection('countries').doc(id))
        .toList();
  }

  static LatLng? mapCenterForIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return mapCenterByIso[iso.toUpperCase()];
  }

  static double mapZoomForIso(String? iso, {double fallback = 4.5}) {
    if (iso == null || iso.isEmpty) return fallback;
    return mapZoomByIso[iso.toUpperCase()] ?? fallback;
  }

  static ({LatLng sw, LatLng ne})? boundsForIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return boundsByIso[iso.toUpperCase()];
  }

  static bool isInsideIsoBounds(LatLng position, String iso) {
    final b = boundsForIso(iso);
    if (b == null) return false;
    return position.latitude >= b.sw.latitude &&
        position.latitude <= b.ne.latitude &&
        position.longitude >= b.sw.longitude &&
        position.longitude <= b.ne.longitude;
  }

  /// Detect ISO from coordinates using registered bounds (no SA default).
  static String? isoFromCoordinates(LatLng position) {
    // Prefer smaller countries first so RU does not swallow neighbors incorrectly
    // when their bounds are nested (they are not nested here).
    const order = ['KG', 'UZ', 'AE', 'SA', 'TR', 'EG', 'RU'];
    for (final iso in order) {
      if (isInsideIsoBounds(position, iso)) return iso;
    }
    for (final iso in boundsByIso.keys) {
      if (order.contains(iso)) continue;
      if (isInsideIsoBounds(position, iso)) return iso;
    }
    return null;
  }

  static String? preferredCountryDocId(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return preferredCountryIdByIso[iso.toUpperCase()] ??
        'country_${iso.toLowerCase()}';
  }

  /// Prefer the country record that owns regions (preferred id), else first ISO match.
  static T? preferCanonicalCountry<T>({
    required Iterable<T> countries,
    required String Function(T) idOf,
    required String Function(T) isoOf,
    String? iso,
  }) {
    if (iso == null || iso.isEmpty) return null;
    final target = iso.toUpperCase();
    final matches = countries
        .where((c) => normalizeIso(isoOf(c)) == target ||
            normalizeIso(idOf(c)) == target)
        .toList();
    if (matches.isEmpty) return null;
    final preferred = preferredCountryDocId(target);
    if (preferred != null) {
      final hit = matches.where((c) => idOf(c) == preferred).toList();
      if (hit.isNotEmpty) return hit.first;
    }
    return matches.first;
  }
}

/// Typed location failure reasons — never collapse into a single GPS message.
enum TouryLocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  coordinatesInvalid,
  geocodingFailure,
  unsupportedCountry,
  noMatchingRegion,
  noMatchingCity,
  networkError,
  databaseError,
  unknown,
}

extension TouryLocationFailureMessage on TouryLocationFailure {
  String get l10nKey {
    switch (this) {
      case TouryLocationFailure.serviceDisabled:
        return 'location_error_service_disabled';
      case TouryLocationFailure.permissionDenied:
        return 'location_error_permission_denied';
      case TouryLocationFailure.permissionDeniedForever:
        return 'location_error_permission_denied_forever';
      case TouryLocationFailure.timeout:
        return 'location_error_timeout';
      case TouryLocationFailure.coordinatesInvalid:
        return 'location_error_coordinates_invalid';
      case TouryLocationFailure.geocodingFailure:
        return 'location_error_geocoding_failure';
      case TouryLocationFailure.unsupportedCountry:
        return 'location_error_unsupported_country';
      case TouryLocationFailure.noMatchingRegion:
        return 'location_error_no_matching_region';
      case TouryLocationFailure.noMatchingCity:
        return 'location_error_no_matching_city';
      case TouryLocationFailure.networkError:
        return 'location_error_network';
      case TouryLocationFailure.databaseError:
        return 'location_error_database';
      case TouryLocationFailure.unknown:
        return 'location_error_unknown';
    }
  }
}

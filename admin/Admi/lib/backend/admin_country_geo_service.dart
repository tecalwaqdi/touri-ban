import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '/flutter_flow/lat_lng.dart';

/// حدود تقريبية + مركز + عملة (للدولة أو منطقة/مدينة).
class AdminGeoPlaceData {
  const AdminGeoPlaceData({
    this.isoCode,
    this.englishName,
    this.displayName,
    this.center,
    this.boundsSouthWest,
    this.boundsNorthEast,
    this.currencyCode,
    this.currencySymbol,
  });

  final String? isoCode;
  final String? englishName;
  final String? displayName;
  final LatLng? center;
  final LatLng? boundsSouthWest;
  final LatLng? boundsNorthEast;
  final String? currencyCode;
  final String? currencySymbol;

  bool get hasCenter => center != null;
  bool get hasBounds => boundsSouthWest != null && boundsNorthEast != null;
}

/// يجلب بيانات جغرافية من REST Countries + Nominatim.
abstract final class AdminCountryGeoService {
  AdminCountryGeoService._();

  static const _userAgent = 'TouryAdmin/1.0 (geo-lookup)';

  static const _symbolFallback = <String, String>{
    'SAR': 'ر.س',
    'KGS': 'сом',
    'RUB': '₽',
    'UZS': "soʻm",
    'USD': r'$',
    'EUR': '€',
  };

  static Future<AdminGeoPlaceData?> fetchForIsoCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != 2) return null;

    String? englishName;
    LatLng? center;
    String? currencyCode;
    String? currencySymbol;

    try {
      final rc = await http
          .get(
            Uri.parse('https://restcountries.com/v3.1/alpha/$code'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (rc.statusCode == 200) {
        final list = jsonDecode(rc.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final data = list.first as Map<String, dynamic>;
          final names = data['name'] as Map<String, dynamic>?;
          englishName = names?['common'] as String?;
          final latlng = data['latlng'] as List<dynamic>?;
          if (latlng != null && latlng.length >= 2) {
            center = LatLng(
              (latlng[0] as num).toDouble(),
              (latlng[1] as num).toDouble(),
            );
          }
          final currencies = data['currencies'] as Map<String, dynamic>?;
          if (currencies != null && currencies.isNotEmpty) {
            currencyCode = currencies.keys.first.toUpperCase();
            final meta = currencies[currencyCode] as Map<String, dynamic>?;
            currencySymbol = (meta?['symbol'] as String?)?.trim();
            currencySymbol ??= _symbolFallback[currencyCode];
          }
        }
      }
    } catch (_) {}

    final box = await _nominatimBounds(
      queryParams: {
        'countrycodes': code,
        'format': 'json',
        'limit': '1',
        'featuretype': 'country',
      },
    );

    if (center == null && box != null) {
      center = LatLng(
        (box.sw.latitude + box.ne.latitude) / 2,
        (box.sw.longitude + box.ne.longitude) / 2,
      );
    }

    if (center == null && box == null) return null;

    return AdminGeoPlaceData(
      isoCode: code,
      englishName: englishName,
      displayName: englishName,
      center: center,
      boundsSouthWest: box?.sw,
      boundsNorthEast: box?.ne,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );
  }

  static Future<AdminGeoPlaceData?> fetchForCountryName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final list = await _nominatimSearch({
        'q': trimmed,
        'format': 'json',
        'limit': '1',
        'featuretype': 'country',
      });
      if (list.isEmpty) return null;
      final item = list.first;
      final code = (item['country_code'] as String?)?.toUpperCase();
      if (code != null && code.length == 2) {
        return fetchForIsoCode(code);
      }
      return _placeFromNominatimItem(item);
    } catch (_) {}
    return null;
  }

  /// منطقة / محافظة داخل دولة.
  static Future<AdminGeoPlaceData?> fetchRegionOrProvince({
    required String name,
    String? countryIso,
    String? countryName,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final iso = countryIso?.trim().toUpperCase();
    final q = [
      trimmed,
      if (countryName != null && countryName.trim().isNotEmpty)
        countryName.trim(),
    ].join(', ');

    final params = <String, String>{
      'q': q,
      'format': 'json',
      'limit': '1',
      'addressdetails': '1',
    };
    if (iso != null && iso.length == 2) {
      params['countrycodes'] = iso;
    }

    try {
      var list = await _nominatimSearch(params);
      if (list.isEmpty) {
        list = await _nominatimSearch({
          'q': trimmed,
          'format': 'json',
          'limit': '1',
          if (iso != null && iso.length == 2) 'countrycodes': iso,
        });
      }
      if (list.isEmpty) return null;
      return _placeFromNominatimItem(list.first, fallbackIso: iso);
    } catch (_) {
      return null;
    }
  }

  /// مدينة / بلدة.
  static Future<AdminGeoPlaceData?> fetchCity({
    required String name,
    String? regionName,
    String? countryIso,
    String? countryName,
  }) {
    final parts = <String>[
      name.trim(),
      if (regionName != null && regionName.trim().isNotEmpty) regionName.trim(),
      if (countryName != null && countryName.trim().isNotEmpty)
        countryName.trim(),
    ];
    return fetchRegionOrProvince(
      name: parts.join(', '),
      countryIso: countryIso,
      countryName: null,
    );
  }

  static bool pointInBounds(LatLng point, LatLng sw, LatLng ne) {
    return point.latitude >= sw.latitude &&
        point.latitude <= ne.latitude &&
        point.longitude >= sw.longitude &&
        point.longitude <= ne.longitude;
  }

  static Map<String, dynamic> geoFieldsForFirestore(AdminGeoPlaceData geo) {
    final map = <String, dynamic>{};
    if (geo.isoCode != null && geo.isoCode!.trim().isNotEmpty) {
      map['iso_code'] = geo.isoCode!.trim().toUpperCase();
    }
    if (geo.englishName != null && geo.englishName!.trim().isNotEmpty) {
      map['naimEnglesh'] = geo.englishName!.trim();
    }
    if (geo.center != null) {
      map['geo_center'] = GeoPoint(geo.center!.latitude, geo.center!.longitude);
    }
    if (geo.boundsSouthWest != null) {
      map['bounds_sw'] = GeoPoint(
        geo.boundsSouthWest!.latitude,
        geo.boundsSouthWest!.longitude,
      );
    }
    if (geo.boundsNorthEast != null) {
      map['bounds_ne'] = GeoPoint(
        geo.boundsNorthEast!.latitude,
        geo.boundsNorthEast!.longitude,
      );
    }
    if (geo.currencyCode != null && geo.currencyCode!.isNotEmpty) {
      map['currency_code'] = geo.currencyCode!.toUpperCase();
    }
    if (geo.currencySymbol != null && geo.currencySymbol!.isNotEmpty) {
      map['CurrencySymbol'] = geo.currencySymbol;
    }
    return map;
  }

  static Map<String, dynamic> regionGeoFieldsForFirestore(AdminGeoPlaceData geo) {
    final map = <String, dynamic>{};
    if (geo.center != null) {
      map['geo_center'] =
          GeoPoint(geo.center!.latitude, geo.center!.longitude);
    }
    if (geo.boundsSouthWest != null) {
      map['bounds_sw'] = GeoPoint(
        geo.boundsSouthWest!.latitude,
        geo.boundsSouthWest!.longitude,
      );
    }
    if (geo.boundsNorthEast != null) {
      map['bounds_ne'] = GeoPoint(
        geo.boundsNorthEast!.latitude,
        geo.boundsNorthEast!.longitude,
      );
    }
    if (geo.displayName != null && geo.displayName!.isNotEmpty) {
      map['geo_display_name'] = geo.displayName;
    }
    map['geo_resolved_at'] = DateTime.now().toUtc().toIso8601String();
    return map;
  }

  static Map<String, dynamic> cityGeoFieldsForFirestore(AdminGeoPlaceData geo) {
    final map = <String, dynamic>{};
    if (geo.center != null) {
      final point = GeoPoint(geo.center!.latitude, geo.center!.longitude);
      map['lat_ling'] = point;
      map['geo_center'] = point;
    }
    if (geo.boundsSouthWest != null) {
      map['bounds_sw'] = GeoPoint(
        geo.boundsSouthWest!.latitude,
        geo.boundsSouthWest!.longitude,
      );
    }
    if (geo.boundsNorthEast != null) {
      map['bounds_ne'] = GeoPoint(
        geo.boundsNorthEast!.latitude,
        geo.boundsNorthEast!.longitude,
      );
    }
    if (geo.displayName != null && geo.displayName!.isNotEmpty) {
      map['naim_viil_map'] = geo.displayName;
    }
    map['geo_resolved_at'] = DateTime.now().toUtc().toIso8601String();
    return map;
  }

  static Future<List<Map<String, dynamic>>> _nominatimSearch(
    Map<String, String> params,
  ) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      params,
    );
    final nom = await http
        .get(
          uri,
          headers: const {
            'User-Agent': _userAgent,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (nom.statusCode != 200) return const [];
    final list = jsonDecode(nom.body);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<({LatLng sw, LatLng ne})?> _nominatimBounds({
    required Map<String, String> queryParams,
  }) async {
    final list = await _nominatimSearch(queryParams);
    if (list.isEmpty) return null;
    return _boundsFromItem(list.first);
  }

  static ({LatLng sw, LatLng ne})? _boundsFromItem(Map<String, dynamic> item) {
    final box = item['boundingbox'] as List<dynamic>?;
    if (box == null || box.length < 4) return null;
    final south = double.tryParse('${box[0]}') ?? 0;
    final north = double.tryParse('${box[1]}') ?? 0;
    final west = double.tryParse('${box[2]}') ?? 0;
    final east = double.tryParse('${box[3]}') ?? 0;
    return (sw: LatLng(south, west), ne: LatLng(north, east));
  }

  static AdminGeoPlaceData _placeFromNominatimItem(
    Map<String, dynamic> item, {
    String? fallbackIso,
  }) {
    final box = _boundsFromItem(item);
    LatLng? center;
    final lat = double.tryParse('${item['lat']}');
    final lon = double.tryParse('${item['lon']}');
    if (lat != null && lon != null) {
      center = LatLng(lat, lon);
    } else if (box != null) {
      center = LatLng(
        (box.sw.latitude + box.ne.latitude) / 2,
        (box.sw.longitude + box.ne.longitude) / 2,
      );
    }
    final code =
        (item['country_code'] as String?)?.toUpperCase() ?? fallbackIso;
    return AdminGeoPlaceData(
      isoCode: code,
      englishName: item['name'] as String?,
      displayName: item['display_name'] as String?,
      center: center,
      boundsSouthWest: box?.sw,
      boundsNorthEast: box?.ne,
    );
  }
}

/// توافق مع الاسم القديم في الشاشات.
typedef AdminCountryGeoData = AdminGeoPlaceData;

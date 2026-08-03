import 'dart:convert';

import 'package:http/http.dart' as http;

import '/flutter_flow/lat_lng.dart';

/// حدود تقريبية للدولة (مستطيل) + مركزها — تُجلب تلقائياً عند الإضافة.
class AdminCountryGeoData {
  const AdminCountryGeoData({
    required this.isoCode,
    this.englishName,
    this.center,
    this.boundsSouthWest,
    this.boundsNorthEast,
  });

  final String isoCode;
  final String? englishName;
  final LatLng? center;
  final LatLng? boundsSouthWest;
  final LatLng? boundsNorthEast;

  bool get hasBounds => boundsSouthWest != null && boundsNorthEast != null;
}

/// يجلب بيانات جغرافية للدولة من الإنترنت (REST Countries + Nominatim).
abstract final class AdminCountryGeoService {
  AdminCountryGeoService._();

  static Future<AdminCountryGeoData?> fetchForIsoCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != 2) return null;

    String? englishName;
    LatLng? center;

    try {
      final rc = await http.get(
        Uri.parse('https://restcountries.com/v3.1/alpha/$code'),
        headers: const {'Accept': 'application/json'},
      );
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
        }
      }
    } catch (_) {}

    LatLng? sw;
    LatLng? ne;
    try {
      final query = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?countrycodes=$code&format=json&limit=1&featuretype=country',
      );
      final nom = await http.get(
        query,
        headers: const {'User-Agent': 'TouryAdmin/1.0'},
      );
      if (nom.statusCode == 200) {
        final list = jsonDecode(nom.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final box = list.first['boundingbox'] as List<dynamic>?;
          if (box != null && box.length >= 4) {
            final south = double.tryParse('${box[0]}') ?? 0;
            final north = double.tryParse('${box[1]}') ?? 0;
            final west = double.tryParse('${box[2]}') ?? 0;
            final east = double.tryParse('${box[3]}') ?? 0;
            sw = LatLng(south, west);
            ne = LatLng(north, east);
          }
        }
      }
    } catch (_) {}

    if (center == null && sw != null && ne != null) {
      center = LatLng(
        (sw.latitude + ne.latitude) / 2,
        (sw.longitude + ne.longitude) / 2,
      );
    }

    if (center == null && sw == null) return null;

    return AdminCountryGeoData(
      isoCode: code,
      englishName: englishName,
      center: center,
      boundsSouthWest: sw,
      boundsNorthEast: ne,
    );
  }

  static Future<AdminCountryGeoData?> fetchForCountryName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final query = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(trimmed)}&format=json&limit=1&featuretype=country',
      );
      final nom = await http.get(
        query,
        headers: const {'User-Agent': 'TouryAdmin/1.0'},
      );
      if (nom.statusCode != 200) return null;
      final list = jsonDecode(nom.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final item = list.first as Map<String, dynamic>;
      final code = (item['country_code'] as String?)?.toUpperCase();
      if (code != null && code.length == 2) {
        return fetchForIsoCode(code);
      }
    } catch (_) {}
    return null;
  }

  static bool pointInBounds(LatLng point, LatLng sw, LatLng ne) {
    return point.latitude >= sw.latitude &&
        point.latitude <= ne.latitude &&
        point.longitude >= sw.longitude &&
        point.longitude <= ne.longitude;
  }

  static Map<String, dynamic> geoFieldsForFirestore(AdminCountryGeoData geo) {
    final map = <String, dynamic>{
      'iso_code': geo.isoCode,
    };
    if (geo.englishName != null && geo.englishName!.trim().isNotEmpty) {
      map['naimEnglesh'] = geo.englishName!.trim();
    }
    if (geo.center != null) {
      map['geo_center'] = geo.center;
    }
    if (geo.boundsSouthWest != null) {
      map['bounds_sw'] = geo.boundsSouthWest;
    }
    if (geo.boundsNorthEast != null) {
      map['bounds_ne'] = geo.boundsNorthEast;
    }
    return map;
  }
}

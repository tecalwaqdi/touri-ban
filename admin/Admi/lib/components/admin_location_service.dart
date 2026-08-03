import 'dart:convert';

import 'package:http/http.dart' as http;

import '/flutter_flow/lat_lng.dart';

const kAdminGoogleMapsApiKey = 'AIzaSyBOPqaoFQ3KTFEgnWSJ_9S-9bPAp8rU2HM';

class GeocodeResult {
  const GeocodeResult({
    required this.latLng,
    required this.address,
    this.name = '',
  });

  final LatLng latLng;
  final String address;
  final String name;
}

class AdminLocationService {
  static const LatLng defaultCenter = LatLng(24.7136, 46.6753);

  static bool isValidLocation(LatLng latLng) =>
      latLng.latitude.abs() > 0.0001 || latLng.longitude.abs() > 0.0001;

  static String formatCoordinates(LatLng latLng) =>
      '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';

  /// Parses decimal or DMS coordinates (e.g. from Google Earth).
  static LatLng? parseCoordinates(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final decimal = _parseDecimalPair(trimmed);
    if (decimal != null) return decimal;

    return _parseDmsPair(trimmed);
  }

  static LatLng? _parseDecimalPair(String input) {
    final cleaned = input
        .replaceAll('°', ' ')
        .replaceAll('º', ' ')
        .replaceAll('،', ',');
    final match = RegExp(
      r'([+-]?\d+(?:\.\d+)?)\s*[,;\s]\s*([+-]?\d+(?:\.\d+)?)',
    ).firstMatch(cleaned);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null || !_isValidLatLng(lat, lng)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  static LatLng? _parseDmsPair(String input) {
    final parts = RegExp(
      r'(\d+(?:\.\d+)?)\s*°\s*(\d+(?:\.\d+)?)?\s*[''"]?\s*(\d+(?:\.\d+)?)?\s*[''"]?\s*([NnSsEeWw])',
    ).allMatches(input).toList();
    if (parts.length < 2) return null;

    final lat = _dmsToDecimal(parts[0]);
    final lng = _dmsToDecimal(parts[1]);
    if (lat == null || lng == null || !_isValidLatLng(lat, lng)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  static double? _dmsToDecimal(RegExpMatch match) {
    final deg = double.tryParse(match.group(1) ?? '');
    if (deg == null) return null;
    final min = double.tryParse(match.group(2) ?? '') ?? 0;
    final sec = double.tryParse(match.group(3) ?? '') ?? 0;
    var decimal = deg.abs() + (min / 60) + (sec / 3600);
    final dir = (match.group(4) ?? '').toUpperCase();
    if (dir == 'S' || dir == 'W') decimal = -decimal;
    if (dir == 'N' || dir == 'E') return decimal;
    if (deg < 0) return deg;
    return decimal;
  }

  static bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180 &&
      (lat.abs() > 0.0001 || lng.abs() > 0.0001);

  static Future<GeocodeResult?> geocode(
    String query, {
    String apiKey = kAdminGoogleMapsApiKey,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final google = await _geocodeGoogle(trimmed, apiKey);
    if (google != null) {
      return google;
    }

    return _geocodeOsm(trimmed);
  }

  static Future<GeocodeResult?> _geocodeGoogle(
    String query,
    String apiKey,
  ) async {
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'address': query,
          'key': apiKey,
          'language': 'ar',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        return null;
      }

      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) {
        return null;
      }

      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>;
      final location = geometry['location'] as Map<String, dynamic>;
      final address = first['formatted_address'] as String? ?? query;

      return GeocodeResult(
        latLng: LatLng(
          (location['lat'] as num).toDouble(),
          (location['lng'] as num).toDouble(),
        ),
        address: address,
        name: address,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<GeocodeResult?> _geocodeOsm(String query) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'limit': '1',
          'accept-language': 'ar',
        },
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'admin_arawatan/1.0'},
      );
      if (response.statusCode != 200) {
        return null;
      }

      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) {
        return null;
      }

      final first = results.first as Map<String, dynamic>;
      final address = first['display_name'] as String? ?? query;

      return GeocodeResult(
        latLng: LatLng(
          double.parse(first['lat'] as String),
          double.parse(first['lon'] as String),
        ),
        address: address,
        name: address,
      );
    } catch (_) {
      return null;
    }
  }
}

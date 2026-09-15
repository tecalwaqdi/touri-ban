import 'dart:convert';

import 'package:http/http.dart' as http;

import '/flutter_flow/lat_lng.dart';

/// Maps key with Places + Geocoding enabled (billing). Do not use the Android
/// Maps SDK key here — that one returns REQUEST_DENIED for Places/Geocode.
const kAdminGoogleMapsApiKey = 'AIzaSyD5G1uXTPM2DP-5ZkeLQA_7FsFjxNWOIzM';

/// Fallback keys tried when the primary key is denied / restricted.
const _kAdminMapsApiKeyFallbacks = <String>[
  'AIzaSyD5G1uXTPM2DP-5ZkeLQA_7FsFjxNWOIzM',
  'AIzaSyDerhonj6V-7hdTOUdCEk1hwCtr-3Hce-4',
  'AIzaSyBOPqaoFQ3KTFEgnWSJ_9S-9bPAp8rU2HM',
];

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

  /// True when coords are still the generic Riyadh map default (not a real pin).
  static bool isDefaultMapCenter(LatLng? latLng) {
    if (latLng == null) return false;
    return (latLng.latitude - defaultCenter.latitude).abs() < 0.02 &&
        (latLng.longitude - defaultCenter.longitude).abs() < 0.02;
  }

  /// Accepts real-world coordinates only (not 0,0 / NaN / out of range).
  static bool isValidLocation(LatLng? latLng) {
    if (latLng == null) return false;
    final lat = latLng.latitude;
    final lng = latLng.longitude;
    if (lat.isNaN || lng.isNaN) return false;
    return _isValidLatLng(lat, lng);
  }

  /// Location is usable for saving a landmark (not empty / not unset default).
  static bool isUsableLandmarkLocation(LatLng? latLng) {
    if (!isValidLocation(latLng)) return false;
    // Default Riyadh center is only OK when the admin actually chose Riyadh —
    // callers that know the city should use [isUsableLandmarkLocationForCity].
    return true;
  }

  static bool isUsableLandmarkLocationForCity(
    LatLng? latLng, {
    LatLng? cityCenter,
    String? cityName,
  }) {
    if (!isValidLocation(latLng)) return false;
    final looksLikeDefault = isDefaultMapCenter(latLng);
    if (!looksLikeDefault) return true;
    // Allow default Riyadh pin only when the selected city is Riyadh.
    final name = (cityName ?? '').trim().toLowerCase();
    final isRiyadhCity = name.contains('riyadh') ||
        name.contains('الرياض') ||
        name.contains('رياض');
    if (isRiyadhCity) return true;
    if (cityCenter != null && isDefaultMapCenter(cityCenter)) return true;
    return false;
  }

  static String formatCoordinates(LatLng latLng) =>
      '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';

  /// Parses decimal, DMS, or Google Maps URL / share text.
  static LatLng? parseCoordinates(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final fromUrl = _parseMapsUrl(trimmed);
    if (fromUrl != null) return fromUrl;

    final decimal = _parseDecimalPair(trimmed);
    if (decimal != null) return decimal;

    return _parseDmsPair(trimmed);
  }

  /// Extracts lat/lng from Google Maps links (maps.app.goo.gl, @lat,lng, q=, !3d!4d).
  static LatLng? _parseMapsUrl(String input) {
    final at = RegExp(
      r'@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(input);
    if (at != null) {
      final lat = double.tryParse(at.group(1)!);
      final lng = double.tryParse(at.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    final bang = RegExp(
      r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)',
    ).firstMatch(input);
    if (bang != null) {
      final lat = double.tryParse(bang.group(1)!);
      final lng = double.tryParse(bang.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    final q = RegExp(
      r'[?&](?:q|query)=(-?\d+(?:\.\d+)?)[,\s+%2C]+(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(input);
    if (q != null) {
      final lat = double.tryParse(q.group(1)!);
      final lng = double.tryParse(q.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    final ll = RegExp(
      r'[?&]ll=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(input);
    if (ll != null) {
      final lat = double.tryParse(ll.group(1)!);
      final lng = double.tryParse(ll.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    return null;
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

  /// Resolves a place name, address, coords, or Maps URL to a real lat/lng.
  static Future<GeocodeResult?> geocode(
    String query, {
    String apiKey = kAdminGoogleMapsApiKey,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // Direct coords / Maps URL — no network needed when already embedded.
    final parsed = parseCoordinates(trimmed);
    if (parsed != null &&
        (trimmed.contains('http') ||
            trimmed.contains('@') ||
            RegExp(r'^-?\d').hasMatch(trimmed))) {
      return GeocodeResult(
        latLng: parsed,
        address: formatCoordinates(parsed),
        name: formatCoordinates(parsed),
      );
    }

    // Short Maps links need a redirect to expose @lat,lng.
    if (_looksLikeMapsUrl(trimmed)) {
      final fromRedirect = await _resolveMapsShortLink(trimmed);
      if (fromRedirect != null) return fromRedirect;
    }

    final keys = <String>{
      apiKey,
      ..._kAdminMapsApiKeyFallbacks,
    }.where((k) => k.trim().isNotEmpty).toList(growable: false);

    // Places Text Search is best for landmark / business names.
    for (final key in keys) {
      final places = await _placesTextSearch(trimmed, key);
      if (places != null) return places;
    }

    for (final key in keys) {
      final google = await _geocodeGoogle(trimmed, key);
      if (google != null) return google;
    }

    final osm = await _geocodeOsm(trimmed);
    if (osm != null) return osm;

    return _geocodePhoton(trimmed);
  }

  static bool _looksLikeMapsUrl(String input) {
    final lower = input.toLowerCase();
    return lower.contains('maps.google.') ||
        lower.contains('google.com/maps') ||
        lower.contains('maps.app.goo.gl') ||
        lower.contains('goo.gl/maps');
  }

  static Future<GeocodeResult?> _resolveMapsShortLink(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'User-Agent': 'admin_arawatan/1.0',
        },
      );
      final finalUrl = response.request?.url.toString() ?? '';
      final body = response.body;
      final parsed = parseCoordinates(finalUrl) ?? parseCoordinates(body);
      if (parsed == null) return null;
      return GeocodeResult(
        latLng: parsed,
        address: formatCoordinates(parsed),
        name: formatCoordinates(parsed),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<GeocodeResult?> _placesTextSearch(
    String query,
    String apiKey,
  ) async {
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/textsearch/json',
        {
          'query': query,
          'key': apiKey,
          'language': 'ar',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        return null;
      }

      final results = data['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) {
        return null;
      }

      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final name = (first['name'] as String?)?.trim() ?? '';
      final address =
          (first['formatted_address'] as String?)?.trim() ?? name;
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null || !_isValidLatLng(lat, lng)) {
        return null;
      }

      return GeocodeResult(
        latLng: LatLng(lat, lng),
        address: address.isNotEmpty ? address : formatCoordinates(LatLng(lat, lng)),
        name: name.isNotEmpty ? name : address,
      );
    } catch (_) {
      return null;
    }
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
          'limit': '3',
          'accept-language': 'ar',
        },
      );
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'TouriAdmin/1.0 (landmark geocode; contact=support@touri.app)',
          'Accept': 'application/json',
        },
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
      final name = (first['name'] as String?)?.trim();
      final lat = double.tryParse('${first['lat']}');
      final lng = double.tryParse('${first['lon']}');
      if (lat == null || lng == null || !_isValidLatLng(lat, lng)) {
        return null;
      }

      return GeocodeResult(
        latLng: LatLng(lat, lng),
        address: address,
        name: (name != null && name.isNotEmpty) ? name : address,
      );
    } catch (_) {
      return null;
    }
  }

  /// Photon (Komoot) — CORS-friendly fallback when Google/OSM fail in browser.
  static Future<GeocodeResult?> _geocodePhoton(String query) async {
    try {
      final uri = Uri.https(
        'photon.komoot.io',
        '/api/',
        {
          'q': query,
          'limit': '1',
          'lang': 'en',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? const [];
      if (features.isEmpty) return null;

      final first = features.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List<dynamic>?;
      if (coords == null || coords.length < 2) return null;

      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      if (!_isValidLatLng(lat, lng)) return null;

      final props = first['properties'] as Map<String, dynamic>? ?? const {};
      final name = (props['name'] as String?)?.trim() ?? '';
      final city = (props['city'] as String?)?.trim() ?? '';
      final country = (props['country'] as String?)?.trim() ?? '';
      final address = [
        if (name.isNotEmpty) name,
        if (city.isNotEmpty) city,
        if (country.isNotEmpty) country,
      ].join(', ');

      return GeocodeResult(
        latLng: LatLng(lat, lng),
        address: address.isNotEmpty ? address : formatCoordinates(LatLng(lat, lng)),
        name: name.isNotEmpty ? name : address,
      );
    } catch (_) {
      return null;
    }
  }
}

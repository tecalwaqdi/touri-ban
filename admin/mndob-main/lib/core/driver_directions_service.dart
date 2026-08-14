import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// نتيجة مسار من Google Routes (أو Directions كاحتياطي).
class DriverRoadRoute {
  const DriverRoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.staticDurationSeconds,
    required this.trafficAware,
    required this.approximate,
    required this.source,
    this.encodedPolyline = '',
  });

  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;
  final int staticDurationSeconds;
  final bool trafficAware;
  final bool approximate;
  final String source;
  final String encodedPolyline;

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes =>
      durationSeconds <= 0 ? 0 : (durationSeconds / 60).ceil();
}

/// جلب مسارات Google Routes (traffic-aware) عبر Cloud Function آمنة.
abstract final class DriverDirectionsService {
  DriverDirectionsService._();

  static const _earthRadiusMeters = 6371000.0;

  static Future<List<LatLng>?> fetchRoadRoute(
    List<LatLng> points, {
    bool optimal = false,
  }) async {
    final route = await fetchRoadRouteResult(points, optimal: optimal);
    return route?.points;
  }

  static Future<DriverRoadRoute?> fetchRoadRouteResult(
    List<LatLng> points, {
    bool optimal = true,
  }) async {
    if (points.length < 2) return null;

    try {
      final body = await makeCloudCall('getRoadRoute', {
        'points': points
            .map((point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                })
            .toList(growable: false),
        'language': 'ar',
        'region': 'sa',
        if (optimal) 'routingPreference': 'TRAFFIC_AWARE_OPTIMAL',
      });
      if (body.containsKey('error')) {
        debugPrint('Routes request failed: ${body['code']}');
        return null;
      }
      return _parseRouteBody(body);
    } catch (e) {
      debugPrint('Routes fetch error: $e');
      return null;
    }
  }

  static DriverRoadRoute? _parseRouteBody(Map<String, dynamic> body) {
    final status = body['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK' && body['ok'] != true) {
      debugPrint('Routes API status=$status');
      return null;
    }

    var distanceMeters = _asInt(body['distanceMeters']);
    var durationSeconds = _asInt(body['durationSeconds']);
    var staticDurationSeconds = _asInt(body['staticDurationSeconds']);
    final encoded = (body['encodedPolyline'] as String?) ?? '';
    final trafficAware = body['trafficAware'] == true;
    final approximate =
        body['approximate'] == true || body['fallback'] == true;
    final source = (body['source'] as String?) ?? 'unknown';

    List<LatLng> points = const [];
    if (encoded.isNotEmpty) {
      points = decodePolyline(encoded);
    }
    if (points.length < 2) {
      final routes = body['routes'];
      if (routes is List && routes.isNotEmpty) {
        final route = routes.first;
        if (route is Map<String, dynamic>) {
          final detailed = _decodeFromLegs(route);
          if (detailed.length >= 2) {
            points = detailed;
          } else {
            final overviewPolyline = route['overview_polyline'];
            final overviewEncoded = overviewPolyline is Map<String, dynamic>
                ? overviewPolyline['points'] as String?
                : null;
            if (overviewEncoded != null && overviewEncoded.isNotEmpty) {
              points = decodePolyline(overviewEncoded);
            }
          }

          if (distanceMeters <= 0 || durationSeconds <= 0) {
            final routeLegs = route['legs'];
            if (routeLegs is List) {
              for (final leg in routeLegs) {
                if (leg is! Map) continue;
                final d = leg['distance'];
                final t = leg['duration'];
                if (d is Map) distanceMeters += _asInt(d['value']);
                if (t is Map) durationSeconds += _asInt(t['value']);
              }
              if (staticDurationSeconds <= 0) {
                staticDurationSeconds = durationSeconds;
              }
            }
          }
        }
      }
    }

    if (points.length < 2 && distanceMeters <= 0 && durationSeconds <= 0) {
      return null;
    }

    return DriverRoadRoute(
      points: points.length >= 2 ? points : const [],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      staticDurationSeconds:
          staticDurationSeconds > 0 ? staticDurationSeconds : durationSeconds,
      trafficAware: trafficAware,
      approximate: approximate || !trafficAware,
      source: source,
      encodedPolyline: encoded,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<LatLng> _decodeFromLegs(Map<String, dynamic> route) {
    final points = <LatLng>[];
    final legs = route['legs'];
    if (legs is! List) return points;

    for (final leg in legs) {
      if (leg is! Map<String, dynamic>) continue;
      final steps = leg['steps'];
      if (steps is! List) continue;
      for (final step in steps) {
        if (step is! Map<String, dynamic>) continue;
        final polyline = step['polyline'];
        if (polyline is! Map<String, dynamic>) continue;
        final encoded = polyline['points'] as String?;
        if (encoded == null || encoded.isEmpty) continue;
        points.addAll(decodePolyline(encoded));
      }
    }
    return points;
  }

  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  static double distanceMeters(LatLng a, LatLng b) {
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static String routeKey(List<LatLng> points, {int precision = 4}) {
    return points
        .map((p) =>
            '${p.latitude.toStringAsFixed(precision)},${p.longitude.toStringAsFixed(precision)}')
        .join('|');
  }

  static String destinationKey(List<LatLng> points, {int precision = 4}) {
    if (points.length <= 1) return '';
    return routeKey(points.sublist(1), precision: precision);
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}

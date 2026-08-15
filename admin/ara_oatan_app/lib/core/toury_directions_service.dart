import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/toury_polyline.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// نتيجة مسار من Google Routes (أو Directions كاحتياطي).
class TouryRoadRoute {
  const TouryRoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.staticDurationSeconds,
    required this.trafficAware,
    required this.approximate,
    required this.source,
    this.encodedPolyline = '',
    this.legs = const [],
  });

  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;
  final int staticDurationSeconds;
  final bool trafficAware;
  final bool approximate;
  final String source;
  final String encodedPolyline;
  final List<TouryRoadLeg> legs;

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes =>
      durationSeconds <= 0 ? 0 : (durationSeconds / 60).ceil();
}

class TouryRoadLeg {
  const TouryRoadLeg({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.staticDurationSeconds,
  });

  final int distanceMeters;
  final int durationSeconds;
  final int staticDurationSeconds;
}

/// جلب مسارات Google Routes (traffic-aware) عبر Cloud Function آمنة.
abstract final class TouryDirectionsService {
  TouryDirectionsService._();

  static const _earthRadiusMeters = 6371000.0;

  /// Polyline فقط (توافق مع الاستدعاءات القديمة).
  static Future<List<LatLng>?> fetchRoadRoute(
    List<LatLng> points, {
    String language = 'en',
    String region = 'sa',
    bool optimal = false,
  }) async {
    final route = await fetchRoadRouteResult(
      points,
      language: language,
      region: region,
      optimal: optimal,
    );
    return route?.points;
  }

  static Future<TouryRoadRoute?> fetchRoadRouteResult(
    List<LatLng> points, {
    String language = 'en',
    String region = 'sa',
    bool optimal = false,
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
        'language': language.replaceAll('_', '-'),
        'region': region.toLowerCase(),
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

  static TouryRoadRoute? _parseRouteBody(Map<String, dynamic> body) {
    final status = body['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK' && body['ok'] != true) {
      debugPrint('Routes API status=$status');
      return null;
    }

    final distanceMeters = _asInt(body['distanceMeters']);
    final durationSeconds = _asInt(body['durationSeconds']);
    final staticDurationSeconds = _asInt(body['staticDurationSeconds']);
    final encoded = (body['encodedPolyline'] as String?) ?? '';
    final trafficAware = body['trafficAware'] == true;
    final approximate =
        body['approximate'] == true || body['fallback'] == true;
    final source = (body['source'] as String?) ?? 'unknown';

    final legs = <TouryRoadLeg>[];
    final rawLegs = body['legs'];
    if (rawLegs is List) {
      for (final leg in rawLegs) {
        if (leg is! Map) continue;
        legs.add(
          TouryRoadLeg(
            distanceMeters: _asInt(leg['distanceMeters']),
            durationSeconds: _asInt(leg['durationSeconds']),
            staticDurationSeconds: _asInt(leg['staticDurationSeconds']),
          ),
        );
      }
    }

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
        }
      }
    }
    if (points.length < 2 && distanceMeters <= 0 && durationSeconds <= 0) {
      return null;
    }

    // Legacy Directions may omit top-level metrics — sum legs.
    var dist = distanceMeters;
    var dur = durationSeconds;
    var staticDur = staticDurationSeconds;
    if (dist <= 0 || dur <= 0) {
      final routes = body['routes'];
      if (routes is List && routes.isNotEmpty && routes.first is Map) {
        final route = Map<String, dynamic>.from(routes.first as Map);
        final routeLegs = route['legs'];
        if (routeLegs is List) {
          for (final leg in routeLegs) {
            if (leg is! Map) continue;
            final d = leg['distance'];
            final t = leg['duration'];
            if (d is Map) dist += _asInt(d['value']);
            if (t is Map) dur += _asInt(t['value']);
          }
          if (staticDur <= 0) staticDur = dur;
        }
      }
    }

    return TouryRoadRoute(
      points: points.length >= 2 ? points : const [],
      distanceMeters: dist,
      durationSeconds: dur,
      staticDurationSeconds: staticDur > 0 ? staticDur : dur,
      trafficAware: trafficAware,
      approximate: approximate || !trafficAware,
      source: source,
      encodedPolyline: encoded,
      legs: legs,
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

  static List<LatLng> decodePolyline(String encoded, {int precision = 5}) =>
      TouryPolyline.decode(encoded, precision: precision);

  static String routeKey(List<LatLng> points, {int precision = 4}) {
    return points
        .map((p) =>
            '${p.latitude.toStringAsFixed(precision)},${p.longitude.toStringAsFixed(precision)}')
        .join('|');
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

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}

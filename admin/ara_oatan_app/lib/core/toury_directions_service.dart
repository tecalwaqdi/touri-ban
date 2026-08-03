import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/toury_polyline.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// جلب مسارات Google Directions وفك ترميز polyline.
abstract final class TouryDirectionsService {
  TouryDirectionsService._();

  static const _earthRadiusMeters = 6371000.0;

  static Future<List<LatLng>?> fetchRoadRoute(
    List<LatLng> points, {
    String language = 'en',
    String region = 'sa',
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
      });
      if (body.containsKey('error')) {
        debugPrint('Directions request failed: ${body['code']}');
        return null;
      }
      final status = body['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK') {
        debugPrint('Directions API status=$status');
        return null;
      }

      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final detailed = _decodeFromLegs(route);
      if (detailed.length >= 2) return detailed;

      final overviewPolyline = route['overview_polyline'];
      final encoded = overviewPolyline is Map<String, dynamic>
          ? overviewPolyline['points'] as String?
          : null;
      if (encoded == null || encoded.isEmpty) return null;

      final decoded = decodePolyline(encoded);
      return decoded.length >= 2 ? decoded : null;
    } catch (e) {
      debugPrint('Directions fetch error: $e');
      return null;
    }
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

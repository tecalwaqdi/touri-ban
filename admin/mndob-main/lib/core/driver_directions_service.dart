import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// جلب مسارات Google Directions وفك ترميز polyline.
abstract final class DriverDirectionsService {
  DriverDirectionsService._();

  static const _earthRadiusMeters = 6371000.0;

  static Future<List<LatLng>?> fetchRoadRoute(List<LatLng> points) async {
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

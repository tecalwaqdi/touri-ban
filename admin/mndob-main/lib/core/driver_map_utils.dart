import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';

abstract final class DriverMapUtils {
  DriverMapUtils._();

  static Future<void> fitBounds(
    Completer<gmaps.GoogleMapController> controller,
    List<LatLng> points, {
    double padding = 48,
  }) async {
    if (points.isEmpty || !controller.isCompleted) return;
    final map = await controller.future;
    if (points.length == 1) {
      await map.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(points.first.toGoogleMaps(), 15),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );
    await map.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  static double? distanceKm(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final lat1 = a.latitude * p;
    final lat2 = b.latitude * p;
    final dLat = (b.latitude - a.latitude) * p;
    final dLng = (b.longitude - a.longitude) * p;
    final h = (1 - math.cos(dLat) / 2) / 2 +
        math.cos(lat1) * math.cos(lat2) * (1 - math.cos(dLng) / 2) / 2;
    return 12742 * math.asin(math.sqrt(h));
  }
}

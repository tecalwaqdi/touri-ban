import 'dart:math' as math;

import '/flutter_flow/lat_lng.dart';

class TouryRouteValidation {
  const TouryRouteValidation({
    required this.points,
    required this.rejectedCount,
    this.errorKey,
  });

  final List<LatLng> points;
  final int rejectedCount;
  final String? errorKey;

  bool get canRoute => points.length >= 2 && errorKey == null;
}

class TouryRouteEstimate {
  const TouryRouteEstimate({
    required this.distanceKm,
    required this.durationHours,
  });

  final double distanceKm;
  final double durationHours;
}

bool touryIsValidCoordinate(LatLng? point) {
  if (point == null) return false;
  final lat = point.latitude;
  final lng = point.longitude;
  return lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180 &&
      !(lat.abs() < 0.000001 && lng.abs() < 0.000001);
}

double touryStraightLineDistanceKm(LatLng from, LatLng to) {
  const earthRadiusKm = 6371.0;
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final deltaLat = (to.latitude - from.latitude) * math.pi / 180;
  final deltaLng = (to.longitude - from.longitude) * math.pi / 180;
  final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(deltaLng / 2) *
          math.sin(deltaLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

TouryRouteValidation touryValidateRoutePoints({
  required LatLng? origin,
  required Iterable<LatLng?> destinations,
  LatLng? selectedAreaCenter,
  double maxDestinationFromAreaKm = 450,
  double maxLegKm = 1500,
}) {
  if (!touryIsValidCoordinate(origin)) {
    return const TouryRouteValidation(
      points: [],
      rejectedCount: 0,
      errorKey: 'map_location_unavailable',
    );
  }

  final points = <LatLng>[origin!];
  var rejected = 0;
  var previous = origin;
  final hasAreaCenter = touryIsValidCoordinate(selectedAreaCenter);

  for (final destination in destinations) {
    if (!touryIsValidCoordinate(destination)) {
      rejected++;
      continue;
    }
    final point = destination!;
    final fromAreaKm = hasAreaCenter
        ? touryStraightLineDistanceKm(selectedAreaCenter!, point)
        : 0.0;
    final legKm = touryStraightLineDistanceKm(previous, point);
    if ((hasAreaCenter && fromAreaKm > maxDestinationFromAreaKm) ||
        legKm > maxLegKm) {
      rejected++;
      continue;
    }
    if (touryStraightLineDistanceKm(previous, point) < 0.03) {
      continue;
    }
    points.add(point);
    previous = point;
  }

  return TouryRouteValidation(
    points: points,
    rejectedCount: rejected,
    errorKey: points.length < 2 ? 'map_no_valid_destinations' : null,
  );
}

TouryRouteEstimate touryEstimateRoute(List<LatLng> points) {
  if (points.length < 2) {
    return const TouryRouteEstimate(distanceKm: 0, durationHours: 0);
  }
  var distanceKm = 0.0;
  for (var i = 1; i < points.length; i++) {
    distanceKm += touryStraightLineDistanceKm(points[i - 1], points[i]);
  }
  final averageSpeedKmH = distanceKm > 120 ? 75.0 : 50.0;
  final stopBufferHours = (points.length - 2).clamp(0, 12) * 0.2;
  return TouryRouteEstimate(
    distanceKm: distanceKm,
    durationHours: distanceKm / averageSpeedKmH + stopBufferHours,
  );
}

bool touryRoadMetricsArePlausible({
  required double distanceKm,
  required double durationSeconds,
  required List<LatLng> points,
}) {
  if (!distanceKm.isFinite ||
      !durationSeconds.isFinite ||
      distanceKm <= 0 ||
      durationSeconds <= 0 ||
      distanceKm > 2500 ||
      durationSeconds > const Duration(hours: 72).inSeconds) {
    return false;
  }
  final direct = touryEstimateRoute(points).distanceKm;
  if (direct <= 0) return false;
  return distanceKm >= direct * 0.75 && distanceKm <= direct * 5 + 50;
}

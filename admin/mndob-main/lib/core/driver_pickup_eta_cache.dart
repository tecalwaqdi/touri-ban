import '/core/driver_directions_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Cached traffic-aware driver → pickup ETA for available orders (pre-accept).
abstract final class DriverPickupEtaCache {
  DriverPickupEtaCache._();

  static final Map<String, _CachedEta> _cache = {};
  static const _ttl = Duration(seconds: 45);

  static Future<DriverPickupEta?> forPickup({
    required String orderId,
    required LatLng? driver,
    required LatLng? pickup,
  }) async {
    if (driver == null || pickup == null) return null;
    final key = orderId;
    final now = DateTime.now();
    final existing = _cache[key];
    if (existing != null &&
        now.difference(existing.at) < _ttl &&
        DriverDirectionsService.distanceMeters(existing.driver, driver) < 80) {
      return existing.value;
    }

    final route = await DriverDirectionsService.fetchRoadRouteResult(
      [driver, pickup],
      optimal: true,
    );
    if (route == null ||
        (route.durationSeconds <= 0 && route.distanceMeters <= 0)) {
      return null;
    }
    final value = DriverPickupEta(
      distanceMeters: route.distanceMeters,
      durationSeconds: route.durationSeconds,
      approximate: route.approximate || !route.trafficAware,
    );
    _cache[key] = _CachedEta(value: value, at: now, driver: driver);
    return value;
  }
}

class DriverPickupEta {
  const DriverPickupEta({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.approximate,
  });

  final int distanceMeters;
  final int durationSeconds;
  final bool approximate;

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes =>
      durationSeconds <= 0 ? 0 : (durationSeconds / 60).ceil();
}

class _CachedEta {
  const _CachedEta({
    required this.value,
    required this.at,
    required this.driver,
  });
  final DriverPickupEta value;
  final DateTime at;
  final LatLng driver;
}

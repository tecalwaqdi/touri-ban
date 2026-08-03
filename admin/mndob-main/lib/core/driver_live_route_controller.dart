import '/core/driver_directions_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// يدير جلب مسار الطرق مع تحديث تلقائي عند تحرك المندوب.
class DriverLiveRouteController {
  List<LatLng>? roadPoints;
  bool failed = false;
  bool loading = false;

  String? _fullKey;
  String? _destinationKey;
  DateTime? _lastFetchAt;

  static const _driverRefreshInterval = Duration(seconds: 15);
  static const _driverMoveThresholdMeters = 80.0;

  Future<void> sync(
    List<LatLng> points, {
    required void Function() onChanged,
  }) async {
    if (points.length < 2) {
      reset();
      onChanged();
      return;
    }

    final destinationKey = DriverDirectionsService.destinationKey(points);
    final origin = points.first;
    final fullKey = DriverDirectionsService.routeKey(points);

    if (fullKey == _fullKey) return;

    final onlyDriverMoved =
        _destinationKey == destinationKey && _fullKey != null;
    if (onlyDriverMoved) {
      final throttled = _lastFetchAt != null &&
          DateTime.now().difference(_lastFetchAt!) < _driverRefreshInterval;
      if (throttled) return;

      final previousOrigin = _parseOriginFromKey(_fullKey!);
      if (previousOrigin != null &&
          DriverDirectionsService.distanceMeters(previousOrigin, origin) <
              _driverMoveThresholdMeters) {
        return;
      }
    }

    _fullKey = fullKey;
    _destinationKey = destinationKey;
    loading = true;
    failed = false;
    onChanged();

    final result = await DriverDirectionsService.fetchRoadRoute(points);
    _lastFetchAt = DateTime.now();
    loading = false;

    if (result == null) {
      failed = true;
      roadPoints = points.length >= 2 ? points : null;
    } else {
      failed = false;
      roadPoints = result;
    }
    onChanged();
  }

  void reset() {
    roadPoints = null;
    failed = false;
    loading = false;
    _fullKey = null;
    _destinationKey = null;
    _lastFetchAt = null;
  }

  LatLng? _parseOriginFromKey(String key) {
    final parts = key.split('|');
    if (parts.isEmpty) return null;
    final coords = parts.first.split(',');
    if (coords.length != 2) return null;
    final lat = double.tryParse(coords[0]);
    final lng = double.tryParse(coords[1]);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }
}

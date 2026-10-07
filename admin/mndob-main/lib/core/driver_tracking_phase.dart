import '/flutter_flow/lat_lng.dart';

/// Canonical trip-tracking phases shared by Customer + Driver maps.
///
/// Route/phase labels on the same `order` document — does **not** replace
/// `status_code` lifecycle writes.
abstract final class DriverTrackingPhase {
  DriverTrackingPhase._();

  static const toPickup = 'to_pickup';
  static const toDestination = 'to_destination';
  static const atDestination = 'at_destination';
  static const returningToPickup = 'returning_to_pickup';
  static const returnedToPickup = 'returned_to_pickup';
  static const completed = 'completed';

  static const all = <String>{
    toPickup,
    toDestination,
    atDestination,
    returningToPickup,
    returnedToPickup,
    completed,
  };

  static String normalize(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (all.contains(v)) return v;
    return '';
  }

  static String resolve({
    required String statusCode,
    required bool returnToPickup,
    String? trackingPhase,
  }) {
    final stored = normalize(trackingPhase);
    final code = statusCode.trim().toLowerCase();

    if (code == 'completed' ||
        code.startsWith('cancelled') ||
        code == 'expired') {
      return completed;
    }

    if (stored.isNotEmpty) {
      if (!returnToPickup &&
          (stored == returningToPickup || stored == returnedToPickup)) {
        return stored == returnedToPickup ? atDestination : toDestination;
      }
      return stored;
    }

    if (code == 'trip_in_progress' || code == 'trip_started') {
      return toDestination;
    }
    if (code == 'driver_arrived' ||
        code == 'driver_assigned' ||
        code == 'driver_arriving') {
      return toPickup;
    }
    return toPickup;
  }

  static LatLng? originalPickup({
    LatLng? lokeshn,
    double? originLatitude,
    double? originLongitude,
  }) {
    if (lokeshn != null &&
        (lokeshn.latitude != 0 || lokeshn.longitude != 0)) {
      return lokeshn;
    }
    final lat = originLatitude;
    final lng = originLongitude;
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      return LatLng(lat, lng);
    }
    return null;
  }
}

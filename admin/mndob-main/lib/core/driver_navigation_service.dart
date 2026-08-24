import 'dart:async';

import 'package:map_launcher/map_launcher.dart' as ml;

import '/core/driver_trip_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// فتح التوجيه في Google Maps (تطبيق خارجي) مثل خرائط جوجل.
abstract final class DriverNavigationService {
  DriverNavigationService._();

  static Future<void> openGoogleMapsNavigation({
    required LatLng destination,
    LatLng? origin,
    List<LatLng> waypoints = const [],
  }) async {
    final dest = '${destination.latitude},${destination.longitude}';
    final originPart = origin != null
        ? '&origin=${origin.latitude},${origin.longitude}'
        : '';
    final wp = waypoints
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');
    final waypointsPart =
        wp.isNotEmpty ? '&waypoints=$wp' : '';

    final directionsUrl =
        'https://www.google.com/maps/dir/?api=1$originPart&destination=$dest$waypointsPart&travelmode=driving';

    try {
      await launchURL(directionsUrl);
      return;
    } catch (_) {}

    await launchMap(
      mapType: ml.MapType.google,
      location: destination,
      title: driverTr(null, 'Trip destination'),
    );
  }

  static Future<void> openGoogleMapsMarker(LatLng location, {String? title}) =>
      launchMap(
        mapType: ml.MapType.google,
        location: location,
        title: title ?? driverTr(null, 'Location'),
      );

  /// Opens Google Maps directions for an accepted order (pickup + stops).
  static Future<void> openOrderRoute({
    required List<LatLng> waypoints,
    LatLng? driverOrigin,
    DocumentReference? orderRef,
  }) async {
    if (orderRef != null) {
      // Opening navigation = driver is moving toward customer.
      unawaited(DriverTripService.markEnRouteIfAssigned(orderRef));
    }
    if (waypoints.isEmpty) return;
    final pts = <LatLng>[
      if (driverOrigin != null) driverOrigin,
      ...waypoints,
    ];
    // Deduplicate consecutive near-identical points.
    final cleaned = <LatLng>[];
    for (final p in pts) {
      if (cleaned.isEmpty ||
          (cleaned.last.latitude - p.latitude).abs() > 1e-5 ||
          (cleaned.last.longitude - p.longitude).abs() > 1e-5) {
        cleaned.add(p);
      }
    }
    if (cleaned.isEmpty) return;
    if (cleaned.length == 1) {
      await openGoogleMapsMarker(
        cleaned.first,
        title: driverTr(null, 'Order location'),
      );
      return;
    }
    await openGoogleMapsNavigation(
      origin: cleaned.first,
      destination: cleaned.last,
      waypoints: cleaned.length > 2
          ? cleaned.sublist(1, cleaned.length - 1)
          : const [],
    );
  }
}

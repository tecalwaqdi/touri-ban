import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_booking_status_localizer.dart';
import 'package:ara_oatan_app/core/toury_trip_progress.dart';
import 'package:ara_oatan_app/flutter_flow/lat_lng.dart';

/// Pure waypoint phase logic mirrored from TouryOrderMeta.trackingRouteWaypoints
/// without Firestore OrderRecord construction.
List<LatLng> _phaseWaypoints({
  required TouryTripStage stage,
  LatLng? driver,
  LatLng? pickup,
  LatLng? dest,
  List<LatLng> stops = const [],
}) {
  if (stage == TouryTripStage.enRoute) {
    if (driver != null && pickup != null && driver != pickup) {
      return [driver, pickup];
    }
    if (driver != null && dest != null && driver != dest) {
      return [driver, dest];
    }
    if (pickup != null && dest != null && pickup != dest) {
      return [pickup, dest];
    }
    return const [];
  }

  if (stage == TouryTripStage.arrived || stage == TouryTripStage.started) {
    final live = <LatLng>[
      if (driver != null) driver,
      if (driver == null && pickup != null) pickup,
      ...stops.where((p) => p != pickup && p != dest && p != driver),
      if (dest != null && dest != driver && dest != pickup) dest,
    ];
    final deduped = <LatLng>[];
    for (final p in live) {
      if (deduped.isEmpty || deduped.last != p) deduped.add(p);
    }
    if (deduped.length >= 2) return deduped;
  }

  return [
    if (pickup != null) pickup,
    ...stops.where((p) => p != pickup && p != dest),
    if (dest != null && dest != pickup) dest,
  ];
}

void main() {
  final driver = const LatLng(24.7136, 46.6753);
  final pickup = const LatLng(24.7200, 46.6800);
  final dest = const LatLng(24.7500, 46.7100);

  test('pre-arrival route is driver → pickup', () {
    final stage = touryResolveTripStage(
      statusCode: TouryBookingStatusCodes.driverAssigned,
    );
    expect(stage, TouryTripStage.enRoute);
    final pts = _phaseWaypoints(
      stage: stage,
      driver: driver,
      pickup: pickup,
      dest: dest,
    );
    expect(pts, [driver, pickup]);
    expect(pts.contains(dest), isFalse);
  });

  test('after start route is driver → destination (no pickup leg)', () {
    final stage = touryResolveTripStage(
      statusCode: TouryBookingStatusCodes.tripInProgress,
    );
    expect(stage, TouryTripStage.started);
    final pts = _phaseWaypoints(
      stage: stage,
      driver: driver,
      pickup: pickup,
      dest: dest,
    );
    expect(pts.first, driver);
    expect(pts.last, dest);
    expect(pts.contains(pickup), isFalse);
  });

  test('after arrive switches off pickup route', () {
    final stage = touryResolveTripStage(
      statusCode: TouryBookingStatusCodes.driverArrived,
    );
    expect(stage, TouryTripStage.arrived);
    final pts = _phaseWaypoints(
      stage: stage,
      driver: driver,
      pickup: pickup,
      dest: dest,
    );
    expect(pts, [driver, dest]);
  });
}

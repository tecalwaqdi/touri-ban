import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_tracking_phase.dart';
import 'package:mndob/flutter_flow/lat_lng.dart';

void main() {
  test('returnToPickup false finishes at the destination', () {
    expect(
      DriverTrackingPhase.resolve(
        statusCode: 'trip_in_progress',
        returnToPickup: false,
        trackingPhase: 'returning_to_pickup',
      ),
      DriverTrackingPhase.toDestination,
    );
    expect(
      DriverTrackingPhase.resolve(
        statusCode: 'trip_in_progress',
        returnToPickup: false,
        trackingPhase: 'at_destination',
      ),
      DriverTrackingPhase.atDestination,
    );
  });

  test('returnToPickup true keeps the return to the original pickup', () {
    expect(
      DriverTrackingPhase.resolve(
        statusCode: 'trip_in_progress',
        returnToPickup: true,
        trackingPhase: 'returning_to_pickup',
      ),
      DriverTrackingPhase.returningToPickup,
    );
  });

  test('original pickup is the booking snapshot, not a live point', () {
    final pickup = DriverTrackingPhase.originalPickup(
      lokeshn: LatLng(42.87, 74.59),
      originLatitude: 41.0,
      originLongitude: 75.0,
    );
    expect(pickup!.latitude, 42.87);
    expect(pickup.longitude, 74.59);
  });
}

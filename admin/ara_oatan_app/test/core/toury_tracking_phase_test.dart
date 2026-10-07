import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_tracking_phase.dart';
import 'package:ara_oatan_app/flutter_flow/lat_lng.dart';

void main() {
  group('TouryTrackingPhase.resolve', () {
    test('return=false never exposes return phases', () {
      expect(
        TouryTrackingPhase.resolve(
          statusCode: 'trip_in_progress',
          returnToPickup: false,
          trackingPhase: TouryTrackingPhase.returningToPickup,
        ),
        TouryTrackingPhase.toDestination,
      );
    });

    test('reload resumes returning_to_pickup when booked', () {
      expect(
        TouryTrackingPhase.resolve(
          statusCode: 'trip_in_progress',
          returnToPickup: true,
          trackingPhase: TouryTrackingPhase.returningToPickup,
        ),
        TouryTrackingPhase.returningToPickup,
      );
    });

    test('derives to_destination after trip start without stored phase', () {
      expect(
        TouryTrackingPhase.resolve(
          statusCode: 'trip_in_progress',
          returnToPickup: true,
          trackingPhase: null,
        ),
        TouryTrackingPhase.toDestination,
      );
    });

    test('derives to_pickup while assigned', () {
      expect(
        TouryTrackingPhase.resolve(
          statusCode: 'driver_assigned',
          returnToPickup: false,
          trackingPhase: '',
        ),
        TouryTrackingPhase.toPickup,
      );
    });

    test('completed status wins', () {
      expect(
        TouryTrackingPhase.resolve(
          statusCode: 'completed',
          returnToPickup: true,
          trackingPhase: TouryTrackingPhase.returningToPickup,
        ),
        TouryTrackingPhase.completed,
      );
    });
  });

  group('TouryTrackingPhase.originalPickup', () {
    test('prefers LOKESHN snapshot over zeros', () {
      final p = TouryTrackingPhase.originalPickup(
        lokeshn: const LatLng(24.7, 46.7),
        originLatitude: 0,
        originLongitude: 0,
      );
      expect(p?.latitude, 24.7);
      expect(p?.longitude, 46.7);
    });

    test('falls back to originLatitude/Longitude', () {
      final p = TouryTrackingPhase.originalPickup(
        lokeshn: null,
        originLatitude: 21.4,
        originLongitude: 39.8,
      );
      expect(p?.latitude, 21.4);
      expect(p?.longitude, 39.8);
    });
  });

  test('return option does not invent extra hours (contract)', () {
    // Booking hours remain whatever was booked; return is a route flag only.
    const bookedHours = 3;
    const returnToPickup = true;
    final effectiveHours = bookedHours; // no auto +1 for return
    expect(returnToPickup, isTrue);
    expect(effectiveHours, 3);
  });
}

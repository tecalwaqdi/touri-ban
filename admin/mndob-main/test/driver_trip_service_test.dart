import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_trip_service.dart';
import 'package:mndob/core/toury_system_status_codes.dart';

void main() {
  group('DriverTripService.haversineMeters', () {
    test('same point is ~0', () {
      expect(
        DriverTripService.haversineMeters(41.3, 69.2, 41.3, 69.2),
        closeTo(0, 0.01),
      );
    });

    test('~1km north of equator-ish city coords', () {
      // ~111m per 0.001 deg latitude
      final meters = DriverTripService.haversineMeters(
        41.3000,
        69.2400,
        41.3010,
        69.2400,
      );
      expect(meters, closeTo(111.2, 5));
    });
  });

  group('TourySystemStatusCodes assignable claim path', () {
    test('pending_driver is assignable', () {
      expect(
        TourySystemStatusCodes.isAssignable('pending_driver', '', ''),
        isTrue,
      );
    });

    test('driver_assigned is not assignable to another driver', () {
      expect(
        TourySystemStatusCodes.isAssignable('driver_assigned', '', ''),
        isFalse,
      );
    });
  });

  group('DriverTripService radii', () {
    test('arrival and dropoff radii are production defaults', () {
      expect(DriverTripService.arrivalRadiusMeters, 80);
      expect(DriverTripService.dropoffRadiusMeters, 150);
      expect(DriverTripService.minTripSecondsBeforeComplete, 60);
    });
  });

  group('DriverTripService.formatRemainingTripTime', () {
    test('formats hours and minutes', () {
      expect(
        DriverTripService.formatRemainingTripTime(const Duration(hours: 2, minutes: 15)),
        '2س 15د',
      );
      expect(
        DriverTripService.formatRemainingTripTime(const Duration(minutes: 12)),
        '12د',
      );
    });
  });
}

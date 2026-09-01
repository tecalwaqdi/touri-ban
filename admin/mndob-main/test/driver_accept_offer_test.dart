import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_order_availability.dart';
import 'package:mndob/core/driver_trip_service.dart';

void main() {
  group('accept offer error messages', () {
    test('maps INTERNAL away from raw code', () {
      expect(
        DriverTripService.messageForCode('INTERNAL'),
        isNot(equals('INTERNAL')),
      );
      expect(
        DriverTripService.messageForCode('internal'),
        contains('server error'),
      );
    });

    test('maps race and expiry codes clearly', () {
      expect(
        DriverTripService.messageForCode('BOOKING_ALREADY_ASSIGNED'),
        contains('another driver'),
      );
      expect(
        DriverTripService.messageForCode('BOOKING_EXPIRED'),
        contains('expired'),
      );
      expect(
        DriverTripService.messageForCode('OFFLINE'),
        contains('internet'),
      );
    });
  });

  group('acceptance window', () {
    test('expired when past acceptanceDeadline', () {
      final now = DateTime.utc(2026, 8, 17, 12);
      final data = <String, dynamic>{
        'acceptanceDeadline': now.subtract(const Duration(minutes: 1)),
      };
      expect(
        DriverOrderAvailability.isAcceptanceExpired(data, now: now),
        isTrue,
      );
    });

    test('not expired inside window from data_order', () {
      final now = DateTime.utc(2026, 8, 17, 12);
      final data = <String, dynamic>{
        'data_order': now.subtract(const Duration(minutes: 10)),
      };
      expect(
        DriverOrderAvailability.isAcceptanceExpired(data, now: now),
        isFalse,
      );
    });
  });
}

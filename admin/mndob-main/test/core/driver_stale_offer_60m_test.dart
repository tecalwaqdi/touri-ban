import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_order_availability.dart';
import 'package:mndob/core/toury_system_status_codes.dart';

void main() {
  group('stale unaccepted offers', () {
    final now = DateTime.utc(2026, 9, 16, 12, 0, 0);

    test('unaccepted order older than 60m is expired', () {
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {
            'data_order': now.subtract(const Duration(minutes: 61)),
            'status_code': TourySystemStatusCodes.pendingDriver,
          },
          now: now,
        ),
        isTrue,
      );
    });

    test('unaccepted order under 60m remains open by time', () {
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {
            'data_order': now.subtract(const Duration(minutes: 59)),
            'status_code': TourySystemStatusCodes.pendingDriver,
          },
          now: now,
        ),
        isFalse,
      );
    });
  });
}

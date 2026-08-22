import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_order_availability.dart';

void main() {
  group('DriverOrderAvailability', () {
    final now = DateTime.utc(2026, 8, 17, 12, 0, 0);

    test('uses acceptanceDeadline from document', () {
      final deadline = now.add(const Duration(minutes: 10));
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {'acceptanceDeadline': deadline},
          now: now,
        ),
        isFalse,
      );
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {'acceptanceDeadline': now.subtract(const Duration(minutes: 1))},
          now: now,
        ),
        isTrue,
      );
    });

    test('falls back to data_order + 1 hour (server field)', () {
      final created59 = now.subtract(const Duration(minutes: 59));
      final created61 = now.subtract(const Duration(minutes: 61));
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {'data_order': created59},
          now: now,
        ),
        isFalse,
      );
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {'data_order': created61},
          now: now,
        ),
        isTrue,
      );
    });

    test('falls back to createdAt + 1 hour', () {
      final created = now.subtract(const Duration(hours: 2));
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {'createdAt': created},
          now: now,
        ),
        isTrue,
      );
    });

    test('missing timestamps cannot prove expiry', () {
      expect(
        DriverOrderAvailability.isAcceptanceExpired(const {}, now: now),
        isFalse,
      );
    });

    test('acceptance_deadline_ms works', () {
      final due = now.subtract(const Duration(seconds: 5)).millisecondsSinceEpoch;
      expect(
        DriverOrderAvailability.isAcceptanceExpired(
          {'acceptance_deadline_ms': due},
          now: now,
        ),
        isTrue,
      );
    });
  });
}

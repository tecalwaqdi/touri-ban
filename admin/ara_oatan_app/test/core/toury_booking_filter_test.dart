import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_booking_filter.dart';

void main() {
  group('touryResolveBookingBucket', () {
    test('canonical cancel codes land in cancelled', () {
      for (final code in const [
        'cancelled',
        'canceled',
        'cancelled_by_customer',
        'cancelled_by_driver',
        'cancelled_by_admin',
      ]) {
        expect(
          touryResolveBookingBucket(statusCode: code),
          TouryBookingBucket.cancelled,
          reason: code,
        );
      }
    });

    test('legacy Arabic cancel text lands in cancelled', () {
      expect(
        touryResolveBookingBucket(halhText: 'ملغي'),
        TouryBookingBucket.cancelled,
      );
    });

    test('cancelled wins over a stale unpaid payment_status', () {
      expect(
        touryResolveBookingBucket(
          statusCode: 'cancelled_by_customer',
          paymentStatus: 'unpaid',
        ),
        TouryBookingBucket.cancelled,
      );
    });

    test('completed codes and driver status land in completed', () {
      expect(
        touryResolveBookingBucket(statusCode: 'completed'),
        TouryBookingBucket.completed,
      );
      expect(
        touryResolveBookingBucket(statusCode: 'trip_completed'),
        TouryBookingBucket.completed,
      );
      expect(
        touryResolveBookingBucket(driverOrderStatus: 'Completed'),
        TouryBookingBucket.completed,
      );
      expect(
        touryResolveBookingBucket(halhText: 'مكتمل'),
        TouryBookingBucket.completed,
      );
    });

    test('unpaid online booking is awaitingPayment, never active', () {
      expect(
        touryResolveBookingBucket(
          statusCode: 'payment_pending',
          paymentStatus: 'unpaid',
        ),
        TouryBookingBucket.awaitingPayment,
      );
      expect(
        touryResolveBookingBucket(statusCode: 'pending_payment'),
        TouryBookingBucket.awaitingPayment,
      );
    });

    test('payment enum Paid does not mark the trip completed', () {
      // A paid-but-still-running trip must stay in the current tab.
      expect(
        touryResolveBookingBucket(
          statusCode: 'trip_in_progress',
          paymentStatus: 'paid',
        ),
        TouryBookingBucket.active,
      );
    });

    test('live driver stages stay active', () {
      for (final code in const [
        'pending_driver',
        'driver_assigned',
        'driver_arriving',
        'driver_arrived',
        'trip_in_progress',
        'trip_started',
      ]) {
        expect(
          touryResolveBookingBucket(statusCode: code),
          TouryBookingBucket.active,
          reason: code,
        );
      }
    });

    test('empty status falls back to active rather than disappearing', () {
      expect(
        touryResolveBookingBucket(),
        TouryBookingBucket.active,
      );
    });

    test('legacy halh_order Canceled is honoured without a status code', () {
      expect(
        touryResolveBookingBucket(halhOrderName: 'Canceled'),
        TouryBookingBucket.cancelled,
      );
    });

    test('every booking resolves to exactly one bucket', () {
      const samples = <String>[
        'pending_driver',
        'driver_assigned',
        'driver_arrived',
        'trip_in_progress',
        'completed',
        'cancelled',
        'payment_pending',
        'some_unknown_future_code',
      ];
      for (final code in samples) {
        final bucket = touryResolveBookingBucket(statusCode: code);
        expect(TouryBookingBucket.values.contains(bucket), isTrue);
      }
    });
  });
}

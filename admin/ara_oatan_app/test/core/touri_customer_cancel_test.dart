import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_booking_status_localizer.dart';
import 'package:ara_oatan_app/core/toury_customer_cancel_policy.dart';

void main() {
  group('TouryCustomerCancelPolicy.ownership', () {
    test('path string and bare uid owner matches', () {
      expect(
        TouryCustomerCancelPolicy.isBookingOwner(
          userField: 'user/cust-1',
          authUid: 'cust-1',
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.isBookingOwner(
          userField: '/user/cust-1',
          authUid: 'cust-1',
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.isBookingOwner(
          userField: 'cust-1',
          authUid: 'cust-1',
        ),
        isTrue,
      );
    });

    test('different customer denied', () {
      expect(
        TouryCustomerCancelPolicy.isBookingOwner(
          userField: 'user/cust-1',
          authUid: 'cust-2',
        ),
        isFalse,
      );
    });
  });

  group('TouryCustomerCancelPolicy.canCustomerCancelBooking', () {
    final createdLongAgo =
        DateTime.now().toUtc().subtract(const Duration(hours: 2));
    final createdRecently =
        DateTime.now().toUtc().subtract(const Duration(minutes: 10));
    final createdAlmostHour =
        DateTime.now().toUtc().subtract(const Duration(minutes: 59));

    test('waiting for driver + within 1h (10 min) → allowed', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          halhText: 'بانتظار قبول السائق',
          createdAt: createdRecently,
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'awaiting_driver',
          createdAt: createdRecently,
        ),
        isTrue,
      );
    });

    test('waiting for driver + 59 min → still allowed', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          createdAt: createdAlmostHour,
        ),
        isTrue,
      );
    });

    test('waiting for driver + after 1h → denied (window expired)', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          createdAt: createdLongAgo,
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.denyReasonKey(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          createdAt: createdLongAgo,
        ),
        'booking_cancel_window_expired',
      );
      final left = TouryCustomerCancelPolicy.remainingCancelWindow(
        createdAt: createdLongAgo,
      );
      expect(left, Duration.zero);
    });

    test('within window remaining countdown is positive', () {
      final left = TouryCustomerCancelPolicy.remainingCancelWindow(
        createdAt: createdRecently,
      );
      expect(left, isNotNull);
      expect(left!.inMinutes, greaterThan(0));
      expect(left.inMinutes, lessThanOrEqualTo(50));
    });

    test('missing createdAt → denied (fail closed)', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          createdAt: null,
        ),
        isFalse,
      );
    });

    test('completed booking → denied', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'completed',
          createdAt: createdRecently,
        ),
        isFalse,
      );
    });

    test('already cancelled is detected (idempotent)', () {
      expect(
        TouryCustomerCancelPolicy.isAlreadyCancelled(
          statusCode: 'cancelled',
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'cancelled',
          createdAt: createdRecently,
        ),
        isFalse,
      );
    });

    test('driver accepted / assigned → denied even within 1h', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.driverAssigned,
          halhText: 'مقبول',
          createdAt: createdRecently,
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          mndobUser: 'user/driver-1',
          createdAt: createdRecently,
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.denyReasonKey(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          mndobUser: 'user/driver-1',
          createdAt: createdRecently,
        ),
        'booking_cancel_after_driver',
      );
    });
  });

  group('payment cancel guard / cash safety', () {
    test('cash never requires paid cancel guard (no refund)', () {
      expect(
        TouryCustomerCancelPolicy.requiresPaidCancelGuard(
          isOnlinePayment: false,
          paymentStatus: 'pending_cash',
          gatewayOrderId: '',
        ),
        isFalse,
      );
    });

    test('paid online without gateway id is blocked', () {
      expect(
        TouryCustomerCancelPolicy.requiresPaidCancelGuard(
          isOnlinePayment: true,
          paymentStatus: 'paid',
          gatewayOrderId: '',
        ),
        isTrue,
      );
    });
  });

  group('cancel payload', () {
    test('does not mutate payment amount/status/owner fields', () {
      final payload = customerCancelUpdatePayload(authUid: 'cust-1');
      expect(payload.containsKey('payment_status'), isFalse);
      expect(payload.containsKey('USER'), isFalse);
      expect(payload.containsKey('mndob_user'), isFalse);
      expect(payload['status_code'], TouryBookingStatusCodes.cancelledByCustomer);
      expect(payload['ALLNOW'], isFalse);
      expect(payload['ActiveOrder'], isFalse);
    });
  });

  group('unpaid payment_pending', () {
    test('allows immediate cancel without window', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'payment_pending',
          paymentStatus: 'unpaid',
          createdAt: DateTime.now().toUtc(),
        ),
        isTrue,
      );
    });

    test('blocks cancel once driver accepted', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'payment_pending',
          paymentStatus: 'unpaid',
          mndobUser: 'driver-ref',
          createdAt: DateTime.now().toUtc(),
        ),
        isFalse,
      );
    });
  });

  group('status localizer payment_pending', () {
    test('does not collapse into pending_driver', () {
      expect(
        BookingStatusLocalizer.resolveCode(statusCode: 'payment_pending'),
        TouryBookingStatusCodes.paymentPending,
      );
    });
  });
}

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

    test('waiting for driver + after 1h → allowed', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          halhText: 'بانتظار قبول السائق',
          createdAt: createdLongAgo,
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'awaiting_driver',
          createdAt: createdLongAgo,
        ),
        isTrue,
      );
    });

    test('waiting for driver + before 1h → denied', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          createdAt: createdRecently,
        ),
        isFalse,
      );
      final left = TouryCustomerCancelPolicy.remainingUntilCancelEligible(
        createdAt: createdRecently,
      );
      expect(left, isNotNull);
      expect(left!.inMinutes, greaterThan(0));
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
          createdAt: createdLongAgo,
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.tripCompleted,
          createdAt: createdLongAgo,
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
        TouryCustomerCancelPolicy.isAlreadyCancelled(
          statusCode: 'pending_driver',
          halhText: 'ملغي',
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'cancelled',
          createdAt: createdLongAgo,
        ),
        isFalse,
      );
    });

    test('driver accepted / assigned → denied even after 1h', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.driverAssigned,
          halhText: 'مقبول',
          createdAt: createdLongAgo,
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          mndobUser: 'user/driver-1',
          createdAt: createdLongAgo,
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.hasDriverAccepted(
          statusCode: 'driver_arriving',
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'trip_in_progress',
          createdAt: createdLongAgo,
        ),
        isFalse,
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

    test('paid online with gateway id can proceed to refund path', () {
      expect(
        TouryCustomerCancelPolicy.requiresPaidCancelGuard(
          isOnlinePayment: true,
          paymentStatus: 'paid',
          gatewayOrderId: 'ng-123',
        ),
        isFalse,
      );
    });
  });

  group('cancel payload', () {
    test('does not mutate payment amount/status/owner fields', () {
      final payload = customerCancelUpdatePayload(authUid: 'cust-1');
      expect(payload.containsKey('payment_status'), isFalse);
      expect(payload.containsKey('amount_halalas'), isFalse);
      expect(payload.containsKey('total'), isFalse);
      expect(payload.containsKey('PaymentMethod'), isFalse);
      expect(payload.containsKey('USER'), isFalse);
      expect(payload.containsKey('mndob_user'), isFalse);
      expect(payload['status_code'], TouryBookingStatusCodes.cancelledByCustomer);
      expect(payload['ALLNOW'], isFalse);
      expect(payload['ActiveOrder'], isFalse);
    });
  });

  group('unpaid payment_pending', () {
    test('allows immediate cancel without 1h wait', () {
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

    test('isUnpaidPaymentPending detects draft', () {
      expect(
        TouryCustomerCancelPolicy.isUnpaidPaymentPending(
          statusCode: 'payment_pending',
          paymentStatus: 'unpaid',
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.isUnpaidPaymentPending(
          statusCode: 'pending_driver',
          paymentStatus: 'paid',
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
      expect(
        BookingStatusLocalizer.isAwaitingDriver(statusCode: 'payment_pending'),
        isFalse,
      );
      expect(
        BookingStatusLocalizer.isPaymentPending(statusCode: 'payment_pending'),
        isTrue,
      );
    });
  });

}

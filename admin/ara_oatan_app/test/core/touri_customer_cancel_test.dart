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
    test('waiting for driver → allowed immediately (no timer)', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          halhText: 'بانتظار قبول السائق',
        ),
        isTrue,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'awaiting_driver',
        ),
        isTrue,
      );
    });

    test('old booking still waiting → still allowed (no 1h window)', () {
      final createdLongAgo =
          DateTime.now().toUtc().subtract(const Duration(hours: 5));
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          createdAt: createdLongAgo,
        ),
        isTrue,
      );
    });

    test('missing createdAt → still allowed when awaiting driver', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          createdAt: null,
        ),
        isTrue,
      );
    });

    test('completed booking → denied', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'completed',
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
        ),
        isFalse,
      );
    });

    test('driver accepted / assigned → denied', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.driverAssigned,
          halhText: 'مقبول',
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          mndobUser: 'user/driver-1',
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.denyReasonKey(
          statusCode: TouryBookingStatusCodes.pendingDriver,
          mndobUser: 'user/driver-1',
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

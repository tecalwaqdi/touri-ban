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
    test('waiting for driver → allowed', () {
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

    test('completed booking → denied', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'completed',
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.tripCompleted,
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
        ),
        isFalse,
      );
    });

    test('accepted during race (driver_arriving) → denied', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'driver_arriving',
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'trip_in_progress',
        ),
        isFalse,
      );
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: 'driver_arrived',
        ),
        isFalse,
      );
    });

    test('driver_assigned still cancellable', () {
      expect(
        TouryCustomerCancelPolicy.canCustomerCancelBooking(
          statusCode: TouryBookingStatusCodes.driverAssigned,
          halhText: 'مقبول',
        ),
        isTrue,
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
      expect(payload['status_code'], TouryBookingStatusCodes.cancelled);
      expect(payload['ALLNOW'], isFalse);
      expect(payload['ActiveOrder'], isFalse);
    });
  });
}

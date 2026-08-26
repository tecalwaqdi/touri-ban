import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_active_booking_guard.dart';
import 'package:ara_oatan_app/core/toury_async_action_guard.dart';

void main() {
  group('TouryAsyncActionGuard', () {
    setUp(TouryAsyncActionGuard.debugReset);

    test('tryStart blocks concurrent same key', () {
      expect(TouryAsyncActionGuard.tryStart('payment:checkout_card'), isTrue);
      expect(TouryAsyncActionGuard.tryStart('payment:checkout_card'), isFalse);
      expect(TouryAsyncActionGuard.debugRunningCount, 1);
      TouryAsyncActionGuard.finish('payment:checkout_card');
      expect(TouryAsyncActionGuard.tryStart('payment:checkout_card'), isTrue);
      TouryAsyncActionGuard.finish('payment:checkout_card');
      expect(TouryAsyncActionGuard.debugRunningCount, 0);
    });

    test('different keys can run concurrently', () {
      expect(TouryAsyncActionGuard.tryStart('profile:update:u1'), isTrue);
      expect(TouryAsyncActionGuard.tryStart('support:create:u1'), isTrue);
      expect(TouryAsyncActionGuard.debugRunningCount, 2);
      TouryAsyncActionGuard.finish('profile:update:u1');
      TouryAsyncActionGuard.finish('support:create:u1');
    });

    test('empty key is rejected', () {
      expect(TouryAsyncActionGuard.tryStart(''), isFalse);
      expect(TouryAsyncActionGuard.tryStart('   '), isFalse);
    });
  });

  group('touryIsSameActiveBookingFlow', () {
    test('same currentOrderId resumes', () {
      expect(
        touryIsSameActiveBookingFlow(
          activeOrderId: 'ord_A',
          currentOrderId: 'ord_A',
        ),
        isTrue,
      );
    });

    test('pendingPaymentOrderId matches active', () {
      expect(
        touryIsSameActiveBookingFlow(
          activeOrderId: 'ord_A',
          pendingPaymentOrderId: 'ord_A',
        ),
        isTrue,
      );
    });

    test('paymentOrderId matches active', () {
      expect(
        touryIsSameActiveBookingFlow(
          activeOrderId: 'ord_A',
          paymentOrderId: 'ord_A',
        ),
        isTrue,
      );
    });

    test('different active order is not same flow', () {
      expect(
        touryIsSameActiveBookingFlow(
          activeOrderId: 'ord_B',
          currentOrderId: 'ord_A',
          pendingPaymentOrderId: 'ord_A',
          paymentOrderId: 'ord_A',
        ),
        isFalse,
      );
    });
  });
}

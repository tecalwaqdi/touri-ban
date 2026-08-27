import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/payments/touri_payment_lock.dart';

void main() {
  group('touriDecidePaymentLock', () {
    test('no active lock allows new attempt', () {
      final d = touriDecidePaymentLock();
      expect(d.kind, TouriPaymentLockKind.none);
      expect(d.blocked, isFalse);
    });

    test('same booking unpaid resumes — not another booking', () {
      final d = touriDecidePaymentLock(
        currentOrderId: 'ord_A',
        pendingPaymentOrderId: 'sess_old',
        paymentOrderId: 'sess_A',
        activeOrderId: 'ord_A',
        activeStatusCode: 'payment_pending',
        activePaymentStatus: 'unpaid',
      );
      expect(d.kind, TouriPaymentLockKind.resumeSame);
      expect(d.blocked, isFalse);
      expect(d.isFalseOtherBooking, isTrue);
      expect(d.resumeOrderId, 'ord_A');
    });

    test('session id matching paymentOrderId still resumes', () {
      final d = touriDecidePaymentLock(
        paymentOrderId: 'sess_hash',
        activeOrderId: 'sess_hash',
        activeStatusCode: 'payment_pending',
        activePaymentStatus: 'unpaid',
      );
      expect(d.kind, TouriPaymentLockKind.resumeSame);
    });

    test('checkout with empty ids resumes leftover unpaid draft', () {
      final d = touriDecidePaymentLock(
        activeOrderId: 'ord_leftover',
        activeStatusCode: 'payment_pending',
        activePaymentStatus: 'unpaid',
      );
      expect(d.kind, TouriPaymentLockKind.resumeUnpaidCheckout);
      expect(d.blocked, isFalse);
      expect(d.isFalseOtherBooking, isTrue);
    });

    test('different unpaid booking is a genuine conflict', () {
      final d = touriDecidePaymentLock(
        currentOrderId: 'ord_A',
        activeOrderId: 'ord_B',
        activeStatusCode: 'payment_pending',
        activePaymentStatus: 'unpaid',
      );
      expect(d.kind, TouriPaymentLockKind.conflictOtherPayment);
      expect(d.blocked, isTrue);
    });

    test('operational trip blocks new checkout', () {
      final d = touriDecidePaymentLock(
        activeOrderId: 'ord_live',
        activeStatusCode: 'pending_driver',
        activePaymentStatus: 'cash_pending',
      );
      expect(d.kind, TouriPaymentLockKind.conflictActiveBooking);
      expect(d.blocked, isTrue);
    });

    test('paid booking blocks retry', () {
      final d = touriDecidePaymentLock(
        currentOrderId: 'ord_A',
        activeOrderId: 'ord_A',
        activeStatusCode: 'pending_driver',
        activePaymentStatus: 'paid',
      );
      expect(d.kind, TouriPaymentLockKind.paidBlock);
    });

    test('terminal booking is ignored', () {
      final d = touriDecidePaymentLock(
        activeOrderId: 'ord_done',
        activeStatusCode: 'cancelled_by_customer',
      );
      expect(d.kind, TouriPaymentLockKind.none);
    });
  });

  group('touriCheckoutCtaKind', () {
    test('cash unpaid confirms booking', () {
      expect(
        touriCheckoutCtaKind(
          cashSelected: true,
          cardSelected: false,
          paid: false,
          hasPendingSameBookingAttempt: false,
          lastAttemptFailed: false,
        ),
        TouriCheckoutCtaKind.confirmCash,
      );
    });

    test('card with pending attempt resumes', () {
      expect(
        touriCheckoutCtaKind(
          cashSelected: false,
          cardSelected: true,
          paid: false,
          hasPendingSameBookingAttempt: true,
          lastAttemptFailed: false,
        ),
        TouriCheckoutCtaKind.resumeCard,
      );
    });

    test('paid disables pay', () {
      expect(
        touriCheckoutCtaKind(
          cashSelected: false,
          cardSelected: true,
          paid: true,
          hasPendingSameBookingAttempt: true,
          lastAttemptFailed: false,
        ),
        TouriCheckoutCtaKind.paid,
      );
    });
  });

  test('stable idempotency is per order not per tap', () {
    expect(
      touriStableOrderIdempotencyKey('abc'),
      touriStableOrderIdempotencyKey('abc'),
    );
    expect(touriStableOrderIdempotencyKey('abc'), 'pay_order_abc');
  });
}

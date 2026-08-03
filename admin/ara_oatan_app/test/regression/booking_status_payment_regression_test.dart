import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_booking_status_localizer.dart';
import 'package:ara_oatan_app/core/toury_checkout_state.dart';
import 'package:ara_oatan_app/core/toury_payment_flags.dart';
import 'package:ara_oatan_app/core/toury_payment_labels.dart';

void main() {
  group('BookingStatusLocalizer regression', () {
    test('maps awaiting_driver alias to pending_driver', () {
      expect(
        BookingStatusLocalizer.resolveCode(statusCode: 'awaiting_driver'),
        TouryBookingStatusCodes.pendingDriver,
      );
      expect(
        BookingStatusLocalizer.resolveCode(statusCode: 'pending_driver'),
        TouryBookingStatusCodes.pendingDriver,
      );
    });

    test('Paid payment enum is NOT trip completed', () {
      expect(
        BookingStatusLocalizer.isTripCompleted(
          statusCode: 'pending_driver',
          halhText: 'بإنتظار قبول المندوب',
          driverOrderStatus: null,
        ),
        isFalse,
      );
      expect(
        BookingStatusLocalizer.isAwaitingDriver(
          statusCode: 'pending_driver',
          halhText: 'بإنتظار قبول المندوب',
          halhOrderName: 'Paid',
        ),
        isTrue,
      );
    });

    test('completed status_code means trip completed', () {
      expect(
        BookingStatusLocalizer.isTripCompleted(
          statusCode: 'trip_completed',
        ),
        isTrue,
      );
    });
  });

  group('Cash book-now payment selection', () {
    test('cash-only mode: unset is allowed; online still blocked', () {
      // Default compile flag ENABLE_ONLINE_PAYMENT=false.
      expect(TouryPaymentFlags.cashOnlyMode, isTrue);
      expect(touryIsCashBookNowPayment(TouryPaymentKeys.unset), isTrue);
      expect(touryRequiresPaymentMethodSelection(TouryPaymentKeys.unset), isFalse);
      expect(touryIsCashBookNowPayment(TouryPaymentKeys.online), isFalse);
    });

    test('explicit cash is cash book-now', () {
      expect(touryIsCashBookNowPayment(TouryPaymentKeys.cash), isTrue);
      expect(touryIsCashBookNowPayment(TouryPaymentKeys.legacyCash), isTrue);
    });

    test('online is not cash book-now', () {
      expect(touryIsCashBookNowPayment(TouryPaymentKeys.online), isFalse);
    });
  });
}

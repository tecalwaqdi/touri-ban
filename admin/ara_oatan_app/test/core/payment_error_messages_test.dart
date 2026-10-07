import 'package:ara_oatan_app/core/toury_payment_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider outlet config maps to temporary unavailable key', () {
    expect(
      touryPaymentApiErrorKey('PROVIDER_OUTLET_NOT_CONFIGURED'),
      TouryPaymentErrorKeys.temporarilyUnavailable,
    );
    expect(
      touryPaymentApiErrorKey('PROVIDER_UNAVAILABLE'),
      TouryPaymentErrorKeys.temporarilyUnavailable,
    );
  });

  test('card decline codes map to card error key', () {
    expect(
      touryPaymentApiErrorKey('PAYMENT_FAILED'),
      TouryPaymentErrorKeys.cardError,
    );
    expect(
      touryPaymentApiErrorKey('CARD_DECLINED'),
      TouryPaymentErrorKeys.cardError,
    );
  });

  test('pending codes are not temporary-unavailable', () {
    expect(
      touryPaymentApiErrorKey('PAYMENT_PENDING'),
      TouryPaymentErrorKeys.paymentPending,
    );
    expect(
      touryPaymentApiErrorKey('BOOKING_PENDING'),
      TouryPaymentErrorKeys.paymentPending,
    );
  });

  test('missing/expired HPP link text maps to link-expired', () {
    expect(
      touryIsMissingOrExpiredPaymentLinkText(
        'Sorry, the payment link does not exist. For more information...',
      ),
      isTrue,
    );
    expect(
      touryPaymentApiErrorKey(
        'Sorry, the payment link does not exist. Contact the merchant.',
      ),
      TouryPaymentErrorKeys.linkExpired,
    );
    expect(
      touryPaymentApiErrorKey('PAYMENT_EXPIRED'),
      TouryPaymentErrorKeys.linkExpired,
    );
    expect(
      touryPaymentApiErrorKey('HPP_EXPIRED'),
      TouryPaymentErrorKeys.linkExpired,
    );
  });

  test('empty or unknown create-order failures are not card errors', () {
    expect(
      touryPaymentApiErrorKey(null),
      TouryPaymentErrorKeys.temporarilyUnavailable,
    );
    expect(
      touryPaymentApiErrorKey(''),
      TouryPaymentErrorKeys.temporarilyUnavailable,
    );
    expect(
      touryPaymentApiErrorKey('SOME_NEW_PROVIDER_CODE'),
      TouryPaymentErrorKeys.temporarilyUnavailable,
    );
  });
}

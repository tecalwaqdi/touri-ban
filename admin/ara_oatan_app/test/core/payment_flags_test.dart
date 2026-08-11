import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_payment_flags.dart';

void main() {
  test('default points at Firebase paymentApi HTTP backend (online off)', () {
    expect(TouryPaymentFlags.enableOnlinePayment, isFalse);
    expect(TouryPaymentFlags.cashOnlyMode, isTrue);
    expect(TouryPaymentFlags.useVercelPaymentApi, isFalse);
    expect(TouryPaymentFlags.useExternalPaymentApi, isFalse);
    expect(TouryPaymentFlags.paymentBackend, 'external_api');
    expect(
      TouryPaymentFlags.paymentApiBaseUrl,
      contains('cloudfunctions.net/paymentApi'),
    );
  });

  test('online option hidden when cash-only', () {
    expect(TouryPaymentFlags.onlineOptionVisible(), isFalse);
    expect(
      TouryPaymentFlags.cashOptionVisible(remoteOkCash: false),
      isTrue,
    );
  });
}

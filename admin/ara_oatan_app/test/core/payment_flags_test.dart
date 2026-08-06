import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_payment_flags.dart';

void main() {
  test('default backend is firebase_functions with cash-only online off', () {
    expect(TouryPaymentFlags.enableOnlinePayment, isFalse);
    expect(TouryPaymentFlags.cashOnlyMode, isTrue);
    expect(TouryPaymentFlags.useVercelPaymentApi, isFalse);
    expect(TouryPaymentFlags.paymentBackend, 'firebase_functions');
  });

  test('online option hidden when cash-only', () {
    expect(TouryPaymentFlags.onlineOptionVisible(), isFalse);
    expect(
      TouryPaymentFlags.cashOptionVisible(remoteOkCash: false),
      isTrue,
    );
  });
}

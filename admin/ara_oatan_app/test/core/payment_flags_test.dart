import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_payment_flags.dart';

void main() {
  test('defaults target Render Payment Backend with online enabled', () {
    expect(TouryPaymentFlags.enableOnlinePayment, isTrue);
    expect(TouryPaymentFlags.cashOnlyMode, isFalse);
    expect(TouryPaymentFlags.paymentBackend, 'external_api');
    expect(TouryPaymentFlags.useExternalPaymentApi, isTrue);
    expect(TouryPaymentFlags.useVercelPaymentApi, isTrue);
    expect(TouryPaymentFlags.useFirebasePaymentFunctions, isFalse);
    expect(
      TouryPaymentFlags.paymentApiBaseUrl,
      'https://touri-ban.onrender.com',
    );
    expect(TouryPaymentFlags.openPaymentInExternalBrowser, isTrue);
    expect(TouryPaymentFlags.allowClientCashFallback, isTrue);
  });

  test('online option visible; cash follows remote OKcash when online on', () {
    expect(TouryPaymentFlags.onlineOptionVisible(), isTrue);
    expect(
      TouryPaymentFlags.cashOptionVisible(remoteOkCash: true),
      isTrue,
    );
    expect(
      TouryPaymentFlags.cashOptionVisible(remoteOkCash: false),
      isFalse,
    );
  });

  test('Firebase payment backend is opt-in only (not auto-selected)', () {
    // Defaults never enable CF path; requires PAYMENT_BACKEND=firebase_functions.
    expect(TouryPaymentFlags.paymentBackend, isNot(equals('firebase_functions')));
    expect(TouryPaymentFlags.useFirebasePaymentFunctions, isFalse);
    expect(
      TouryPaymentFlags.paymentApiBaseUrl.contains('cloudfunctions.net'),
      isFalse,
    );
  });
}

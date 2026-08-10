import 'package:flutter_test/flutter_test.dart';

import 'package:mndob/core/driver_payment_flags.dart';
import 'package:mndob/core/driver_trip_constants.dart';

void main() {
  test('wallet top-up API defaults to Render', () {
    expect(DriverPaymentFlags.paymentApiBaseUrl, 'https://touri-ban.onrender.com');
    expect(DriverPaymentFlags.enableWalletTopUpApi, isTrue);
    expect(DriverPaymentFlags.useExternalWalletTopUp, isTrue);
  });

  test('cash eligibility threshold remains 200 SAR', () {
    expect(DriverWalletRules.minCashWalletBalance, 200.0);
  });
}

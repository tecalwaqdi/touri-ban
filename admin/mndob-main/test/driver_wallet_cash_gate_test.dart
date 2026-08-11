import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_trip_constants.dart';
import 'package:mndob/core/driver_payment_labels.dart';
import 'package:mndob/backend/schema/enums/enums.dart';

void main() {
  group('DriverWalletRules', () {
    test('cash eligibility threshold is 200', () {
      expect(DriverWalletRules.minCashWalletBalance, 200.0);
    });

    test('CASH + 199 blocked, 200 allowed (eligibility math)', () {
      const min = DriverWalletRules.minCashWalletBalance;
      expect(199 < min, isTrue);
      expect(200 >= min, isTrue);
    });
  });

  group('Cash vs online gate', () {
    test('cash payment methods are detected', () {
      expect(DriverPaymentLabels.isCash(PaymentMethod.Cash), isTrue);
    });
  });
}

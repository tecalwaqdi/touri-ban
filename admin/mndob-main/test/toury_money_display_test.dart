import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/toury_money_display.dart';

void main() {
  group('TouryMoneyAmount', () {
    test('resolves SAR aliases without exposing SAR text in number format', () {
      expect(TouryMoneyAmount.resolveCurrencyCode('SAR'), 'SAR');
      expect(TouryMoneyAmount.resolveCurrencyCode('sar'), 'SAR');
      expect(TouryMoneyAmount.resolveCurrencyCode('ر.س'), 'SAR');
      expect(
        TouryMoneyAmount.formatNumber(1500),
        '1,500.00',
      );
      expect(
        TouryMoneyAmount.formatNumber(1500),
        isNot(contains('SAR')),
      );
      expect(
        TouryMoneyAmount.formatNumber(-500, showPlusForPositive: true),
        '-500.00',
      );
      expect(
        TouryMoneyAmount.formatNumber(1000, showPlusForPositive: true),
        '+1,000.00',
      );
    });

    test('isSaudiRiyal detects wallet currency codes', () {
      expect(TouryMoneyAmount.isSaudiRiyal('SAR'), isTrue);
      expect(TouryMoneyAmount.isSaudiRiyal('KGS'), isFalse);
    });
  });
}

import 'dart:ui';

import 'package:ara_oatan_app/core/toury_money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TouryMoneyFormat', () {
    test('resolves SAR aliases', () {
      expect(TouryMoneyFormat.resolveCurrencyCode(currencyCode: 'SAR'), 'SAR');
      expect(TouryMoneyFormat.resolveCurrencyCode(currencyCode: 'ر.س'), 'SAR');
      expect(TouryMoneyFormat.isSaudiRiyal(currencyCode: 'SAR'), isTrue);
    });

    test('formatPlain uses glyph in ar/ur and Latin SAR elsewhere', () {
      final en = TouryMoneyFormat.formatPlain(
        100,
        locale: const Locale('en'),
        currencyCode: 'SAR',
      );
      expect(en.contains('ر.س'), isFalse);
      expect(en.contains('\u20C1'), isFalse);
      expect(en.contains('SAR'), isTrue);

      final ru = TouryMoneyFormat.formatPlain(
        70,
        locale: const Locale('ru'),
        currencyCode: 'SAR',
      );
      expect(ru.contains('\u20C1'), isFalse);
      expect(ru.contains('SAR'), isTrue);

      final ar = TouryMoneyFormat.formatPlain(
        100,
        locale: const Locale('ar'),
        currencyCode: 'SAR',
      );
      expect(ar.contains('ر.س'), isFalse);
      expect(ar.contains('SAR'), isFalse);
      expect(ar.contains('\u20C1'), isTrue);

      final ur = TouryMoneyFormat.formatPlain(
        100,
        locale: const Locale('ur'),
        currencyCode: 'SAR',
      );
      expect(ur.contains('\u20C1'), isTrue);
      expect(ur.contains('SAR'), isFalse);
    });
  });
}

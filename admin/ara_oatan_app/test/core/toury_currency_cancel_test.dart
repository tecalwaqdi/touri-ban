import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_currency.dart';
import 'package:ara_oatan_app/core/toury_customer_order_actions.dart';

void main() {
  group('TouryCurrency', () {
    test('maps ISO symbols with locale-aware SAR', () {
      expect(TouryCurrency.symbolForCode('KGS'), 'сом');
      expect(TouryCurrency.symbolForCode('SAR'), 'SAR');
      expect(
        TouryCurrency.symbolForCode('SAR', locale: const Locale('ar')),
        TouryCurrency.officialRiyalSign,
      );
      expect(
        TouryCurrency.symbolForCode('SAR', locale: const Locale('ru')),
        'SAR',
      );
      expect(TouryCurrency.symbolForCode('RUB'), '₽');
      expect(TouryCurrency.symbolForCode('UZS'), "soʻm");
    });

    test('override wins over catalog for non-SAR', () {
      expect(TouryCurrency.symbolForCode('KGS', override: 'с'), 'с');
    });

    test('legacy ر.س override normalizes by locale', () {
      expect(
        TouryCurrency.symbolForCode('SAR', override: 'ر.س'),
        'SAR',
      );
      expect(
        TouryCurrency.symbolForCode(
          'SAR',
          override: 'ر.س',
          locale: const Locale('ar'),
        ),
        TouryCurrency.officialRiyalSign,
      );
    });
  });

  group('TouryCustomerOrderActions error mapping', () {
    test('localizedError never returns raw firebase dumps', () {
      final out = TouryCustomerOrderActions.localizedError(
        'The caller does not have permission to execute the specified operation.',
      );
      expect(out.contains('caller'), isFalse);
      expect(out.isNotEmpty, isTrue);
    });

    test('known keys translate via easy_localization fallback path', () {
      // Without EasyLocalization binding, .tr() may return the key;
      // localizedError then maps unknown to booking_unknown_error key or text.
      final out =
          TouryCustomerOrderActions.localizedError('booking_permission_denied');
      expect(out.isNotEmpty, isTrue);
    });
  });
}

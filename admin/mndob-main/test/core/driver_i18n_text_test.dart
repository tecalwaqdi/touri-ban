import 'package:flutter_test/flutter_test.dart';

import 'package:mndob/core/driver_i18n_text.dart';

void main() {
  group('driverLocalizedText', () {
    test('prefers Russian over Arabic for ru locale', () {
      final text = driverLocalizedText(
        const {'ar': 'إندونيسيا', 'en': 'Indonesia', 'ru': 'Индонезия'},
        'إندونيسيا',
        localeKey: 'ru',
      );
      expect(text, 'Индонезия');
    });

    test('falls back to English when locale missing and legacy is Arabic', () {
      final text = driverLocalizedText(
        const {'ar': 'جاكرتا', 'en': 'Jakarta'},
        'جاكرتا',
        localeKey: 'ru',
      );
      expect(text, 'Jakarta');
    });

    test('Arabic UI keeps Arabic script', () {
      final text = driverLocalizedText(
        const {'ar': 'جاكرتا', 'en': 'Jakarta'},
        'جاكرتا',
        localeKey: 'ar',
      );
      expect(text, 'جاكرتا');
    });

    test('never prefers Arabic for non-ar when only Arabic exists', () {
      final text = driverLocalizedText(
        const {'ar': 'مكة'},
        'مكة',
        localeKey: 'en',
      );
      expect(text, '');
    });
  });
}

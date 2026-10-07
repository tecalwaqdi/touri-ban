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

  group('Makkah searching area', () {
    const makkah = {
      'ar': 'مكة المكرمة',
      'en': 'Makkah',
      'ru': 'Мекка',
    };
    const cachedArabic = 'مكة المكرمة';

    test('locale ru resolves to Мекка even when cache is Arabic', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'ru',
          namesI18n: makkah,
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'Мекка',
      );
    });

    test('locale en resolves to Makkah', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'en',
          namesI18n: makkah,
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'Makkah',
      );
    });

    test('locale ar resolves to مكة المكرمة', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'ar',
          namesI18n: makkah,
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'مكة المكرمة',
      );
    });

    test('ru missing and en present uses English not Arabic', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'ru',
          namesI18n: const {'ar': 'مكة المكرمة', 'en': 'Makkah'},
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'Makkah',
      );
    });

    test('ky missing and en present uses English not Arabic', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'ky',
          namesI18n: const {'ar': 'مكة المكرمة', 'en': 'Makkah'},
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'Makkah',
      );
    });

    test('fr missing and en present uses English not Arabic', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'fr',
          namesI18n: const {'ar': 'مكة المكرمة', 'en': 'Makkah'},
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'Makkah',
      );
    });

    test('pt missing and en present uses English not Arabic', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'pt',
          namesI18n: const {'ar': 'مكة المكرمة', 'en': 'Makkah'},
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'Makkah',
      );
    });

    test('cached Arabic alone is hidden for Russian', () {
      expect(
        driverSearchingAreaLabel(
          localeKey: 'ru',
          cachedText: cachedArabic,
        ),
        '',
      );
    });
  });
}

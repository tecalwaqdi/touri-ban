import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_i18n_text.dart';
import 'package:ara_oatan_app/core/toury_landmark_filter.dart';
import 'package:ara_oatan_app/core/toury_landmark_categories.dart';

void main() {
  group('touryLocalizedText locale isolation', () {
    test('ky prefers en over arabic fallback', () {
      final text = touryLocalizedText(
        {'ar': 'الرياض', 'en': 'Riyadh'},
        'الرياض',
        localeKey: 'ky',
      );
      expect(text, 'Riyadh');
      expect(touryLooksArabic(text), isFalse);
    });

    test('ky prefers en over ru when ky missing', () {
      final text = touryLocalizedText(
        {'ar': 'الرياض', 'en': 'Riyadh', 'ru': 'Эр-Рияд'},
        'الرياض',
        localeKey: 'ky',
      );
      expect(text, 'Riyadh');
    });

    test('ky uses ky when present', () {
      final text = touryLocalizedText(
        {'ar': 'الرياض', 'en': 'Riyadh', 'ky': 'Эр-Рияд'},
        'الرياض',
        localeKey: 'ky',
      );
      expect(text, 'Эр-Рияд');
    });

    test('ar can use arabic', () {
      final text = touryLocalizedText(
        {'ar': 'الرياض', 'en': 'Riyadh'},
        'الرياض',
        localeKey: 'ar',
      );
      expect(text, 'الرياض');
    });

    test('ar ignores english polluted into ar key', () {
      final text = touryLocalizedText(
        {'ar': 'Biet Nassif', 'en': 'Biet Nassif', 'local': 'بيت نصيف'},
        'بيت نصيف',
        localeKey: 'ar',
      );
      expect(text, 'بيت نصيف');
      expect(touryLooksArabic(text), isTrue);
    });
  });

  group('Makkah geo name', () {
    const makkah = {
      'ar': 'مكة المكرمة',
      'en': 'Makkah',
      'ru': 'Мекка',
    };
    const cachedArabic = 'مكة المكرمة';

    test('locale ru resolves to Мекка', () {
      expect(
        touryGeoNameLabel(
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
        touryGeoNameLabel(
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
        touryGeoNameLabel(
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
        touryGeoNameLabel(
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
        touryGeoNameLabel(
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
        touryGeoNameLabel(
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
        touryGeoNameLabel(
          localeKey: 'pt',
          namesI18n: const {'ar': 'مكة المكرمة', 'en': 'Makkah'},
          legacyNaim: cachedArabic,
          cachedText: cachedArabic,
        ),
        'Makkah',
      );
    });
  });

  group('landmark junk filter', () {
    test('bans aircraft names', () {
      expect(touryIsBannedLandmarkName('McDonnell Douglas F-15D Eagle'), isTrue);
      expect(touryIsBannedLandmarkName('Panavia Tornado ADV F3'), isTrue);
      expect(touryIsBannedLandmarkName('Boeing 707-386C'), isTrue);
      expect(touryIsBannedLandmarkName('Makkah Gate'), isFalse);
      expect(touryIsBannedLandmarkName('الحجر الأسود'), isFalse);
    });
  });

  group('landmark categories', () {
    test('maps localized labels to arabic storage', () {
      expect(
        TouryLandmarkCategories.toStorage('معالم دينية'),
        TouryLandmarkCategories.storageReligious,
      );
      expect(TouryLandmarkCategories.isAll('الكل'), isTrue);
    });
  });
}

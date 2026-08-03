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

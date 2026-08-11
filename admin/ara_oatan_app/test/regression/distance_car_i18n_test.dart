import 'package:flutter_test/flutter_test.dart';
import 'package:ara_oatan_app/core/toury_distance_format.dart';
import 'package:ara_oatan_app/core/toury_i18n_text.dart';

void main() {
  group('distance format', () {
    test('21564 meters becomes ~21.6 km string', () {
      expect(touryAsDistanceKm(21564), closeTo(21.564, 0.001));
      expect(touryFormatDistanceKm(21564, locale: 'en'), '21.6 km');
    });

    test('small km values stay as km', () {
      expect(touryAsDistanceKm(12.5), 12.5);
      expect(touryFormatDistanceKm(12.5, locale: 'en'), '12.5 km');
    });

    test('explicit meters conversion', () {
      expect(touryMetersToKm(21564), closeTo(21.564, 0.001));
    });
  });

  group('car name locale isolation', () {
    test('ky prefers en over arabic raw name', () {
      final name = touryLocalizedText(
        {'ar': 'سيارة سيدان', 'en': 'Sedan'},
        'سيارة سيدان',
        localeKey: 'ky',
      );
      expect(name, 'Sedan');
      expect(RegExp(r'[\u0600-\u06FF]').hasMatch(name), isFalse);
    });

    test('ky prefers en over russian when ky missing', () {
      final name = touryLocalizedText(
        {'ar': 'سيدان', 'en': 'Sedan', 'ru': 'Седан'},
        'سيدان',
        localeKey: 'ky',
      );
      expect(name, 'Sedan');
    });

    test('ky never leaks arabic address', () {
      final address = touryLocalizedAddress(
        'أبراج البيت، مكة المكرمة',
        localeKey: 'ky',
      );
      expect(address, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/core/i18n/admin_geo_names.dart';

void main() {
  test('saving one locale preserves the other six and extra locales', () {
    final saved = adminGeoNamesForSave(
      existing: {
        'ar': 'Riyadh-AR',
        'en': 'Riyadh',
        'ru': 'Riyadh-RU',
        'ky': 'Riyadh-KY',
        'fr': 'Riyad',
        'ur': 'Riyadh-UR',
        'pt': 'Riade',
        'uz': 'Riyadh-UZ',
      },
      editedByLocale: {
        'ar': 'Riyadh-AR',
        'en': 'Riyadh City',
        'ru': 'Riyadh-RU',
        'ky': 'Riyadh-KY',
        'fr': 'Riyad',
        'ur': 'Riyadh-UR',
        'pt': 'Riade',
      },
    );

    expect(saved['en'], 'Riyadh City');
    expect(saved['ar'], 'Riyadh-AR');
    expect(saved['ru'], 'Riyadh-RU');
    expect(saved['ky'], 'Riyadh-KY');
    expect(saved['fr'], 'Riyad');
    expect(saved['ur'], 'Riyadh-UR');
    expect(saved['pt'], 'Riade');
    expect(saved['uz'], 'Riyadh-UZ');
  });

  test('an Arabic value is not copied into a non-Arabic locale', () {
    final saved = adminGeoNamesForSave(
      existing: {'ar': 'Jeddah-AR', 'en': 'Jeddah'},
      editedByLocale: {
        'ar': 'Jeddah-AR',
        'en': 'Jeddah',
        'ru': '',
        'ky': '',
        'fr': 'Djeddah',
        'ur': '',
        'pt': '',
      },
    );

    expect(saved['fr'], 'Djeddah');
    expect(saved['ru'], isNull);
    expect(saved['en'], 'Jeddah');
    expect(saved['ar'], 'Jeddah-AR');
    expect(saved['en'], isNot('Jeddah-AR'));
    expect(saved['fr'], isNot('Jeddah-AR'));
  });

  test('country city village and landmark forms share the seven locales', () {
    expect(adminGeoLocales, ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt']);
  });
}

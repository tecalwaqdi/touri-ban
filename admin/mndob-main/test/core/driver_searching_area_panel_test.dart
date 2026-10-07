import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_i18n_text.dart';

void main() {
  const makkah = {
    'ar': 'مكة المكرمة',
    'en': 'Makkah',
    'ru': 'Мекка',
    'ky': 'Мекке',
    'fr': 'La Mecque',
    'ur': 'مکہ',
    'pt': 'Meca',
  };

  String cityFor(String locale) => driverSearchingAreaLabel(
        localeKey: locale,
        namesI18n: makkah,
        legacyNaim: 'مكة المكرمة',
        cachedText: 'مكة المكرمة',
      );

  final titles = <String, String>{
    'ru': 'Поиск поездок в {area}. Пожалуйста, подождите...',
    'ky': '{area} боюнча сапар изделүүдө. Күтө туруңуз...',
    'fr': 'Recherche de courses à {area}, veuillez patienter...',
    'ur': '{area} میں سفر تلاش ہو رہے ہیں، براہ کرم انتظار کریں...',
    'pt': 'Procurando viagens em {area}',
    'en': 'Searching for trips in {area}',
    'ar': 'يبحث عن رحلات في {area} يرجى الإنتظار...',
  };

  test('locale files keep the searching title and substitute the city', () {
    final root = Directory.current.path.endsWith('mndob-main')
        ? Directory.current
        : Directory('admin/mndob-main');
    for (final entry in titles.entries) {
      final file = File('${root.path}/assets/langs/${entry.key}.json');
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(
        map['Searching for trips in {area}'],
        entry.value,
        reason: entry.key,
      );
      final city = cityFor(entry.key);
      final rendered = entry.value.replaceAll('{area}', city);
      expect(rendered.contains(city), isTrue, reason: entry.key);
      if (entry.key == 'ru') {
        expect(rendered, 'Поиск поездок в Мекка. Пожалуйста, подождите...');
        expect(rendered.contains('مكة'), isFalse);
      } else if (entry.key != 'ar' && entry.key != 'ur') {
        expect(rendered.contains('مكة'), isFalse, reason: entry.key);
        expect(rendered.contains(city), isTrue, reason: entry.key);
      } else if (entry.key == 'ar') {
        expect(city, 'مكة المكرمة');
        expect(rendered, 'يبحث عن رحلات في مكة المكرمة يرجى الإنتظار...');
      }
    }
  });
}

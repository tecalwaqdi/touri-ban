import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/l10n/ui_catalog.dart';

void main() {
  const langs = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];

  test('admin active lookup keys have all seven locales', () {
    var missing = 0;
    var empty = 0;
    for (final entry in kArabicUiLookup.entries) {
      final map = kUiCatalog[entry.value];
      if (map == null) {
        missing += langs.length;
        continue;
      }
      for (final lang in langs) {
        final value = (map[lang] ?? '').trim();
        if (!map.containsKey(lang)) {
          missing++;
        } else if (value.isEmpty) {
          empty++;
        }
      }
    }
    expect(missing, 0, reason: 'ADMIN_ACTIVE_KEYS_MISSING');
    expect(empty, 0, reason: 'ADMIN_ACTIVE_KEYS_EMPTY');
    expect(kArabicUiLookup.length, greaterThan(0));
  });
}

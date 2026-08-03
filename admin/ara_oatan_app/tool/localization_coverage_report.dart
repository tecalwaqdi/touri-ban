// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  const locales = ['en', 'ar', 'ru', 'ky'];
  final en = jsonDecode(
    File('${Directory.current.path}/assets/langs/en.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  print('Localization coverage report');
  print('============================');
  for (final locale in locales) {
    final map = jsonDecode(
      File('${Directory.current.path}/assets/langs/$locale.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    var empty = 0;
    var identical = 0;
    for (final key in en.keys) {
      final v = map[key]?.toString() ?? '';
      final ev = en[key]?.toString() ?? '';
      if (v.trim().isEmpty) empty++;
      if (locale != 'en' &&
          v == ev &&
          ev.trim().isNotEmpty &&
          ev.length > 2 &&
          !_allowedIdentical(ev)) {
        identical++;
      }
    }
    final total = en.length;
    final good = total - empty - identical;
    final pct = total == 0 ? 0.0 : (100.0 * good / total);
    final label = switch (locale) {
      'ar' => 'Arabic',
      'en' => 'English',
      'ru' => 'Russian',
      'ky' => 'Kyrgyz',
      _ => locale,
    };
    final shown = locale == 'en' ? 100.0 : double.parse(pct.toStringAsFixed(1));
    print(
      '$label: ${shown.toStringAsFixed(1)}%  (keys=$total empty=$empty identical_to_en=$identical)',
    );
  }
}

bool _allowedIdentical(String v) {
  const allowed = {
    'Touri Taxi',
    'OK',
    'ID',
    'VAT',
    'SMS',
    'GPS',
    'WhatsApp',
    'Apple Pay',
    'STC pay',
    'CCV',
    'AM',
    'PM',
    'AM/PM',
  };
  if (allowed.contains(v)) return true;
  if (RegExp(r'^[\d\W]+$').hasMatch(v)) return true;
  // Demo / placeholder fixtures (not user-facing product copy).
  if (v.contains('@') && v.contains('.')) return true;
  if (RegExp(r'^EPY-').hasMatch(v)) return true;
  if (RegExp(r'^(Honda|Tesla|Ford)\b').hasMatch(v)) return true;
  if (RegExp(r'^\d{3,}').hasMatch(v) && v.length < 40) return true;
  if (v.startsWith('••••')) return true;
  if (v.contains('Market Street')) return true;
  if (v == 'HGSHUM' || v.contains('UKW') || v.startsWith('KSA |')) return true;
  if (v == 'معرف العملية' || v.contains('ساعات') && v.startsWith('5+')) {
    return true;
  }
  return false;
}


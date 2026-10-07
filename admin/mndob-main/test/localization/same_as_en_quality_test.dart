import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const intentionalExactValues = {
  'OK',
  'Ok',
  'Touri Taxi',
  'SAR',
  'GPS',
  'IBAN',
  'N/A',
  'ID',
  'SMS',
  'OTP',
  'PDF',
  'URL',
  'API',
  'WhatsApp',
  'Jeddah',
  'Dammam',
  'Makkah',
  'Madinah',
  'Taif',
  'Abha',
  'Tabuk',
  'Google',
  'Apple',
  'Facebook',
  'STC pay',
  'Apple Pay',
  'Visa',
  'Mastercard',
  'AM',
  'PM',
  'AM/PM',
  'MM',
  'YY',
  'CCV',
  'CVV',
  'iOS',
  'Android',
  'FAQ',
  'PIN',
  'QR',
  'km',
  'm',
  'min',
  'h',
  'km/h',
  'R.S',
  'RS',
  'SR',
  'HTTP',
  'HTTPS',
  'SHA-1',
  'JWT',
  'ETA',
  'UI',
  'UX',
  'Documents',
  'Document',
  'Destination',
  'Distance',
  'Actions',
  'Action',
  'Transaction',
  'Transactions',
  'Affiliation',
  'Status',
  'Online',
  'Offline',
  'Cancel',
  'Confirm',
  'Error',
  'Info',
  'Complete',
  'Pending',
  'Total',
  'Email',
  'Chat',
  'Total:',
  'Mada / Visa / Mastercard',
  'Zion 1',
  'check.io',
  'Contact',
  'Restaurant',
  'Restaurants',
  '-destinations',
  '23 minutes',
  '25 minutes',
};

final _nonProse = RegExp(r'^[\d\s\-+.,:/#@$%•|A-Z]+$');
final _demoFixture = RegExp(
  r'(\\\$|\*\*\*\*|\(\d{3}\)|Street|Avenue|Viewpoint|Zion \d|check\.io|'
  r'Rodriguez|Mcmullens|Ragina Smith|Raku Davis|Raney Bold|Ra Kuo|Andrew D\.|'
  r'Michael Chen|Emily Rodriguez|Mada / Visa)',
);
final _email = RegExp(r'@');
final _unitTemplate = RegExp(
  r'^(\{km\} km|\{min\} min|\{m\} m|ETA ~ \{min\} min|'
  r'\{hours\} h \{minutes\} min|Ticket #\{id\}|\{count\} minutes)$',
);
final _placeholder = RegExp(r'\{([a-zA-Z0-9_]+)\}');

Map<String, String> loadLang(String lang) {
  final file = File('assets/langs/$lang.json');
  expect(file.existsSync(), isTrue, reason: 'missing $lang.json');
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (e.value is String) e.key: e.value as String,
  };
}

bool isIntentionalSameAsEn(String value) {
  final v = value.trim();
  if (v.isEmpty) return true;
  if (intentionalExactValues.contains(v) ||
      intentionalExactValues.contains(value)) {
    return true;
  }
  if (_email.hasMatch(v)) return true;
  if (_demoFixture.hasMatch(v)) return true;
  if (!RegExp(r'[A-Za-z]').hasMatch(v)) return true;
  if (_unitTemplate.hasMatch(v)) return true;
  if (v.length <= 2 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(v)) return true;
  if (_nonProse.hasMatch(v)) return true;
  if (v.contains('••••')) return true;
  return false;
}

List<String> realUntranslatedKeys(
  Map<String, String> en,
  Map<String, String> loc,
) {
  final out = <String>[];
  for (final e in loc.entries) {
    final ev = en[e.key];
    if (ev == null) continue;
    if (e.value != ev) continue;
    if (isIntentionalSameAsEn(ev)) continue;
    out.add(e.key);
  }
  return out..sort();
}

List<String> intentionalSameAsEnKeys(
  Map<String, String> en,
  Map<String, String> loc,
) {
  final out = <String>[];
  for (final e in loc.entries) {
    final ev = en[e.key];
    if (ev == null) continue;
    if (e.value != ev) continue;
    if (isIntentionalSameAsEn(ev)) out.add(e.key);
  }
  return out..sort();
}

void main() {
  const locales = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];
  const targetLocales = ['pt', 'fr', 'ur'];

  group('Driver same_as_en quality', () {
    late Map<String, Map<String, String>> maps;
    setUpAll(() {
      maps = {for (final l in locales) l: loadLang(l)};
    });

    test('pt/fr/ur report INTENTIONAL vs REAL_UNTRANSLATED', () {
      final en = maps['en']!;
      for (final l in targetLocales) {
        final intentional = intentionalSameAsEnKeys(en, maps[l]!);
        final real = realUntranslatedKeys(en, maps[l]!);
        // ignore: avoid_print
        print(
          'REPORT $l INTENTIONAL_SAME_AS_EN=${intentional.length} '
          'REAL_UNTRANSLATED=${real.length}',
        );
        expect(
          real,
          isEmpty,
          reason: 'REAL_UNTRANSLATED $l (${real.length}): '
              '${real.take(40).join(', ')}',
        );
      }
    });

    test('placeholders still match English for translated locales', () {
      final en = maps['en']!;
      for (final l in targetLocales) {
        final mism = <String>[];
        for (final e in en.entries) {
          final a =
              _placeholder.allMatches(e.value).map((m) => m.group(1)!).toSet();
          if (a.isEmpty) continue;
          final other = maps[l]![e.key];
          if (other == null) {
            mism.add(e.key);
            continue;
          }
          final b =
              _placeholder.allMatches(other).map((m) => m.group(1)!).toSet();
          if (a.length != b.length || !a.every(b.contains)) mism.add(e.key);
        }
        expect(mism, isEmpty, reason: 'interp $l: $mism');
      }
    });
  });
}

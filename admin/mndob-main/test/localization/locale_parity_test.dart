import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const locales = ['ar', 'en', 'ru', 'ky', 'fr', 'ur', 'pt'];
  final placeholder = RegExp(r'\{([a-zA-Z0-9_]+)\}');

  Map<String, String> loadLang(String lang) {
    final file = File('assets/langs/$lang.json');
    expect(file.existsSync(), isTrue, reason: 'missing $lang.json');
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final e in raw.entries)
        if (e.value is String) e.key: e.value as String,
    };
  }

  Set<String> placeholders(String value) =>
      placeholder.allMatches(value).map((m) => m.group(1)!).toSet();

  bool samePlaceholders(Set<String> a, Set<String> b) =>
      a.length == b.length && a.every(b.contains);

  group('Driver locale parity', () {
    late Map<String, Map<String, String>> maps;
    setUpAll(() {
      maps = {for (final l in locales) l: loadLang(l)};
    });

    test('all locales share the same key set', () {
      final en = maps['en']!.keys.toSet();
      for (final l in locales) {
        expect(maps[l]!.keys.toSet(), en, reason: 'key set mismatch for $l');
      }
    });

    test('no empty values', () {
      for (final l in locales) {
        final empty = maps[l]!
            .entries
            .where((e) => e.value.trim().isEmpty)
            .map((e) => e.key)
            .toList();
        expect(empty, isEmpty, reason: 'empty values in $l: $empty');
      }
    });

    test('interpolation placeholders match English when EN has placeholders',
        () {
      final en = maps['en']!;
      for (final l in locales) {
        if (l == 'en') continue;
        final mism = <String>[];
        for (final e in en.entries) {
          final a = placeholders(e.value);
          if (a.isEmpty) continue;
          final other = maps[l]![e.key];
          if (other == null) {
            mism.add(e.key);
            continue;
          }
          if (!samePlaceholders(a, placeholders(other))) mism.add(e.key);
        }
        expect(mism, isEmpty, reason: 'interp mismatch $l: $mism');
      }
    });

    test('critical return-to-pickup keys present', () {
      const required = [
        'return_to_customer_pickup_label',
        'return_to_pickup_yes',
        'return_to_pickup_no',
        'start_return_to_customer',
      ];
      for (final l in locales) {
        for (final k in required) {
          expect(maps[l]!.containsKey(k), isTrue, reason: '$l missing $k');
          expect(maps[l]![k]!.trim(), isNotEmpty);
        }
      }
    });
  });
}

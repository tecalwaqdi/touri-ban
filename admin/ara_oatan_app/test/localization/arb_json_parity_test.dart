import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  // When running via `flutter test`, CWD is package root.
  final en = _load('$root/assets/langs/en.json');
  final ar = _load('$root/assets/langs/ar.json');
  final ru = _load('$root/assets/langs/ru.json');
  final ky = _load('$root/assets/langs/ky.json');

  test('all production JSON files share the same keys', () {
    expect(ar.keys.toSet(), en.keys.toSet());
    expect(ru.keys.toSet(), en.keys.toSet());
    expect(ky.keys.toSet(), en.keys.toSet());
  });

  test('no empty values in production locales', () {
    for (final entry in {
      'en': en,
      'ar': ar,
      'ru': ru,
      'ky': ky,
    }.entries) {
      final empties = entry.value.entries
          .where((e) => e.value.toString().trim().isEmpty)
          .map((e) => e.key)
          .toList();
      expect(empties, isEmpty, reason: '${entry.key} empty keys: $empties');
    }
  });

  test('no Unicode replacement characters', () {
    for (final map in [en, ar, ru, ky]) {
      for (final value in map.values) {
        expect(value.toString().contains('\uFFFD'), isFalse);
      }
    }
  });

  test('glossary status keys exist in all locales', () {
    const keys = [
      'status_pending_driver',
      'status_driver_assigned',
      'status_cancelled',
      'status_paid',
      'kyrgyz_char_sample',
      'current_location_label',
      'view_route_label',
    ];
    for (final key in keys) {
      expect(en.containsKey(key), isTrue);
      expect(ar.containsKey(key), isTrue);
      expect(ru.containsKey(key), isTrue);
      expect(ky.containsKey(key), isTrue);
    }
  });

  test('Kyrgyz sample includes special letters', () {
    final sample = ky['kyrgyz_char_sample']!.toString();
    for (final ch in ['ң', 'ө', 'ү', 'Ң', 'Ө', 'Ү']) {
      expect(sample.contains(ch), isTrue, reason: 'missing $ch');
    }
  });
}

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

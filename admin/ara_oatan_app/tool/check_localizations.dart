// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Verifies ARB/JSON localization completeness for ar/en/ru/ky.
void main(List<String> args) {
  final root = Directory.current.path;
  final arbDir = Directory('$root/lib/l10n');
  final langsDir = Directory('$root/assets/langs');
  final errors = <String>[];

  const locales = ['en', 'ar', 'ru', 'ky'];
  final arbs = <String, Map<String, dynamic>>{};
  for (final locale in locales) {
    final file = File('${arbDir.path}/app_$locale.arb');
    if (!file.existsSync()) {
      errors.add('Missing ARB: app_$locale.arb');
      continue;
    }
    arbs[locale] = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  final enKeys = arbs['en']?.keys
          .where((k) => !k.startsWith('@'))
          .where((k) => k != '@@locale')
          .toSet() ??
      {};

  for (final locale in locales) {
    final map = arbs[locale];
    if (map == null) continue;
    final keys = map.keys
        .where((k) => !k.startsWith('@'))
        .where((k) => k != '@@locale')
        .toSet();
    final missing = enKeys.difference(keys);
    final empty = <String>[];
    for (final k in enKeys) {
      final v = map[k];
      if (v == null || (v is String && v.trim().isEmpty)) {
        empty.add(k);
      }
      if (v is String && v.contains('\uFFFD')) {
        errors.add('Replacement char in $locale:$k');
      }
    }
    if (missing.isNotEmpty) {
      errors.add('$locale missing ${missing.length} keys (e.g. ${missing.take(5).join(", ")})');
    }
    if (empty.isNotEmpty) {
      errors.add('$locale empty ${empty.length} keys');
    }
  }

  for (final locale in locales) {
    final file = File('${langsDir.path}/$locale.json');
    if (!file.existsSync()) {
      errors.add('Missing JSON assets/langs/$locale.json');
    }
  }

  // Extra languages must not live in runtime langs folder.
  for (final entity in langsDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final name = entity.uri.pathSegments.last.replaceAll('.json', '');
    if (!locales.contains(name)) {
      errors.add('Non-production locale still in assets/langs: $name');
    }
  }

  if (errors.isEmpty) {
    print('check_localizations: OK (${enKeys.length} keys × ${locales.length} locales)');
    exit(0);
  }
  print('check_localizations: FAIL');
  for (final e in errors) {
    print(' - $e');
  }
  exit(1);
}

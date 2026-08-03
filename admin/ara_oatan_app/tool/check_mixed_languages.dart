// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final errors = <String>[];
  const locales = ['en', 'ar', 'ru', 'ky'];
  final data = <String, Map<String, dynamic>>{};
  for (final l in locales) {
    data[l] = jsonDecode(
      File('${Directory.current.path}/assets/langs/$l.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  }

  // French words that must not appear in production UI languages.
  final frenchMarkers = [
    'Bonjour',
    'Merci',
    'Réservation',
    "S'il vous plaît",
    'Changer la langue',
  ];
  for (final locale in locales) {
    for (final entry in data[locale]!.entries) {
      final v = entry.value.toString();
      for (final marker in frenchMarkers) {
        if (v.contains(marker)) {
          errors.add('French marker "$marker" in $locale:${entry.key}');
        }
      }
    }
  }

  // Arabic script inside Russian/Kyrgyz values (excluding brand-neutral).
  final arabicRe = RegExp(r'[\u0600-\u06FF]{3,}');
  for (final locale in ['ru', 'ky']) {
    for (final entry in data[locale]!.entries) {
      final v = entry.value.toString();
      if (arabicRe.hasMatch(v) && !v.contains('Touri')) {
        errors.add('Arabic script inside $locale:${entry.key}');
      }
    }
  }

  if (errors.isEmpty) {
    print('check_mixed_languages: OK');
    exit(0);
  }
  print('check_mixed_languages: FAIL (${errors.length})');
  for (final e in errors.take(50)) {
    print(' - $e');
  }
  exit(1);
}

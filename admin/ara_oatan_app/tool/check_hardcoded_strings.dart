// ignore_for_file: avoid_print
import 'dart:io';

/// Scans Dart UI files for likely user-visible hardcoded strings.
/// Fails when high-confidence hardcoded Text(...) literals are found.
void main(List<String> args) {
  final lib = Directory('${Directory.current.path}/lib');
  final allowExact = <String>{
    'Touri Taxi',
    'cairo',
    'Noto Sans',
    'Roboto',
    'Arial',
    'Product Sans',
  };
  final allowPrefixes = <String>[
    'assets/',
    'http',
    'packages/',
    'ui_text_',
    'ux_',
    'wallet_',
    'booking_',
    'checkout_',
    'notification_',
    'status_',
    'error_',
    'map_',
    'dialog_',
    'payment_',
    'custom_place_',
    'instant_',
    'app_',
  ];

  final textRe = RegExp(r"""Text\(\s*['\"]([^'\"]{3,})['\"]""");
  final findings = <String>[];

  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    if (file.path.contains('${Platform.pathSeparator}generated')) continue;
    final rel = file.path.replaceAll('\\', '/');
    // Skip schema/backend internals and flutter_flow util dumps somewhat.
    if (rel.contains('/backend/schema/')) continue;
    final src = file.readAsStringSync();
    for (final match in textRe.allMatches(src)) {
      final value = match.group(1)!;
      if (allowExact.contains(value)) continue;
      if (allowPrefixes.any(value.startsWith)) continue;
      if (value.contains('.tr(')) continue;
      final window = src.substring(
        (match.start - 40).clamp(0, src.length),
        (match.end + 30).clamp(0, src.length),
      );
      if (window.contains('.tr(') || window.contains('getText(')) continue;
      // Ignore pure technical identifiers.
      if (RegExp(r'^[a-z0-9_./-]+$').hasMatch(value) && !value.contains(' ')) {
        continue;
      }
      // High confidence: Arabic or multi-word English UI copy.
      final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(value);
      final isUiEnglish = RegExp(r'[A-Za-z]{3,}').hasMatch(value) &&
          (value.contains(' ') || value.endsWith('...') || value.endsWith('!'));
      if (isArabic || isUiEnglish) {
        findings.add('$rel :: $value');
      }
    }
  }

  if (findings.isEmpty) {
    print('check_hardcoded_strings: OK');
    exit(0);
  }

  // Soft-fail mode during migration: report count, fail only if --strict.
  final strict = args.contains('--strict');
  print('check_hardcoded_strings: found ${findings.length} candidates');
  for (final f in findings.take(80)) {
    print(' - $f');
  }
  if (findings.length > 80) {
    print(' - ... ${findings.length - 80} more');
  }
  exit(strict ? 1 : 0);
}

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final base = Directory('assets/langs');
  final codes = ['en', 'ar', 'ru', 'ky'];
  final maps = <String, Map<String, dynamic>>{};
  for (final c in codes) {
    final f = File('${base.path}/$c.json');
    if (!f.existsSync()) {
      stderr.writeln('MISSING ${f.path}');
      exit(1);
    }
    maps[c] = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }
  final all = <String>{};
  for (final m in maps.values) {
    all.addAll(m.keys.cast<String>());
  }
  var errors = 0;
  for (final c in codes) {
    final missing = all.difference(maps[c]!.keys.toSet());
    if (missing.isNotEmpty) {
      stderr.writeln('$c missing ${missing.length}: ${missing.take(10)}');
      errors++;
    }
    final empty = maps[c]!
        .entries
        .where((e) => (e.value?.toString() ?? '').trim().isEmpty)
        .map((e) => e.key)
        .toList();
    if (empty.isNotEmpty) {
      stderr.writeln('$c empty ${empty.length}: $empty');
      errors++;
    }
  }
  final ph = RegExp(r'\{[^}]+\}');
  for (final k in all) {
    final sets = <String, Set<String>>{};
    for (final c in codes) {
      final v = maps[c]![k]?.toString() ?? '';
      sets[c] = ph.allMatches(v).map((m) => m.group(0)!).toSet();
    }
    final first = sets['en']!;
    for (final c in codes.skip(1)) {
      if (sets[c]!.difference(first).isNotEmpty ||
          first.difference(sets[c]!).isNotEmpty) {
        stderr.writeln('placeholder mismatch $k: $sets');
        errors++;
        break;
      }
    }
  }
  if (errors > 0) {
    stderr.writeln('check_lang_parity: FAIL ($errors)');
    exit(1);
  }
  stdout.writeln('check_lang_parity: OK (${all.length} keys × 4)');
}

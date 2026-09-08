import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strict admin i18n gate — delegates to the Python validator so missing keys,
/// empty values, Arabic-in-EN, and uiTr lookup gaps fail CI.
void main() {
  test('admin translation validator passes', () async {
    final root = Directory.current.path;
    // Prefer project-local venv if present (created during i18n repair).
    final candidates = <String>[
      // worktree root when tests run from admin/Admi
      '$root/../../.venv-i18n/bin/python',
      '$root/.venv-i18n/bin/python',
      'python3',
    ];
    String? python;
    for (final c in candidates) {
      if (c == 'python3' || File(c).existsSync()) {
        python = c;
        break;
      }
    }
    expect(python, isNotNull);

    final script = File('$root/tool/i18n/validate_admin_translations.py');
    expect(script.existsSync(), isTrue,
        reason: 'validator script missing at ${script.path}');

    final result = await Process.run(
      python!,
      [script.path],
      workingDirectory: root,
    );
    if (result.exitCode != 0) {
      fail(
        'validate_admin_translations.py failed (exit ${result.exitCode})\n'
        'stdout:\n${result.stdout}\n'
        'stderr:\n${result.stderr}',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

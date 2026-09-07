import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdminFirestoreList does not reload on countQueryBuilder identity', () {
    final src = File(
      'lib/components/admin_firestore_list.dart',
    ).readAsStringSync();
    // Regression: comparing countQueryBuilder by identity forced full reload
    // whenever parent setState rebuilt the lambda → list flicker.
    expect(
      src.contains('oldWidget.countQueryBuilder != widget.countQueryBuilder'),
      isFalse,
    );
    expect(
      src.contains('widget.countQueryBuilder != oldWidget.countQueryBuilder'),
      isFalse,
    );
    expect(src.contains('adminFirestoreListShouldReset'), isTrue);
    expect(src.contains('_resetAndLoad()'), isTrue);
  });

  test('explicit refresh prefers soft path (keeps rows when loaded)', () {
    final src = File(
      'lib/components/admin_firestore_list.dart',
    ).readAsStringSync();
    // _resetAndReload must soft-refresh when items already present.
    expect(src.contains('_loading = _items.isEmpty'), isTrue);
    expect(src.contains('await _lightRefresh()'), isTrue);
  });

  test('Driver list initState does not empty setState before stats', () {
    final src = File(
      'lib/admin/admindrever/admindrever_widget.dart',
    ).readAsStringSync();
    // Empty safeSetState in postFrameCallback historically rebuilt lambdas.
    expect(
      RegExp(
        r'addPostFrameCallback\(\(_\)\s*\{\s*safeSetState\(\(\)\s*\{\s*\}\);',
      ).hasMatch(src),
      isFalse,
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdminFirestoreList does not reload on countQueryBuilder identity', () {
    final src =
        File('lib/components/admin_firestore_list.dart').readAsStringSync();
    // Regression: comparing countQueryBuilder by identity forced full reload
    // whenever parent setState rebuilt the lambda → list flicker.
    expect(
        src.contains('widget.countQueryBuilder != oldWidget.countQueryBuilder'),
        isFalse);
    expect(src.contains('_resetAndLoad()'), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:ara_oatan_app/core/toury_mkan_pagination.dart';

void main() {
  tearDown(() {
    TouryMkanPaginationHub.clearForTests();
  });

  test('hub exposes refreshFromServer for Admin→Customer sync', () {
    // Compile-time / API contract: soft refresh must exist so landmark lists
    // can pick up Admin writes without reinstall.
    final c = TouryMkanPaginationController();
    expect(c.refreshFromServer, isA<Function>());
    c.dispose();
  });
}

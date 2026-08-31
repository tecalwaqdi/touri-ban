import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admindrever/admin_driver_expiry_adapter.dart';
import 'package:admin_arawatan/core/admin_driver_profile_view.dart';

void main() {
  testWidgets('expiry document type labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox(key: Key('root')))),
    );
    final ctx = tester.element(find.byKey(const Key('root')));
    expect(
      AdminDriverExpiryRow.documentTypeLabel(ctx, 'national_id'),
      isNotEmpty,
    );
    expect(
      AdminDriverExpiryRow.documentTypeLabel(ctx, 'driver_license'),
      isNotEmpty,
    );
    expect(
      AdminDriverExpiryRow.documentTypeLabel(ctx, 'vehicle_registration'),
      isNotEmpty,
    );
  });

  test('parseDocExpiry handles DateTime', () {
    final d = DateTime(2026, 6, 1);
    expect(AdminDriverProfileView.parseDocExpiry(d), d);
  });

  test('parseDocExpiry null stays null', () {
    expect(AdminDriverProfileView.parseDocExpiry(null), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/components/admin_enterprise_kit.dart';
import 'package:admin_arawatan/components/admin_ui.dart';
import 'package:admin_arawatan/core/admin_design/admin_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ADMIN_UI_V2 design system', () {
    test('primary palette matches V2 tokens', () {
      expect(AdminColors.primary, const Color(0xFF1C736E));
      expect(AdminColors.appBackground, const Color(0xFFF5F7F9));
      expect(AdminColors.textPrimary, const Color(0xFF17202A));
      expect(AdminUi.brandTeal, AdminColors.primary);
      expect(AdminUi.radiusMd, AdminRadius.card);
      expect(AdminSpacing.tableRowHeight, 48);
      expect(AdminSpacing.inputHeight, 40);
      expect(AdminSpacing.sidebarWidthDesktop, 256);
    });

    test('typography uses Cairo', () {
      expect(AdminTypography.fontFamily, 'cairo');
    });

    testWidgets('AdminPageHeader and period segmented render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const AdminPageHeader(
                  title: 'المالية',
                  subtitle: 'اختبار',
                ),
                AdminPeriodSegmented<int>(
                  values: const [1, 2],
                  labels: const {1: 'اليوم', 2: 'أمس'},
                  selected: 1,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('المالية'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
    });
  });
}

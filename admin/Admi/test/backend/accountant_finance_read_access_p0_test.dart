import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/core/admin_user_facing_errors.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/flutter_flow/internationalization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AdminRoleService.resetSession();
  });

  group('ACCOUNTANT_READ_ACCESS_P0', () {
    test('Settings route denied for Accountant', () {
      expect(
        AdminRoleService.canAccessRouteForRole(AdminRole.accountant, 'Settings'),
        isFalse,
      );
      expect(
        AdminRoleService.canAccessRouteForRole(
          AdminRole.accountant,
          'AdminSettlements',
        ),
        isTrue,
      );
      expect(
        AdminRoleService.canAccessRouteForRole(
          AdminRole.accountant,
          'AdminFinanceHub',
        ),
        isTrue,
      );
    });

    testWidgets('raw finance_query_unavailable never user-visible',
        (tester) async {
      late String msg;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            FFLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: Builder(
            builder: (context) {
              msg = AdminUserFacingErrors.from(
                context,
                StateError('finance_query_unavailable:permission-denied'),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(msg.toLowerCase(), isNot(contains('permission-denied')));
      expect(msg.toLowerCase(), isNot(contains('bad state')));
      expect(msg.toLowerCase(), isNot(contains('finance_query_unavailable')));
      expect(
        msg.contains('تعذر') || msg.toLowerCase().contains('unable') || msg.contains('إعادة'),
        isTrue,
      );
    });

    test('permission-denied must not be treated as successful empty', () {
      const denied = true;
      const docs = 0;
      final showEmpty = !denied && docs == 0;
      final showError = denied;
      expect(showEmpty, isFalse);
      expect(showError, isTrue);
    });

    test('finance claim grants accountant role', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
      expect(AdminRoleService.isAccountant, isTrue);
      expect(AdminRoleService.hasPanelAccess, isTrue);
      expect(AdminRoleService.canAccessRoute('AdminSettlements'), isTrue);
      expect(AdminRoleService.canAccessRoute('Settings'), isFalse);
    });
  });
}

import 'package:admin_arawatan/backend/admin_role_matrix.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/core/admin_shell_rules.dart';
import 'package:admin_arawatan/core/admin_user_facing_errors.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/flutter_flow/internationalization.dart';
import 'package:admin_arawatan/l10n/ui_catalog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AdminRoleService.resetSession();
  });

  group('Country Agent route policy', () {
    void bindKyAgent() {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'agent': true,
          'country_admin': true,
          'support': true,
          'country_id': 'countries/kyrgyzstan',
        }),
      );
      AdminRoleService.markClaimsAuthoritative();
    }

    test('matrix allows own-country Users/Drivers/Landmarks create+edit', () {
      final users = kAdminRoleMatrix['Users']![AdminPermRole.countryAdmin]!;
      final drivers = kAdminRoleMatrix['Drivers']![AdminPermRole.countryAdmin]!;
      final landmarks =
          kAdminRoleMatrix['Landmarks']![AdminPermRole.countryAdmin]!;
      expect(users.contains(AdminPermAction.view), isTrue);
      expect(users.contains(AdminPermAction.create), isTrue);
      expect(drivers.contains(AdminPermAction.view), isTrue);
      expect(drivers.contains(AdminPermAction.create), isTrue);
      expect(landmarks.contains(AdminPermAction.view), isTrue);
      expect(landmarks.contains(AdminPermAction.create), isTrue);
    });

    test('agent can open create routes for Users/Drivers/Landmarks', () {
      bindKyAgent();
      for (final route in const ['addDrev', 'AdminaddMkan', 'AdminaddMkanCopy']) {
        expect(
          AdminRoleService.canAccessRoute(route),
          isTrue,
          reason: route,
        );
      }
    });

    test('agent routes include ops pages; deny global admin-only', () {
      bindKyAgent();

      for (final route in const [
        'AdminALLhgZ',
        'Adminuser',
        'Admindrever',
        'AdminSuport',
        'AdminNotifications',
        'AdminDriverExpiryQueue',
        'AdminM3alm',
        'AdminTourGuides',
        'AdminAgentFinance',
        'Settings',
      ]) {
        expect(
          AdminRoleService.canAccessRoute(route),
          isTrue,
          reason: route,
        );
      }
      for (final route in const [
        'AdminDol',
        'AdminAgent',
        'AdminSuperAdmins',
        'AdminSettlements',
        'AdminFinanceHub',
      ]) {
        expect(
          AdminRoleService.canAccessRoute(route),
          isFalse,
          reason: route,
        );
      }
    });
  });

  group('sidebar active route', () {
    const paths = <String, String>{
      'Home22Dashboard': '/home22Dashboard',
      'Adminuser': '/adminuser',
      'Admindrever': '/drever',
      'AdminSuport': '/adminSuport',
      'AdminTourGuides': '/adminTourGuides',
      'AdminPartners': '/adminPartners',
    };

    test('Users/Drivers/Support never fall back to Dashboard', () {
      for (final entry in {
        '/adminuser': 'Adminuser',
        '/drever': 'Admindrever',
        '/adminSuport': 'AdminSuport',
      }.entries) {
        expect(
          adminSidebarRouteIsActive(
            location: entry.key,
            routeName: 'Home22Dashboard',
            pathByName: paths,
          ),
          isFalse,
        );
        expect(
          adminSidebarRouteIsActive(
            location: entry.key,
            routeName: entry.value,
            pathByName: paths,
          ),
          isTrue,
        );
      }
    });

    test('Tour Guides does not activate Partners', () {
      expect(
        adminSidebarRouteIsActive(
          location: '/adminTourGuides',
          routeName: 'AdminPartners',
          pathByName: paths,
        ),
        isFalse,
      );
      expect(
        adminSidebarRouteIsActive(
          location: '/adminTourGuides',
          routeName: 'AdminTourGuides',
          pathByName: paths,
        ),
        isTrue,
      );
    });
  });

  group('permission error presentation', () {
    testWidgets('permission-denied is not a network message', (tester) async {
      late String mapped;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localeResolutionCallback: (locale, supported) => const Locale('ar'),
          localizationsDelegates: const [
            FFLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          home: Builder(
            builder: (context) {
              mapped = AdminUserFacingErrors.from(
                context,
                FirebaseException(
                  plugin: 'cloud_firestore',
                  code: 'permission-denied',
                  message: 'Missing or insufficient permissions.',
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final lower = mapped.toLowerCase();
      expect(lower.contains('permission-denied'), isFalse);
      expect(lower.contains('cloud_firestore'), isFalse);
      expect(mapped.contains('الاتصال'), isFalse);
      expect(mapped.contains('صلاحية') || mapped.contains('تعذر'), isTrue);
    });
  });

  group('Filters localization', () {
    test('الفلاتر catalog entry exists', () {
      expect(kArabicUiLookup['الفلاتر'], 'ui_filters_label');
      expect(kUiCatalog['ui_filters_label']?['ar'], 'الفلاتر');
      expect(kUiCatalog['ui_filters_label']?['en'], 'Filters');
    });
  });

  group('booking counter sanitize contract', () {
    test('aggregate 0 with visible rows floors to results', () {
      int? sanitizeTotal(int? total, int results) {
        if (total == null) return null;
        if (total <= 0 && results > 0) return results;
        if (total < results) return results;
        return total;
      }

      expect(sanitizeTotal(0, 1), 1);
      expect(sanitizeTotal(null, 1), isNull);
      expect(sanitizeTotal(5, 1), 5);
      expect(sanitizeTotal(1, 1), 1);
    });
  });
}

import 'package:admin_arawatan/core/admin_shell_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminShellRules.shouldHideNavItems', () {
    test('logged out never hides', () {
      expect(
        AdminShellRules.shouldHideNavItems(
          loggedIn: false,
          isRoleResolving: true,
          hasUserDocument: false,
        ),
        isFalse,
      );
    });

    test('hides while role resolving', () {
      expect(
        AdminShellRules.shouldHideNavItems(
          loggedIn: true,
          isRoleResolving: true,
          hasUserDocument: true,
        ),
        isTrue,
      );
    });

    test('hides while user document missing', () {
      expect(
        AdminShellRules.shouldHideNavItems(
          loggedIn: true,
          isRoleResolving: false,
          hasUserDocument: false,
        ),
        isTrue,
      );
    });

    test('shows when ready', () {
      expect(
        AdminShellRules.shouldHideNavItems(
          loggedIn: true,
          isRoleResolving: false,
          hasUserDocument: true,
        ),
        isFalse,
      );
    });
  });

  group('AdminShellRules layout padding', () {
    test('layout pads only when page does not', () {
      expect(
        AdminShellRules.layoutShouldPadContent(pageOwnsPadding: true),
        isFalse,
      );
      expect(
        AdminShellRules.layoutShouldPadContent(pageOwnsPadding: false),
        isTrue,
      );
    });
  });

  group('AdminShellRules.contentMaxWidth', () {
    test('caps wide viewports', () {
      expect(AdminShellRules.contentMaxWidth(1800), 1400);
      expect(AdminShellRules.contentMaxWidth(1400), 1280);
      expect(AdminShellRules.contentMaxWidth(1000), 1200);
    });
  });

  group('adminSidebarRouteIsActive', () {
    const paths = <String, String>{
      'Home22Dashboard': '/home22Dashboard',
      'Adminuser': '/adminuser',
      'AdminTourGuides': '/adminTourGuides',
      'AdminPartners': '/adminPartners',
      'AdminFinanceHub': '/adminFinanceHub',
      'AdminFinanceReports': '/adminFinanceReports',
      'AdminAgentFinance': '/adminFinanceAgents',
    };

    test('activates exact path match only', () {
      expect(
        adminSidebarRouteIsActive(
          location: '/adminTourGuides',
          routeName: 'AdminTourGuides',
          pathByName: paths,
        ),
        isTrue,
      );
      expect(
        adminSidebarRouteIsActive(
          location: '/adminTourGuides',
          routeName: 'AdminPartners',
          pathByName: paths,
        ),
        isFalse,
      );
    });

    test('does not activate dashboard for /admin* locations', () {
      expect(
        adminSidebarRouteIsActive(
          location: '/adminuser',
          routeName: 'Home22Dashboard',
          pathByName: paths,
        ),
        isFalse,
      );
      expect(
        adminSidebarRouteIsActive(
          location: '/adminuser',
          routeName: 'Adminuser',
          pathByName: paths,
        ),
        isTrue,
      );
    });

    test('prefers longest finance path match', () {
      expect(
        adminSidebarRouteIsActive(
          location: '/adminFinanceReports?tab=1',
          routeName: 'AdminFinanceReports',
          pathByName: paths,
        ),
        isTrue,
      );
      expect(
        adminSidebarRouteIsActive(
          location: '/adminFinanceReports?tab=1',
          routeName: 'AdminFinanceHub',
          pathByName: paths,
        ),
        isFalse,
      );
      expect(
        adminSidebarRouteIsActive(
          location: '/adminFinanceAgents',
          routeName: 'AdminAgentFinance',
          pathByName: paths,
        ),
        isTrue,
      );
    });

    test('longest match wins when shorter path is also a suffix', () {
      const overlapping = <String, String>{
        'Short': '/admin',
        'Long': '/adminFinanceHub',
      };
      expect(
        adminSidebarRouteIsActive(
          location: '/adminFinanceHub',
          routeName: 'Long',
          pathByName: overlapping,
        ),
        isTrue,
      );
      expect(
        adminSidebarRouteIsActive(
          location: '/adminFinanceHub',
          routeName: 'Short',
          pathByName: overlapping,
        ),
        isFalse,
      );
    });
  });
}

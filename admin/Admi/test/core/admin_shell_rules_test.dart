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
}

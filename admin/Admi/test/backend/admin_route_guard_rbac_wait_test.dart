import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_rbac_phase.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/home22_dashboard/home22_dashboard_widget.dart';
import 'package:admin_arawatan/backend/admin_route_guard.dart';

void main() {
  setUp(() {
    AdminRoleService.resetSession();
  });

  test('country agent cannot open settlement details once claims authoritative',
      () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({
        'country_admin': true,
        'country_id': 'countries/saudi_arabia',
      }),
    );
    AdminRoleService.markClaimsAuthoritative();
    expect(AdminRoleService.rbacPhase, AdminRbacPhase.authoritative);
    expect(AdminRoleService.currentRole, AdminRole.countryAgent);
    expect(AdminRoleService.canAccessRoute('AdminSettlementDetails'), isFalse);
    expect(AdminRoleService.canAccessRoute('AdminAgentFinance'), isTrue);
    expect(homePathForCurrentUser(), Home22DashboardWidget.routePath);
  });

  test('super admin can open settlement details when claims authoritative', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({'super_admin': true}),
    );
    AdminRoleService.markClaimsAuthoritative();
    expect(AdminRoleService.canAccessRoute('AdminSettlementDetails'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminAgentFinance'), isTrue);
  });

  test('rbacPhase stays non-authoritative until markClaimsAuthoritative', () {
    AdminRoleService.bindClaims(AuthClaims.fromToken(null));
    expect(AdminRoleService.rbacPhase, isNot(AdminRbacPhase.authoritative));
  });
}

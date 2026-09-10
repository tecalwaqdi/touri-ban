import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/home22_dashboard/dashboard_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AdminRoleService.resetSession);

  test('Phase 5 dashboard omits Profits quick action', () {
    expect(
      DashboardPresentation.quickActionRouteOrder.contains('AdminProfits'),
      isFalse,
    );
    expect(
      DashboardPresentation.quickActionRouteOrder.contains('AdminFinanceHub'),
      isTrue,
    );
  });

  test('Accountant: finance workspace read, no writes, no wallets', () {
    AdminRoleService.bindClaims(AuthClaims.fromToken({'finance': true}));
    expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminFinanceReconciliation'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminSettlements'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminFinanceReceivables'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminFinancialPeriods'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminDriverWallets'), isFalse);
    expect(AdminRoleService.canWriteSettlements, isFalse);
  });

  test('Country Agent: Agent Finance only among finance homes', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({
        'agent': true,
        'country_admin': true,
        'country_id': 'countries/spain',
      }),
    );
    expect(AdminRoleService.canAccessRoute('AdminAgentFinance'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isFalse);
    expect(AdminRoleService.canAccessRoute('AdminFinanceChannels'), isFalse);
    expect(AdminRoleService.canAccessRoute('AdminDriverWallets'), isFalse);
    expect(AdminRoleService.canWriteSettlements, isFalse);
  });

  test('Super Admin: full finance + legacy wallets', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({'super_admin': true}),
    );
    expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminDriverWallets'), isTrue);
    expect(AdminRoleService.canWriteSettlements, isTrue);
  });
}

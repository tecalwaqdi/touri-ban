import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AdminRoleService.resetSession();
  });

  group('Agent / country agent finance route RBAC', () {
    void bindAgent() {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'agent': true,
          'country_admin': true,
          'country_id': 'countries/spain',
        }),
      );
    }

    test('allows own Agent Finance surface', () {
      bindAgent();
      expect(AdminRoleService.isCountryAgent, isTrue);
      expect(AdminRoleService.isAgentAccount, isTrue);
      expect(AdminRoleService.canAccessRoute('AdminAgentFinance'), isTrue);
      expect(AdminRoleService.canAccessRoute('Home22Dashboard'), isTrue);
      expect(AdminRoleService.canAccessRoute('Settings'), isTrue);
    });

    test('denies global finance administration routes', () {
      bindAgent();
      for (final route in [
        'AdminFinanceHub',
        'AdminProfits',
        'AdminFinanceChannels',
        'AdminFinanceReceivables',
        'AdminSettlements',
        'AdminSettlementDetails',
        'AdminSettlementReceipt',
        'AdminReconciliation',
        'AdminFinancialPeriods',
        'AdminFinanceReports',
        'AdminFinanceAudit',
        'AdminDiagnostics',
        'AdminDriverWallets',
      ]) {
        expect(
          AdminRoleService.canAccessRoute(route),
          isFalse,
          reason: '$route must be denied for agent',
        );
      }
    });

    test('agent with finance claim still cannot open global finance admin', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'agent': true,
          'finance': true,
          'country_id': 'countries/spain',
        }),
      );
      expect(AdminRoleService.isFinanceStaff, isFalse);
      expect(AdminRoleService.canAccessRoute('AdminSettlements'), isFalse);
      expect(AdminRoleService.canAccessRoute('AdminFinanceAudit'), isFalse);
      expect(AdminRoleService.canAccessRoute('AdminAgentFinance'), isTrue);
      expect(AdminRoleService.canWriteSettlements, isFalse);
    });
  });

  group('Finance staff + Super Admin regression', () {
    test('pure finance retains global finance routes', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
      expect(AdminRoleService.isFinanceStaff, isTrue);
      expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminSettlements'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminFinanceAudit'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminFinancialPeriods'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminAgentFinance'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminReconciliation'), isTrue);
      expect(AdminRoleService.canAccessRoute('Home22Dashboard'), isFalse);
      expect(AdminRoleService.canWriteSettlements, isTrue);
    });

    test('super admin retains all finance routes', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'super_admin': true,
          'finance': true,
          'agent': true,
        }),
      );
      expect(AdminRoleService.isSuperAdmin, isTrue);
      expect(AdminRoleService.isCountryAgent, isFalse);
      expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminAgentFinance'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminSettlements'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminFinanceAudit'), isTrue);
      expect(AdminRoleService.canAccessRoute('AdminFinancialPeriods'), isTrue);
      expect(AdminRoleService.canWriteSettlements, isTrue);
    });
  });
}

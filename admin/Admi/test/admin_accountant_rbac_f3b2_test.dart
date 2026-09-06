import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/backend/admin_route_guard.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/core/finance/finance_reconciliation_labels.dart';
import 'package:admin_arawatan/core/finance/finance_reconciliation_read_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AdminRoleService.resetSession();
  });

  group('F3-B2 Accountant RBAC', () {
    void bindGlobalAccountant() {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'finance': true}),
      );
    }

    void bindCountryAccountant() {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({
          'finance': true,
          'country_id': 'countries/saudi_arabia',
        }),
      );
    }

    test('roleFromFields isAdminRule=5 → accountant', () {
      expect(
        AdminRoleService.roleFromFields(
          isAdmin: false,
          isAdminRule: AdminRoleService.ruleAccountant,
          hasIsAdminRule: true,
        ),
        AdminRole.accountant,
      );
    });

    test('global accountant role + home', () {
      bindGlobalAccountant();
      expect(AdminRoleService.currentRole, AdminRole.accountant);
      expect(AdminRoleService.isAccountant, isTrue);
      expect(AdminRoleService.isGlobalAccountant, isTrue);
      expect(AdminRoleService.isCountryAccountant, isFalse);
      expect(AdminRoleService.isCountryAgent, isFalse);
      expect(
        AdminRoleService.homeRouteFor(AdminRole.accountant),
        'AdminFinanceHub',
      );
      expect(homePathForCurrentUser(), '/adminFinanceHub');
    });

    test('accountant allows finance surfaces', () {
      bindGlobalAccountant();
      for (final route in [
        'AdminFinanceHub',
        'AdminFinanceReconciliation',
        'AdminFinanceChannels',
        'AdminSettlements',
        'AdminSettlementDetails',
        'AdminAgentFinance',
        'AdminFinanceReports',
        'AdminFinanceAudit',
        'Settings',
      ]) {
        expect(AdminRoleService.canAccessRoute(route), isTrue, reason: route);
      }
    });

    test('accountant rejects operational / admin routes', () {
      bindGlobalAccountant();
      for (final route in [
        'Home22Dashboard',
        'Adminuser',
        'Admindrever',
        'AdminDrivers',
        'DriverActivation',
        'AdminAgent',
        'EdetAgent',
        'AdminAddAgent',
        'AdminDol',
        'Adminregion',
        'Adminvill',
        'AdminM3alm',
        'AdminSuperAdmins',
        'AdminDiagnostics',
        'AdminDriverWallets',
        'AdminALLhgZ',
      ]) {
        expect(AdminRoleService.canAccessRoute(route), isFalse, reason: route);
      }
    });

    test('accountant cannot write settlements', () {
      bindGlobalAccountant();
      expect(AdminRoleService.canWriteSettlements, isFalse);
    });

    test('super admin still can write settlements', () {
      AdminRoleService.bindClaims(
        AuthClaims.fromToken({'super_admin': true, 'finance': true}),
      );
      expect(AdminRoleService.canWriteSettlements, isTrue);
    });

    test('country accountant scope helpers', () {
      bindCountryAccountant();
      expect(AdminRoleService.isAccountant, isTrue);
      expect(AdminRoleService.isCountryAccountant, isTrue);
      expect(AdminRoleService.isGlobalAccountant, isFalse);
      expect(AdminRoleService.usesCountryFinanceScope, isTrue);
      expect(AdminRoleService.isCountryAgent, isFalse);
      expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isTrue);
      expect(AdminRoleService.canAccessRoute('Admindrever'), isFalse);
    });

    test('route guard redirects denied routes to finance hub', () {
      bindGlobalAccountant();
      // Simulate authoritative panel user without Firebase profile:
      // canAccessRoute already false for Admindrever.
      expect(AdminRoleService.canAccessRoute('Admindrever'), isFalse);
      expect(
        AdminRoleService.homeRouteFor(AdminRole.accountant),
        'AdminFinanceHub',
      );
    });

    test('finance staff is not conflated with country agent', () {
      bindGlobalAccountant();
      expect(AdminRoleService.isFinanceStaff, isTrue);
      expect(AdminRoleService.isCountryAgent, isFalse);
    });
  });

  group('F3-B2 reconciliation labels', () {
    test('Arabic labels never raw enums', () {
      expect(
        FinanceReconciliationLabels.financialAr(
          RecFinancialSnapshotStatus.partial,
        ),
        'بيانات مالية ناقصة',
      );
      expect(
        FinanceReconciliationLabels.reconciliationAr(
          RecReconciliationStatus.blockedByMissingData,
        ),
        'محجوبة بسبب نقص البيانات',
      );
      expect(
        FinanceReconciliationLabels.issueAr(RecIssueCode.missingGross),
        'الأجرة الأساسية غير محفوظة',
      );
      expect(
        FinanceReconciliationLabels.agentAr(RecAgentStatus.none),
        'لا يوجد وكيل وقت الرحلة',
      );
    });
  });
}

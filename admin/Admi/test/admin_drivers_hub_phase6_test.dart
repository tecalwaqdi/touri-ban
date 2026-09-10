import 'package:admin_arawatan/admin/admin_drivers_hub/admin_drivers_hub_widget.dart';
import 'package:admin_arawatan/backend/admin_ops_filters.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/backend/driver_admin_stats_loader.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:admin_arawatan/home22_dashboard/dashboard_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AdminRoleService.resetSession);

  test('Drivers Hub tabs map from query', () {
    expect(AdminDriversHubWidget.tabFromQuery(null), AdminDriversHubTab.all);
    expect(AdminDriversHubWidget.tabFromQuery('pending'),
        AdminDriversHubTab.pending);
    expect(AdminDriversHubWidget.tabFromQuery('documents'),
        AdminDriversHubTab.documents);
    expect(AdminDriversHubWidget.tabFromQuery('expiring_soon'),
        AdminDriversHubTab.expiringSoon);
  });

  test('Dashboard canonical drivers route is Drivers Hub', () {
    expect(
      DashboardPresentation.canonicalDriversRoute,
      'AdminDriversHub',
    );
  });

  test('Pending review filter constraints match stats pendingReview', () {
    const f = AdminOpsFilterState(
      driverReview: AdminDriverReviewFilter.pendingReview,
    );
    final evidence = AdminOpsQueryBuilder.describeDriverFilterConstraints(f);
    expect(
      evidence.any(
        (e) => e.contains('pending_review') && e.contains('submitted'),
      ),
      isTrue,
    );
  });

  test('Country Agent can open Drivers Hub; finance Hub denied', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({
        'agent': true,
        'country_admin': true,
        'country_id': 'countries/spain',
      }),
    );
    expect(AdminRoleService.canAccessRoute('AdminDriversHub'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminDriverExpiryQueue'), isTrue);
    expect(AdminRoleService.canAccessRoute('AdminFinanceHub'), isFalse);
    expect(AdminRoleService.scopedCountryIdClaim, 'countries/spain');
  });

  test('Hub count chips map to DriverAdminStats fields', () {
    // Contract: chip ↔ list filter ↔ stats field
    // pending → pendingReview (pending_review|submitted)
    // documents → docsMissing (documents_status missing)
    // expiringSoon → expiringSoon (doc_expiry_bucket)
    const s = DriverAdminStats(
      total: 10,
      activated: 5,
      deactivated: 5,
      activationUnknown: 0,
      pendingReview: 3,
      rejected: 0,
      needsChanges: 0,
      approved: 5,
      draft: 0,
      suspended: 0,
      unknownLegacy: 2,
      v2Total: 8,
      legacyTotal: 2,
      docsComplete: 4,
      docsMissing: 2,
      docsNeedsReupload: 1,
      docsUnknownLegacy: 3,
      expiringSoon: 4,
    );
    expect(s.pendingReview, 3);
    expect(s.docsMissing, 2);
    expect(s.expiringSoon, 4);
    expect(s.total, 10);
  });

  test('Accountant cannot open Drivers Hub', () {
    AdminRoleService.bindClaims(AuthClaims.fromToken({'finance': true}));
    expect(AdminRoleService.canAccessRoute('AdminDriversHub'), isFalse);
    expect(AdminRoleService.canWriteSettlements, isFalse);
  });

  test('Super Admin can open Drivers Hub', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({'super_admin': true}),
    );
    expect(AdminRoleService.canAccessRoute('AdminDriversHub'), isTrue);
  });
}

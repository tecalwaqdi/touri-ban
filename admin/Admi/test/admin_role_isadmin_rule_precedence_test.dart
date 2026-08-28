import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';

void main() {
  setUp(() {
    AdminRoleService.bindClaims(AuthClaims.fromToken(null));
    AdminRoleService.bindProfile(null);
  });

  test('isAdminRule=2 wins over legacy IsAdmin=true (country agent)', () {
    expect(
      AdminRoleService.roleFromFields(
        isAdmin: true,
        isAdminRule: 2,
        hasIsAdminRule: true,
      ),
      AdminRole.countryAgent,
    );
  });

  test('isAdminRule=1 is super admin', () {
    expect(
      AdminRoleService.roleFromFields(
        isAdmin: true,
        isAdminRule: 1,
        hasIsAdminRule: true,
      ),
      AdminRole.superAdmin,
    );
  });

  test('legacy IsAdmin=true without rule remains super admin', () {
    expect(
      AdminRoleService.roleFromFields(
        isAdmin: true,
        isAdminRule: 0,
        hasIsAdminRule: false,
      ),
      AdminRole.superAdmin,
    );
  });

  test('partner rule is not overridden by IsAdmin', () {
    expect(
      AdminRoleService.roleFromFields(
        isAdmin: true,
        isAdminRule: 3,
        hasIsAdminRule: true,
      ),
      AdminRole.partner,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';

void main() {
  setUp(() {
    AdminRoleService.bindClaims(AuthClaims.fromToken(null));
    AdminRoleService.bindProfile(null);
  });

  test('super_admin claim suppresses isCountryAgent even with country_admin', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({
        'super_admin': true,
        'country_admin': true,
        'agent': true,
        'country_id': 'countries/demo_saudi',
      }),
    );
    expect(AdminRoleService.isSuperAdmin, isTrue);
    expect(AdminRoleService.isCountryAgent, isFalse);
    expect(AdminRoleService.scopedCountryRef, isNull);
  });

  test('country_admin without super_admin remains scoped agent', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({
        'country_admin': true,
        'country_id': 'countries/demo_saudi',
      }),
    );
    expect(AdminRoleService.isSuperAdmin, isFalse);
    expect(AdminRoleService.isCountryAgent, isTrue);
  });
}

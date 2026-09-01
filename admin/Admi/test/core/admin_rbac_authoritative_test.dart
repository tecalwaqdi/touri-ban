import 'package:admin_arawatan/backend/admin_rbac_phase.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/backend/schema/user_record.dart';
import 'package:admin_arawatan/core/auth/auth_claims.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

UserRecord _profileSuperAdmin() {
  return UserRecord.getDocumentFromData(
    {
      'IsAdmin': true,
      'isAdminRule': AdminRoleService.ruleSuperAdmin,
      'email': 'stale@example.com',
    },
    FirebaseFirestore.instance.collection('user').doc('u1'),
  );
}

void main() {
  setUpAll(_initFirebase);

  setUp(() {
    AdminRoleService.resetSession();
  });

  test('bootstrap: profile grants access before claims sync', () {
    AdminRoleService.bindProfile(_profileSuperAdmin());
    expect(AdminRoleService.hasPanelAccess, isTrue);
    expect(AdminRoleService.rbacPhase, AdminRbacPhase.bootstrap);
  });

  test('authoritative: revoked claims deny despite stale profile', () {
    AdminRoleService.bindProfile(_profileSuperAdmin());
    AdminRoleService.bindClaims(AuthClaims.fromToken({}));
    AdminRoleService.markClaimsAuthoritative();
    expect(AdminRoleService.hasPanelAccess, isFalse);
    expect(AdminRoleService.currentRole, AdminRole.none);
  });

  test('authoritative: claims grant access without profile role', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({'super_admin': true}),
    );
    expect(AdminRoleService.hasPanelAccess, isTrue);
    expect(AdminRoleService.isSuperAdmin, isTrue);
  });

  test('country agent scope uses claims country when authoritative', () {
    AdminRoleService.bindClaims(
      AuthClaims.fromToken({
        'country_admin': true,
        'country_id': 'countries/saudi_arabia',
      }),
    );
    AdminRoleService.markClaimsAuthoritative();
    expect(AdminRoleService.isCountryAgent, isTrue);
    expect(AdminRoleService.scopedCountryRef?.path, 'countries/saudi_arabia');
  });
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/auth/firebase_auth/auth_util.dart';
import 'package:admin_arawatan/backend/admin_production_landmark_seed.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/backend/backend.dart';
import 'package:admin_arawatan/flutter_flow/flutter_flow_util.dart';

Future<void> _initFirebaseForTest() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY',
      authDomain: 'tutorial-multi-language-70gx4j.firebaseapp.com',
      projectId: 'tutorial-multi-language-70gx4j',
      storageBucket: 'tutorial-multi-language-70gx4j.firebasestorage.app',
      messagingSenderId: '638010533068',
      appId: '1:638010533068:web:cd138c3c2424cbef844e69',
    ),
  );
}

/// Automated production seed — run:
///   flutter test test/seed_production_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed production landmarks to Firestore', () async {
    await _initFirebaseForTest();

    const email = 'demo.super@arawatan.sa';
    const password = 'Demo@2026';

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        final cred =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final uid = cred.user?.uid;
        if (uid != null) {
          await UserRecord.collection.doc(uid).set(
                createUserRecordData(
                  email: email,
                  displayName: 'سوبر أدمن التعبئة',
                  uid: uid,
                  actevUser: true,
                  createdTime: getCurrentTimestamp,
                  isAdmin: true,
                  isAdminRule: AdminRoleService.ruleSuperAdmin,
                ),
                SetOptions(merge: true),
              );
        }
      } else {
        fail('Auth failed: ${e.code}');
      }
    }

    await ensureCurrentUserDocument();
    final result = await AdminProductionLandmarkSeed.runAuthenticated();

    expect(result.success, true, reason: result.error ?? 'unknown');
    expect(result.landmarks, greaterThanOrEqualTo(50));
    expect(result.orders, greaterThanOrEqualTo(90));

    await FirebaseAuth.instance.signOut();
  }, timeout: const Timeout(Duration(minutes: 15)));
}

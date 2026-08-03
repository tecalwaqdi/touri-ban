import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:admin_arawatan/auth/firebase_auth/auth_util.dart';
import 'package:admin_arawatan/backend/admin_production_landmark_seed.dart';
import 'package:admin_arawatan/backend/admin_role_service.dart';
import 'package:admin_arawatan/backend/backend.dart';
import 'package:admin_arawatan/backend/firebase/firebase_config.dart';
import 'package:admin_arawatan/flutter_flow/flutter_flow_util.dart';

/// One-shot CLI entry: signs in and seeds Firestore production data.
///
/// Run from project root:
///   flutter run -t tool/seed_production_main.dart -d RF8M73GXMYV --release
///
/// Optional env:
///   SEED_EMAIL, SEED_PASSWORD
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();

  const email = String.fromEnvironment(
    'SEED_EMAIL',
    defaultValue: 'demo.super@arawatan.sa',
  );
  const password = String.fromEnvironment(
    'SEED_PASSWORD',
    defaultValue: 'Demo@2026',
  );

  stdout.writeln('=== تعبئة بيانات الإنتاج ===');
  stdout.writeln('تسجيل الدخول: $email');

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
      stdout.writeln('إنشاء حساب سوبر أدمن مؤقت للتعبئة...');
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      stderr.writeln('فشل تسجيل الدخول: ${e.code} ${e.message}');
      exit(1);
    }
  }

  await ensureCurrentUserDocument();
  stdout.writeln('جاري كتابة البيانات إلى Firestore...');

  final result = await AdminProductionLandmarkSeed.runAuthenticated();

  if (!result.success) {
    stderr.writeln('فشل: ${result.error}');
    exit(1);
  }

  stdout.writeln('');
  stdout.writeln('تمت التعبئة بنجاح:');
  stdout.writeln('  معالم: ${result.landmarks}');
  stdout.writeln('  مناطق: ${result.regions}');
  stdout.writeln('  مدن: ${result.cities}');
  stdout.writeln('  حجوزات: ${result.orders}');
  stdout.writeln('  تذاكر دعم: ${result.supportTickets}');
  stdout.writeln('');

  await FirebaseAuth.instance.signOut();
  exit(0);
}

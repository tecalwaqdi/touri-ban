import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '/core/cloud_functions/cloud_functions_client.dart';

/// Creates panel users via Cloud Functions when available; otherwise a
/// secondary Auth app + admin Firestore write (no-Billing / no CF mode).
class AdminUserCreation {
  AdminUserCreation._();

  static const _secondaryAppName = 'AdminUserProvision';

  /// When true (default), fall back to client Auth+Firestore if CF is missing.
  static const bool allowClientFallback = bool.fromEnvironment(
    'TOURY_ADMIN_USER_CREATE_FALLBACK',
    defaultValue: true,
  );

  static String authErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'not-found':
        case 'NOT_FOUND':
          return 'خدمة إنشاء الحساب غير متاحة حالياً. تحقق من نشر دوال Firebase في منطقة us-central1.';
        case 'already-exists':
          return 'البريد الإلكتروني مستخدم مسبقاً. استخدم بريداً آخر أو عدّل الوكيل الحالي.';
        case 'invalid-argument':
          return 'البريد الإلكتروني أو كلمة المرور غير صالحة.';
        case 'permission-denied':
          return 'ليس لديك صلاحية إنشاء هذا النوع من الحسابات.';
        case 'unauthenticated':
          return 'يجب تسجيل الدخول أولاً.';
        default:
          return 'تعذر إنشاء الحساب: ${error.message ?? error.code}';
      }
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم مسبقاً.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة. يجب أن تكون 6 أحرف على الأقل.';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح.';
        default:
          return 'تعذر إنشاء الحساب: ${error.message ?? error.code}';
      }
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'ليس لديك صلاحية كتابة ملف المستخدم في Firestore.';
      }
      return 'تعذر إنشاء الحساب: ${error.message ?? error.code}';
    }
    return error.toString();
  }

  static bool _isCfUnavailable(Object error) {
    if (error is FirebaseFunctionsException) {
      final code = error.code.toLowerCase();
      final msg = '${error.message ?? ''}'.toLowerCase();
      return code == 'not-found' ||
          code == 'unavailable' ||
          code == 'unimplemented' ||
          msg.contains('not found') ||
          msg.contains('not been deployed') ||
          msg.contains('billing');
    }
    return false;
  }

  static Future<String> createEmailUser({
    required String email,
    required String password,
    Map<String, dynamic> userData = const {},
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || password.length < 6) {
      throw Exception(authErrorMessage(
        FirebaseFunctionsException(
          code: 'invalid-argument',
          message: 'Invalid email/password.',
        ),
      ));
    }

    try {
      final result = await CloudFunctionsClient.createPanelUser(
        email: trimmed,
        password: password,
        userData: userData,
      );
      final uid = result['uid'] as String?;
      if (uid == null || uid.isEmpty) {
        throw Exception('تعذر إنشاء الحساب.');
      }
      return uid;
    } catch (e) {
      if (allowClientFallback && _isCfUnavailable(e)) {
        debugPrint(
          'createPanelUser unavailable ($e) — using secondary Auth fallback.',
        );
        try {
          return await _createViaSecondaryAuth(
            email: trimmed,
            password: password,
            userData: userData,
          );
        } catch (fallbackError) {
          throw Exception(authErrorMessage(fallbackError));
        }
      }
      throw Exception(authErrorMessage(e));
    }
  }

  static Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: Firebase.app().options,
      );
    }
  }

  /// Creates Auth user on a secondary app (keeps admin session) then writes
  /// `user/{uid}` with the signed-in admin on the default Firestore.
  static Future<String> _createViaSecondaryAuth({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final app = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    try {
      await auth.signOut();
    } catch (_) {}

    late final String uid;
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      uid = cred.user?.uid ?? '';
      if (uid.isEmpty) {
        throw Exception('تعذر إنشاء الحساب.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw FirebaseFunctionsException(
          code: 'already-exists',
          message: e.message ?? e.code,
        );
      }
      rethrow;
    } finally {
      try {
        await auth.signOut();
      } catch (_) {}
    }

    final doc = _hydrateUserData(userData, email: email, uid: uid);
    await FirebaseFirestore.instance.collection('user').doc(uid).set(
          doc,
          SetOptions(merge: true),
        );
    return uid;
  }

  static final _refFields = <String>{
    'Rev_dloh_agent',
    'Rev_dolh',
    'partner_mkan',
    'transport_company',
    'mndob_vill',
    'mndob_type_car',
    'mndob_user',
    'region_ref',
  };

  static Map<String, dynamic> _hydrateUserData(
    Map<String, dynamic> raw, {
    required String email,
    required String uid,
  }) {
    final data = <String, dynamic>{
      'email': email,
      'uid': uid,
      'created_time': FieldValue.serverTimestamp(),
      'actev_user': true,
      ...raw,
    };

    for (final field in _refFields) {
      final value = data[field];
      if (value is String && value.contains('/')) {
        data[field] = FirebaseFirestore.instance.doc(value);
      }
    }

    for (final field in const [
      'created_time',
      'agentDateReg',
      'agentDateEnd',
      'approved_at',
      'auto_activated_at',
      'submitted_at',
    ]) {
      final value = data[field];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          data[field] = Timestamp.fromDate(parsed);
        }
      }
    }

    return data;
  }
}

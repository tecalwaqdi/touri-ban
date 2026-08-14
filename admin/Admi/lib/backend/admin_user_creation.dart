import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/lat_lng.dart';

/// Creates panel users via Cloud Functions when available; otherwise a
/// secondary Auth app + admin Firestore write (no-billing / no CF mode).
class AdminUserCreation {
  AdminUserCreation._();

  static const _secondaryAppName = 'AdminUserProvision';

  /// When true, fall back to client Auth+Firestore if CF is missing.
  /// Production default is false — set
  /// `--dart-define=TOURY_ADMIN_USER_CREATE_FALLBACK=true` only for local/dev.
  static const bool allowClientFallback = bool.fromEnvironment(
    'TOURY_ADMIN_USER_CREATE_FALLBACK',
    defaultValue: false,
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
        case 'internal':
        case 'INTERNAL':
          return 'تعذر إنشاء الحساب على الخادم. تحقق من صلاحياتك أو جرّب بريداً آخر.';
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
    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    return raw;
  }

  static bool _isCfUnavailable(Object error) {
    if (error is FirebaseFunctionsException) {
      final code = error.code.toLowerCase();
      final msg = '${error.message ?? ''}'.toLowerCase();
      return code == 'not-found' ||
          code == 'unavailable' ||
          code == 'unimplemented' ||
          // Non-JSON LatLng / bad payload often surfaces as internal.
          code == 'internal' ||
          msg.contains('not found') ||
          msg.contains('not been deployed') ||
          msg.contains('billing') ||
          msg.contains('internal');
    }
    final s = error.toString().toLowerCase();
    return s.contains('encodable') || s.contains('latlng');
  }

  /// Makes [userData] JSON-safe for HTTPS callables (no LatLng / Timestamp).
  static Map<String, dynamic> sanitizeForCallable(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      final v = _jsonSafe(value);
      if (v != null || value == null) {
        out[key] = v;
      }
    });
    return out;
  }

  static dynamic _jsonSafe(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is LatLng) {
      return {
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }
    if (value is GeoPoint) {
      return {
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }
    if (value is DocumentReference) {
      return value.path;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map) {
      return sanitizeForCallable(Map<String, dynamic>.from(value));
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList();
    }
    debugPrint('AdminUserCreation: dropped non-JSON field value: $value');
    return null;
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

    final safeData = sanitizeForCallable(userData);

    try {
      final result = await CloudFunctionsClient.createPanelUser(
        email: trimmed,
        password: password,
        userData: safeData,
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
            userData: safeData,
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

  static final _geoFields = <String>{
    'agent_geo_center',
    'agent_bounds_sw',
    'agent_bounds_ne',
    'geo_center',
    'bounds_sw',
    'bounds_ne',
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

    for (final field in _geoFields) {
      final value = data[field];
      final point = _toGeoPoint(value);
      if (point != null) {
        data[field] = point;
      }
    }

    for (final field in const [
      'created_time',
      'agentDateReg',
      'agentDateEnd',
      'agent_date_reg',
      'agent_date_end',
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

  static GeoPoint? _toGeoPoint(dynamic value) {
    if (value is GeoPoint) return value;
    if (value is LatLng) {
      return GeoPoint(value.latitude, value.longitude);
    }
    if (value is Map) {
      final lat = value['latitude'] ?? value['lat'];
      final lng = value['longitude'] ?? value['lng'] ?? value['lon'];
      if (lat is num && lng is num) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }
}

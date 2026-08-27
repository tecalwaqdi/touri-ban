import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/backend/firebase_storage/storage.dart';
import '/backend/profile_photo_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Maps Firebase / network exceptions to localized admin-panel messages.
abstract final class AdminUserFacingErrors {
  static String from(BuildContext context, Object error) {
    if (error is StorageUploadException) {
      return error.message;
    }
    if (error is FirebaseAuthException) {
      return _auth(context, error.code);
    }
    if (error is FirebaseException) {
      return _firebase(context, error);
    }
    final s = error.toString().toLowerCase();
    if (s.contains('quota') || s.contains('402')) {
      return appTr(context, 'adm_err_storage_quota');
    }
    if (s.contains('billing') ||
        s.contains('delinquent') ||
        s.contains('payment required')) {
      return appTr(context, 'adm_err_storage_billing');
    }
    if (s.contains('socket') ||
        s.contains('network') ||
        s.contains('failed host lookup')) {
      return appTr(context, 'adm_err_network');
    }
    // Prefer already-localized upload messages wrapped in Exception.
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      final inner = raw.substring('Exception: '.length).trim();
      if (_isRawFirebaseStorageNoise(inner)) {
        return appTr(context, 'adm_err_storage_quota');
      }
      if (inner.isNotEmpty && !_looksLikeStackOrType(inner)) {
        return inner;
      }
    }
    if (_isRawFirebaseStorageNoise(raw)) {
      return appTr(context, 'adm_err_storage_quota');
    }
    if (raw.isNotEmpty &&
        !raw.contains('FirebaseException') &&
        !raw.contains('Firebase Storage:') &&
        !_looksLikeStackOrType(raw)) {
      // Keep short Arabic/English operational messages.
      if (raw.length < 280) return raw;
    }
    return appTr(context, 'adm_err_generic');
  }

  static bool _isRawFirebaseStorageNoise(String s) {
    final lower = s.toLowerCase();
    return lower.contains('firebase storage:') ||
        lower.contains('quota for bucket') ||
        lower.contains('storage/quota');
  }

  static bool _looksLikeStackOrType(String s) {
    return s.contains('Instance of') ||
        s.contains('#0 ') ||
        s.contains('package:') ||
        s.contains('dart:');
  }

  static String _auth(BuildContext context, String code) {
    switch (code) {
      case 'user-not-found':
        return appTr(context, 'adm_login_user_not_found');
      case 'wrong-password':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'invalid-credential':
        return appTr(context, 'adm_login_wrong_password');
      case 'invalid-email':
        return appTr(context, 'adm_login_invalid_email');
      case 'user-disabled':
        return appTr(context, 'adm_login_user_disabled');
      case 'too-many-requests':
        return appTr(context, 'adm_login_too_many_requests');
      case 'network-request-failed':
        return appTr(context, 'adm_err_network');
      case 'email-already-in-use':
        return appTr(context, 'adm_login_email_in_use');
      case 'weak-password':
        return appTr(context, 'adm_login_weak_password');
      case 'requires-recent-login':
        return appTr(context, 'adm_auth_recent_login');
      default:
        return appTr(context, 'adm_err_generic');
    }
  }

  static String _firebase(BuildContext context, FirebaseException error) {
    final code = error.code.toLowerCase();
    final msg = (error.message ?? '').toLowerCase();
    if (code.contains('quota') || msg.contains('quota') || msg.contains('402')) {
      return appTr(context, 'adm_err_storage_quota');
    }
    if (msg.contains('billing') ||
        msg.contains('delinquent') ||
        msg.contains('payment')) {
      return appTr(context, 'adm_err_storage_billing');
    }
    // Never surface composite-index console URLs or raw query text to operators.
    if (code == 'failed-precondition' ||
        msg.contains('requires an index') ||
        msg.contains('create_composite') ||
        msg.contains('console.firebase.google.com')) {
      return appTr(context, 'adm_err_query_index');
    }
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
      case 'storage/unauthorized':
        return appTr(context, 'adm_err_permission');
      case 'unauthenticated':
      case 'storage/unauthenticated':
        return appTr(context, 'adm_err_unauthenticated');
      case 'not-found':
      case 'object-not-found':
        return appTr(context, 'adm_err_not_found');
      case 'unavailable':
        return appTr(context, 'adm_err_unavailable');
      case 'already-exists':
        return appTr(context, 'adm_err_already_exists');
      case 'invalid-argument':
        return appTr(context, 'adm_err_invalid_argument');
      case 'canceled':
        return appTr(context, 'adm_err_canceled');
      case 'empty-file':
        return appTr(context, 'adm_err_empty_file');
      default:
        // Prefer human Storage message over generic when available.
        final mapped = uploadErrorMessage(error);
        if (mapped.isNotEmpty && !mapped.contains('(')) {
          return mapped;
        }
        return appTr(context, 'adm_err_generic');
    }
  }
}

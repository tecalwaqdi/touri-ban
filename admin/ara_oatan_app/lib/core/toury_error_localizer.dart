import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Maps technical errors to user-safe localized messages. Never expose
/// exception.toString(), stack traces, or raw gateway payloads.
abstract final class ErrorLocalizer {
  static String fromObject(Object? error) {
    if (error == null) return 'error_generic_user'.tr();

    if (error is FirebaseAuthException) {
      return fromFirebaseAuth(error.code);
    }
    if (error is FirebaseException) {
      return fromFirebase(error.code);
    }
    if (error is PlatformException) {
      return fromPlatform(error.code, error.message);
    }
    if (error is TimeoutExceptionLike || _looksLikeTimeout(error)) {
      return 'error_network_user'.tr();
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('socket') ||
        raw.contains('network') ||
        raw.contains('failed host lookup') ||
        raw.contains('unable to resolve') ||
        raw.contains('dns') ||
        raw.contains('connection') ||
        raw.contains('firestore.googleapis.com')) {
      return 'error_network_user'.tr();
    }
    if (raw.contains('permission') && raw.contains('location')) {
      return 'error_location_permission'.tr();
    }
    if (raw.contains('route') && raw.contains('unavail')) {
      return 'error_route_unavailable'.tr();
    }
    return 'error_generic_user'.tr();
  }

  static String fromCode(String? code, {Map<String, String>? params}) {
    final c = (code ?? '').trim().toLowerCase();
    // StateError / wrapped messages may include prefixes.
    final normalized = c
        .replaceFirst(RegExp(r'^bad state:\s*'), '')
        .replaceFirst(RegExp(r'^exception:\s*'), '')
        .trim();
    switch (normalized) {
      case 'not-found':
      case 'not_found':
      case 'notfound':
        return 'error_payment_function_unavailable'.tr();
      case 'payment_failed':
      case 'ngenius_failed':
        return 'status_payment_failed'.tr();
      case 'payment_pending':
        return 'status_payment_pending'.tr();
      case 'network_error':
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'error_network_user'.tr();
      case 'location_permission':
        return 'error_location_permission'.tr();
      case 'permission-denied':
      case 'permission_denied':
        return 'booking_permission_denied'.tr();
      case 'unauthenticated':
        return 'booking_auth_required'.tr();
      case 'already-exists':
      case 'already_exists':
        return 'booking_duplicate_request'.tr();
      case 'resource-exhausted':
      case 'resource_exhausted':
        return 'error_resource_exhausted'.tr();
      case 'cancelled':
      case 'canceled':
        return 'error_cancelled'.tr();
      case 'session-expired':
      case 'session_expired':
        return 'error_session_expired'.tr();
      case 'email-already-in-use':
      case 'email_already_in_use':
        return 'error_email_already_in_use'.tr();
      case 'weak-password':
      case 'weak_password':
        return 'error_weak_password'.tr();
      case 'user-disabled':
      case 'user_disabled':
        return 'error_user_disabled'.tr();
      case 'operation-not-allowed':
      case 'operation_not_allowed':
        return 'error_operation_not_allowed'.tr();
      case 'too-many-requests':
      case 'too_many_requests':
        return 'error_too_many_requests'.tr();
      case 'invalid-verification-code':
      case 'invalid_verification_code':
        return 'error_invalid_verification_code'.tr();
      case 'route_unavailable':
        return 'error_route_unavailable'.tr();
      case 'outside_service_area':
        return 'error_outside_service_area'.tr();
      case 'booking_save_failed':
      case 'booking_missing_required_data':
        return 'booking_save_failed'.tr();
      case 'booking_missing_car':
        return 'ux_no_car_selected'.tr();
      case 'booking_missing_country':
        return 'dialog_country_mismatch_msg'.tr();
      case 'booking_missing_pickup':
        return 'dialog_location_required'.tr();
      case 'booking_missing_user':
        return 'error_generic_user'.tr();
      case 'booking_price_inconsistent':
        return 'booking_save_failed'.tr();
      case 'booking_active_exists':
      case 'active_booking_exists':
        return 'booking_active_exists'.tr();
      default:
        if (normalized.contains('unable to resolve') ||
            normalized.contains('failed host lookup') ||
            normalized.contains('firestore.googleapis.com') ||
            normalized.contains('socket') ||
            normalized.contains('network')) {
          return 'error_network_user'.tr();
        }
        // Never surface raw NOT_FOUND / INTERNAL to users.
        if (normalized.contains('not-found') ||
            normalized.contains('not_found')) {
          return 'error_payment_function_unavailable'.tr();
        }
        return 'error_generic_user'.tr();
    }
  }

  static String fromFirebaseAuth(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'error_generic_user'.tr();
      case 'email-already-in-use':
        return 'error_email_already_in_use'.tr();
      case 'weak-password':
        return 'error_weak_password'.tr();
      case 'user-disabled':
        return 'error_user_disabled'.tr();
      case 'operation-not-allowed':
        return 'error_operation_not_allowed'.tr();
      case 'too-many-requests':
        return 'error_too_many_requests'.tr();
      case 'invalid-verification-code':
        return 'error_invalid_verification_code'.tr();
      case 'session-expired':
        return 'error_session_expired'.tr();
      case 'network-request-failed':
        return 'error_network_user'.tr();
      default:
        return 'error_generic_user'.tr();
    }
  }

  static String fromFirebase(String code) {
    switch (code) {
      case 'not-found':
        return 'error_payment_function_unavailable'.tr();
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'error_network_user'.tr();
      case 'permission-denied':
        return 'booking_permission_denied'.tr();
      case 'unauthenticated':
        return 'booking_auth_required'.tr();
      case 'already-exists':
        return 'booking_duplicate_request'.tr();
      case 'resource-exhausted':
        return 'error_resource_exhausted'.tr();
      case 'cancelled':
      case 'canceled':
        return 'error_cancelled'.tr();
      default:
        return 'error_generic_user'.tr();
    }
  }

  static String fromPlatform(String code, String? message) {
    final m = (message ?? '').toLowerCase();
    if (code.contains('PERMISSION') || m.contains('permission')) {
      if (m.contains('location') || code.contains('LOCATION')) {
        return 'error_location_permission'.tr();
      }
    }
    return 'error_generic_user'.tr();
  }

  static bool _looksLikeTimeout(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('timeout') || s.contains('timed out');
  }
}

/// Marker for timeout-like errors without importing dart:async everywhere.
class TimeoutExceptionLike implements Exception {}

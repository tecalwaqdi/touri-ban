import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

/// Stable localization keys for Payment API / provider failures.
abstract final class TouryPaymentErrorKeys {
  static const temporarilyUnavailable =
      'checkout_payment_temporarily_unavailable';
  static const cardError = 'checkout_payment_card_error';
  static const linkExpired = 'checkout_payment_link_expired';
  static const paymentPending = 'PAYMENT_PENDING';
}

/// N-Genius HPP / WebView copy when the access code is dead or missing.
/// Must not be shown as "electronic payment service unavailable".
bool touryIsMissingOrExpiredPaymentLinkText(String? raw) {
  final t = (raw ?? '').toLowerCase();
  if (t.isEmpty) return false;
  return t.contains('payment link does not exist') ||
      t.contains('link does not exist') ||
      t.contains('unable to retrieve order') ||
      t.contains('payment page is not available') ||
      t.contains('order could not be found') ||
      (t.contains('unable to retrieve') && t.contains('order'));
}

/// Maps raw API codes to localization keys (no UI / no .tr()).
///
/// Card-entry messages must only be used after an actual card attempt.
/// Create-order provider failures (before WebView) use temporary-unavailable.
String touryPaymentApiErrorKey(String? rawCode) {
  final code = (rawCode ?? '').trim();
  if (code.isEmpty) {
    return TouryPaymentErrorKeys.temporarilyUnavailable;
  }

  // Payment API sometimes surfaces provider HTML/message as the "code".
  if (touryIsMissingOrExpiredPaymentLinkText(code)) {
    return TouryPaymentErrorKeys.linkExpired;
  }

  final upper = code.toUpperCase();

  const providerUnavailable = <String>{
    'PROVIDER_OUTLET_NOT_CONFIGURED',
    'PROVIDER_UNAVAILABLE',
    'CONFIG_ERROR',
    'NETWORK_ERROR',
    'UNKNOWN_ERROR',
  };
  if (providerUnavailable.contains(upper)) {
    return TouryPaymentErrorKeys.temporarilyUnavailable;
  }

  // Still processing — never "service unavailable".
  if (upper == 'BOOKING_PENDING' || upper == 'PAYMENT_PENDING') {
    return TouryPaymentErrorKeys.paymentPending;
  }

  const cardOrAttempt = <String>{
    'PAYMENT_FAILED',
    'INVALID_CARD',
    'CARD_DECLINED',
    'PAYMENT_AMOUNT_MISMATCH',
    'PAYMENT_CURRENCY_MISMATCH',
  };
  if (cardOrAttempt.contains(upper)) {
    return TouryPaymentErrorKeys.cardError;
  }

  if (upper == 'PAYMENT_CANCELLED') return 'PAYMENT_CANCELLED';
  if (upper == 'PAYMENT_EXPIRED' ||
      upper == 'PAYMENT_ATTEMPT_EXPIRED' ||
      upper == 'HPP_EXPIRED' ||
      upper == 'PAYMENT_LINK_MISSING') {
    return TouryPaymentErrorKeys.linkExpired;
  }
  if (upper == 'ACTIVE_BOOKING_EXISTS' ||
      upper == 'PAYMENT_ACTIVE_OTHER_BOOKING') {
    return 'booking_active_exists';
  }
  if (upper == 'BOOKING_VEHICLE_COUNTRY_MISMATCH') {
    return 'booking_vehicle_country_mismatch';
  }
  if (upper == 'PAYMENT_NATIVE_UNAVAILABLE') {
    return 'payment_sdk_fallback_hpp';
  }

  const passThrough = <String>{
    'AUTH_REQUIRED',
    'AUTH_INVALID',
    'FORBIDDEN',
    'BOOKING_NOT_PAYABLE',
    'INVALID_REQUEST',
    'INVALID_HOURS',
    'UNSUPPORTED_CURRENCY',
    'CHECKOUT_ONLINE_PAYMENT_DISABLED',
  };
  if (passThrough.contains(upper)) {
    return upper;
  }

  if (kDebugMode) {
    debugPrint('touryPaymentApiErrorKey unmapped code=$upper');
  }
  return TouryPaymentErrorKeys.temporarilyUnavailable;
}

/// Customer-facing message for a Payment API / provider code.
String touryPaymentApiErrorMessage(String? rawCode) {
  return touryPaymentApiErrorKey(rawCode).tr();
}

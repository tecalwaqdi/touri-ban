import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

/// Stable localization keys for Payment API / provider failures.
abstract final class TouryPaymentErrorKeys {
  static const temporarilyUnavailable =
      'checkout_payment_temporarily_unavailable';
  static const cardError = 'checkout_payment_card_error';
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

  final upper = code.toUpperCase();

  const providerUnavailable = <String>{
    'PROVIDER_OUTLET_NOT_CONFIGURED',
    'PROVIDER_UNAVAILABLE',
    'CONFIG_ERROR',
    'NETWORK_ERROR',
    'UNKNOWN_ERROR',
    'BOOKING_PENDING',
    'PAYMENT_PENDING',
  };
  if (providerUnavailable.contains(upper)) {
    return TouryPaymentErrorKeys.temporarilyUnavailable;
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
  if (upper == 'PAYMENT_EXPIRED') return 'PAYMENT_EXPIRED';
  if (upper == 'ACTIVE_BOOKING_EXISTS') return 'booking_active_exists';

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

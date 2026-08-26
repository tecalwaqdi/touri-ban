import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Structured native N-Genius Mobile SDK outcomes.
/// SDK success is NOT authoritative paid — backend/webhook remains SoT.
enum TouryNativePaymentOutcome {
  unavailable,
  completed,
  cancelled,
  failed,
  error,
}

class TouryNativePaymentResult {
  const TouryNativePaymentResult({
    required this.outcome,
    this.errorCategory,
    this.detail,
  });

  final TouryNativePaymentOutcome outcome;
  final String? errorCategory;
  final String? detail;

  bool get isCompleted => outcome == TouryNativePaymentOutcome.completed;
  bool get isCancelled => outcome == TouryNativePaymentOutcome.cancelled;
  bool get needsFallback =>
      outcome == TouryNativePaymentOutcome.unavailable ||
      outcome == TouryNativePaymentOutcome.error;
}

/// Platform channel to official N-Genius Android / iOS SDKs.
/// Never receives PAN/CVV or merchant secrets.
class TouryNgeniusNativeBridge {
  TouryNgeniusNativeBridge({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('touri/ngenius_payment');

  final MethodChannel _channel;

  static const _supported = {
    TargetPlatform.android,
    TargetPlatform.iOS,
  };

  bool get isPlatformSupported =>
      !kIsWeb && _supported.contains(defaultTargetPlatform);

  Future<bool> isAvailable() async {
    if (!isPlatformSupported) return false;
    try {
      final raw = await _channel.invokeMethod<dynamic>('isAvailable');
      return raw == true;
    } catch (_) {
      return false;
    }
  }

  /// Launch official card UI + 3DS. Returns SDK-local outcome only.
  Future<TouryNativePaymentResult> startCardPayment({
    required String gatewayAuthorizationUrl,
    required String payPageUrl,
    required String paymentCode,
    String? orderJson,
    String languageCode = 'en',
  }) async {
    if (!isPlatformSupported) {
      return const TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.unavailable,
        errorCategory: 'UNSUPPORTED_PLATFORM',
      );
    }
    if (gatewayAuthorizationUrl.isEmpty ||
        payPageUrl.isEmpty ||
        paymentCode.isEmpty) {
      return const TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.error,
        errorCategory: 'INVALID_SDK_SESSION',
      );
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('startCardPayment', {
        'gatewayAuthorizationUrl': gatewayAuthorizationUrl,
        'payPageUrl': payPageUrl,
        'paymentCode': paymentCode,
        if (orderJson != null && orderJson.isNotEmpty) 'orderJson': orderJson,
        'languageCode': languageCode == 'ar' ? 'ar' : 'en',
      });
      return _mapResult(raw);
    } on PlatformException catch (e) {
      final code = (e.code).toUpperCase();
      if (code.contains('CANCEL')) {
        return TouryNativePaymentResult(
          outcome: TouryNativePaymentOutcome.cancelled,
          errorCategory: code,
          detail: e.message,
        );
      }
      if (code.contains('UNAVAILABLE') || code.contains('MISSING')) {
        return TouryNativePaymentResult(
          outcome: TouryNativePaymentOutcome.unavailable,
          errorCategory: code,
          detail: e.message,
        );
      }
      return TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.error,
        errorCategory: code.isEmpty ? 'PLATFORM_EXCEPTION' : code,
        detail: e.message,
      );
    } catch (_) {
      return const TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.error,
        errorCategory: 'NATIVE_EXCEPTION',
      );
    }
  }

  TouryNativePaymentResult _mapResult(dynamic raw) {
    Map<String, dynamic>? map;
    if (raw is Map) {
      map = raw.map((k, v) => MapEntry(k.toString(), v));
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    final status = (map?['status'] ?? map?['outcome'] ?? '')
        .toString()
        .toLowerCase();
    if (status == 'success' ||
        status == 'completed' ||
        status == 'authorized' ||
        status == 'captured' ||
        status == 'payment_success') {
      return const TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.completed,
      );
    }
    if (status == 'cancelled' || status == 'canceled' || status == 'cancel') {
      return TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.cancelled,
        errorCategory: (map?['errorCategory'] ?? 'USER_CANCELLED').toString(),
      );
    }
    if (status == 'failed' || status == 'declined' || status == 'failure') {
      return TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.failed,
        errorCategory: (map?['errorCategory'] ?? 'DECLINED').toString(),
        detail: map?['detail']?.toString(),
      );
    }
    if (status == 'unavailable') {
      return TouryNativePaymentResult(
        outcome: TouryNativePaymentOutcome.unavailable,
        errorCategory: (map?['errorCategory'] ?? 'SDK_UNAVAILABLE').toString(),
      );
    }
    return TouryNativePaymentResult(
      outcome: TouryNativePaymentOutcome.error,
      errorCategory: (map?['errorCategory'] ?? 'UNKNOWN').toString(),
      detail: map?['detail']?.toString(),
    );
  }
}

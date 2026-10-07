import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/backend/api_requests/api_calls.dart';
import '/core/toury_payment_error_messages.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_flow.dart';
import '/core/payments/payment_api_client.dart';
import '/core/payments/touri_ngenius_native_bridge.dart';
import '/core/toury_order_integration.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// High-level payment experience: Mobile SDK primary, HPP safe fallback.
/// Never marks paid from SDK alone — caller must poll backend.
class TouryPaymentExperienceService {
  TouryPaymentExperienceService({
    TouryNgeniusNativeBridge? bridge,
    PaymentApiClient? apiClient,
  })  : _bridge = bridge ?? TouryNgeniusNativeBridge(),
        _api = apiClient ?? PaymentApiClient();

  final TouryNgeniusNativeBridge _bridge;
  final PaymentApiClient _api;

  /// Create order server-side, prefer native SDK, fall back to existing HPP.
  ///
  /// Set [forceRefreshSession] on resume/retry so an expired SDK/HPP session
  /// is minted fresh instead of reusing a dead auth URL.
  Future<TouryCardPaymentResult> startCardCheckout({
    required BuildContext context,
    required String description,
    required int amountHalalas,
    required String carPath,
    required String countryPath,
    required int bookingHours,
    required int additionalHours,
    String? orderPath,
    bool forceRefreshSession = false,
  }) async {
    if (TouryPaymentFlags.forceHostedPaymentPage || kIsWeb) {
      if (kDebugMode) {
        debugPrint(
          'PAYMENT_MODE=hpp SDK_PATH_SELECTED=false '
          'reason=force_hpp_or_web mode=${TouryPaymentFlags.mobilePaymentMode}',
        );
      }
      return touryExecuteCardPayment(
        description: description,
        amountHalalas: amountHalalas,
        carPath: carPath,
        countryPath: countryPath,
        bookingHours: bookingHours,
        additionalHours: additionalHours,
        orderPath: orderPath,
        forceRefreshHpp: forceRefreshSession,
      );
    }

    if (amountHalalas <= 0 && (orderPath == null || orderPath.isEmpty)) {
      return TouryCardPaymentResult(
        success: false,
        errorMessage: 'checkout_payment_temporarily_unavailable'.tr(),
      );
    }

    final app = FFAppState();
    if (app.paymentIdempotencyKey.isEmpty) {
      app.paymentIdempotencyKey =
          'booking_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    }

    late final Map<String, dynamic> body;
    try {
      body = await _api.createCardBookingPayment(
        idempotencyKey: app.paymentIdempotencyKey,
        carPath: carPath,
        countryPath: countryPath,
        bookingHours: bookingHours,
        additionalHours: additionalHours,
        booking: TouryOrderIntegration.cloudBookingPayload(),
        description: description,
        locale: context.locale.languageCode,
        orderPath: orderPath,
        forceRefreshHpp: forceRefreshSession,
      );
    } on PaymentApiException catch (e) {
      return TouryCardPaymentResult(
        success: false,
        errorMessage: touryPaymentApiErrorMessage(e.code),
      );
    } catch (_) {
      return TouryCardPaymentResult(
        success: false,
        errorMessage: 'checkout_payment_temporarily_unavailable'.tr(),
      );
    }

    final paymentId = body['id']?.toString();
    final bookingId = body['bookingId']?.toString() ?? paymentId;
    if (bookingId != null && bookingId.isNotEmpty) {
      app.pendingPaymentOrderId = bookingId;
    }
    final status = (body['status']?.toString() ?? '').toLowerCase();
    if (status == 'paid' ||
        status == 'captured' ||
        body['bookingCreated'] == true) {
      return TouryCardPaymentResult(
        success: true,
        paymentId: paymentId,
        bookingId: bookingId,
        status: status.isEmpty ? 'paid' : status,
        response: ApiCallResponse(body, const {}, 200),
      );
    }

    final sdk = body['sdk'];
    Map<String, dynamic>? sdkMap;
    if (sdk is Map) {
      sdkMap = sdk.map((k, v) => MapEntry(k.toString(), v));
    }
    final fallbackUrl = body['fallback'] is Map
        ? (body['fallback'] as Map)['hostedPaymentUrl']?.toString()
        : null;
    final hppUrl = _hppOrNull(
      fallbackUrl ??
          body['threeDsUrl']?.toString() ??
          body['paymentUrl']?.toString(),
    );

    final authUrl = sdkMap?['gatewayAuthorizationUrl']?.toString() ?? '';
    final payPageUrl = sdkMap?['payPageUrl']?.toString() ?? '';
    final paymentCode = sdkMap?['paymentCode']?.toString() ?? '';
    final orderJsonRaw = sdkMap?['orderJson'];
    final orderJson = orderJsonRaw == null
        ? null
        : (orderJsonRaw is String ? orderJsonRaw : jsonEncode(orderJsonRaw));

    // iOS NISdk requires OrderResponse JSON; Android CardPaymentRequest needs
    // auth URL + code only. Missing iOS orderJson → HPP fallback (in-app).
    final iosNeedsOrderJson =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final sdkSessionReady = authUrl.isNotEmpty &&
        payPageUrl.isNotEmpty &&
        paymentCode.isNotEmpty &&
        (!iosNeedsOrderJson ||
            (orderJson != null && orderJson.trim().isNotEmpty));

    final orderJsonPresent =
        orderJson != null && orderJson.trim().isNotEmpty;
    final bridgeAvailable = await _bridge.isAvailable();
    final sdkReady = TouryPaymentFlags.preferMobileSdk &&
        sdkSessionReady &&
        bridgeAvailable;

    if (kDebugMode) {
      debugPrint(
        'PAYMENT_MODE=sdk SDK_PATH_SELECTED=${TouryPaymentFlags.preferMobileSdk} '
        'SDK_ORDER_JSON_PRESENT=$orderJsonPresent '
        'sdkSessionReady=$sdkSessionReady bridge=$bridgeAvailable',
      );
    }

    if (sdkReady) {
      if (kDebugMode) {
        debugPrint(
          'NATIVE_BRIDGE_CALLED=true host=${Uri.tryParse(authUrl)?.host}',
        );
      }
      final lang = context.locale.languageCode.toLowerCase().startsWith('ar')
          ? 'ar'
          : 'en';
      final native = await _bridge.startCardPayment(
        gatewayAuthorizationUrl: authUrl,
        payPageUrl: payPageUrl,
        paymentCode: paymentCode,
        orderJson: orderJson,
        languageCode: lang,
      );

      if (native.isCompleted) {
        return TouryCardPaymentResult(
          success: true,
          paymentId: paymentId,
          bookingId: bookingId,
          status: 'pending_backend_confirmation',
          response: ApiCallResponse(body, const {}, 200),
        );
      }
      if (native.isCancelled) {
        return TouryCardPaymentResult(
          success: false,
          paymentId: paymentId,
          bookingId: bookingId,
          status: 'cancelled',
          errorMessage: 'payment_cancelled_no_charge'.tr(),
        );
      }
      if (native.outcome == TouryNativePaymentOutcome.failed) {
        return TouryCardPaymentResult(
          success: false,
          paymentId: paymentId,
          bookingId: bookingId,
          status: 'failed',
          errorMessage: 'checkout_payment_declined'.tr(),
        );
      }
      // Same order → HPP fallback (no second create).
      if (kDebugMode) {
        final reason = native.errorCategory ?? native.outcome.name;
        debugPrint(
          'HPP_FALLBACK_TRIGGERED=true HPP_FALLBACK_REASON=$reason '
          'EXTERNAL_BROWSER_OPENED=false',
        );
        if (reason.toUpperCase().contains('SIMULATOR') ||
            reason.toUpperCase().contains('UNAVAILABLE')) {
          debugPrint('SIMULATOR_SDK_LIMITATION=true reason=$reason');
        }
      }
    } else if (kDebugMode) {
      debugPrint(
        'NATIVE_BRIDGE_CALLED=false prefer=${TouryPaymentFlags.preferMobileSdk} '
        'auth=${authUrl.isNotEmpty} pay=${payPageUrl.isNotEmpty} '
        'code=${paymentCode.isNotEmpty} orderJson=$orderJsonPresent '
        'bridge=$bridgeAvailable',
      );
      if (TouryPaymentFlags.preferMobileSdk && !sdkSessionReady) {
        debugPrint(
          'HPP_FALLBACK_TRIGGERED=true HPP_FALLBACK_REASON=sdk_session_incomplete '
          'SDK_ORDER_JSON_PRESENT=$orderJsonPresent',
        );
      } else if (TouryPaymentFlags.preferMobileSdk && !bridgeAvailable) {
        debugPrint(
          'HPP_FALLBACK_TRIGGERED=true HPP_FALLBACK_REASON=bridge_unavailable '
          'SIMULATOR_SDK_LIMITATION=possible',
        );
      }
    }

    if (hppUrl == null || hppUrl.isEmpty) {
      return TouryCardPaymentResult(
        success: false,
        paymentId: paymentId,
        bookingId: bookingId,
        errorMessage: 'checkout_payment_link_expired'.tr(),
        status: 'hpp_missing',
      );
    }

    return TouryCardPaymentResult(
      success: true,
      paymentId: paymentId,
      bookingId: bookingId,
      threeDsUrl: hppUrl,
      status: body['status']?.toString(),
      response: ApiCallResponse(body, const {}, 200),
    );
  }

  String? _hppOrNull(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    if (!host.endsWith('ngenius-payments.com')) return null;
    if (!(host.startsWith('paypage.') || host.contains('.paypage.'))) {
      return null;
    }
    if (!uri.queryParameters.containsKey('code')) return null;
    return raw;
  }
}

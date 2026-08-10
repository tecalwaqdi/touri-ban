import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/enums/enums.dart';
import '/core/app_design_system.dart';
import '/core/toury_brand_widgets.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_ngenius_service.dart';
import '/core/toury_payment_error_messages.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_labels.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_order_meta.dart';
import '/core/payments/payment_api_client.dart';
import '/design_system/colors/ds_color_scales.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// نتيجة محاولة الدفع بالبطاقة عبر Network International (N-Genius).
class TouryCardPaymentResult {
  const TouryCardPaymentResult({
    required this.success,
    this.response,
    this.paymentId,
    this.bookingId,
    this.threeDsUrl,
    this.errorMessage,
    this.status,
  });

  final bool success;
  final ApiCallResponse? response;
  final String? paymentId;
  /// Unpaid / activated order id (same as session id for new bookings).
  final String? bookingId;
  final String? threeDsUrl;
  final String? errorMessage;
  final String? status;

  bool get needsThreeDs =>
      threeDsUrl != null &&
      threeDsUrl!.isNotEmpty &&
      !isPaid;

  /// Only server-normalized paid/captured — never treat return URL as paid.
  bool get isPaid {
    final s = (status ?? TouryNGeniusService.status(response?.jsonBody) ?? '')
        .toLowerCase();
    return s == 'paid' || s == 'captured';
  }
}

/// تنفيذ دفع بطاقة عبر Cloud Function أو Payment API الخارجي → N-Genius فقط.
Future<TouryCardPaymentResult> touryExecuteCardPayment({
  required String description,
  required int amountHalalas,
  required String carPath,
  required String countryPath,
  required int bookingHours,
  required int additionalHours,
}) async {
  if (!TouryPaymentFlags.enableOnlinePayment || TouryPaymentFlags.cashOnlyMode) {
    return TouryCardPaymentResult(
      success: false,
      errorMessage: 'checkout_online_payment_disabled'.tr(),
    );
  }
  if (amountHalalas <= 0) {
    return TouryCardPaymentResult(
      success: false,
      errorMessage: 'checkout_payment_temporarily_unavailable'.tr(),
    );
  }

  if (TouryPaymentFlags.useExternalPaymentApi) {
    try {
      final app = FFAppState();
      if (app.paymentIdempotencyKey.isEmpty) {
        app.paymentIdempotencyKey =
            'booking_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      }
      final client = PaymentApiClient();
      final body = await client.createCardBookingPayment(
        idempotencyKey: app.paymentIdempotencyKey,
        carPath: carPath,
        countryPath: countryPath,
        bookingHours: bookingHours,
        additionalHours: additionalHours,
        booking: TouryOrderIntegration.cloudBookingPayload(),
        description: description,
      );
      final paymentId = body['id']?.toString();
      final bookingId = body['bookingId']?.toString() ?? paymentId;
      final rawUrl = body['threeDsUrl']?.toString() ??
          body['paymentUrl']?.toString();
      final threeDsUrl = _hostedPaymentPageUrlOrNull(rawUrl);
      if (paymentId == null || paymentId.isEmpty) {
        return TouryCardPaymentResult(
          success: false,
          errorMessage: 'checkout_payment_temporarily_unavailable'.tr(),
        );
      }
      if (bookingId != null && bookingId.isNotEmpty) {
        app.pendingPaymentOrderId = bookingId;
      }
      // Already paid on server — no new HPP (duplicate tap / delayed UI).
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
      if (threeDsUrl == null) {
        // Keep unpaid order; mint a fresh HPP on next retry.
        return TouryCardPaymentResult(
          success: false,
          paymentId: paymentId,
          bookingId: bookingId,
          errorMessage: 'checkout_hosted_payment_unavailable'.tr(),
        );
      }
      return TouryCardPaymentResult(
        success: true,
        paymentId: paymentId,
        bookingId: bookingId,
        threeDsUrl: threeDsUrl,
        status: body['status']?.toString(),
        response: ApiCallResponse(body, const {}, 200),
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
  }

  final response = await NGeniusPaymentCall.call(
    description: description,
    amount: amountHalalas,
    paymentPurpose: 'booking',
    carPath: carPath,
    countryPath: countryPath,
    bookingHours: bookingHours,
    additionalHours: additionalHours,
  );

  if (!TouryNGeniusService.createReady(response)) {
    final err = response.jsonBody is Map
        ? (response.jsonBody as Map)['error']?.toString()
        : null;
    return TouryCardPaymentResult(
      success: false,
      response: response,
      errorMessage: touryPaymentApiErrorMessage(err),
    );
  }

  final body = response.jsonBody;
  return TouryCardPaymentResult(
    success: true,
    response: response,
    paymentId: TouryNGeniusService.paymentId(body),
    threeDsUrl: NGeniusPaymentCall.url(body),
    status: TouryNGeniusService.status(body),
  );
}

/// يوجّه بعد الدفع: صفحة 3DS للبوابة أو التحقق المباشر من N-Genius.
Future<void> touryNavigateAfterCardPayment(
  BuildContext context, {
  required TouryCardPaymentResult result,
  required TypeHgz paymentFlowType,
  VoidCallback? onPaidWithoutWebView,
}) async {
  if (!result.success || result.paymentId == null) return;

  FFAppState().update(() {
    FFAppState().paymentOrderId = result.paymentId!;
    FFAppState().paymentInProgress = true;
    FFAppState().DonePay = false;
    FFAppState().paymentFlowKind = paymentFlowType;
  });

  // Never treat a missing return/3DS URL as paid — only explicit paid/captured.
  if (result.isPaid) {
    if (onPaidWithoutWebView != null) {
      onPaidWithoutWebView();
      return;
    }
    if (!context.mounted) return;
    context.pushNamed(
      PaymentConfirmWidget.routeName,
      queryParameters: {
        'fromWebView': serializeParam(false, ParamType.bool),
      }.withoutNulls,
    );
    return;
  }

  final threeDs = result.threeDsUrl?.trim() ?? '';
  if (threeDs.isEmpty || _hostedPaymentPageUrlOrNull(threeDs) == null) {
    FFAppState().clearSensitivePaymentSession();
    if (!context.mounted) return;
    TouryDialogs.showSnackBar(
      context,
      'checkout_hosted_payment_unavailable'.tr(),
      type: TouryMessageType.error,
    );
    return;
  }

  if (!context.mounted) return;

  // Prefer system browser / Safari VC to isolate simulator WKWebView 3DS issues.
  if (TouryPaymentFlags.openPaymentInExternalBrowser) {
    final opened = await _openHostedPaymentInBrowser(context, threeDs);
    if (opened) {
      if (!context.mounted) return;
      TouryDialogs.showSnackBar(
        context,
        'checkout_complete_payment_in_browser'.tr(),
        type: TouryMessageType.info,
      );
      context.pushNamed(
        PaymentConfirmWidget.routeName,
        queryParameters: {
          'fromWebView': serializeParam(false, ParamType.bool),
        }.withoutNulls,
      );
      return;
    }
    // Fall through to in-app WebView if browser open failed.
    if (kDebugMode) {
      debugPrint('external_browser_open_failed host=${Uri.tryParse(threeDs)?.host}');
    }
  }

  if (!context.mounted) return;
  context.pushNamed(
    WebviewWidget.routeName,
    queryParameters: {
      'url': serializeParam(threeDs, ParamType.String),
    }.withoutNulls,
  );
}

/// Opens HPP in Safari / in-app Safari view; returns false if nothing launched.
Future<bool> _openHostedPaymentInBrowser(
  BuildContext context,
  String paymentUrl,
) async {
  final uri = Uri.tryParse(paymentUrl);
  if (uri == null || uri.scheme != 'https') return false;

  // 1) SFSafariViewController (real Safari engine inside app) — best on device/sim.
  try {
    if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      return true;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('inAppBrowserView failed: $e');
  }

  // 2) External Safari / default browser.
  try {
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('externalApplication failed: $e');
  }

  // 3) Platform default.
  try {
    if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      return true;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('platformDefault failed: $e');
  }

  // 4) Manual dialog — user taps Open / sees that browser must open.
  if (!context.mounted) return false;
  final host = uri.host;
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('checkout_open_payment_browser_title'.tr()),
      content: Text(
        'checkout_open_payment_browser_body'.tr(namedArgs: {'host': host}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'cancel'),
          child: Text('checkout_open_payment_browser_cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'open'),
          child: Text('checkout_open_payment_browser_action'.tr()),
        ),
      ],
    ),
  );
  if (choice == 'open') {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
  return false;
}

/// بطاقة طريقة الدفع المختارة.
class TouryPaymentMethodCard extends StatelessWidget {
  const TouryPaymentMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? TouryBrand.tealDark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? accent.withValues(alpha: isDark ? 0.18 : 0.08)
          : TouryBrand.cardFor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : TouryBrand.borderFor(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: TouryBrand.textPrimaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12,
                        color: TouryBrand.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_off,
                color: selected ? accent : TouryBrand.borderFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط ملخص الدفع في صفحة الحجز.
class TouryPaymentSummaryBar extends StatelessWidget {
  const TouryPaymentSummaryBar({
    super.key,
    required this.methodLabel,
    required this.totalLabel,
    required this.onChangeMethod,
  });

  final String methodLabel;
  final String totalLabel;
  final VoidCallback onChangeMethod;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? TouryBrand.teal.withValues(alpha: 0.12)
            : DsPrimaryScale.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TouryBrand.teal.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_rounded,
            color: isDark ? DsPrimaryScale.shade400 : DsPrimaryScale.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  methodLabel,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w700,
                    color: TouryBrand.textPrimaryFor(context),
                  ),
                ),
                Text(
                  totalLabel,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFAAC0BD)
                        : const Color(0xFF004D40),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeMethod,
            child: Text('ux_change'.tr()),
          ),
        ],
      ),
    );
  }
}



/// Retry card payment for an existing unpaid order (no duplicate booking).
Future<TouryCardPaymentResult> touryRetryUnpaidOrderPayment({
  required OrderRecord order,
}) async {
  if (!TouryPaymentFlags.enableOnlinePayment || TouryPaymentFlags.cashOnlyMode) {
    return TouryCardPaymentResult(
      success: false,
      errorMessage: 'checkout_online_payment_disabled'.tr(),
    );
  }
  if (!order.isAwaitingPayment) {
    return TouryCardPaymentResult(
      success: false,
      errorMessage: 'checkout_payment_temporarily_unavailable'.tr(),
    );
  }
  final carPath = order.carRev?.path ?? '';
  final countryPath = (order.snapshotData['Rev_dolh'] is DocumentReference)
      ? (order.snapshotData['Rev_dolh'] as DocumentReference).path
      : '';
  if (carPath.isEmpty || countryPath.isEmpty) {
    return TouryCardPaymentResult(
      success: false,
      errorMessage: 'checkout_payment_temporarily_unavailable'.tr(),
    );
  }

  final app = FFAppState();
  // Stable idempotency per unpaid order — refreshes HPP without double charge.
  app.paymentIdempotencyKey = 'pay_order_${order.reference.id}';
  app.pendingPaymentOrderId = order.reference.id;

  if (TouryPaymentFlags.useExternalPaymentApi) {
    try {
      final client = PaymentApiClient();
      final body = await client.createCardBookingPayment(
        idempotencyKey: app.paymentIdempotencyKey,
        carPath: carPath,
        countryPath: countryPath,
        bookingHours: order.totalTaim > 0 ? order.totalTaim : 1,
        additionalHours: 0,
        booking: TouryOrderIntegration.cloudBookingPayload(),
        orderPath: order.reference.path,
        description: 'Toury-retry-${order.reference.id.substring(0, 8)}',
      );
      final paymentId = body['id']?.toString();
      final bookingId = body['bookingId']?.toString() ?? order.reference.id;
      final status = (body['status']?.toString() ?? '').toLowerCase();
      if (status == 'paid' ||
          status == 'captured' ||
          body['bookingCreated'] == true) {
        return TouryCardPaymentResult(
          success: true,
          paymentId: paymentId ?? order.reference.id,
          bookingId: bookingId,
          status: 'paid',
          response: ApiCallResponse(body, const {}, 200),
        );
      }
      final rawUrl = body['threeDsUrl']?.toString() ??
          body['paymentUrl']?.toString();
      final threeDsUrl = _hostedPaymentPageUrlOrNull(rawUrl);
      if (paymentId == null || paymentId.isEmpty || threeDsUrl == null) {
        return TouryCardPaymentResult(
          success: false,
          paymentId: paymentId,
          bookingId: bookingId,
          errorMessage: 'checkout_hosted_payment_unavailable'.tr(),
        );
      }
      return TouryCardPaymentResult(
        success: true,
        paymentId: paymentId,
        bookingId: bookingId,
        threeDsUrl: threeDsUrl,
        status: body['status']?.toString(),
        response: ApiCallResponse(body, const {}, 200),
      );
    } on PaymentApiException catch (e) {
      if (e.code == 'PAYMENT_ALREADY_EXISTS') {
        return TouryCardPaymentResult(
          success: true,
          paymentId: order.reference.id,
          bookingId: order.reference.id,
          status: 'paid',
        );
      }
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
  }

  return TouryCardPaymentResult(
    success: false,
    errorMessage: 'checkout_payment_temporarily_unavailable'.tr(),
  );
}

/// Shown when HPP closes / fails but unpaid order was saved.
Future<void> touryShowPaymentIncompleteSheet(
  BuildContext context, {
  String? orderId,
}) async {
  final id = (orderId ?? FFAppState().pendingPaymentOrderId).trim();
  if (!context.mounted) return;
  final choice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('payment_incomplete_title'.tr()),
      content: Text('payment_incomplete_body'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'orders'),
          child: Text('payment_incomplete_go_orders'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'retry'),
          child: Text('payment_incomplete_retry'.tr()),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (choice == 'orders') {
    context.goNamed(List22TaskOverviewResponsiveWidget.routeName);
    return;
  }
  if (choice == 'retry' && id.isNotEmpty) {
    try {
      final snap = await OrderRecord.getDocumentOnce(
        OrderRecord.collection.doc(id),
      );
      final result = await touryRetryUnpaidOrderPayment(order: snap);
      if (!context.mounted) return;
      await touryNavigateAfterCardPayment(
        context,
        result: result,
        paymentFlowType: TypeHgz.Rhlh,
      );
    } catch (_) {
      if (!context.mounted) return;
      TouryDialogs.showSnackBar(
        context,
        'checkout_payment_temporarily_unavailable'.tr(),
        type: TouryMessageType.error,
      );
    }
  }
}

bool touryHasElectronicPaymentSelected() {
  if (!TouryPaymentFlags.enableOnlinePayment) return false;
  // Require both flags — ElectronicPayment alone can stay stale after wallet flows.
  return FFAppState().ElectronicPayment &&
      touryIsOnlinePaymentValue(FFAppState().payth);
}

/// Accept only N-Genius Hosted Payment Page URLs (never API order endpoints).
String? _hostedPaymentPageUrlOrNull(String? raw) {
  final url = (raw ?? '').trim();
  if (url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return null;
  final host = uri.host.toLowerCase();
  if (host.contains('api-gateway')) return null;
  if (!host.endsWith('ngenius-payments.com')) return null;
  final isPaypage =
      host.startsWith('paypage.') || host.contains('.paypage.');
  if (!isPaypage) return null;
  if (!uri.queryParameters.containsKey('code')) return null;
  return url;
}

String tourySelectedPaymentSubtitle(String payth) {
  if (TouryPaymentFlags.cashOnlyMode || touryIsCashPaymentValue(payth)) {
    return 'ux_cash_on_delivery'.tr();
  }
  if (touryIsUnsetPaymentValue(payth)) {
    return 'ux_choose_payment_method'.tr();
  }
  return 'ux_card_payment_network'.tr();
}

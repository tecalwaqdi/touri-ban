import 'package:easy_localization/easy_localization.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_flow.dart';
import '/core/toury_payment_notifications.dart';
import '/core/toury_payment_verify.dart';
import '/core/toury_ngenius_service.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_wallet_ngenius.dart';
import '/core/payments/payment_api_client.dart';
import 'dart:async';
import '/backend/schema/enums/enums.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'payment_confirm_model.dart';
export 'payment_confirm_model.dart';

class PaymentConfirmWidget extends StatefulWidget {
  const PaymentConfirmWidget({
    super.key,
    this.fromWebView,
  });

  /// false عند الوصول بعد إغلاق صفحة 3DS — يُنفَّذ التحقق وإنشاء الطلب.
  final bool? fromWebView;

  static String routeName = 'paymentConfirm';
  static String routePath = '/paymentConfirm';

  @override
  State<PaymentConfirmWidget> createState() => _PaymentConfirmWidgetState();
}

class _PaymentConfirmWidgetState extends State<PaymentConfirmWidget>
    with TickerProviderStateMixin {
  late PaymentConfirmModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentConfirmModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().paymentInProgress = false;
      safeSetState(() {});

      // true = closed/failed HPP without verified pay — keep unpaid order + retry CTA.
      if (widget.fromWebView == true) {
        FFAppState().DonePay = false;
        if (mounted) {
          await touryShowPaymentIncompleteSheet(
            context,
            orderId: FFAppState().pendingPaymentOrderId.isNotEmpty
                ? FFAppState().pendingPaymentOrderId
                : FFAppState().paymentOrderId,
          );
        }
        return;
      }

      if (FFAppState().paymentFlowKind == TypeHgz.Wallet) {
        try {
          final credited = await touryFinalizeWalletTopUp();
          FFAppState().DonePay = credited;
          safeSetState(() {});
        } catch (e, st) {
          debugPrint('PaymentConfirm wallet: $e\n$st');
          FFAppState().DonePay = false;
          if (mounted) {
            TouryDialogs.showSnackBar(
              context,
              'wallet_error_generic'.tr(namedArgs: {'error': e.toString()}),
              type: TouryMessageType.error,
            );
          }
        }
        return;
      }

      try {
        var verify = await touryVerifyGatewayPayment(
          FFAppState().paymentOrderId,
        );
        _model.verifyResponse = verify.response;

        // External Safari/browser flow: user may still be paying — poll like WebView.
        if (TouryPaymentFlags.openPaymentInExternalBrowser &&
            verify.isPending) {
          for (var i = 0; i < 60 && mounted; i++) {
            await Future<void>.delayed(const Duration(seconds: 3));
            verify = await touryVerifyGatewayPayment(
              FFAppState().paymentOrderId,
            );
            _model.verifyResponse = verify.response;
            if (verify.isPaid || verify.isFailed) break;
          }
        }

        if (verify.isPending) {
          FFAppState().DonePay = false;
          if (mounted) {
            await touryShowPaymentIncompleteSheet(
              context,
              orderId: FFAppState().pendingPaymentOrderId.isNotEmpty
                  ? FFAppState().pendingPaymentOrderId
                  : FFAppState().paymentOrderId,
            );
          }
          return;
        }

        if (!verify.isPaid) {
          FFAppState().DonePay = false;
          // Keep unpaid order id for retry; clear only ephemeral payment secrets.
          FFAppState().clearSensitivePaymentSession();
          if (mounted) {
            await touryShowPaymentIncompleteSheet(
              context,
              orderId: FFAppState().pendingPaymentOrderId.isNotEmpty
                  ? FFAppState().pendingPaymentOrderId
                  : FFAppState().paymentOrderId,
            );
          }
          return;
        }

        FFAppState().DonePay = true;
        safeSetState(() {});

        final gatewayId = verify.orderId ?? FFAppState().paymentOrderId;
        final Map<String, dynamic> finalized;
        if (TouryPaymentFlags.useExternalPaymentApi) {
          // Webhook creates the order; poll status until bookingId appears.
          final statusBody = await PaymentApiClient().waitForPaidBooking(
            sessionId: gatewayId,
          );
          finalized = {
            'orderId': statusBody['bookingId'] ??
                statusBody['orderId'] ??
                gatewayId,
            'id': statusBody['id'] ?? gatewayId,
            'bookingCreated': statusBody['bookingCreated'],
          };
        } else {
          final cf = await TouryNGeniusService.finalizeBooking(
            sessionId: gatewayId,
            booking: TouryOrderIntegration.cloudBookingPayload(),
          );
          finalized = cf.jsonBody is Map
              ? Map<String, dynamic>.from(cf.jsonBody as Map)
              : <String, dynamic>{};
          if (cf.jsonBody is Map && (cf.jsonBody as Map).containsKey('error')) {
            throw Exception((cf.jsonBody as Map)['error']);
          }
        }
        final orderId = finalized['orderId']?.toString() ??
            finalized['id']?.toString() ??
            gatewayId;
        if (finalized.containsKey('error')) {
          throw StateError('Server booking finalization failed.');
        }
        final orderNumber = orderId;

        final settingsRows = await TouryFirestoreCache.settingsOnce(
          singleRecord: true,
        );
        final nglValue =
            settingsRows.isNotEmpty ? settingsRows.first.ngl : null;

        unawaited(
          touryNotifyAfterSuccessfulOrderPayment(
            villnow: FFAppState().villnow,
            typecarRev: FFAppState().typecarRev,
            nglValue: nglValue,
            totalsaat: FFAppState().totalsaat,
            totalmndob3: FFAppState().totalmndob3,
            currency: FFAppState().RMZCurrency,
            orderIdLabel: orderNumber,
          ),
        );

        FFAppState().totalmndob3 = 0.0;
        FFAppState().clearPendingPaymentOrder();
        FFAppState().clearSensitivePaymentSession();
        safeSetState(() {});
      } catch (e, st) {
        debugPrint('PaymentConfirm init: $e\n$st');
        FFAppState().DonePay = false;
        FFAppState().clearSensitivePaymentSession();
        if (mounted) {
          TouryDialogs.showSnackBar(
            context,
            'payment_order_save_error'.tr(),
            type: TouryMessageType.error,
          );
        }
      }
    });

    animationsMap.addAll({
      'iconOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          RotateEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'buttonOnPageLoadAnimation': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
      'iconOnPageLoadAnimation2': AnimationInfo(
        loop: true,
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          RotateEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _goToOrders() async {
    context.goNamed(List22TaskOverviewResponsiveWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              context.goNamed(List22TaskOverviewResponsiveWidget.routeName);
            },
            child: Scaffold(
            key: scaffoldKey,
            backgroundColor: colors.scaffold,
            body: SafeArea(
              top: true,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.lg,
                    vertical: DsSpacing.xxxl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: DsConstants.maxFormWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (FFAppState().DonePay == true) _buildSuccess(context),
                        if (FFAppState().DonePay == false) _buildFailure(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsFadeSlide(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: DsScaleFade(
              child: Container(
                width: 140.0,
                height: 140.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                  boxShadow: DsShadows.soft(dark: context.dsIsDark),
                ),
                child: Icon(
                  DsIcons.success,
                  color: colors.onPrimary,
                  size: DsConstants.avatarLg,
                ).animateOnPageLoad(
                    animationsMap['iconOnPageLoadAnimation1']!),
              ),
            ),
          ),
          const SizedBox(height: DsSpacing.xl),
          Text(
            FFLocalizations.of(context).getText(
              '4z6c8kax' /* Payment Confirmed! */,
            ),
            textAlign: TextAlign.center,
            style: typography.displaySmall.copyWith(color: colors.primary),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            FFLocalizations.of(context).getText(
              'u59e07ie' /* "Your request has been sent su... */,
            ),
            textAlign: TextAlign.center,
            style: typography.bodyLarge.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.xxl),
          DsButton.primary(
            label: FFLocalizations.of(context).getText(
              'p9jmmxjk' /* Go to Order */,
            ),
            icon: DsIcons.bookings,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: _goToOrders,
          ).animateOnPageLoad(animationsMap['buttonOnPageLoadAnimation']!),
        ],
      ),
    );
  }

  Widget _buildFailure(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsFadeSlide(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: DsConstants.avatarXl,
              height: DsConstants.avatarXl,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                DsIcons.error,
                color: colors.error,
                size: DsIcons.xl,
              ).animateOnPageLoad(
                  animationsMap['iconOnPageLoadAnimation2']!),
            ),
          ),
          const SizedBox(height: DsSpacing.xl),
          Text(
            FFLocalizations.of(context).getText(
              'bcn7sdi9' /* The last payment was not compl... */,
            ),
            textAlign: TextAlign.center,
            style: typography.titleMedium.copyWith(color: colors.error),
          ),
          const SizedBox(height: DsSpacing.xxl),
          DsButton.outlined(
            label: FFLocalizations.of(context).getText(
              'bu4ebz14' /* Go to Order */,
            ),
            icon: DsIcons.bookings,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: _goToOrders,
          ),
        ],
      ),
    );
  }
}

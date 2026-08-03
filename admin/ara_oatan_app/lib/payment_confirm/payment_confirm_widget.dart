import 'package:easy_localization/easy_localization.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_payment_notifications.dart';
import '/core/toury_payment_verify.dart';
import '/core/toury_ngenius_service.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_wallet_ngenius.dart';
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

      // true = عرض للعرض بعد فشل/إلغاء دون إعادة إنشاء الطلب.
      // false أو null = تحقق من البوابة وأنشئ الطلب.
      if (widget.fromWebView == true) return;

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
        final verify = await touryVerifyGatewayPayment(
          FFAppState().paymentOrderId,
        );
        _model.verifyResponse = verify.response;

        if (verify.isPending) {
          FFAppState().DonePay = false;
          if (mounted) {
            TouryDialogs.showSnackBar(
              context,
              'payment_pending_message'.tr(),
              type: TouryMessageType.warning,
            );
          }
          return;
        }

        if (!verify.isPaid) {
          FFAppState().DonePay = false;
          FFAppState().clearSensitivePaymentSession();
          if (mounted) {
            TouryDialogs.showSnackBar(
              context,
              verify.isFailed
                  ? 'payment_failed_message'.tr()
                  : 'payment_verify_error'.tr(),
              type: TouryMessageType.error,
            );
          }
          return;
        }

        FFAppState().DonePay = true;
        safeSetState(() {});

        final gatewayId = verify.orderId ?? FFAppState().paymentOrderId;
        final finalized = await TouryNGeniusService.finalizeBooking(
          sessionId: gatewayId,
          booking: TouryOrderIntegration.cloudBookingPayload(),
        );
        if (!TouryNGeniusService.httpOk(finalized)) {
          throw StateError('Server booking finalization failed.');
        }
        final orderNumber = castToType<String>(
              getJsonField(finalized.jsonBody, r'''$.orderId'''),
            ) ??
            gatewayId;

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

          return Scaffold(
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.primaryStrong],
                  ),
                  boxShadow: DsShadows.primaryGlow(dark: context.dsIsDark),
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

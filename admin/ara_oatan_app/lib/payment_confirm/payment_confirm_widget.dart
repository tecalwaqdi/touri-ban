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
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'payment_confirm_model.dart';
export 'payment_confirm_model.dart';

enum _PaymentConfirmPhase {
  verifying,
  pending,
  success,
  failed,
}

class PaymentConfirmWidget extends StatefulWidget {
  const PaymentConfirmWidget({
    super.key,
    this.fromWebView,
    this.awaitingExternalHpp,
  });

  /// true = closed/failed HPP without verified pay — keep unpaid order + retry CTA.
  final bool? fromWebView;

  /// true when HPP was opened in Safari / external browser (fallback only).
  final bool? awaitingExternalHpp;

  static String routeName = 'paymentConfirm';
  static String routePath = '/paymentConfirm';

  @override
  State<PaymentConfirmWidget> createState() => _PaymentConfirmWidgetState();
}

class _PaymentConfirmWidgetState extends State<PaymentConfirmWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PaymentConfirmModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};
  _PaymentConfirmPhase _phase = _PaymentConfirmPhase.verifying;
  int _verifyGeneration = 0;
  bool _finalizeBusy = false;
  static const int _maxPollAttempts = 10;
  static const Duration _pollInterval = Duration(seconds: 2);

  bool get _awaitingHpp => widget.awaitingExternalHpp == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = createModel(context, () => PaymentConfirmModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().paymentInProgress = false;
      safeSetState(() {});

      if (widget.fromWebView == true) {
        FFAppState().DonePay = false;
        if (mounted) {
          safeSetState(() => _phase = _PaymentConfirmPhase.failed);
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
        await _finalizeWallet();
        return;
      }

      await _runVerify(reason: 'init');
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_phase != _PaymentConfirmPhase.verifying &&
        _phase != _PaymentConfirmPhase.pending) {
      return;
    }
    if (FFAppState().paymentFlowKind == TypeHgz.Wallet) return;
    unawaited(_runVerify(reason: 'resume'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verifyGeneration++;
    _model.dispose();
    super.dispose();
  }

  Future<void> _finalizeWallet() async {
    try {
      final credited = await touryFinalizeWalletTopUp();
      FFAppState().DonePay = credited;
      if (!mounted) return;
      safeSetState(() {
        _phase = credited
            ? _PaymentConfirmPhase.success
            : _PaymentConfirmPhase.failed;
      });
    } catch (e, st) {
      debugPrint('PaymentConfirm wallet: $e\n$st');
      FFAppState().DonePay = false;
      if (mounted) {
        safeSetState(() => _phase = _PaymentConfirmPhase.failed);
        TouryDialogs.showSnackBar(
          context,
          'wallet_error_generic'.tr(namedArgs: {'error': ''}),
          type: TouryMessageType.error,
        );
      }
    }
  }

  Future<void> _runVerify({required String reason}) async {
    if (_finalizeBusy) return;
    final gen = ++_verifyGeneration;
    if (mounted) {
      safeSetState(() => _phase = _PaymentConfirmPhase.verifying);
    }

    try {
      var verify = await touryVerifyGatewayPayment(
        FFAppState().paymentOrderId,
      );
      if (!mounted || gen != _verifyGeneration) return;
      _model.verifyResponse = verify.response;

      // Bounded poll — never indefinite spinner (HPP Safari loss / slow webhook).
      final shouldPoll = verify.isPending &&
          (_awaitingHpp || TouryPaymentFlags.openPaymentInExternalBrowser);
      if (shouldPoll) {
        for (var i = 0; i < _maxPollAttempts && mounted; i++) {
          if (gen != _verifyGeneration) return;
          await Future<void>.delayed(_pollInterval);
          if (!mounted || gen != _verifyGeneration) return;
          verify = await touryVerifyGatewayPayment(
            FFAppState().paymentOrderId,
          );
          _model.verifyResponse = verify.response;
          if (verify.isPaid || verify.isFailed) break;
        }
      }

      if (!mounted || gen != _verifyGeneration) return;

      if (verify.isPending) {
        FFAppState().DonePay = false;
        safeSetState(() => _phase = _PaymentConfirmPhase.pending);
        return;
      }

      if (!verify.isPaid) {
        FFAppState().DonePay = false;
        FFAppState().clearSensitivePaymentSession();
        safeSetState(() => _phase = _PaymentConfirmPhase.failed);
        await touryShowPaymentIncompleteSheet(
          context,
          orderId: FFAppState().pendingPaymentOrderId.isNotEmpty
              ? FFAppState().pendingPaymentOrderId
              : FFAppState().paymentOrderId,
        );
        return;
      }

      _finalizeBusy = true;
      try {
        FFAppState().DonePay = true;
        final gatewayId = verify.orderId ?? FFAppState().paymentOrderId;
        final Map<String, dynamic> finalized;
        if (TouryPaymentFlags.useExternalPaymentApi) {
          final statusBody = await PaymentApiClient().waitForPaidBooking(
            sessionId: gatewayId,
            attempts: 12,
            interval: const Duration(seconds: 2),
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
        if (!mounted || gen != _verifyGeneration) return;

        final orderId = finalized['orderId']?.toString() ??
            finalized['id']?.toString() ??
            gatewayId;
        if (finalized.containsKey('error')) {
          throw StateError('Server booking finalization failed.');
        }

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
            orderIdLabel: orderId,
          ),
        );

        FFAppState().totalmndob3 = 0.0;
        FFAppState().clearPendingPaymentOrder();
        FFAppState().clearSensitivePaymentSession();
        if (!mounted || gen != _verifyGeneration) return;
        safeSetState(() => _phase = _PaymentConfirmPhase.success);
      } on PaymentApiException catch (e) {
        debugPrint('PaymentConfirm finalize pending: $e');
        if (!mounted || gen != _verifyGeneration) return;
        // Paid at gateway but booking not ready — recoverable pending.
        if (e.code == 'BOOKING_PENDING' || e.code == 'PAYMENT_PENDING') {
          FFAppState().DonePay = false;
          safeSetState(() => _phase = _PaymentConfirmPhase.pending);
          return;
        }
        FFAppState().DonePay = false;
        safeSetState(() => _phase = _PaymentConfirmPhase.failed);
        TouryDialogs.showSnackBar(
          context,
          'payment_order_save_error'.tr(),
          type: TouryMessageType.error,
        );
      }
    } catch (e, st) {
      debugPrint('PaymentConfirm verify($reason): $e\n$st');
      FFAppState().DonePay = false;
      FFAppState().clearSensitivePaymentSession();
      if (mounted && gen == _verifyGeneration) {
        safeSetState(() => _phase = _PaymentConfirmPhase.failed);
        TouryDialogs.showSnackBar(
          context,
          'payment_order_save_error'.tr(),
          type: TouryMessageType.error,
        );
      }
    } finally {
      _finalizeBusy = false;
    }
  }

  Future<void> _goToOrders() async {
    context.goNamed(List22TaskOverviewResponsiveWidget.routeName);
  }

  Future<void> _retryPayment() async {
    final id = FFAppState().pendingPaymentOrderId.isNotEmpty
        ? FFAppState().pendingPaymentOrderId
        : FFAppState().paymentOrderId;
    if (id.trim().isEmpty) {
      await _goToOrders();
      return;
    }
    try {
      final snap = await OrderRecord.getDocumentOnce(
        OrderRecord.collection.doc(id),
      );
      if (!mounted) return;
      final result = await touryRetryUnpaidOrderPayment(order: snap);
      if (!mounted) return;
      await touryNavigateAfterCardPayment(
        context,
        result: result,
        paymentFlowType: TypeHgz.Rhlh,
      );
    } catch (_) {
      if (!mounted) return;
      TouryDialogs.showSnackBar(
        context,
        'checkout_payment_temporarily_unavailable'.tr(),
        type: TouryMessageType.error,
      );
    }
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
                          if (_phase == _PaymentConfirmPhase.verifying)
                            _buildVerifying(context),
                          if (_phase == _PaymentConfirmPhase.pending)
                            _buildPending(context),
                          if (_phase == _PaymentConfirmPhase.success)
                            _buildSuccess(context),
                          if (_phase == _PaymentConfirmPhase.failed)
                            _buildFailure(context),
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

  Widget _buildVerifying(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final title = _awaitingHpp
        ? 'payment_hpp_opened_title'.tr()
        : 'payment_verifying_title'.tr();
    final body = _awaitingHpp
        ? 'payment_hpp_opened_body'.tr()
        : 'payment_verifying_body'.tr();

    return DsFadeSlide(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: DsSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: typography.titleMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPending(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsFadeSlide(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: DsSpacing.xl),
          Text(
            'payment_pending_title'.tr(),
            textAlign: TextAlign.center,
            style: typography.titleMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            'payment_pending_body'.tr(),
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.xxl),
          DsButton.primary(
            label: 'payment_recheck'.tr(),
            icon: Icons.refresh_rounded,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: () => _runVerify(reason: 'manual'),
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.outlined(
            label: 'payment_incomplete_retry'.tr(),
            icon: Icons.payment_rounded,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: _retryPayment,
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.text(
            label: 'payment_incomplete_go_orders'.tr(),
            size: DsButtonSize.lg,
            onPressed: _goToOrders,
          ),
        ],
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
          DsButton.primary(
            label: 'payment_incomplete_retry'.tr(),
            icon: Icons.payment_rounded,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: _retryPayment,
          ),
          const SizedBox(height: DsSpacing.sm),
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

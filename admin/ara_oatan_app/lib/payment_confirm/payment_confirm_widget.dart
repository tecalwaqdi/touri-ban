import 'package:easy_localization/easy_localization.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_payment_flags.dart';
import '/core/toury_payment_flow.dart';
import '/core/toury_payment_notifications.dart';
import '/core/toury_payment_verify.dart';
import '/core/toury_ngenius_service.dart';
import '/core/toury_order_integration.dart';
import '/core/toury_order_meta.dart';
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
    this.sessionId,
    this.autoResumeStaleHpp,
  });

  /// true = closed/failed HPP without verified pay — keep unpaid order + retry CTA.
  final bool? fromWebView;

  /// true when HPP was opened in Safari / external browser (fallback only).
  final bool? awaitingExternalHpp;

  /// Optional payment session id from deep-link return (external HPP).
  final String? sessionId;

  /// Dead N-Genius link detected — mint a fresh session via forceRefreshSession.
  final bool? autoResumeStaleHpp;

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
  String? _extraHoursOrderId;
  bool get _isExtraHours =>
      _extraHoursOrderId != null ||
      FFAppState().paymentFlowKind == TypeHgz.Saat;
  static const int _maxPollAttempts = 10;
  static const Duration _pollInterval = Duration(seconds: 2);

  /// Cap automatic stale-HPP force-refresh so a broken outlet cannot loop.
  static int _staleHppAutoResumeAttempts = 0;

  bool get _awaitingHpp => widget.awaitingExternalHpp == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = createModel(context, () => PaymentConfirmModel());

    final deepLinkSession = widget.sessionId?.trim() ?? '';
    if (deepLinkSession.isNotEmpty) {
      FFAppState().update(() {
        if (FFAppState().paymentOrderId.trim().isEmpty) {
          FFAppState().paymentOrderId = deepLinkSession;
        }
        if (FFAppState().pendingPaymentOrderId.trim().isEmpty) {
          FFAppState().pendingPaymentOrderId = deepLinkSession;
        }
      });
    }

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().paymentInProgress = false;
      safeSetState(() {});

      if (widget.autoResumeStaleHpp == true && !_isExtraHours) {
        if (mounted) {
          safeSetState(() => _phase = _PaymentConfirmPhase.pending);
        }
        if (_staleHppAutoResumeAttempts >= 1) {
          if (mounted) {
            TouryDialogs.showSnackBar(
              context,
              'checkout_payment_link_expired'.tr(),
              type: TouryMessageType.warning,
            );
          }
          return;
        }
        _staleHppAutoResumeAttempts++;
        if (mounted) {
          TouryDialogs.showSnackBar(
            context,
            'checkout_payment_link_expired'.tr(),
            type: TouryMessageType.warning,
          );
        }
        await _retryPayment();
        return;
      }

      if (widget.fromWebView == true && !_isExtraHours) {
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

      // Never trap the user on a spinner-only HPP screen.
      if (_awaitingHpp && mounted) {
        safeSetState(() => _phase = _PaymentConfirmPhase.pending);
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
    if (mounted && !_awaitingHpp) {
      safeSetState(() => _phase = _PaymentConfirmPhase.verifying);
    }

    try {
      var verify = await touryVerifyGatewayPayment(
        FFAppState().paymentOrderId,
        extraHours: _isExtraHours,
      );
      if (!mounted || gen != _verifyGeneration) return;
      _model.verifyResponse = verify.response;

      // Bounded poll — never indefinite spinner (HPP Safari / SDK webhook lag).
      final shouldPoll = touryShouldPollPaymentStatus(
        isPending: verify.isPending || verify.isError,
        awaitingExternalHpp: _awaitingHpp,
        openPaymentInExternalBrowser:
            TouryPaymentFlags.openPaymentInExternalBrowser,
        preferMobileSdk: TouryPaymentFlags.preferMobileSdk,
      );
      if (shouldPoll) {
        for (var i = 0; i < _maxPollAttempts && mounted; i++) {
          if (gen != _verifyGeneration) return;
          await Future<void>.delayed(_pollInterval);
          if (!mounted || gen != _verifyGeneration) return;
          verify = await touryVerifyGatewayPayment(
            FFAppState().paymentOrderId,
            extraHours: _isExtraHours,
          );
          _model.verifyResponse = verify.response;
          if (verify.isPaid || verify.isFailed) break;
        }
      }

      if (!mounted || gen != _verifyGeneration) return;

      final body = verify.response?.jsonBody;
      if (_isExtraHours || (body is Map && body['purpose'] == 'extra_hours')) {
        _extraHoursOrderId = body is Map
            ? body['orderId']?.toString()
            : FFAppState().revOrderSaatExtr?.id;
        FFAppState().paymentFlowKind = TypeHgz.Saat;
        if (!verify.isPaid) {
          FFAppState().DonePay = false;
          safeSetState(() => _phase = verify.isFailed
              ? _PaymentConfirmPhase.failed
              : _PaymentConfirmPhase.pending);
          return;
        }
        _finalizeBusy = true;
        final result = await TouryNGeniusService.finalizeExtraHours(
          sessionId: verify.orderId ?? FFAppState().paymentOrderId,
        );
        if (!mounted || gen != _verifyGeneration) return;
        if (!TouryNGeniusService.httpOk(result) ||
            result.jsonBody['applied'] != true) {
          FFAppState().DonePay = false;
          safeSetState(() => _phase = _PaymentConfirmPhase.failed);
          TouryDialogs.showSnackBar(
              context, 'extra_hours_paid_not_applied'.tr(),
              type: TouryMessageType.error);
          return;
        }
        _extraHoursOrderId = result.jsonBody['orderId']?.toString();
        FFAppState().paymentInProgress = false;
        FFAppState().DonePay = true;
        await _goToBooking();
        return;
      }

      // Transient API/network errors → recoverable pending, not a dead-end.
      if (verify.isRecoverablePending) {
        FFAppState().DonePay = false;
        safeSetState(() => _phase = _PaymentConfirmPhase.pending);
        return;
      }

      if (!verify.isPaid) {
        FFAppState().DonePay = false;
        // Keep pendingPaymentOrderId so retry/orders resume still works.
        FFAppState().paymentInProgress = false;
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
            'orderId':
                statusBody['bookingId'] ?? statusBody['orderId'] ?? gatewayId,
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

        // Online drivers only (`ngl == true`). Settings.ngl is unrelated.
        unawaited(
          touryNotifyAfterSuccessfulOrderPayment(
            villnow: FFAppState().villnow,
            typecarRev: FFAppState().typecarRev,
            nglValue: true,
            totalsaat: FFAppState().totalsaat,
            totalmndob3: FFAppState().totalmndob3,
            currency: FFAppState().RMZCurrency,
            orderIdLabel: orderId,
          ),
        );

        FFAppState().totalmndob3 = 0.0;
        FFAppState().clearPendingPaymentOrder();
        FFAppState().clearSensitivePaymentSession();
        _staleHppAutoResumeAttempts = 0;
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
      FFAppState().paymentInProgress = false;
      // Keep session ids — user can verify/retry after a transient failure.
      if (mounted && gen == _verifyGeneration) {
        safeSetState(() => _phase = _PaymentConfirmPhase.pending);
        TouryDialogs.showSnackBar(
          context,
          'payment_pending_body'.tr(),
          type: TouryMessageType.warning,
        );
      }
    } finally {
      _finalizeBusy = false;
    }
  }

  Future<void> _goToOrders() async {
    FFAppState().paymentInProgress = false;
    if (!mounted) return;
    context.goNamed(List22TaskOverviewResponsiveWidget.routeName);
  }

  /// Leave payment UI without cancelling gateway (safe while webhook may land).
  Future<void> _leavePaymentSafely() async {
    _verifyGeneration++;
    FFAppState().paymentInProgress = false;
    if (!mounted) return;
    await _goToBooking();
  }

  Future<void> _goToBooking() async {
    FFAppState().paymentInProgress = false;
    final id = _isExtraHours
        ? (_extraHoursOrderId ?? FFAppState().revOrderSaatExtr?.id ?? '')
        : (FFAppState().pendingPaymentOrderId.isNotEmpty
            ? FFAppState().pendingPaymentOrderId
            : FFAppState().paymentOrderId);
    if (id.trim().isEmpty) {
      await _goToOrders();
      return;
    }
    try {
      final snap = await OrderRecord.getDocumentOnce(
        OrderRecord.collection.doc(id),
      );
      if (!mounted) return;
      context.goNamed(
        TfaselOrderWidget.routeName,
        queryParameters: {
          'idorder': serializeParam(snap, ParamType.Document),
        }.withoutNulls,
        extra: <String, dynamic>{'idorder': snap},
      );
    } catch (_) {
      await _goToOrders();
    }
  }

  Future<void> _cancelAttempt() async {
    if (_isExtraHours) {
      await _leavePaymentSafely();
      return;
    }
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('payment_cancel_attempt_title'.tr()),
            content: Text('payment_cancel_attempt_body'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('order_cancel_confirm_back'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('checkout_cancel_payment_attempt'.tr()),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    final sessionId = FFAppState().paymentOrderId.trim();
    final bookingId = FFAppState().pendingPaymentOrderId.trim();
    final done = await touryCancelPaymentAttempt(
      sessionId: sessionId.isNotEmpty ? sessionId : null,
      bookingId: bookingId.isNotEmpty ? bookingId : null,
    );
    if (!mounted) return;
    FFAppState().paymentInProgress = false;
    TouryDialogs.showSnackBar(
      context,
      done
          ? 'payment_attempt_cancelled'.tr()
          : 'payment_back_to_booking'.tr(),
      type: done ? TouryMessageType.success : TouryMessageType.info,
    );
    // Always leave — never trap the user if cancel API is down.
    await _goToBooking();
  }

  Future<void> _retryPayment() async {
    if (_isExtraHours) {
      await _goToBooking();
      return;
    }
    final bookingId = FFAppState().pendingPaymentOrderId.trim();
    final sessionId = FFAppState().paymentOrderId.trim();
    final id = bookingId.isNotEmpty ? bookingId : sessionId;
    if (id.isEmpty) {
      TouryDialogs.showSnackBar(
        context,
        'payment_incomplete_go_orders'.tr(),
        type: TouryMessageType.info,
      );
      await _goToOrders();
      return;
    }
    try {
      final snap = await OrderRecord.getDocumentOnce(
        OrderRecord.collection.doc(id),
      );
      if (!mounted) return;
      if (!snap.isAwaitingPayment) {
        // Already paid / no longer payable — verify instead of a dead retry.
        await _runVerify(reason: 'retry_not_awaiting');
        return;
      }
      final result =
          await touryRetryUnpaidOrderPayment(context: context, order: snap);
      if (!mounted) return;
      if (!result.success) {
        final status = (result.status ?? '').toLowerCase();
        final msg = result.errorMessage ??
            'checkout_payment_temporarily_unavailable'.tr();
        // Stale session / not payable: leave to booking with a clear message.
        if (status == 'not_awaiting' || status == 'not_payable') {
          TouryDialogs.showSnackBar(
            context,
            msg,
            type: TouryMessageType.info,
          );
          await _leavePaymentSafely();
          return;
        }
        TouryDialogs.showSnackBar(
          context,
          msg,
          type: status == 'cancelled'
              ? TouryMessageType.warning
              : TouryMessageType.error,
        );
        return;
      }
      await touryNavigateAfterCardPayment(
        context,
        result: result,
        paymentFlowType: TypeHgz.Rhlh,
      );
    } catch (_) {
      if (!mounted) return;
      // Session id ≠ Firestore order id after cold resume — offer orders path.
      TouryDialogs.showSnackBar(
        context,
        'payment_incomplete_go_orders'.tr(),
        type: TouryMessageType.warning,
      );
      await _goToOrders();
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
              unawaited(_leavePaymentSafely());
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                title: _phase == _PaymentConfirmPhase.success
                    ? FFLocalizations.of(context).getText('4z6c8kax')
                    : (_phase == _PaymentConfirmPhase.failed
                        ? FFLocalizations.of(context).getText('bcn7sdi9')
                        : 'payment_pending_title'.tr()),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () {
                    if (_phase == _PaymentConfirmPhase.success) {
                      unawaited(_goToOrders());
                    } else {
                      unawaited(_leavePaymentSafely());
                    }
                  },
                ),
              ),
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
          const SizedBox(height: DsSpacing.xxl),
          DsButton.primary(
            label: 'checkout_check_payment_status'.tr(),
            icon: Icons.refresh_rounded,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: () => _runVerify(reason: 'manual'),
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.outlined(
            label: 'payment_back_to_booking'.tr(),
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: _leavePaymentSafely,
          ),
          if (!_isExtraHours) ...[
            const SizedBox(height: DsSpacing.sm),
            DsButton.text(
              label: 'checkout_cancel_payment_attempt'.tr(),
              size: DsButtonSize.lg,
              onPressed: _cancelAttempt,
            ),
          ],
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
            label: 'checkout_check_payment_status'.tr(),
            icon: Icons.refresh_rounded,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: () => _runVerify(reason: 'manual'),
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.outlined(
            label: 'checkout_resume_payment'.tr(),
            icon: Icons.payment_rounded,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: _retryPayment,
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.outlined(
            label: (_isExtraHours
                    ? 'payment_back_to_booking'
                    : 'checkout_cancel_payment_attempt')
                .tr(),
            icon: Icons.close_rounded,
            size: DsButtonSize.lg,
            expanded: true,
            onPressed: _cancelAttempt,
          ),
          const SizedBox(height: DsSpacing.sm),
          DsButton.text(
            label: 'payment_back_to_booking'.tr(),
            size: DsButtonSize.lg,
            onPressed: _leavePaymentSafely,
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
                ).animateOnPageLoad(animationsMap['iconOnPageLoadAnimation1']!),
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
              ).animateOnPageLoad(animationsMap['iconOnPageLoadAnimation2']!),
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

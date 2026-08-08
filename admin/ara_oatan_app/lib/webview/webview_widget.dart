import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/schema/enums/enums.dart';
import '/core/toury_ngenius_service.dart';
import '/core/toury_payment_verify.dart';
import '/core/toury_wallet_ngenius.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_web_view.dart';
import '/index.dart';
import 'webview_model.dart';

export 'webview_model.dart';

class WebviewWidget extends StatefulWidget {
  const WebviewWidget({
    super.key,
    required this.url,
  });

  final String? url;

  static String routeName = 'webview';
  static String routePath = '/webview';

  @override
  State<WebviewWidget> createState() => _WebviewWidgetState();
}

class _WebviewWidgetState extends State<WebviewWidget> {
  late WebviewModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _verifyTimer;
  bool _finalizingPayment = false;
  int _pollAttempts = 0;

  /// Cap polling so a stuck 3DS session cannot run forever (~3 minutes).
  static const int _maxPollAttempts = 60;
  static const Duration _pollInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WebviewModel());
    _startThreeDsPolling();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  void _startThreeDsPolling() {
    _verifyTimer?.cancel();
    _pollAttempts = 0;
    _verifyTimer = Timer.periodic(_pollInterval, (_) async {
      if (_finalizingPayment || !mounted) return;

      _pollAttempts += 1;
      if (_pollAttempts > _maxPollAttempts) {
        _verifyTimer?.cancel();
        if (!mounted) return;
        FFAppState().update(() {
          FFAppState().DonePay = false;
          FFAppState().paymentInProgress = false;
        });
        DsSnackBar.show(
          context,
          message: 'payment_pending_message'.tr(),
          tone: DsSnackTone.warning,
        );
        context.pushReplacementNamed(
          PaymentConfirmWidget.routeName,
          queryParameters: {
            'fromWebView': serializeParam(true, ParamType.bool),
          }.withoutNulls,
        );
        return;
      }

      final orderId = FFAppState().paymentOrderId.trim();
      if (orderId.isEmpty) return;

      final verify = await touryVerifyGatewayPayment(orderId);
      if (verify.isFailed) {
        _verifyTimer?.cancel();
        if (!mounted) return;
        FFAppState().update(() {
          FFAppState().DonePay = false;
          FFAppState().paymentInProgress = false;
        });
        context.pushReplacementNamed(
          PaymentConfirmWidget.routeName,
          queryParameters: {
            'fromWebView': serializeParam(true, ParamType.bool),
          }.withoutNulls,
        );
        return;
      }

      if (!verify.isPaid) return;

      _finalizingPayment = true;
      _verifyTimer?.cancel();

      if (FFAppState().paymentFlowKind == TypeHgz.Wallet) {
        final credited = await touryFinalizeWalletTopUp();
        FFAppState().update(() {
          FFAppState().DonePay = credited;
          FFAppState().paymentInProgress = false;
        });
        if (!mounted) return;
        context.goNamed(List22TaskOverviewResponsiveWidget.routeName);
        return;
      }

      if (FFAppState().paymentFlowKind == TypeHgz.Saat) {
        final finalized = await TouryNGeniusService.finalizeExtraHours(
          sessionId: verify.orderId ?? orderId,
        );
        FFAppState().update(() {
          FFAppState().DonePay = TouryNGeniusService.httpOk(finalized);
          FFAppState().paymentInProgress = false;
        });
        if (!mounted) return;
        context.goNamed(List22TaskOverviewResponsiveWidget.routeName);
        return;
      }

      if (!mounted) return;
      // fromWebView:false → PaymentConfirm re-queries Render status (never trusts HPP return).
      context.pushReplacementNamed(
        PaymentConfirmWidget.routeName,
        queryParameters: {
          'fromWebView': serializeParam(false, ParamType.bool),
        }.withoutNulls,
      );
    });
  }

  Future<void> _closePage(BuildContext context) async {
    final verify = await touryVerifyGatewayPayment(
      FFAppState().paymentOrderId,
    );
    if (!context.mounted) return;
    if (verify.isPending) {
      DsSnackBar.show(
        context,
        message: 'payment_pending_message'.tr(),
        tone: DsSnackTone.warning,
      );
      return;
    }
    if (!verify.isPaid) {
      FFAppState().DonePay = false;
      if (!context.mounted) return;
      context.pushReplacementNamed(
        PaymentConfirmWidget.routeName,
        queryParameters: {
          'fromWebView': serializeParam(
            true,
            ParamType.bool,
          ),
        }.withoutNulls,
      );
      return;
    }

    if (FFAppState().paymentFlowKind == TypeHgz.Wallet) {
      final credited = await touryFinalizeWalletTopUp();
      if (!context.mounted) return;
      if (credited) {
        context.goNamed(
          List22TaskOverviewResponsiveWidget.routeName,
        );
      }
      return;
    }

    if (FFAppState().paymentFlowKind == TypeHgz.Saat) {
      final finalized = await TouryNGeniusService.finalizeExtraHours(
        sessionId: verify.orderId ?? FFAppState().paymentOrderId,
      );
      if (!TouryNGeniusService.httpOk(finalized)) {
        return;
      }
      FFAppState().DonePay = true;
      FFAppState().paymentInProgress = false;
      FFAppState().clearSensitivePaymentSession();
      if (!context.mounted) return;
      context.goNamed(
        List22TaskOverviewResponsiveWidget.routeName,
      );
      return;
    }

    if (!context.mounted) return;
    context.pushReplacementNamed(
      PaymentConfirmWidget.routeName,
      queryParameters: {
        'fromWebView': serializeParam(
          false,
          ParamType.bool,
        ),
      }.withoutNulls,
    );
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _closePage(context);
            },
            child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                title: FFLocalizations.of(context).getText(
                  'xnttfo6b' /* Pay the reservation fee */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => _closePage(context),
                ),
              ),
              body: SafeArea(
                top: true,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DsSpacing.md,
                        DsSpacing.sm,
                        DsSpacing.md,
                        DsSpacing.sm,
                      ),
                      child: DsCard(
                        color: colors.warningContainer,
                        bordered: false,
                        padding: const EdgeInsets.all(DsSpacing.sm),
                        child: Row(
                          children: [
                            Icon(
                              DsIcons.warning,
                              size: DsIcons.sm,
                              color: colors.warning,
                            ),
                            const SizedBox(width: DsSpacing.xs),
                            Expanded(
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'b9sdhl84' /* Please do not close the page u... */,
                                ),
                                style: typography.bodySmall.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: DsSpacing.xs),
                            DsButton.danger(
                              label: FFLocalizations.of(context).getText(
                                'mu3vm7cj' /* Close Page */,
                              ),
                              icon: DsIcons.close,
                              size: DsButtonSize.sm,
                              onPressed: () => _closePage(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: DsRadius.lgRadius,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return FlutterFlowWebView(
                              content: widget.url!,
                              bypass: false,
                              height: constraints.maxHeight,
                              verticalScroll: false,
                              horizontalScroll: false,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/schema/enums/enums.dart';
import '/core/toury_ngenius_service.dart';
import '/core/toury_payment_error_messages.dart';
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
  bool _handledProviderErrorPage = false;
  bool _closing = false;
  int _pollAttempts = 0;
  bool get _isExtraHours => FFAppState().paymentFlowKind == TypeHgz.Saat;

  /// Cap polling so a stuck 3DS session cannot run forever (~90s).
  static const int _maxPollAttempts = 30;
  static const Duration _pollInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WebviewModel());
    _startThreeDsPolling();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  bool _urlLooksLikeProviderError(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';
    final path = uri?.path.toLowerCase() ?? '';

    final isPaypage = host.contains('paypage') ||
        host.contains('ngenius-payments.com');
    if (!isPaypage) return false;

    final looksLikeProviderError = lower.contains('error') ||
        path.contains('error') ||
        lower.contains('not-found') ||
        lower.contains('notfound');
    final paypageWithoutCode = host.startsWith('paypage.') &&
        uri != null &&
        !uri.queryParameters.containsKey('code');
    return looksLikeProviderError || paypageWithoutCode;
  }

  void _onPaymentPageFinished(String rawUrl) {
    if (_finalizingPayment || _handledProviderErrorPage) return;

    final url = rawUrl.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';

    assert(() {
      // ignore: avoid_print
      print('payment_webview_host=$host path=${uri?.path ?? ''}');
      return true;
    }());

    final lower = url.toLowerCase();
    final isPaymentReturnPath = lower.contains('payment-return') ||
        (uri?.path.toLowerCase().contains('payment-return') ?? false);
    final isKnownReturnHost = host.contains('web.app') ||
        host.contains('onrender.com') ||
        host == 'touri-ban.onrender.com';
    if (isKnownReturnHost && isPaymentReturnPath) {
      return;
    }

    if (!_urlLooksLikeProviderError(url)) return;
    unawaited(_recoverStaleHpp(reason: 'provider_error_url'));
  }

  void _onPaymentPageBodyText(String rawUrl, String bodyText) {
    if (_finalizingPayment || _handledProviderErrorPage) return;
    final host = Uri.tryParse(rawUrl)?.host.toLowerCase() ?? '';
    final onPaypage = host.contains('paypage') ||
        host.contains('ngenius-payments.com');
    if (!onPaypage && !_urlLooksLikeProviderError(rawUrl)) return;
    if (!touryIsMissingOrExpiredPaymentLinkText(bodyText)) return;
    unawaited(_recoverStaleHpp(reason: 'missing_payment_link_body'));
  }

  /// Dead / expired HPP must not leave the user on "still processing".
  /// Keep booking id so resume can forceRefreshSession and mint a new link.
  Future<void> _recoverStaleHpp({required String reason}) async {
    if (_handledProviderErrorPage || _finalizingPayment) return;
    _handledProviderErrorPage = true;
    _verifyTimer?.cancel();
    if (kDebugMode) {
      debugPrint('payment_webview_stale_hpp reason=$reason');
    }

    FFAppState().update(() {
      FFAppState().DonePay = false;
      FFAppState().paymentInProgress = false;
      // Keep pendingPaymentOrderId + paymentOrderId for force-refresh resume.
      // Do NOT clear ElectronicPayment — that breaks checkout resume flags.
    });

    if (!mounted) return;
    if (_isExtraHours) {
      DsSnackBar.show(
        context,
        message: TouryPaymentErrorKeys.linkExpired.tr(),
        tone: DsSnackTone.warning,
      );
      Navigator.pop(context);
      return;
    }

    DsSnackBar.show(
      context,
      message: TouryPaymentErrorKeys.linkExpired.tr(),
      tone: DsSnackTone.warning,
    );
    if (!mounted) return;
    context.pushReplacementNamed(
      PaymentConfirmWidget.routeName,
      queryParameters: {
        'fromWebView': serializeParam(false, ParamType.bool),
        'awaitingExternalHpp': serializeParam(false, ParamType.bool),
        'autoResumeStaleHpp': serializeParam(true, ParamType.bool),
      }.withoutNulls,
    );
  }

  void _startThreeDsPolling() {
    _verifyTimer?.cancel();
    _pollAttempts = 0;
    _verifyTimer = Timer.periodic(_pollInterval, (_) async {
      if (_finalizingPayment || !mounted || _handledProviderErrorPage) return;

      _pollAttempts += 1;
      if (_pollAttempts > _maxPollAttempts) {
        _verifyTimer?.cancel();
        if (!mounted) return;
        // Long pending on HPP without paid/failed → treat as stale session.
        await _recoverStaleHpp(reason: 'poll_timeout');
        return;
      }

      final orderId = FFAppState().paymentOrderId.trim();
      if (orderId.isEmpty) return;

      final verify =
          await touryVerifyGatewayPayment(orderId, extraHours: _isExtraHours);
      if (_handledProviderErrorPage || !mounted) return;

      if (verify.isFailed) {
        _verifyTimer?.cancel();
        if (!mounted) return;
        FFAppState().update(() {
          FFAppState().DonePay = false;
          FFAppState().paymentInProgress = false;
        });
        if (_isExtraHours) {
          Navigator.pop(context);
          return;
        }
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
          FFAppState().DonePay = TouryNGeniusService.httpOk(finalized) &&
              finalized.jsonBody['applied'] == true;
          FFAppState().paymentInProgress = false;
        });
        if (!mounted) return;
        if (!FFAppState().DonePay) {
          DsSnackBar.show(context,
              message: 'extra_hours_paid_not_applied'.tr(),
              tone: DsSnackTone.error);
        }
        Navigator.pop(context);
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
    if (_closing) return;
    _closing = true;
    _verifyTimer?.cancel();

    TouryPaymentVerification verify;
    try {
      verify = await touryVerifyGatewayPayment(
        FFAppState().paymentOrderId,
        extraHours: _isExtraHours,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => const TouryPaymentVerification(
          result: TouryPaymentVerifyResult.error,
        ),
      );
    } catch (_) {
      verify = const TouryPaymentVerification(
        result: TouryPaymentVerifyResult.error,
      );
    }

    if (!context.mounted) return;
    if (_isExtraHours && !verify.isPaid) {
      FFAppState().paymentInProgress = false;
      Navigator.pop(context);
      return;
    }

    // Never trap the user on WebView — route to PaymentConfirm recovery.
    if (verify.isPending || verify.isError) {
      FFAppState().paymentInProgress = false;
      if (!context.mounted) return;
      context.pushReplacementNamed(
        PaymentConfirmWidget.routeName,
        queryParameters: {
          'fromWebView': serializeParam(false, ParamType.bool),
          'awaitingExternalHpp': serializeParam(false, ParamType.bool),
        }.withoutNulls,
      );
      return;
    }
    if (!verify.isPaid) {
      FFAppState().DonePay = false;
      FFAppState().paymentInProgress = false;
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
      if (!TouryNGeniusService.httpOk(finalized) ||
          finalized.jsonBody['applied'] != true) {
        if (context.mounted) {
          DsSnackBar.show(context,
              message: 'extra_hours_paid_not_applied'.tr(),
              tone: DsSnackTone.error);
        }
        _closing = false;
        return;
      }
      FFAppState().DonePay = true;
      FFAppState().paymentInProgress = false;
      FFAppState().clearSensitivePaymentSession();
      if (!context.mounted) return;
      Navigator.pop(context);
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
              unawaited(_closePage(context));
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
                    onPressed: () => unawaited(_closePage(context)),
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
                          elevated: true,
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
                                onPressed: () => unawaited(_closePage(context)),
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
                                onPageFinished: _onPaymentPageFinished,
                                onPageBodyText: _onPaymentPageBodyText,
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

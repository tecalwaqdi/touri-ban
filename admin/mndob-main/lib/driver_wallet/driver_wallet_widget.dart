import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/driver_country_service.dart';
import '/core/driver_payment_api_client.dart';
import '/core/driver_payment_flags.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_wallet_service.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_money_display.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'driver_wallet_model.dart';
export 'driver_wallet_model.dart';

class DriverWalletWidget extends StatefulWidget {
  const DriverWalletWidget({super.key});

  static String routeName = 'DriverWallet';
  static String routePath = '/driverWallet';

  @override
  State<DriverWalletWidget> createState() => _DriverWalletWidgetState();
}

class _DriverWalletWidgetState extends State<DriverWalletWidget> {
  late DriverWalletModel _model;
  bool _busy = false;

  static const _topUpPackages = [100.0, 200.0, 300.0, 500.0];

  String get _fallbackCurrency {
    final iso = DriverCountryService.currentIso2();
    return TouryCountryRegistry.currencyForIso(iso);
  }

  DateFormat get _df {
    final code = Localizations.localeOf(context).languageCode;
    return DateFormat('yyyy-MM-dd HH:mm', code);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverWalletModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _topUp(double amountSar) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (DriverPaymentFlags.useExternalWalletTopUp) {
        await _topUpViaPaymentApi(amountSar);
      } else {
        await _topUpViaLegacyCallable(amountSar);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _topUpViaPaymentApi(double amountSar) async {
    final packageId = 'sar_${amountSar.toInt()}';
    final idem =
        'wallet_${currentUserUid}_${amountSar.toInt()}_${DateTime.now().millisecondsSinceEpoch}';
    final client = DriverPaymentApiClient();
    try {
      final res = await client.createWalletTopUp(
        idempotencyKey: idem,
        amountMajor: amountSar,
        packageId: packageId,
        email: currentUserEmail,
        description: 'Wallet top-up',
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      await _openHostedPageAndWaitForCredit(client, res, amountSar);
    } on DriverPaymentApiException catch (e) {
      if (!mounted) return;
      await _showTopUpFailed(retryAmount: amountSar, detail: e.code);
    } catch (_) {
      if (!mounted) return;
      await _showTopUpFailed(retryAmount: amountSar);
    }
  }

  Future<void> _openHostedPageAndWaitForCredit(
    DriverPaymentApiClient client,
    Map<String, dynamic> res,
    double amountSar,
  ) async {
    final url = (res['paymentUrl'] ??
            res['payment_url'] ??
            res['threeDsUrl'] ??
            res['three_ds_url'] ??
            '')
        .toString();
    final paymentId = (res['id'] ?? '').toString();
    if (url.isEmpty || paymentId.isEmpty) {
      await _showTopUpFailed(retryAmount: amountSar);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      await _showTopUpFailed(retryAmount: amountSar);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;

    final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(driverTr(context, 'Top up wallet')),
            content: Text(
              driverTr(
                context,
                'Complete payment in the browser, then confirm here. Balance updates only after server confirmation.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(driverTr(context, 'Cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(driverTr(context, 'Confirm')),
              ),
            ],
          ),
        ) ??
        false;

    if (!proceed || !mounted) {
      await _showTopUpFailed(retryAmount: amountSar);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await client.waitForWalletCredit(sessionId: paymentId);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(driverTr(context, 'Wallet top-up succeeded')),
          ),
        );
        safeSetState(() {});
      }
    } on DriverPaymentApiException catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await _showTopUpFailed(retryAmount: amountSar);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await _showTopUpFailed(retryAmount: amountSar);
      }
    }
  }

  Future<void> _showTopUpFailed({double? retryAmount, String? detail}) async {
    if (!mounted) return;
    final base = driverTr(context, 'Wallet top-up failed');
    final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(driverTr(context, 'Top up wallet')),
            content: Text(
              detail == null || detail.isEmpty ? base : '$base\n($detail)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(driverTr(context, 'Cancel')),
              ),
              if (retryAmount != null && retryAmount > 0)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(driverTr(context, 'Retry')),
                ),
            ],
          ),
        ) ??
        false;
    if (retry && retryAmount != null && retryAmount > 0 && mounted) {
      await _topUp(retryAmount);
    }
  }

  /// Legacy Firebase callable path (rollback only).
  Future<void> _topUpViaLegacyCallable(double amountSar) async {
    final packageId = 'sar_${amountSar.toInt()}';
    final idem =
        'wallet_${currentUserUid}_${amountSar.toInt()}_${DateTime.now().millisecondsSinceEpoch}';
    final res = await makeCloudCall('createNGeniusPayment', {
      'paymentPurpose': 'wallet',
      'packageId': packageId,
      'amountMajor': amountSar,
      'idempotencyKey': idem,
      'description': 'Wallet top-up — $currentUserDisplayName',
    });
    if (!mounted) return;
    if (res['error'] != null) {
      await _showTopUpFailed(
        retryAmount: amountSar,
        detail: res['error']?.toString(),
      );
      return;
    }
    final url = (res['payment_url'] ??
            res['paymentUrl'] ??
            res['three_ds_url'] ??
            res['redirectUrl'] ??
            '')
        .toString();
    final paymentId =
        (res['id'] ?? res['paymentId'] ?? res['sessionId'] ?? '').toString();
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (paymentId.isEmpty || !mounted) {
      await _showTopUpFailed(retryAmount: amountSar);
      return;
    }

    final done = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(driverTr(context, 'Top up wallet')),
            content: Text(
              driverTr(
                context,
                'Complete payment in the browser, then confirm here. Balance updates only after server confirmation.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(driverTr(context, 'Cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(driverTr(context, 'Confirm')),
              ),
            ],
          ),
        ) ??
        false;
    if (!done || !mounted) {
      await _showTopUpFailed(retryAmount: amountSar);
      return;
    }

    final fin = await makeCloudCall('finalizeNGeniusWalletTopUp', {
      'id': paymentId,
    });
    if (!mounted) return;
    if (fin['error'] != null && fin['credited'] != true) {
      await _showTopUpFailed(
        retryAmount: amountSar,
        detail: fin['error']?.toString(),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(driverTr(context, 'Wallet top-up succeeded'))),
    );
    safeSetState(() {});
  }

  Future<void> _payCompany(double balance) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(driverTr(context, 'Pay company')),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: driverTr(context, 'Amount'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(driverTr(context, 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, v);
            },
            child: Text(driverTr(context, 'Confirm')),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0 || !mounted) return;
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(driverTr(context, 'Insufficient wallet balance')),
        ),
      );
      return;
    }

    var confirmBelowMin = false;
    if (balance - amount < DriverWalletRules.minCashWalletBalance) {
      final warn = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(driverTr(context, 'Confirm')),
              content: Text(
                driverTr(
                  context,
                  'After payment your balance will be below the cash-order minimum and you will not receive cash orders until you top up.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(driverTr(context, 'Cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(driverTr(context, 'Confirm')),
                ),
              ],
            ),
          ) ??
          false;
      if (!warn) return;
      confirmBelowMin = true;
    }

    setState(() => _busy = true);
    try {
      final key =
          'cp_${currentUserUid}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final res = await makeCloudCall('payCompanyFromWallet', {
        'amount': amount,
        'confirmBelowMin': confirmBelowMin,
        'idempotencyKey': key,
        'reference': key,
      });
      if (!mounted) return;
      if (res['error'] != null || res['ok'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              driverTr(
                context,
                (res['error'] ?? 'Something went wrong. Please try again.')
                    .toString(),
              ),
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            driverTr(
              context,
              res['alreadyProcessed'] == true
                  ? 'Payment already recorded'
                  : 'Company payment completed',
            ),
          ),
        ),
      );
      safeSetState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _txLabel(String type) {
    switch (type) {
      case 'top_up':
      case 'credit':
        return driverTr(context, 'Top up');
      case 'company_payment':
        return driverTr(context, 'Pay company');
      case 'debit':
        return driverTr(context, 'Debit');
      case 'admin_adjustment':
        return driverTr(context, 'Admin adjustment');
      default:
        return type.isEmpty ? driverTr(context, 'Transaction') : type;
    }
  }

  String _txStatus(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'completed':
      case 'complete':
      case 'success':
      case 'succeeded':
        return driverTr(context, 'completed');
      case 'pending':
        return driverTr(context, 'pending');
      case 'failed':
      case 'error':
        return driverTr(context, 'failed');
      default:
        if (status.trim().isEmpty) return driverTr(context, 'completed');
        return driverTr(context, status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Scaffold(
            backgroundColor: colors.scaffold,
            appBar: DriverMainAppBar(
              title: driverTr(context, 'Wallet'),
            ),
            body: SafeArea(
              child: StreamBuilder(
                stream: DriverWalletService.walletStream(),
                builder: (context, walletSnap) {
                  if (walletSnap.connectionState == ConnectionState.waiting &&
                      !walletSnap.hasData) {
                    return const DsLoading();
                  }
                  final wallet = walletSnap.data;
                  final currency = (wallet?.currency ?? '').trim().isNotEmpty
                      ? wallet!.currency
                      : _fallbackCurrency;
                  final balance = wallet?.currentBalance ?? 0.0;
                  final cashOk =
                      balance >= DriverWalletRules.minCashWalletBalance;
                  final unpaid =
                      valueOrDefault(currentUserDocument?.totalApp, 0);

                  return StreamBuilder(
                    stream: DriverWalletService.transactionsStream(),
                    builder: (context, txSnap) {
                      final txs = txSnap.data ?? const [];

                      return DriverContentWidth(
                        child: ListView(
                          padding: DsSpacing.pagePadding,
                          children: [
                            DsWalletCard(
                              balanceLabel:
                                  driverTr(context, 'Current balance'),
                              balanceValue: balance.toStringAsFixed(2),
                              balanceAmount: TouryMoneyAmount(
                                amount: balance,
                                currencyCode: currency,
                                style: typography.displaySmall.copyWith(
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                                symbolSize: 28,
                              ),
                            ),
                            DsSpacing.gapSm,
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: DsSpacing.sm,
                                vertical: DsSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: (cashOk ? colors.success : colors.error)
                                    .withValues(alpha: 0.10),
                                borderRadius: DsRadius.medium,
                              ),
                              child: Text(
                                cashOk
                                    ? driverTr(
                                        context,
                                        'Eligible for cash orders',
                                      )
                                    : driverTrNamed(
                                        context,
                                        'Wallet balance below cash minimum',
                                        {
                                          'amount':
                                              TouryMoneyAmount.formatNumber(
                                            DriverWalletRules
                                                .minCashWalletBalance,
                                            fractionDigits: 0,
                                          ),
                                        },
                                      ),
                                style: typography.bodySmall.copyWith(
                                  color:
                                      cashOk ? colors.success : colors.error,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            if (unpaid > 0) ...[
                              DsSpacing.gapSm,
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      driverTr(context, 'Unpaid commissions'),
                                      style: typography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TouryMoneyAmount(
                                    amount: unpaid.toDouble(),
                                    currencyCode: currency,
                                    style: typography.bodySmall.copyWith(
                                      color: colors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    compact: true,
                                  ),
                                ],
                              ),
                            ],
                            DsSpacing.gapLg,
                            Text(
                              driverTr(context, 'Top up wallet'),
                              style: typography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            DsSpacing.gapSm,
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const gap = 8.0;
                                final width =
                                    (constraints.maxWidth - gap) / 2;
                                return Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: _topUpPackages.map((p) {
                                    return SizedBox(
                                      width: width,
                                      child: Material(
                                        color: colors.primarySoft
                                            .withValues(alpha: 0.65),
                                        borderRadius: DsRadius.medium,
                                        child: InkWell(
                                          borderRadius: DsRadius.medium,
                                          onTap: _busy ? null : () => _topUp(p),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: DsSpacing.sm,
                                              vertical: DsSpacing.md,
                                            ),
                                            child: Center(
                                              child: TouryMoneyAmount(
                                                amount: p,
                                                currencyCode: currency,
                                                fractionDigits: 0,
                                                style:
                                                    typography.titleSmall.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: colors.primaryStrong,
                                                ),
                                                symbolSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            DsSpacing.gapMd,
                            DsButton.primary(
                              label: driverTr(context, 'Pay company'),
                              icon: Icons.account_balance_rounded,
                              expanded: true,
                              loading: _busy,
                              enabled: !_busy && balance > 0,
                              onPressed: () => _payCompany(balance),
                            ),
                            DsSpacing.gapXl,
                            Text(
                              driverTr(context, 'Transactions'),
                              style: typography.titleMedium.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            DsSpacing.gapSm,
                            if (txs.isEmpty)
                              DsEmptyState(
                                title: driverTr(
                                  context,
                                  'No transactions yet',
                                ),
                                icon: Icons.account_balance_wallet_outlined,
                              )
                            else
                              ...txs.map((t) {
                                final isCredit = t.type == 'credit' ||
                                    t.type == 'top_up' ||
                                    t.amount > 0;
                                final amountColor =
                                    isCredit ? colors.success : colors.error;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: DsSpacing.sm,
                                  ),
                                  child: DsCard(
                                    padding: const EdgeInsets.all(DsSpacing.sm),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isCredit
                                                ? colors.successContainer
                                                : colors.errorContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCredit
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            size: 18,
                                            color: amountColor,
                                          ),
                                        ),
                                        const SizedBox(width: DsSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _txLabel(t.type),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: typography.titleSmall
                                                    .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                t.createdAt == null
                                                    ? _txStatus(t.status)
                                                    : '${_df.format(t.createdAt!)} · ${_txStatus(t.status)}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: typography.bodySmall
                                                    .copyWith(
                                                  color: colors.textSecondary,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: DsSpacing.xs),
                                        TouryMoneyAmount(
                                          amount: t.amount.abs() *
                                              (isCredit ? 1 : -1),
                                          currencyCode: currency,
                                          showPlusForPositive: isCredit,
                                          style: typography.titleSmall.copyWith(
                                            color: amountColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          symbolSize: 14,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/driver_country_service.dart';
import '/core/driver_i18n.dart';
import '/core/driver_trip_constants.dart';
import '/core/driver_wallet_service.dart';
import '/core/toury_country_registry.dart';
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
  final _df = DateFormat('yyyy-MM-dd HH:mm');
  bool _busy = false;

  static const _topUpPackages = [100.0, 200.0, 300.0, 500.0];

  String get _fallbackCurrency {
    final iso = DriverCountryService.currentIso2();
    return TouryCountryRegistry.currencySymbol(iso);
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
        final retry = await makeCloudCall('createNGeniusPayment', {
          'paymentPurpose': 'wallet',
          'amountMajor': amountSar,
          'idempotencyKey': '${idem}_b',
          'description': 'Wallet top-up — $currentUserDisplayName',
        });
        if (retry['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                driverTr(
                  context,
                  (retry['error'] ?? res['error'] ?? 'Something went wrong. Please try again.')
                      .toString(),
                ),
              ),
            ),
          );
          return;
        }
        await _openPaymentAndFinalize(retry);
        return;
      }
      await _openPaymentAndFinalize(res);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPaymentAndFinalize(Map<String, dynamic> res) async {
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
    if (paymentId.isEmpty || !mounted) return;

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
    if (!done || !mounted) return;

    final fin = await makeCloudCall('finalizeNGeniusWalletTopUp', {
      'id': paymentId,
    });
    if (!mounted) return;
    if (fin['error'] != null && fin['credited'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            driverTr(
              context,
              (fin['error'] ??
                      'Payment not confirmed yet. Try again after completion.')
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
            fin['alreadyCredited'] == true
                ? 'Top-up already applied'
                : 'Wallet topped up successfully',
          ),
        ),
      ),
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
                'بعد الدفع سيصبح رصيدك أقل من 200 ريال ولن تتمكن من استقبال الطلبات النقدية حتى تشحن المحفظة.',
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
                              currency: currency,
                            ),
                            DsSpacing.gapSm,
                            Text(
                              cashOk
                                  ? driverTr(
                                      context,
                                      'Eligible for cash orders',
                                    )
                                  : 'يجب أن يكون رصيد محفظتك 200 ريال على الأقل لقبول الطلبات النقدية.',
                              style: typography.bodySmall.copyWith(
                                color: cashOk
                                    ? colors.success
                                    : colors.error,
                              ),
                            ),
                            if (unpaid > 0) ...[
                              DsSpacing.gapSm,
                              Text(
                                '${driverTr(context, 'Unpaid commissions')}: ${unpaid.toStringAsFixed(2)} $currency',
                                style: typography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                            DsSpacing.gapMd,
                            Text(
                              driverTr(context, 'Top up wallet'),
                              style: typography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            DsSpacing.gapXs,
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _topUpPackages
                                  .map(
                                    (p) => DsButton.secondary(
                                      label: '${p.toInt()} $currency',
                                      enabled: !_busy,
                                      onPressed: () => _topUp(p),
                                    ),
                                  )
                                  .toList(),
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DsSpacing.gapXs,
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
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: DsSpacing.sm,
                                  ),
                                  child: DsCard(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isCredit
                                              ? colors.successContainer
                                              : colors.errorContainer,
                                          borderRadius: DsRadius.medium,
                                        ),
                                        child: Icon(
                                          isCredit
                                              ? Icons.arrow_downward_rounded
                                              : Icons.arrow_upward_rounded,
                                          color: isCredit
                                              ? colors.success
                                              : colors.error,
                                        ),
                                      ),
                                      title: Text(_txLabel(t.type)),
                                      subtitle: Text(
                                        t.createdAt == null
                                            ? t.status
                                            : '${_df.format(t.createdAt!)} · ${t.status}',
                                      ),
                                      trailing: Text(
                                        '${isCredit ? '+' : ''}${t.amount.toStringAsFixed(2)} $currency',
                                        style: typography.titleSmall.copyWith(
                                          color: isCredit
                                              ? colors.success
                                              : colors.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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

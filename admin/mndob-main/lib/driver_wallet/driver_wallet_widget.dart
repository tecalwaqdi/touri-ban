import '/auth/firebase_auth/auth_util.dart';
import '/core/driver_country_service.dart';
import '/core/driver_i18n.dart';
import '/core/driver_wallet_service.dart';
import '/core/toury_country_registry.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Scaffold(
            backgroundColor: colors.scaffold,
            appBar: DsAppBar(
              title: driverTr(context, 'Wallet'),
            ),
            body: SafeArea(
              child: StreamBuilder(
                stream: DriverWalletService.walletStream(),
                builder: (context, walletSnap) {
                  if (!walletSnap.hasData) {
                    return const DsLoading();
                  }
                  final wallet = walletSnap.data!;
                  final currency = wallet.currency.trim().isNotEmpty
                      ? wallet.currency
                      : _fallbackCurrency;
                  final earnings =
                      valueOrDefault(currentUserDocument?.totalMndob, 0);
                  final commission =
                      valueOrDefault(currentUserDocument?.totalApp, 0);

                  return StreamBuilder(
                    stream: DriverWalletService.transactionsStream(),
                    builder: (context, txSnap) {
                      final txs = txSnap.data ?? const [];

                      return ListView(
                        padding: DsSpacing.pagePadding,
                        children: [
                          DsWalletCard(
                            balanceLabel: driverTr(context, 'Current balance'),
                            balanceValue:
                                wallet.currentBalance.toStringAsFixed(2),
                            currency: currency,
                          ),
                          DsSpacing.gapMd,
                          Row(
                            children: [
                              Expanded(
                                child: DsStatisticsCard(
                                  label: driverTr(context, 'Total earnings'),
                                  value: '$earnings $currency',
                                  icon: Icons.trending_up_rounded,
                                ),
                              ),
                              DsSpacing.gapSm,
                              Expanded(
                                child: DsStatisticsCard(
                                  label: driverTr(
                                    context,
                                    'Unpaid commissions',
                                  ),
                                  value: '$commission $currency',
                                  icon: Icons.receipt_long_rounded,
                                ),
                              ),
                            ],
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
                              final isCredit =
                                  t.type == 'credit' || t.amount > 0;
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
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      t.description.isNotEmpty
                                          ? t.description
                                          : t.type,
                                      style: typography.bodyMedium.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      t.createdAt != null
                                          ? _df.format(t.createdAt!)
                                          : '',
                                      style: typography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${t.amount.abs().toStringAsFixed(2)} $currency',
                                      style: typography.titleSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isCredit
                                            ? colors.success
                                            : colors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
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

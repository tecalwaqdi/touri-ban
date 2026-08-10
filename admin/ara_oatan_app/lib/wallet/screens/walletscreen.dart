import 'package:easy_localization/easy_localization.dart';
import 'package:ara_oatan_app/add_payment_card/add_payment_card_widget.dart';
import 'package:ara_oatan_app/backend/schema/servies/walletservies.dart';
import 'package:ara_oatan_app/backend/schema/transactionrecord.dart';
import 'package:ara_oatan_app/backend/schema/walletrecord.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/api_requests/api_calls.dart';
import '/core/toury_ngenius.dart';
import '/core/toury_wallet_ngenius.dart';
import '/core/toury_wallet_packages.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

class WalletScreenWidget extends StatefulWidget {
  const WalletScreenWidget({super.key});
  static String routeName = 'WalletPag';
  static String routePath = '/walletPag';

  @override
  State<WalletScreenWidget> createState() => _WalletScreenWidgetState();
}

class _WalletScreenWidgetState extends State<WalletScreenWidget> {
  late WalletScreenModel _model;
  TextEditingController? _amountController;
  final _formKey = GlobalKey<FormState>();
  String? _selectedPaymentMethodId = 'ngenius_hosted';
  int _transactionsRevision = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WalletScreenModel());
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _model.dispose();
    _amountController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserUid = currentUser?.uid;

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                title: 'wallet_title'.tr(),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: DsSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBalanceCard(currentUserUid),
                      _buildActionButtons(currentUserUid),
                      _buildTransactionHistory(currentUserUid, typography),
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

  Widget _buildBalanceCard(String? userId) {
    if (userId == null) {
      return _buildNotSignedInState();
    }

    return StreamBuilder<WalletRecord?>(
      stream: WalletService.getWalletStream(userId),
      builder: (context, snapshot) {
        final colors = context.dsColors;
        final typography = context.dsTypography;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: DsSpacing.pagePadding,
            child: DsCard(
              elevated: true,
              padding: const EdgeInsets.symmetric(vertical: DsSpacing.huge),
              child: const DsLoading(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: DsSpacing.pagePadding,
            child: DsCard(
              elevated: true,
              color: colors.errorContainer,
              bordered: false,
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colors.error,
                    size: DsIcons.xl,
                  ),
                  const SizedBox(height: DsSpacing.xs),
                  Text(
                    'wallet_load_error'.tr(),
                    textAlign: TextAlign.center,
                    style: typography.bodyMedium.copyWith(color: colors.error),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: DsSpacing.pagePadding,
            child: DsCard(
              elevated: true,
              color: colors.primary,
              bordered: false,
              padding: const EdgeInsets.all(DsSpacing.xl),
              child: Column(
                children: [
                  Text(
                    'wallet_not_created'.tr(),
                    textAlign: TextAlign.center,
                    style: typography.bodyMedium.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  DsButton.secondary(
                    label: 'wallet_create_button'.tr(),
                    icon: Icons.account_balance_wallet_outlined,
                    expanded: true,
                    onPressed: () async {
                      try {
                        await WalletService.getOrCreateWallet(userId);
                        if (!mounted) return;
                        DsSnackBar.show(
                          context,
                          message: 'wallet_created_success'.tr(),
                          tone: DsSnackTone.success,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        DsSnackBar.show(
                          context,
                          message: 'wallet_error_generic'.tr(namedArgs: {
                            'error': '$e',
                          }),
                          tone: DsSnackTone.error,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        final wallet = snapshot.data!;
        final balance = wallet.currentBalance;
        final currency = wallet.currency;

        return Padding(
          padding: DsSpacing.pagePadding,
          child: DsFadeSlide(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: DsRadius.large,
                boxShadow: DsShadows.card(dark: context.dsIsDark),
              ),
              padding: const EdgeInsets.all(DsSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'wallet_current_balance'.tr(),
                    style: typography.bodyMedium.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xs),
                  Text(
                    '${balance.toStringAsFixed(2)} $currency',
                    style: typography.displaySmall.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        'wallet_currency_label'.tr(),
                        wallet.currency,
                      ),
                      _buildInfoItem(
                        'wallet_last_updated'.tr(),
                        wallet.lastUpdated != null
                            ? DateFormat('dd/MM HH:mm')
                                .format(wallet.lastUpdated!)
                            : 'wallet_never'.tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotSignedInState() {
    return Padding(
      padding: DsSpacing.pagePadding,
      child: DsEmptyState(
        icon: Icons.account_circle_outlined,
        title: 'wallet_login_required_title'.tr(),
        message: 'wallet_login_required_msg'.tr(),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: typography.labelSmall.copyWith(
            color: colors.onPrimary.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: DsSpacing.xxs),
        Text(
          value,
          style: typography.bodyMedium.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String? userId) {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: DsButton.primary(
              label: 'wallet_add_balance'.tr(),
              icon: Icons.add_rounded,
              expanded: true,
              onPressed: () async {
                await _showAddMoneyDialog(userId);
              },
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: StreamBuilder<WalletRecord?>(
              stream: WalletService.getWalletStream(userId),
              builder: (context, snapshot) {
                final wallet = snapshot.data;
                final hasBalance = wallet?.currentBalance != null &&
                    wallet!.currentBalance > 0;

                return DsButton.outlined(
                  label: 'wallet_withdraw'.tr(),
                  icon: Icons.upload_rounded,
                  expanded: true,
                  enabled: hasBalance,
                  onPressed: hasBalance
                      ? () async {
                          if (wallet != null) {
                            await _showWithdrawDialog(userId, wallet);
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(String? userId, DsTypography typography) {
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final colors = context.dsColors;

    return Padding(
      padding: DsSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'wallet_transactions'.tr(),
                style: typography.titleMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'wallet_view_all'.tr(),
                style: typography.labelLarge.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          StreamBuilder<List<TransactionRecord>>(
            key: ValueKey(_transactionsRevision),
            stream: Stream.fromFuture(
                WalletService.getTransactions(userId: userId, limit: 10)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: DsSpacing.xl),
                  child: DsLoading(),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState('wallet_transactions_error'.tr());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final transactions = snapshot.data!.take(10).toList();

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: transactions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DsSpacing.sm),
                itemBuilder: (context, index) {
                  return DsFadeSlide(
                    delay: Duration(
                      milliseconds: (index * 40).clamp(0, 200),
                    ),
                    child: _buildTransactionItem(transactions[index]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionRecord transaction) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final amount = transaction.amount;
    final type = transaction.type;
    final description = transaction.description;
    final createdAt = transaction.createdAt ?? DateTime.now();
    final status = transaction.status;

    String typeName = '';
    switch (type) {
      case 'credit':
        typeName = 'wallet_tx_deposit'.tr();
        break;
      case 'debit':
        typeName = 'wallet_tx_withdraw'.tr();
        break;
      case 'refund':
        typeName = 'wallet_tx_refund'.tr();
        break;
      case 'transfer':
        typeName = 'wallet_tx_transfer'.tr();
        break;
      default:
        typeName = type;
    }

    String statusName = '';
    switch (status) {
      case 'completed':
        statusName = 'wallet_status_completed'.tr();
        break;
      case 'pending':
        statusName = 'wallet_status_pending'.tr();
        break;
      case 'failed':
        statusName = 'wallet_status_failed'.tr();
        break;
      case 'cancelled':
        statusName = 'wallet_status_cancelled'.tr();
        break;
      default:
        statusName = status;
    }

    final statusColor = _getStatusColor(status);

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.sm),
      child: Row(
        children: [
          Container(
            width: DsConstants.avatarMd,
            height: DsConstants.avatarMd,
            decoration: BoxDecoration(
              color: _getTransactionColor(type).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTransactionIcon(type),
              color: _getTransactionColor(type),
              size: DsIcons.sm,
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: typography.titleSmall.copyWith(
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: DsSpacing.chipPadding,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: DsRadius.pill,
                      ),
                      child: Text(
                        statusName,
                        style: typography.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.xxs),
                Text(
                  '$typeName · ${DateFormat('dd/MM/yyyy • HH:mm').format(createdAt)}',
                  style: typography.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Text(
            '${type == 'debit' ? '-' : '+'}${amount.toStringAsFixed(2)}',
            style: typography.titleMedium.copyWith(
              color: type == 'debit' ? colors.error : colors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return DsEmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'wallet_no_transactions'.tr(),
      message: 'wallet_no_transactions_hint'.tr(),
    );
  }

  Widget _buildErrorState(String message) {
    return DsErrorState(
      title: message,
    );
  }

  Color _getTransactionColor(String type) {
    final colors = context.dsColors;
    switch (type) {
      case 'credit':
        return colors.success;
      case 'debit':
        return colors.error;
      case 'refund':
        return colors.info;
      case 'transfer':
        return colors.warning;
      default:
        return colors.primary;
    }
  }

  Color _getStatusColor(String status) {
    final colors = context.dsColors;
    switch (status) {
      case 'completed':
        return colors.success;
      case 'pending':
        return colors.warning;
      case 'failed':
        return colors.error;
      case 'cancelled':
        return colors.textSecondary;
      default:
        return colors.primary;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'credit':
        return Icons.download_rounded;
      case 'debit':
        return Icons.upload_rounded;
      case 'refund':
        return Icons.refresh_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Future<void> _showAddMoneyDialog(String userId) async {
    _amountController?.clear();
    _selectedPaymentMethodId = 'ngenius_hosted';
    String? selectedPackageId;

    final currentUserRef = currentUserReference;

    if (currentUserRef == null) {
      DsSnackBar.show(
        context,
        message: 'wallet_login_first'.tr(),
        tone: DsSnackTone.error,
      );
      return;
    }

    final packages = await touryLoadWalletTopUpPackages();

    return showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = DsColors.of(dialogContext);
        final typography = DsTypography.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: DsRadius.large),
              title: Text(
                'wallet_add_balance_title'.tr(),
                style: typography.titleLarge.copyWith(color: colors.textPrimary),
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (packages.isEmpty)
                      Text(
                        'wallet_topup_packages_unavailable'.tr(),
                        style: typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      )
                    else
                      ...packages.map((pkg) {
                        final selected = selectedPackageId == pkg.packageId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: DsSpacing.xs),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: DsRadius.medium,
                              onTap: () => setDialogState(() {
                                selectedPackageId = pkg.packageId;
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(DsSpacing.sm),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? colors.selected
                                      : colors.surface,
                                  border: Border.all(
                                    color: selected
                                        ? colors.primary
                                        : colors.border,
                                    width: selected ? 2 : 1,
                                  ),
                                  borderRadius: DsRadius.medium,
                                ),
                                child: Text(
                                  '${pkg.amountMajor.toStringAsFixed(2)} ${pkg.currency}',
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    // Keep legacy payment-method UI collapsed; hosted N-Genius only.
                    const Visibility(
                      visible: false,
                      maintainState: false,
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                DsSpacing.md,
                0,
                DsSpacing.md,
                DsSpacing.md,
              ),
              actions: [
                DsButton.text(
                  label: 'dialog_cancel'.tr(),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                DsButton.primary(
                  label: 'wallet_add_confirm'.tr(),
                  enabled: packages.isNotEmpty,
                  onPressed: packages.isEmpty
                      ? null
                      : () async {
                          if (selectedPackageId == null ||
                              selectedPackageId!.isEmpty) {
                            DsSnackBar.show(
                              context,
                              message: 'wallet_topup_select_package'.tr(),
                              tone: DsSnackTone.error,
                            );
                            return;
                          }
                          final selected = packages.firstWhere(
                            (p) => p.packageId == selectedPackageId,
                          );

                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: DsLoading(),
                              ),
                            );

                            final paymentResponse =
                                await touryStartWalletTopUp(
                              userId: userId,
                              packageId: selected.packageId,
                              displayAmountMinor: selected.amountMinor,
                            );

                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }

                            if (!TouryNGeniusService.createReady(
                              paymentResponse,
                            )) {
                              DsSnackBar.show(
                                context,
                                message: 'checkout_payment_card_error'.tr(),
                                tone: DsSnackTone.error,
                              );
                              touryClearWalletTopUpPending();
                              return;
                            }

                            Navigator.pop(dialogContext);

                            final paymentUrl = NGeniusPaymentCall.url(
                              paymentResponse!.jsonBody,
                            );
                            final amountLabel =
                                selected.amountMajor.toStringAsFixed(2);
                            if (paymentUrl == null || paymentUrl.isEmpty) {
                              final credited = await touryFinalizeWalletTopUp();
                              if (credited && mounted) {
                                safeSetState(() => _transactionsRevision++);
                                DsSnackBar.show(
                                  context,
                                  message: 'wallet_add_success'.tr(namedArgs: {
                                    'amount': amountLabel,
                                  }),
                                  tone: DsSnackTone.success,
                                );
                              }
                              return;
                            }

                            context.pushNamed(
                              WebviewWidget.routeName,
                              queryParameters: {
                                'url': paymentUrl,
                              },
                            );
                          } catch (e) {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            touryClearWalletTopUpPending();
                            DsSnackBar.show(
                              context,
                              message: 'wallet_error_generic'.tr(namedArgs: {
                                'error': e.toString(),
                              }),
                              tone: DsSnackTone.error,
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showWithdrawDialog(String userId, WalletRecord wallet) async {
    _amountController?.clear();
    _selectedPaymentMethodId = 'ngenius_hosted';
    final balance = wallet.currentBalance;
    final currency = wallet.currency;

    final currentUserRef = currentUserReference;
    if (currentUserRef == null) {
      DsSnackBar.show(
        context,
        message: 'wallet_login_first'.tr(),
        tone: DsSnackTone.error,
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = DsColors.of(dialogContext);
        final typography = DsTypography.of(dialogContext);

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: DsRadius.large),
          title: Text(
            'wallet_withdraw_title'.tr(),
            style: typography.titleLarge.copyWith(color: colors.textPrimary),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'wallet_available_balance'.tr(namedArgs: {
                      'amount': balance.toStringAsFixed(2),
                      'currency': currency,
                    }),
                    style: typography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: typography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'wallet_amount_label'.tr(),
                      prefixIcon: Icon(
                        Icons.attach_money_rounded,
                        color: colors.iconMuted,
                      ),
                      hintText: '0.00',
                      filled: true,
                      fillColor: colors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: DsRadius.medium,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: DsRadius.medium,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: DsRadius.medium,
                        borderSide: BorderSide(color: colors.primary, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'wallet_amount_required'.tr();
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'wallet_amount_invalid'.tr();
                      }
                      if (amount > balance) {
                        return 'wallet_amount_exceeds_balance'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: DsSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: colors.primary,
                        size: DsIcons.sm,
                      ),
                      const SizedBox(width: DsSpacing.xs),
                      Expanded(
                        child: Text(
                          'wallet_withdraw_request_note'.tr(),
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: false,
                    maintainState: false,
                    child: StreamBuilder<List<PaymentMethodsRecord>>(
                      stream: queryPaymentMethodsRecord(
                        queryBuilder: (paymentMethodsRecord) =>
                            paymentMethodsRecord
                                .where('userRev', isEqualTo: currentUserRef)
                                .where('acctev', isEqualTo: true),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const DsLoading();
                        }

                        final paymentMethods = snapshot.data ?? [];

                        if (paymentMethods.isEmpty) {
                          return Column(
                            children: [
                              Text(
                                'wallet_no_payment_methods'.tr(),
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.md),
                              DsButton.primary(
                                label: 'wallet_add_payment_method'.tr(),
                                icon: Icons.add_card_rounded,
                                expanded: true,
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  context.pushNamed(
                                    AddPaymentCardWidget.routeName,
                                  );
                                },
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'wallet_choose_payout'.tr(),
                              style: typography.bodyMedium.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.xs),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: paymentMethods.length,
                              itemBuilder: (context, index) {
                                final method = paymentMethods[index];
                                final last4 = method.displayLast4;
                                final selected =
                                    _selectedPaymentMethodId ==
                                        method.reference.id;

                                return Container(
                                  margin:
                                      const EdgeInsets.only(bottom: DsSpacing.xs),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selected
                                          ? colors.primary
                                          : colors.border,
                                      width: selected ? 2 : 1,
                                    ),
                                    borderRadius: DsRadius.medium,
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text(
                                      'wallet_card_ending'.tr(namedArgs: {
                                        'last4': last4,
                                      }),
                                      style: typography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      method.naim,
                                      style: typography.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    value: method.reference.id,
                                    groupValue: _selectedPaymentMethodId,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentMethodId = value;
                                      });
                                    },
                                    activeColor: colors.primary,
                                    tileColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: DsSpacing.xs,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            0,
            DsSpacing.md,
            DsSpacing.md,
          ),
          actions: [
            DsButton.text(
              label: 'dialog_cancel'.tr(),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            DsButton.primary(
              label: 'wallet_withdraw_confirm'.tr(),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                final amount = double.parse(_amountController!.text);

                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: DsLoading(),
                    ),
                  );

                  final requested = await touryRequestWalletWithdrawal(
                    amountSar: amount,
                  );
                  if (!requested) {
                    throw Exception('wallet_withdraw_request_failed'.tr());
                  }

                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  Navigator.pop(dialogContext);

                  if (mounted) {
                    safeSetState(() => _transactionsRevision++);
                  }

                  DsSnackBar.show(
                    context,
                    message:
                        'wallet_withdraw_request_success'.tr(namedArgs: {
                      'amount': amount.toStringAsFixed(2),
                      'currency': currency,
                    }),
                    tone: DsSnackTone.success,
                  );
                } catch (e) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  DsSnackBar.show(
                    context,
                    message: 'wallet_error_generic'.tr(namedArgs: {
                      'error': e.toString(),
                    }),
                    tone: DsSnackTone.error,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class WalletScreenModel extends FlutterFlowModel<WalletScreenWidget> {
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

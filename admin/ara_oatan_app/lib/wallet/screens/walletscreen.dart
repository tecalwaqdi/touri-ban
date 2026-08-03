import 'package:easy_localization/easy_localization.dart';
import 'package:ara_oatan_app/add_payment_card/add_payment_card_widget.dart';
import 'package:ara_oatan_app/auth/base_auth_user_provider.dart';
import 'package:ara_oatan_app/backend/schema/servies/walletservies.dart';
import 'package:ara_oatan_app/backend/schema/transactionrecord.dart';
import 'package:ara_oatan_app/backend/schema/walletrecord.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/core/toury_ngenius.dart';
import '/core/toury_wallet_ngenius.dart';
import '/core/toury_wallet_packages.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:provider/provider.dart';

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
    // In your build method or functions:
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserUid = currentUser?.uid;
    final currentUserRef = currentUserReference;

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'wallet_title'.tr(),
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                letterSpacing: 0.0,
              ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Current Balance Card
              _buildBalanceCard(currentUserUid),

              // Action Buttons
              _buildActionButtons(currentUserUid),

              // Transaction History
              _buildTransactionHistory(currentUserUid),
            ],
          ),
        ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).alternate,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).error,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'wallet_load_error'.tr(),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily:
                                FlutterFlowTheme.of(context).bodyMediumFamily,
                            color: Colors.white,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FlutterFlowTheme.of(context).primary,
                    FlutterFlowTheme.of(context).secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'wallet_not_created'.tr(),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily:
                                FlutterFlowTheme.of(context).bodyMediumFamily,
                            color: Colors.white70,
                            letterSpacing: 0.0,
                          ),
                    ),
                    SizedBox(height: 16),
                    FFButtonWidget(
                      onPressed: () async {
                        try {
                          await WalletService.getOrCreateWallet(userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('wallet_created_success'.tr()),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('wallet_error_generic'.tr(namedArgs: {
                                'error': '$e',
                              })),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      text: 'wallet_create_button'.tr(),
                      options: FFButtonOptions(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.white,
                        textStyle: FlutterFlowTheme.of(context)
                            .titleSmall
                            .override(
                              fontFamily:
                                  FlutterFlowTheme.of(context).titleSmallFamily,
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                            ),
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final wallet = snapshot.data!;
        final balance = wallet.currentBalance;
        final currency = wallet.currency;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FlutterFlowTheme.of(context).primary,
                  FlutterFlowTheme.of(context).secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'wallet_current_balance'.tr(),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).bodyMediumFamily,
                          color: Colors.white70,
                          letterSpacing: 0.0,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${balance.toStringAsFixed(2)} $currency',
                    style: FlutterFlowTheme.of(context).displayLarge.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).displayLargeFamily,
                          color: Colors.white,
                          fontSize: 48,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                          'wallet_currency_label'.tr(), wallet.currency),
                      _buildInfoItem(
                          'wallet_last_updated'.tr(),
                          wallet.lastUpdated != null
                              ? DateFormat('dd/MM HH:mm')
                                  .format(wallet.lastUpdated!)
                              : 'wallet_never'.tr()),
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
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).alternate,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
              SizedBox(height: 16),
              Text(
                'wallet_login_required_title'.tr(),
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily:
                          FlutterFlowTheme.of(context).headlineSmallFamily,
                      letterSpacing: 0.0,
                    ),
              ),
              SizedBox(height: 8),
              Text(
                'wallet_login_required_msg'.tr(),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                color: Colors.white70,
                letterSpacing: 0.0,
              ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                color: Colors.white,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String? userId) {
    if (userId == null) {
      return SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: FFButtonWidget(
              onPressed: () async {
                await _showAddMoneyDialog(userId);
              },
              text: 'wallet_add_balance'.tr(),
              icon: const Icon(Icons.add, size: 20),
              options: FFButtonOptions(
                height: 50,
                padding: const EdgeInsets.all(0),
                iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                color: FlutterFlowTheme.of(context).primary,
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: FlutterFlowTheme.of(context).titleSmallFamily,
                      color: Colors.white,
                      letterSpacing: 0.0,
                    ),
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<WalletRecord?>(
              stream: WalletService.getWalletStream(userId),
              builder: (context, snapshot) {
                final wallet = snapshot.data;
                final hasBalance = wallet?.currentBalance != null &&
                    wallet!.currentBalance > 0;

                return FFButtonWidget(
                  onPressed: hasBalance
                      ? () async {
                          if (wallet != null) {
                            await _showWithdrawDialog(userId, wallet);
                          }
                        }
                      : null,
                  text: 'wallet_withdraw'.tr(),
                  icon: const Icon(Icons.upload, size: 20),
                  options: FFButtonOptions(
                    height: 50,
                    padding: const EdgeInsets.all(0),
                    iconPadding:
                        const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).titleSmallFamily,
                          color: hasBalance
                              ? FlutterFlowTheme.of(context).primaryText
                              : FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                        ),
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(String? userId) {
    if (userId == null) {
      return SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'wallet_transactions'.tr(),
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily:
                          FlutterFlowTheme.of(context).headlineSmallFamily,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              InkWell(
                onTap: () {
                  // Navigate to full transaction history screen
                  // context.pushNamed('FullTransactionHistory');
                },
                child: Text(
                  'wallet_view_all'.tr(),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily:
                            FlutterFlowTheme.of(context).bodyMediumFamily,
                        color: FlutterFlowTheme.of(context).primary,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<TransactionRecord>>(
            key: ValueKey(_transactionsRevision),
            stream: Stream.fromFuture(
                WalletService.getTransactions(userId: userId, limit: 10)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildTransactionItem(transactions[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionRecord transaction) {
    final amount = transaction.amount;
    final type = transaction.type;
    final description = transaction.description;
    final createdAt = transaction.createdAt ?? DateTime.now();
    final status = transaction.status;

    // Arabic type names
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

    // Arabic status names
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

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTransactionColor(type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTransactionIcon(type),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyMediumFamily,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.0,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusName,
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodySmallFamily,
                                    color: Colors.white,
                                    fontSize: 10,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        typeName,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily:
                                  FlutterFlowTheme.of(context).bodySmallFamily,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '•',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily:
                                  FlutterFlowTheme.of(context).bodySmallFamily,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy • HH:mm').format(createdAt),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily:
                                  FlutterFlowTheme.of(context).bodySmallFamily,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${type == 'debit' ? '-' : '+'}${amount.toStringAsFixed(2)}',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: FlutterFlowTheme.of(context).titleMediumFamily,
                    color: type == 'debit'
                        ? FlutterFlowTheme.of(context).error
                        : FlutterFlowTheme.of(context).success,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'wallet_no_transactions'.tr(),
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'wallet_no_transactions_hint'.tr(),
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  letterSpacing: 0.0,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: FlutterFlowTheme.of(context).error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyLargeFamily,
                  color: FlutterFlowTheme.of(context).error,
                  letterSpacing: 0.0,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getTransactionColor(String type) {
    switch (type) {
      case 'credit':
        return FlutterFlowTheme.of(context).success;
      case 'debit':
        return FlutterFlowTheme.of(context).error;
      case 'refund':
        return FlutterFlowTheme.of(context).info;
      case 'transfer':
        return FlutterFlowTheme.of(context).warning;
      default:
        return FlutterFlowTheme.of(context).primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return FlutterFlowTheme.of(context).success;
      case 'pending':
        return FlutterFlowTheme.of(context).warning;
      case 'failed':
        return FlutterFlowTheme.of(context).error;
      case 'cancelled':
        return FlutterFlowTheme.of(context).secondaryText;
      default:
        return FlutterFlowTheme.of(context).primary;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'credit':
        return Icons.download;
      case 'debit':
        return Icons.upload;
      case 'refund':
        return Icons.refresh;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.payment;
    }
  }

  Future<void> _showAddMoneyDialog(String userId) async {
    _amountController?.clear();
    _selectedPaymentMethodId = 'ngenius_hosted';
    String? selectedPackageId;

    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserUid = currentUser?.uid;
    final currentUserRef = currentUserReference;

    if (currentUserRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('wallet_login_first'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final packages = await touryLoadWalletTopUpPackages();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('wallet_add_balance_title'.tr()),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (packages.isEmpty)
                      Text(
                        'wallet_topup_packages_unavailable'.tr(),
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      )
                    else
                      ...packages.map((pkg) {
                        final selected = selectedPackageId == pkg.packageId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => setDialogState(() {
                              selectedPackageId = pkg.packageId;
                            }),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? FlutterFlowTheme.of(context).primary
                                      : FlutterFlowTheme.of(context).alternate,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pkg.amountMajor.toStringAsFixed(2)} ${pkg.currency}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }),
                    // Keep legacy payment-method UI collapsed; hosted N-Genius only.
                    Visibility(
                      visible: false,
                      maintainState: false,
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'dialog_cancel'.tr(),
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: packages.isEmpty
                      ? null
                      : () async {
                          if (selectedPackageId == null ||
                              selectedPackageId!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'wallet_topup_select_package'.tr(),
                                ),
                                backgroundColor: Colors.red,
                              ),
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
                              builder: (context) => Center(
                                child: CircularProgressIndicator(
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('checkout_payment_card_error'.tr()),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              touryClearWalletTopUpPending();
                              return;
                            }

                            Navigator.pop(context);

                            final paymentUrl = NGeniusPaymentCall.url(
                              paymentResponse!.jsonBody,
                            );
                            final amountLabel =
                                selected.amountMajor.toStringAsFixed(2);
                            if (paymentUrl == null || paymentUrl.isEmpty) {
                              final credited = await touryFinalizeWalletTopUp();
                              if (credited && mounted) {
                                safeSetState(() => _transactionsRevision++);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'wallet_add_success'.tr(namedArgs: {
                                        'amount': amountLabel,
                                      }),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'wallet_error_generic'.tr(namedArgs: {
                                    'error': e.toString(),
                                  }),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: Text('wallet_add_confirm'.tr()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('wallet_login_first'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('wallet_withdraw_title'.tr()),
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
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily:
                              FlutterFlowTheme.of(context).bodyMediumFamily,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.0,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'wallet_amount_label'.tr(),
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
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
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.schedule_outlined,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                    title: Text('wallet_withdraw_request_note'.tr()),
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final paymentMethods = snapshot.data ?? [];

                        if (paymentMethods.isEmpty) {
                          return Column(
                            children: [
                              Text(
                                'wallet_no_payment_methods'.tr(),
                                style: TextStyle(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FFButtonWidget(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  if (AddPaymentCardWidget.routeName != null) {
                                    context.pushNamed(
                                        AddPaymentCardWidget.routeName!);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddPaymentCardWidget(),
                                      ),
                                    );
                                  }
                                },
                                text: 'wallet_add_payment_method'.tr(),
                                icon: Icon(
                                  Icons.add_card,
                                  size: 20,
                                  color: FlutterFlowTheme.of(context).info,
                                ),
                                options: FFButtonOptions(
                                  width: double.infinity,
                                  height: 50,
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 0, 16, 0),
                                  iconPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          0, 0, 8, 0),
                                  color: FlutterFlowTheme.of(context).primary,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .titleSmallFamily,
                                        color:
                                            FlutterFlowTheme.of(context).info,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  elevation: 0.0,
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'wallet_choose_payout'.tr(),
                              style: FlutterFlowTheme.of(context).bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: paymentMethods.length,
                              itemBuilder: (context, index) {
                                final method = paymentMethods[index];
                                final last4 = method.displayLast4;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedPaymentMethodId ==
                                              method.reference.id
                                          ? FlutterFlowTheme.of(context).primary
                                          : FlutterFlowTheme.of(context)
                                              .alternate,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text(
                                      'wallet_card_ending'.tr(namedArgs: {
                                        'last4': last4,
                                      }),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMediumFamily,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    subtitle: Text(
                                      method.naim,
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmallFamily,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    value: method.reference.id,
                                    groupValue: _selectedPaymentMethodId,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentMethodId = value;
                                      });
                                    },
                                    activeColor:
                                        FlutterFlowTheme.of(context).primary,
                                    tileColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'dialog_cancel'.tr(),
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                final amount = double.parse(_amountController!.text);

                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: CircularProgressIndicator(
                        color: FlutterFlowTheme.of(context).primary,
                      ),
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

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('wallet_withdraw_request_success'.tr(namedArgs: {
                        'amount': amount.toStringAsFixed(2),
                        'currency': currency,
                      })),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('wallet_error_generic'.tr(namedArgs: {
                        'error': e.toString(),
                      })),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('wallet_withdraw_confirm'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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

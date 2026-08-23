import 'package:cloud_firestore/cloud_firestore.dart';

import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'admin_settlement_receipt_model.dart';
export 'admin_settlement_receipt_model.dart';

class AdminSettlementReceiptWidget extends StatefulWidget {
  const AdminSettlementReceiptWidget({super.key, this.paymentId});

  final String? paymentId;

  static const String routeName = 'AdminSettlementReceipt';
  static const String routePath = '/adminSettlementReceipt';

  @override
  State<AdminSettlementReceiptWidget> createState() =>
      _AdminSettlementReceiptWidgetState();
}

class _AdminSettlementReceiptWidgetState
    extends State<AdminSettlementReceiptWidget> {
  late AdminSettlementReceiptModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminSettlementReceiptModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _money(int? minor, String currency) {
    final m = MoneyAmount(currency: currency, minorUnits: minor ?? 0);
    return m.displayLabel;
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.paymentId;
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'Settlement Payment Receipt'),
      child: id == null || id.isEmpty
          ? Text(uiTr(context, 'معرّف الدفعة مفقود'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('financial_settlement_payments')
                  .doc(id)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.data!.exists) {
                  return Text(uiTr(context, 'الدفعة غير موجودة'));
                }
                final p = snap.data!.data()!;
                final cur = p['currency'] as String? ?? 'SAR';
                return Padding(
                  padding: AdminUi.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uiTr(context, 'Settlement Payment Receipt'),
                        style: theme.headlineSmall,
                        softWrap: true,
                      ),
                      Text(
                        uiTr(context, 'ليست فاتورة ضريبية / Not a tax invoice'),
                        style: theme.labelSmall,
                        softWrap: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${uiTr(context, 'الرقم')}: ${p['receiptNumber'] ?? '—'}',
                        softWrap: true,
                      ),
                      Text('Settlement: ${p['settlementCode']}', softWrap: true),
                      Text('Driver: ${p['driverId']}', softWrap: true),
                      Text('Direction: ${p['direction']}', softWrap: true),
                      Text(
                        'Amount: ${_money(p['amountMinor'] as int?, cur)}',
                        softWrap: true,
                      ),
                      Text('Method: ${p['method']}', softWrap: true),
                      Text(
                        'Reference: ${p['externalReference'] ?? '—'}',
                        softWrap: true,
                      ),
                      Text('Paid: ${p['paidAt']}', softWrap: true),
                      Text('Confirmed: ${p['confirmedAt']}', softWrap: true),
                      Text(
                        'Confirmed by: ${p['confirmedBy'] ?? '—'}',
                        softWrap: true,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

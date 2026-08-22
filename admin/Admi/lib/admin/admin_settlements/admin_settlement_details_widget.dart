import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_error_messages.dart';
import '/core/finance/money_amount.dart';
import '/core/finance/settlement_ledger_client.dart';
import '/core/finance/finance_controls_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'admin_settlement_details_model.dart';
export 'admin_settlement_details_model.dart';

class AdminSettlementDetailsWidget extends StatefulWidget {
  const AdminSettlementDetailsWidget({
    super.key,
    this.settlementId,
  });

  final String? settlementId;

  static const String routeName = 'AdminSettlementDetails';
  static const String routePath = '/adminSettlementDetails';

  @override
  State<AdminSettlementDetailsWidget> createState() =>
      _AdminSettlementDetailsWidgetState();
}

class _AdminSettlementDetailsWidgetState
    extends State<AdminSettlementDetailsWidget> {
  late AdminSettlementDetailsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminSettlementDetailsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _money(int? minor, String currency) {
    final m = MoneyAmount(currency: currency, minorUnits: minor ?? 0);
    return '${m.majorUnits.toStringAsFixed(2)} ${m.code}';
  }

  void _snackError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(adminFriendlyError(context, e))),
    );
  }

  Future<void> _lock(Map<String, dynamic> data) async {
    final derived = (data['derivedCount'] as num?)?.toInt() ?? 0;
    final cur = data['currency'] as String? ?? 'SAR';
    final due = data['absoluteSettlementAmountMinor'] as int?;
    final ok = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'تأكيد قفل التسوية'),
      whatHappens:
          '${uiTr(context, 'الرحلات')}: ${data['eligibleTripCount']}\n'
          'Cash liability: ${_money(data['driverCashLiabilityMinor'] as int?, cur)}\n'
          'Online liability: ${_money(data['companyOnlineLiabilityMinor'] as int?, cur)}\n'
          'Net: ${_money(data['netTripPositionMinor'] as int?, cur)}\n'
          '${derived > 0 ? 'This settlement includes $derived DERIVED financial records.\n' : ''}'
          '${uiTr(context, 'Accounting record only — no wallet movement')}',
      subject: '${data['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'Locks trip lines; no wallet movement'),
      confirmLabel: uiTr(context, 'Lock Settlement'),
      irreversible: true,
      currency: cur,
      amount: _money(due, cur),
      direction: '${data['direction'] ?? ''}',
      reference: widget.settlementId,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await SettlementLedgerClient.lock(
        settlementId: widget.settlementId!,
        idempotencyKey: SettlementLedgerClient.newIdempotencyKey('lock'),
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _voidLocked(Map<String, dynamic> data) async {
    final cur = data['currency'] as String? ?? 'SAR';
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'Void settlement'),
      whatHappens: uiTr(
        context,
        'Voids this settlement. Accounting only — no wallet movement.',
      ),
      subject: '${data['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'Settlement becomes void and cannot be paid'),
      confirmLabel: uiTr(context, 'Void'),
      destructive: true,
      irreversible: true,
      currency: cur,
      amount: _money(data['absoluteSettlementAmountMinor'] as int?, cur),
      direction: '${data['direction'] ?? ''}',
      reference: widget.settlementId,
    );
    if (!confirmed || !mounted) return;

    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(ctx, 'السبب')),
        content: TextField(
          controller: reason,
          decoration: InputDecoration(labelText: uiTr(ctx, 'السبب')),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(uiTr(ctx, 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(uiTr(ctx, 'Void')),
          ),
        ],
      ),
    );
    final reasonText = reason.text.trim();
    reason.dispose();
    if (ok != true || reasonText.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      await SettlementLedgerClient.voidSettlement(
        settlementId: widget.settlementId!,
        reason: reasonText,
        idempotencyKey: SettlementLedgerClient.newIdempotencyKey('void'),
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordPayment(Map<String, dynamic> data) async {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final receivedCtrl = TextEditingController();
    String method = 'bank_transfer';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(uiTr(ctx, 'Record Payment')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: uiTr(ctx, 'المبلغ (وحدات العملة)'),
                      ),
                    ),
                    DropdownButton<String>(
                      value: method,
                      items: const [
                        DropdownMenuItem(value: 'bank_transfer', child: Text('bank_transfer')),
                        DropdownMenuItem(value: 'cash', child: Text('cash')),
                        DropdownMenuItem(value: 'external_transfer', child: Text('external_transfer')),
                        DropdownMenuItem(value: 'other', child: Text('other')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => method = v);
                      },
                    ),
                    TextField(
                      controller: refCtrl,
                      decoration: InputDecoration(labelText: uiTr(ctx, 'المرجع')),
                    ),
                    if (method == 'cash')
                      TextField(
                        controller: receivedCtrl,
                        decoration: InputDecoration(labelText: 'receivedBy'),
                      ),
                    Text(
                      uiTr(ctx, 'يحفظ كـ Pending — لا يخفض Outstanding حتى التأكيد'),
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(uiTr(ctx, 'إلغاء')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(uiTr(ctx, 'Save as Pending')),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) return;
    final major = double.tryParse(amountCtrl.text.trim());
    if (major == null) return;
    final currency = data['currency'] as String? ?? 'SAR';
    final exp = CurrencyMoneyPolicy.exponentOrNull(currency) ?? 2;
    var factor = 1;
    for (var i = 0; i < exp; i++) {
      factor *= 10;
    }
    final minor = (major * factor).round();
    setState(() => _busy = true);
    try {
      await SettlementLedgerClient.createPayment(
        settlementId: widget.settlementId!,
        amountMinor: minor,
        method: method,
        idempotencyKey: SettlementLedgerClient.newIdempotencyKey('pay'),
        externalReference: refCtrl.text.trim(),
        receivedBy: receivedCtrl.text.trim().isEmpty ? null : receivedCtrl.text.trim(),
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPayment(Map<String, dynamic> settlement, Map<String, dynamic> pay) async {
    final cur = settlement['currency'] as String? ?? 'SAR';
    final due = (settlement['absoluteSettlementAmountMinor'] as num?)?.toInt() ?? 0;
    final paid = (settlement['paidConfirmedMinor'] as num?)?.toInt() ?? 0;
    final thisAmt = (pay['amountMinor'] as num?)?.toInt() ?? 0;
    final remaining = due - paid - thisAmt;
    final ok = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'Confirm Payment'),
      whatHappens:
          'Settlement: ${_money(due, cur)}\n'
          'Paid: ${_money(paid, cur)}\n'
          'This payment: ${_money(thisAmt, cur)}\n'
          'Remaining after confirm: ${_money(remaining, cur)}',
      subject: '${settlement['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'Reduces outstanding; accounting only'),
      confirmLabel: uiTr(context, 'Confirm Payment'),
      irreversible: true,
      currency: cur,
      amount: _money(thisAmt, cur),
      direction: '${settlement['direction'] ?? ''}',
      reference: '${pay['externalReference'] ?? pay['paymentId'] ?? ''}',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await SettlementLedgerClient.confirmPayment(
        paymentId: pay['paymentId'] as String? ?? '',
        idempotencyKey: SettlementLedgerClient.newIdempotencyKey('confirm'),
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifySource() async {
    setState(() => _busy = true);
    try {
      final r = await FinanceControlsClient.verifySettlementSource(
        widget.settlementId!,
      );
      if (!mounted) return;
      final flag = r['flag'];
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(uiTr(ctx, 'Verify Against Current Source')),
          content: Text(
            flag == 'SOURCE_CHANGED_AFTER_LOCK'
                ? 'SOURCE_CHANGED_AFTER_LOCK — snapshot unchanged'
                : 'Snapshot matches current source. mutated=${r['mutated']}',
          ),
        ),
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reversePayment(
    Map<String, dynamic> settlement,
    Map<String, dynamic> pay,
    String currency,
  ) async {
    final thisAmt = (pay['amountMinor'] as num?)?.toInt() ?? 0;
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'Reverse Payment'),
      whatHappens: uiTr(
        context,
        'Reverses a confirmed payment. Outstanding will increase.',
      ),
      subject: '${settlement['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'Increases outstanding; accounting only'),
      confirmLabel: uiTr(context, 'Reverse'),
      destructive: true,
      irreversible: true,
      currency: currency,
      amount: _money(thisAmt, currency),
      direction: '${settlement['direction'] ?? ''}',
      reference: '${pay['externalReference'] ?? pay['paymentId'] ?? ''}',
    );
    if (!confirmed || !mounted) return;

    final reason = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(ctx, 'Reverse Payment')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reason,
              decoration: InputDecoration(labelText: uiTr(ctx, 'السبب')),
            ),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: uiTr(ctx, 'Partial amount (major, optional)'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(uiTr(ctx, 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(uiTr(ctx, 'Reverse')),
          ),
        ],
      ),
    );
    final reasonText = reason.text.trim();
    final amountText = amount.text.trim();
    reason.dispose();
    amount.dispose();
    if (ok != true || reasonText.isEmpty || !mounted) return;
    final major = double.tryParse(amountText);
    int? minor;
    if (major != null) {
      final exp = CurrencyMoneyPolicy.exponentOrNull(currency) ?? 2;
      var factor = 1;
      for (var i = 0; i < exp; i++) {
        factor *= 10;
      }
      minor = (major * factor).round();
    }
    setState(() => _busy = true);
    try {
      await SettlementLedgerClient.reversePayment(
        paymentId: pay['paymentId'] as String? ?? '',
        reason: reasonText,
        idempotencyKey: SettlementLedgerClient.newIdempotencyKey('rev'),
        reversalAmountMinor: minor,
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.settlementId;
    final theme = FlutterFlowTheme.of(context);
    final canWrite = AdminRoleService.canWriteSettlements;
    if (id == null || id.isEmpty) {
      return AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: uiTr(context, 'التسوية'),
        child: Text(uiTr(context, 'معرّف التسوية مفقود')),
      );
    }

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'تفاصيل التسوية'),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('financial_settlements')
            .doc(id)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return Text(uiTr(context, 'التسوية غير موجودة'));
          }
          final d = snap.data!.data()!;
          final cur = d['currency'] as String? ?? 'SAR';
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              Text('${d['settlementCode']} · ${d['status']}', style: theme.headlineSmall),
              Text(
                'Driver ${d['driverId']} · ${d['countryId']} · $cur · ${d['direction']}',
              ),
              Text('${d['periodStart']} → ${d['periodEnd']}'),
              const SizedBox(height: 12),
              Text(uiTr(context, 'الإجماليات'), style: theme.titleMedium),
              Text('Cash collected ${_money(d['cashCustomerCollectedMinor'] as int?, cur)}'),
              Text('Cash entitlement ${_money(d['cashDriverEntitlementMinor'] as int?, cur)}'),
              Text('Driver cash liability ${_money(d['driverCashLiabilityMinor'] as int?, cur)}'),
              Text('Online collected ${_money(d['onlineCustomerCollectedMinor'] as int?, cur)}'),
              Text('Company online liability ${_money(d['companyOnlineLiabilityMinor'] as int?, cur)}'),
              Text('Platform ${_money(d['platformFeeMinor'] as int?, cur)}'),
              Text('VAT ${_money(d['recordedVatMinor'] as int?, cur)}'),
              Text('Discount ${_money(d['recordedDiscountMinor'] as int?, cur)}'),
              Text('Net ${_money(d['netTripPositionMinor'] as int?, cur)}'),
              const SizedBox(height: 12),
              Text(uiTr(context, 'Amount Due'), style: theme.titleMedium),
              Text(_money(d['absoluteSettlementAmountMinor'] as int?, cur)),
              Text('${uiTr(context, 'Paid')}: ${_money(d['paidConfirmedMinor'] as int?, cur)}'),
              Text('${uiTr(context, 'Outstanding')}: ${_money(d['outstandingMinor'] as int?, cur)}'),
              Text('${uiTr(context, 'Direction')}: ${d['direction']}'),
              Text('Eligible ${d['eligibleTripCount']} · Excluded ${d['excludedTripCount']} · DERIVED ${d['derivedCount']}'),
              const SizedBox(height: 12),
              if (canWrite && !_busy) ...[
                if (d['status'] == 'draft')
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () async {
                          await SettlementLedgerClient.refreshDraft(settlementId: id);
                        },
                        child: Text(uiTr(context, 'Refresh Preview')),
                      ),
                      FilledButton(
                        onPressed: () => _lock(d),
                        child: Text(uiTr(context, 'Lock Settlement')),
                      ),
                      OutlinedButton(
                        onPressed: () => _voidLocked(d),
                        child: Text(uiTr(context, 'Void draft')),
                      ),
                    ],
                  ),
                if (d['status'] == 'locked' || d['status'] == 'partially_paid')
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _recordPayment(d),
                        child: Text(uiTr(context, 'Record Payment')),
                      ),
                      OutlinedButton(
                        onPressed: () => _voidLocked(d),
                        child: Text(uiTr(context, 'Void locked')),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 16),
              Text(uiTr(context, 'Payments'), style: theme.titleMedium),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('financial_settlement_payments')
                    .where('settlementId', isEqualTo: id)
                    .snapshots(),
                builder: (context, paySnap) {
                  if (!paySnap.hasData) return const SizedBox.shrink();
                  return Column(
                    children: [
                      for (final p in paySnap.data!.docs)
                        ListTile(
                          dense: true,
                          title: Text(
                            '${p.data()['method']} · ${_money(p.data()['amountMinor'] as int?, cur)} · ${p.data()['status']}',
                          ),
                          subtitle: Text(
                            '${p.data()['externalReference'] ?? ''} · ${p.data()['createdBy']} · ${p.data()['receiptNumber'] ?? ''}',
                          ),
                          trailing: canWrite && !_busy
                              ? (p.data()['status'] == 'pending'
                                  ? TextButton(
                                      onPressed: () => _confirmPayment(
                                        d,
                                        {...p.data(), 'paymentId': p.id},
                                      ),
                                      child: Text(uiTr(context, 'Confirm')),
                                    )
                                  : p.data()['status'] == 'confirmed'
                                      ? TextButton(
                                          onPressed: () => _reversePayment(
                                            d,
                                            {...p.data(), 'paymentId': p.id},
                                            cur,
                                          ),
                                          child: Text(uiTr(context, 'Reverse')),
                                        )
                                      : (p.data()['receiptNumber'] != null
                                          ? TextButton(
                                              onPressed: () => context.pushNamed(
                                                AdminSettlementReceiptWidget.routeName,
                                                queryParameters: {
                                                  'paymentId': serializeParam(
                                                    p.id,
                                                    ParamType.String,
                                                  ),
                                                }.withoutNulls,
                                              ),
                                              child: Text(uiTr(context, 'Receipt')),
                                            )
                                          : null))
                              : (p.data()['receiptNumber'] != null
                                  ? TextButton(
                                      onPressed: () => context.pushNamed(
                                        AdminSettlementReceiptWidget.routeName,
                                        queryParameters: {
                                          'paymentId': serializeParam(
                                            p.id,
                                            ParamType.String,
                                          ),
                                        }.withoutNulls,
                                      ),
                                      child: Text(uiTr(context, 'Receipt')),
                                    )
                                  : null),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(uiTr(context, 'الرحلات'), style: theme.titleMedium),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('financial_settlements')
                    .doc(id)
                    .collection('lines')
                    .snapshots(),
                builder: (context, lines) {
                  if (!lines.hasData) return const SizedBox.shrink();
                  return Column(
                    children: [
                      for (final l in lines.data!.docs)
                        ListTile(
                          dense: true,
                          title: Text(l.id),
                          subtitle: Text(
                            '${l.data()['paymentMethod']} · ${l.data()['confidence']} · '
                            'paid ${l.data()['customerPaidMinor']} · net ${l.data()['driverNetMinor']}',
                          ),
                        ),
                    ],
                  );
                },
              ),
              Text(uiTr(context, 'مستبعد'), style: theme.titleMedium),
              for (final e in (d['excluded'] as List? ?? []))
                Text('• ${e is Map ? e['orderId'] : e} ${e is Map ? e['reason'] : ''}'),
              const SizedBox(height: 12),
              Text(uiTr(context, 'Unallocated Payments'), style: theme.titleMedium),
              Text(
                uiTr(
                  context,
                  'Legacy company_payments stay UNALLOCATED until an admin selects them explicitly. No heuristic matching.',
                ),
                style: theme.bodySmall,
              ),
              if (d['paymentEvidence'] is Map) ...[
                const SizedBox(height: 12),
                Text(uiTr(context, 'Payment Evidence'), style: theme.titleMedium),
                Text('${d['paymentEvidence']}'),
              ],
              const SizedBox(height: 12),
              Text(uiTr(context, 'Audit Timeline'), style: theme.titleMedium),
              if (d['status'] != 'draft')
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy ? null : _verifySource,
                    child: Text(uiTr(context, 'Verify Against Current Source')),
                  ),
                ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('financial_settlements')
                    .doc(id)
                    .collection('events')
                    .snapshots(),
                builder: (context, ev) {
                  if (!ev.hasData) return const SizedBox.shrink();
                  final docs = [...ev.data!.docs]..sort((a, b) {
                      final ta = a.data()['timestamp'] as String? ?? '';
                      final tb = b.data()['timestamp'] as String? ?? '';
                      return ta.compareTo(tb);
                    });
                  return Column(
                    children: [
                      for (final e in docs)
                        ListTile(
                          dense: true,
                          title: Text('${e.data()['type']}'),
                          subtitle: Text(
                            '${e.data()['actorRole']} · ${e.data()['beforeStatus']} → ${e.data()['afterStatus']}',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

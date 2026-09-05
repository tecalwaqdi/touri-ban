import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_enterprise_kit.dart'
    show AdminStatusBadge, AdminBadgeTone;
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_error_messages.dart';
import '/core/admin_currency.dart';
import '/core/finance/admin_finance_ui_labels.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/settlement_detail_presentation.dart';
import '/core/finance/finance_runtime_gate.dart';
import '/core/finance/money_amount.dart';
import '/core/finance/settlement_ledger_client.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/settlement_state_labels.dart';
import '/core/finance/settlement_visual_fixture.dart';
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
    final symbol = AdminCurrency.symbolByCode[currency] ?? currency;
    final major = (minor ?? 0) / 100.0;
    return AdminOrderMoneyDisplay.formatMajor(major, symbol: symbol);
  }

  void _snackError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(adminFriendlyError(context, e))),
    );
  }

  Future<void> _lock(Map<String, dynamic> data) async {
    if (!FinanceRuntimeGate.canAttemptFinanceWrites) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(
              context,
              'البيانات المالية تقريبية — الكتابة المالية غير متاحة',
            ),
          ),
        ),
      );
      return;
    }
    final derived = (data['derivedCount'] as num?)?.toInt() ?? 0;
    final cur = data['currency'] as String? ?? 'SAR';
    final due = data['absoluteSettlementAmountMinor'] as int?;
    final ok = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'تأكيد اعتماد التسوية'),
      whatHappens: [
        '${uiTr(context, 'الرحلات')}: ${data['eligibleTripCount']}',
        '${uiTr(context, 'ذمة نقدية')}: ${_money(data['driverCashLiabilityMinor'] as int?, cur)}',
        '${uiTr(context, 'ذمة إلكترونية')}: ${_money(data['companyOnlineLiabilityMinor'] as int?, cur)}',
        '${uiTr(context, 'الصافي')}: ${_money(data['netTripPositionMinor'] as int?, cur)}',
        if (derived > 0)
          '${uiTr(context, 'تتضمن هذه التسوية')} $derived ${uiTr(context, 'سجلاً مالياً مشتقاً.')}',
      ].join('\n'),
      subject: '${data['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'تُثبَّت بنود الرحلات في التسوية'),
      confirmLabel: uiTr(context, 'اعتماد التسوية'),
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
      title: uiTr(context, 'إلغاء التسوية'),
      whatHappens: uiTr(
        context,
        'يلغي هذه التسوية. محاسبي فقط — بدون حركة محفظة.',
      ),
      subject: '${data['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'تصبح التسوية ملغاة ولا يمكن دفعها'),
      confirmLabel: uiTr(context, 'إلغاء'),
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
            child: Text(uiTr(ctx, 'إلغاء')),
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
              title: Text(uiTr(ctx, 'تسجيل دفعة')),
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
                      items: [
                        DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Text(SettlementStateLabels.methodAr(
                                'bank_transfer'))),
                        DropdownMenuItem(
                            value: 'cash',
                            child:
                                Text(SettlementStateLabels.methodAr('cash'))),
                        DropdownMenuItem(
                            value: 'external_transfer',
                            child: Text(SettlementStateLabels.methodAr(
                                'external_transfer'))),
                        DropdownMenuItem(
                            value: 'other',
                            child:
                                Text(SettlementStateLabels.methodAr('other'))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => method = v);
                      },
                    ),
                    TextField(
                      controller: refCtrl,
                      decoration:
                          InputDecoration(labelText: uiTr(ctx, 'المرجع')),
                    ),
                    if (method == 'cash')
                      TextField(
                        controller: receivedCtrl,
                        decoration:
                            InputDecoration(labelText: uiTr(ctx, 'المستلم')),
                      ),
                    Text(
                      uiTr(ctx,
                          'يحفظ كـ Pending — لا يخفض Outstanding حتى التأكيد'),
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
                  child: Text(uiTr(ctx, 'حفظ كقيد انتظار')),
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
        receivedBy:
            receivedCtrl.text.trim().isEmpty ? null : receivedCtrl.text.trim(),
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPayment(
      Map<String, dynamic> settlement, Map<String, dynamic> pay) async {
    if (!FinanceRuntimeGate.canAttemptFinanceWrites) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(
              context,
              'البيانات المالية تقريبية — الكتابة المالية غير متاحة',
            ),
          ),
        ),
      );
      return;
    }
    final cur = settlement['currency'] as String? ?? 'SAR';
    final due =
        (settlement['absoluteSettlementAmountMinor'] as num?)?.toInt() ?? 0;
    final paid = (settlement['paidConfirmedMinor'] as num?)?.toInt() ?? 0;
    final thisAmt = (pay['amountMinor'] as num?)?.toInt() ?? 0;
    final remaining = due - paid - thisAmt;
    final ok = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'تأكيد الدفعة'),
      whatHappens: [
        '${uiTr(context, 'التسوية')}: ${_money(due, cur)}',
        '${uiTr(context, 'المدفوع')}: ${_money(paid, cur)}',
        '${uiTr(context, 'هذه الدفعة')}: ${_money(thisAmt, cur)}',
        '${uiTr(context, 'المتبقي بعد التأكيد')}: ${_money(remaining, cur)}',
      ].join('\n'),
      subject: '${settlement['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'يخفض المتبقي؛ محاسبي فقط'),
      confirmLabel: uiTr(context, 'تأكيد الدفعة'),
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
          title: Text(uiTr(ctx, 'التحقق من المصدر الحالي')),
          content: Text(
            flag == 'SOURCE_CHANGED_AFTER_LOCK'
                ? uiTr(ctx, 'تغير المصدر بعد القفل — اللقطة دون تغيير')
                : '${uiTr(ctx, 'اللقطة مطابقة للمصدر الحالي.')} mutated=${r['mutated']}',
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
      title: uiTr(context, 'عكس الدفعة'),
      whatHappens: uiTr(
        context,
        'يعكس دفعة مؤكدة. سيزداد المتبقي.',
      ),
      subject: '${settlement['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'يزيد المتبقي؛ محاسبي فقط'),
      confirmLabel: uiTr(context, 'عكس'),
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
        title: Text(uiTr(ctx, 'عكس الدفعة')),
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
    final canWrite = AdminRoleService.canWriteSettlements &&
        FinanceRuntimeGate.canAttemptFinanceWrites;
    if (id == null || id.isEmpty) {
      return AdminLayoutWidget(
        padContent: false,
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: uiTr(context, 'التسوية'),
        child: Text(uiTr(context, 'معرّف التسوية مفقود')),
      );
    }

    final fixture = SettlementVisualFixture.dataFor(id);
    if (fixture != null) {
      return AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: uiTr(context, 'تفاصيل التسوية'),
        child: ListView(
          padding: AdminUi.pagePadding(context),
          children: [
            AdminStatusBadge(
              label: uiTr(context, 'عرض تجريبي — ليس بيانات إنتاج'),
              tone: AdminBadgeTone.info,
            ),
            const SizedBox(height: 8),
            Text(
              '${fixture['settlementCode']} · ${AdminFinanceUiLabels.settlementStatusAr('${fixture['status']}')}',
              style: theme.headlineSmall,
            ),
            Text(
              '${uiTr(context, 'المندوب')}: ${fixture['driverId'] ?? '—'} · '
              '${uiTr(context, 'الدولة')}: ${fixture['countryId'] ?? '—'} · '
              '${AdminCurrency.symbolByCode['${fixture['currency']}'] ?? fixture['currency']} · '
              '${AdminFinanceUiLabels.settlementDirectionAr('${fixture['direction']}')}',
              softWrap: true,
            ),
            Text(
              '${fixture['periodStart']} → ${fixture['periodEnd']}',
              softWrap: true,
            ),
            const SizedBox(height: 12),
            Text(
              '${uiTr(context, 'المبلغ المستحق')}: '
              '${_money(fixture['amountDueMinor'] as int?, 'SAR')}',
            ),
            Text(
              '${uiTr(context, 'المدفوع')}: '
              '${_money(fixture['paidMinor'] as int?, 'SAR')}',
            ),
            Text(
              '${uiTr(context, 'المتبقي')}: '
              '${_money(fixture['outstandingMinor'] as int?, 'SAR')}',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _lock(fixture),
                  child: Text(uiTr(context, 'قفل التسوية')),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await showAdminConfirmDialog(
                      context: context,
                      title: uiTr(context, 'تأكيد الدفعة'),
                      whatHappens: uiTr(
                        context,
                        'Fixture only — Cancel to dismiss',
                      ),
                      subject: fixture['settlementCode'] as String,
                      currency: 'SAR',
                      amount: _money(50000, 'SAR'),
                      direction: 'DRIVER_PAYS_COMPANY',
                      reference: id,
                      confirmLabel: uiTr(context, 'تأكيد الدفعة'),
                    );
                  },
                  child: Text(uiTr(context, 'تأكيد الدفعة')),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await showAdminConfirmDialog(
                      context: context,
                      title: uiTr(context, 'عكس الدفعة'),
                      whatHappens: uiTr(
                        context,
                        'Fixture only — Cancel to dismiss',
                      ),
                      subject: fixture['settlementCode'] as String,
                      currency: 'SAR',
                      amount: _money(50000, 'SAR'),
                      direction: 'DRIVER_PAYS_COMPANY',
                      reference: id,
                      destructive: true,
                      irreversible: true,
                    );
                  },
                  child: Text(uiTr(context, 'عكس الدفعة')),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await showAdminConfirmDialog(
                      context: context,
                      title: uiTr(context, 'إلغاء التسوية'),
                      whatHappens: uiTr(
                        context,
                        'Fixture only — Cancel to dismiss',
                      ),
                      subject: fixture['settlementCode'] as String,
                      currency: 'SAR',
                      amount: _money(80400, 'SAR'),
                      direction: 'DRIVER_PAYS_COMPANY',
                      reference: id,
                      destructive: true,
                      irreversible: true,
                    );
                  },
                  child: Text(uiTr(context, 'إلغاء التسوية')),
                ),
              ],
            ),
          ],
        ),
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
            return Text(
              uiTr(context, 'التسوية غير موجودة'),
              style: AccountantFinanceText.body(theme),
            );
          }
          final d = snap.data!.data()!;
          return _AccountantSettlementDetailBody(
            settlementId: id,
            data: d,
            busy: _busy,
            canWrite: canWrite,
            money: _money,
            onLock: () => _lock(d),
            onVoid: () => _voidLocked(d),
            onRecordPayment: () => _recordPayment(d),
            onRefreshDraft: () async {
              await SettlementLedgerClient.refreshDraft(settlementId: id);
            },
            onConfirmPayment: (pay) => _confirmPayment(d, pay),
            onReversePayment: (pay, cur) => _reversePayment(d, pay, cur),
            onVerifySource: _verifySource,
          );
        },
      ),
    );
  }
}

/// F2.2 accountant settlement detail — business-first, contrast-safe.
class _AccountantSettlementDetailBody extends StatelessWidget {
  const _AccountantSettlementDetailBody({
    required this.settlementId,
    required this.data,
    required this.busy,
    required this.canWrite,
    required this.money,
    required this.onLock,
    required this.onVoid,
    required this.onRecordPayment,
    required this.onRefreshDraft,
    required this.onConfirmPayment,
    required this.onReversePayment,
    required this.onVerifySource,
  });

  final String settlementId;
  final Map<String, dynamic> data;
  final bool busy;
  final bool canWrite;
  final String Function(int? minor, String currency) money;
  final VoidCallback onLock;
  final VoidCallback onVoid;
  final VoidCallback onRecordPayment;
  final Future<void> Function() onRefreshDraft;
  final Future<void> Function(Map<String, dynamic> pay) onConfirmPayment;
  final Future<void> Function(Map<String, dynamic> pay, String currency)
      onReversePayment;
  final Future<void> Function() onVerifySource;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final cur = data['currency'] as String? ?? 'SAR';
    final due =
        (data['absoluteSettlementAmountMinor'] as num?)?.toInt() ?? 0;
    final paid = (data['paidConfirmedMinor'] as num?)?.toInt() ?? 0;
    final out = (data['outstandingMinor'] as num?)?.toInt() ?? 0;
    final status = '${data['status'] ?? ''}';
    final direction = '${data['direction'] ?? ''}';
    final driverId = '${data['driverId'] ?? ''}'.trim();
    final code = '${data['settlementCode'] ?? settlementId}';
    final outcome = SettlementDetailPresentation.settlementOutcomeAr(
      direction: direction,
      status: status,
      dueMinor: due,
      paidMinor: paid,
      outstandingMinor: out,
    );

    return ListView(
      padding: AdminUi.pagePadding(context),
      children: [
        Text(code, style: AccountantFinanceText.pageTitle(theme)),
        const SizedBox(height: 8),
        Text(outcome, style: AccountantFinanceText.body(theme).copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 12),
        _sectionCard(
          theme,
          title: uiTr(context, 'ملخص التسوية'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kv(theme, uiTr(context, 'رقم التسوية'), code),
              _kv(
                theme,
                uiTr(context, 'الحالة'),
                SettlementDetailPresentation.settlementStatusAr(status),
              ),
              _kv(
                theme,
                uiTr(context, 'الدولة'),
                SettlementDetailPresentation.countryAr(
                  '${data['countryId'] ?? ''}',
                ),
              ),
              _driverRow(theme, driverId),
              _kv(
                theme,
                uiTr(context, 'الفترة'),
                SettlementDetailPresentation.periodAr(
                  data['periodStart'],
                  data['periodEnd'],
                ),
              ),
              _kv(
                theme,
                uiTr(context, 'اتجاه المستحق'),
                SettlementDetailPresentation.directionAr(direction),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          theme,
          title: uiTr(context, 'المبالغ'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _moneyRow(theme, uiTr(context, 'المبلغ المستحق'), money(due, cur)),
              _moneyRow(theme, uiTr(context, 'المدفوع'), money(paid, cur)),
              _moneyRow(theme, uiTr(context, 'المتبقي'), money(out, cur)),
            ],
          ),
        ),
        if (canWrite && !busy) ...[
          const SizedBox(height: 12),
          if (status == 'draft')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () async => onRefreshDraft(),
                  child: Text(uiTr(context, 'تحديث الأرقام')),
                ),
                FilledButton(
                  onPressed: onLock,
                  child: Text(uiTr(context, 'اعتماد التسوية')),
                ),
                OutlinedButton(
                  onPressed: onVoid,
                  child: Text(uiTr(context, 'إلغاء المسودة')),
                ),
              ],
            ),
          if (status == 'locked' || status == 'partially_paid')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onRecordPayment,
                  child: Text(uiTr(context, 'تسجيل دفعة')),
                ),
                OutlinedButton(
                  onPressed: onVoid,
                  child: Text(uiTr(context, 'إلغاء التسوية')),
                ),
              ],
            ),
        ],
        const SizedBox(height: 12),
        _sectionCard(
          theme,
          title: uiTr(context, 'الدفعات'),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('financial_settlement_payments')
                .where('settlementId', isEqualTo: settlementId)
                .limit(100)
                .snapshots(),
            builder: (context, paySnap) {
              if (paySnap.hasError) {
                return Text(
                  uiTr(context, 'تعذر تحميل المدفوعات'),
                  style: AccountantFinanceText.body(theme),
                );
              }
              if (!paySnap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = paySnap.data!.docs;
              if (docs.isEmpty) {
                return Text(
                  uiTr(context, 'لا توجد دفعات'),
                  style: AccountantFinanceText.label(theme),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final p in docs)
                    _paymentRow(
                      context,
                      theme,
                      p,
                      cur,
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          theme,
          title: uiTr(context, 'الرحلات'),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('financial_settlements')
                .doc(settlementId)
                .collection('lines')
                .limit(200)
                .snapshots(),
            builder: (context, lines) {
              if (lines.hasError) {
                return Text(
                  uiTr(context, 'تعذر تحميل الرحلات'),
                  style: AccountantFinanceText.body(theme),
                );
              }
              if (!lines.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final real = lines.data!.docs.where((l) {
                return !SettlementDetailPresentation.isQaTripLine(
                  l.id,
                  l.data(),
                );
              }).toList();
              if (real.isEmpty) {
                return Text(
                  uiTr(context, 'لا توجد رحلات مؤهلة'),
                  style: AccountantFinanceText.label(theme),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final l in real)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AccountantFinanceLabels.tripRefLabel(l.id),
                            style: AccountantFinanceText.body(theme).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${SettlementDetailPresentation.paymentMethodAr('${l.data()['paymentMethod']}')}'
                            ' · ${uiTr(context, 'صافي السائق')}: '
                            '${money((l.data()['driverNetMinor'] as num?)?.toInt(), cur)}',
                            style: AccountantFinanceText.label(theme),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Builder(builder: (context) {
          final excluded = (data['excluded'] as List? ?? [])
              .where((e) {
                final oid = e is Map ? '${e['orderId'] ?? ''}' : '$e';
                return !SettlementDetailPresentation.isQaTripId(oid);
              })
              .toList();
          if (excluded.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _sectionCard(
              theme,
              title: uiTr(context, 'مستبعد'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in excluded)
                    Text(
                      '• ${e is Map ? AccountantFinanceLabels.tripRefLabel('${e['orderId'] ?? ''}') : e}',
                      style: AccountantFinanceText.body(theme),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        _sectionCard(
          theme,
          title: uiTr(context, 'دفعات غير مخصصة'),
          child: Text(
            SettlementDetailPresentation.unallocatedPaymentsAr(),
            style: AccountantFinanceText.body(theme),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          theme,
          title: uiTr(context, 'سجل العمليات'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (status != 'draft')
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: busy ? null : () => onVerifySource(),
                    child: Text(uiTr(context, 'التحقق من المصدر الحالي')),
                  ),
                ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('financial_settlements')
                    .doc(settlementId)
                    .collection('events')
                    .limit(100)
                    .snapshots(),
                builder: (context, ev) {
                  if (ev.hasError) {
                    return Text(
                      uiTr(context, 'تعذر تحميل الأحداث'),
                      style: AccountantFinanceText.body(theme),
                    );
                  }
                  if (!ev.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final docs = [...ev.data!.docs]..sort((a, b) {
                      final ta = a.data()['timestamp'] as String? ?? '';
                      final tb = b.data()['timestamp'] as String? ?? '';
                      return ta.compareTo(tb);
                    });
                  if (docs.isEmpty) {
                    return Text(
                      uiTr(context, 'لا يوجد سجل'),
                      style: AccountantFinanceText.label(theme),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in docs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SettlementDetailPresentation.humanDateAr(
                                  e.data()['timestamp'],
                                ),
                                style: AccountantFinanceText.label(theme),
                              ),
                              Text(
                                SettlementDetailPresentation.auditEventAr(
                                  '${e.data()['type']}',
                                ),
                                style: AccountantFinanceText.body(theme)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${uiTr(context, 'بواسطة')}: '
                                '${SettlementDetailPresentation.actorRoleAr('${e.data()['actorRole']}')}',
                                style: AccountantFinanceText.label(theme),
                              ),
                              Builder(builder: (_) {
                                final note =
                                    SettlementDetailPresentation
                                        .statusTransitionAr(
                                  '${e.data()['beforeStatus'] ?? ''}',
                                  '${e.data()['afterStatus'] ?? ''}',
                                );
                                if (note.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  note,
                                  style: AccountantFinanceText.label(theme),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            title: Text(
              uiTr(context, 'بيانات تقنية'),
              style: AccountantFinanceText.sectionTitle(theme),
            ),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${uiTr(context, 'معرّف التسوية')}: $settlementId',
                      style: AccountantFinanceText.label(theme),
                    ),
                    Text(
                      '${uiTr(context, 'معرف السائق')}: ${driverId.isEmpty ? '—' : driverId}',
                      style: AccountantFinanceText.label(theme),
                    ),
                    Text(
                      '${uiTr(context, 'مسار الدولة')}: ${data['countryId'] ?? '—'}',
                      style: AccountantFinanceText.label(theme),
                    ),
                    Text(
                      '${uiTr(context, 'الفترة خام')}: ${data['periodStart']} → ${data['periodEnd']}',
                      style: AccountantFinanceText.label(theme),
                    ),
                    Text(
                      '${uiTr(context, 'مؤهلة')}: ${data['eligibleTripCount']} · '
                      '${uiTr(context, 'مستبعدة')}: ${data['excludedTripCount']} · '
                      '${uiTr(context, 'مشتقة')}: ${data['derivedCount']}',
                      style: AccountantFinanceText.label(theme),
                    ),
                    if (data['paymentEvidence'] is Map)
                      Text(
                        '${uiTr(context, 'أدلة الدفع')}: ${data['paymentEvidence']}',
                        style: AccountantFinanceText.label(theme),
                      ),
                    if (AdminRoleService.isSuperAdmin)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('financial_settlements')
                            .doc(settlementId)
                            .collection('lines')
                            .limit(200)
                            .snapshots(),
                        builder: (context, lines) {
                          if (!lines.hasData) {
                            return const SizedBox.shrink();
                          }
                          final qa = lines.data!.docs.where((l) {
                            return SettlementDetailPresentation.isQaTripLine(
                              l.id,
                              l.data(),
                            );
                          }).toList();
                          if (qa.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${uiTr(context, 'تشخيص تقني — رحلات اختبار')}: '
                              '${qa.map((e) => e.id).join(', ')}',
                              style: AccountantFinanceText.label(theme),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    FlutterFlowTheme theme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AccountantFinanceText.sectionTitle(theme)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _kv(FlutterFlowTheme theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: AccountantFinanceText.label(theme)),
          ),
          Expanded(
            child: Text(v, style: AccountantFinanceText.body(theme)),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(FlutterFlowTheme theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: AccountantFinanceText.label(theme)),
          ),
          Text(v, style: AccountantFinanceText.money(theme)),
        ],
      ),
    );
  }

  Widget _driverRow(FlutterFlowTheme theme, String driverId) {
    if (driverId.isEmpty) {
      return _kv(
        theme,
        'السائق',
        SettlementDetailPresentation.driverFallbackAr(),
      );
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('user').doc(driverId).get(),
      builder: (context, snap) {
        final name = SettlementDetailPresentation.driverDisplayName(
          snap.data?.data(),
        );
        final shown =
            SettlementDetailPresentation.looksLikeRawUid(name, driverId)
                ? SettlementDetailPresentation.driverFallbackAr()
                : name;
        return _kv(theme, uiTr(context, 'السائق'), shown);
      },
    );
  }

  Widget _paymentRow(
    BuildContext context,
    FlutterFlowTheme theme,
    QueryDocumentSnapshot<Map<String, dynamic>> p,
    String cur,
  ) {
    final d = p.data();
    final ref = '${d['externalReference'] ?? d['receiptNumber'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            SettlementDetailPresentation.paymentMethodAr('${d['method']}'),
            style: AccountantFinanceText.body(theme).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${uiTr(context, 'المبلغ')}: ${money((d['amountMinor'] as num?)?.toInt(), cur)}',
            style: AccountantFinanceText.money(theme),
          ),
          Text(
            '${uiTr(context, 'الحالة')}: '
            '${SettlementDetailPresentation.paymentStatusAr('${d['status']}')}',
            style: AccountantFinanceText.label(theme),
          ),
          Text(
            '${uiTr(context, 'التاريخ')}: '
            '${SettlementDetailPresentation.humanDateAr(d['createdAt'] ?? d['confirmedAt'])}',
            style: AccountantFinanceText.label(theme),
          ),
          if (ref.isNotEmpty)
            Text(
              '${uiTr(context, 'المرجع')}: $ref',
              style: AccountantFinanceText.label(theme),
            ),
          if (canWrite && !busy)
            Wrap(
              spacing: 4,
              children: [
                if (d['status'] == 'pending')
                  TextButton(
                    onPressed: () => onConfirmPayment({...d, 'paymentId': p.id}),
                    child: Text(uiTr(context, 'تأكيد')),
                  ),
                if (d['status'] == 'confirmed')
                  TextButton(
                    onPressed: () =>
                        onReversePayment({...d, 'paymentId': p.id}, cur),
                    child: Text(uiTr(context, 'عكس')),
                  ),
                if (d['receiptNumber'] != null)
                  TextButton(
                    onPressed: () => context.pushNamed(
                      AdminSettlementReceiptWidget.routeName,
                      queryParameters: {
                        'paymentId': serializeParam(p.id, ParamType.String),
                      }.withoutNulls,
                    ),
                    child: Text(uiTr(context, 'إيصال')),
                  ),
              ],
            )
          else if (d['receiptNumber'] != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => context.pushNamed(
                  AdminSettlementReceiptWidget.routeName,
                  queryParameters: {
                    'paymentId': serializeParam(p.id, ParamType.String),
                  }.withoutNulls,
                ),
                child: Text(uiTr(context, 'إيصال')),
              ),
            ),
        ],
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_enterprise_kit.dart' show AdminStatusBadge, AdminBadgeTone;
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_error_messages.dart';
import '/core/admin_currency.dart';
import '/core/finance/admin_money_presentation.dart';
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
      title: uiTr(context, 'تأكيد قفل التسوية'),
      whatHappens: [
        '${uiTr(context, 'الرحلات')}: ${data['eligibleTripCount']}',
        '${uiTr(context, 'ذمة نقدية')}: ${_money(data['driverCashLiabilityMinor'] as int?, cur)}',
        '${uiTr(context, 'ذمة إلكترونية')}: ${_money(data['companyOnlineLiabilityMinor'] as int?, cur)}',
        '${uiTr(context, 'الصافي')}: ${_money(data['netTripPositionMinor'] as int?, cur)}',
        if (derived > 0)
          '${uiTr(context, 'تتضمن هذه التسوية')} $derived ${uiTr(context, 'سجلاً مالياً مشتقاً.')}',
        uiTr(context, 'سجل محاسبي فقط — بدون حركة محفظة'),
      ].join('\n'),
      subject: '${data['settlementCode'] ?? widget.settlementId}',
      impact: uiTr(context, 'يقفل بنود الرحلات؛ بدون حركة محفظة'),
      confirmLabel: uiTr(context, 'قفل التسوية'),
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
                        DropdownMenuItem(value: 'bank_transfer', child: Text(SettlementStateLabels.methodAr('bank_transfer'))),
                        DropdownMenuItem(value: 'cash', child: Text(SettlementStateLabels.methodAr('cash'))),
                        DropdownMenuItem(value: 'external_transfer', child: Text(SettlementStateLabels.methodAr('external_transfer'))),
                        DropdownMenuItem(value: 'other', child: Text(SettlementStateLabels.methodAr('other'))),
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
                        decoration: InputDecoration(labelText: uiTr(ctx, 'المستلم')),
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
        receivedBy: receivedCtrl.text.trim().isEmpty ? null : receivedCtrl.text.trim(),
      );
    } catch (e) {
      _snackError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPayment(Map<String, dynamic> settlement, Map<String, dynamic> pay) async {
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
    final due = (settlement['absoluteSettlementAmountMinor'] as num?)?.toInt() ?? 0;
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
              '${fixture['settlementCode']} · ${fixture['status']}',
              style: theme.headlineSmall,
            ),
            Text(
              'Driver ${fixture['driverId']} · ${fixture['countryId']} · '
              '${fixture['currency']} · ${fixture['direction']}',
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
                softWrap: true,
              ),
              Text('${d['periodStart']} → ${d['periodEnd']}', softWrap: true),
              const SizedBox(height: 12),
              Text(uiTr(context, 'الإجماليات'), style: theme.titleMedium),
              Text('${uiTr(context, 'التحصيل النقدي')}: ${_money(d['cashCustomerCollectedMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'استحقاق المندوب النقدي')}: ${_money(d['cashDriverEntitlementMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'ذمة المندوب النقدية')}: ${_money(d['driverCashLiabilityMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'التحصيل الإلكتروني')}: ${_money(d['onlineCustomerCollectedMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'ذمة الشركة الإلكترونية')}: ${_money(d['companyOnlineLiabilityMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'عمولة المنصة')}: ${_money(d['platformFeeMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'الضريبة')}: ${_money(d['recordedVatMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'الخصم')}: ${_money(d['recordedDiscountMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'الصافي')}: ${_money(d['netTripPositionMinor'] as int?, cur)}', softWrap: true),
              const SizedBox(height: 12),
              Text(uiTr(context, 'المبلغ المستحق'), style: theme.titleMedium),
              Text(_money(d['absoluteSettlementAmountMinor'] as int?, cur), softWrap: true),
              Text('${uiTr(context, 'المدفوع')}: ${_money(d['paidConfirmedMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'المتبقي')}: ${_money(d['outstandingMinor'] as int?, cur)}', softWrap: true),
              Text('${uiTr(context, 'الاتجاه')}: ${SettlementStateLabels.directionAr('${d['direction']}')}', softWrap: true),
              Text(
                '${uiTr(context, 'مؤهلة')}: ${d['eligibleTripCount']} · ${uiTr(context, 'مستبعدة')}: ${d['excludedTripCount']} · ${uiTr(context, 'مشتقة')}: ${d['derivedCount']}',
                softWrap: true,
              ),
              const SizedBox(height: 12),
              if (canWrite && !_busy) ...[
                if (d['status'] == 'draft')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () async {
                          await SettlementLedgerClient.refreshDraft(settlementId: id);
                        },
                        child: Text(uiTr(context, 'تحديث المعاينة')),
                      ),
                      FilledButton(
                        onPressed: () => _lock(d),
                        child: Text(uiTr(context, 'قفل التسوية')),
                      ),
                      OutlinedButton(
                        onPressed: () => _voidLocked(d),
                        child: Text(uiTr(context, 'إلغاء المسودة')),
                      ),
                    ],
                  ),
                if (d['status'] == 'locked' || d['status'] == 'partially_paid')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _recordPayment(d),
                        child: Text(uiTr(context, 'تسجيل دفعة')),
                      ),
                      OutlinedButton(
                        onPressed: () => _voidLocked(d),
                        child: Text(uiTr(context, 'إلغاء المقفلة')),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 16),
              Text(uiTr(context, 'الدفعات'), style: theme.titleMedium),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('financial_settlement_payments')
                    .where('settlementId', isEqualTo: id)
                    .limit(100)
                    .snapshots(),
                builder: (context, paySnap) {
                  if (paySnap.hasError) {
                    return Text(
                      uiTr(context, 'تعذر تحميل المدفوعات'),
                      softWrap: true,
                    );
                  }
                  if (!paySnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final p in paySnap.data!.docs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${SettlementStateLabels.methodAr('${p.data()['method']}')} · ${_money(p.data()['amountMinor'] as int?, cur)} · ${SettlementStateLabels.statusAr('${p.data()['status']}')}',
                                softWrap: true,
                              ),
                              Text(
                                '${p.data()['externalReference'] ?? ''} · ${p.data()['createdBy']} · ${p.data()['receiptNumber'] ?? ''}',
                                softWrap: true,
                                style: theme.bodySmall,
                              ),
                              if (canWrite && !_busy)
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    if (p.data()['status'] == 'pending')
                                      TextButton(
                                        onPressed: () => _confirmPayment(
                                          d,
                                          {...p.data(), 'paymentId': p.id},
                                        ),
                                        child: Text(uiTr(context, 'تأكيد')),
                                      ),
                                    if (p.data()['status'] == 'confirmed')
                                      TextButton(
                                        onPressed: () => _reversePayment(
                                          d,
                                          {...p.data(), 'paymentId': p.id},
                                          cur,
                                        ),
                                        child: Text(uiTr(context, 'عكس')),
                                      ),
                                    if (p.data()['receiptNumber'] != null)
                                      TextButton(
                                        onPressed: () => context.pushNamed(
                                          AdminSettlementReceiptWidget.routeName,
                                          queryParameters: {
                                            'paymentId': serializeParam(
                                              p.id,
                                              ParamType.String,
                                            ),
                                          }.withoutNulls,
                                        ),
                                        child: Text(uiTr(context, 'إيصال')),
                                      ),
                                  ],
                                )
                              else if (p.data()['receiptNumber'] != null)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton(
                                    onPressed: () => context.pushNamed(
                                      AdminSettlementReceiptWidget.routeName,
                                      queryParameters: {
                                        'paymentId': serializeParam(
                                          p.id,
                                          ParamType.String,
                                        ),
                                      }.withoutNulls,
                                    ),
                                    child: Text(uiTr(context, 'إيصال')),
                                  ),
                                ),
                            ],
                          ),
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
                    .limit(200)
                    .snapshots(),
                builder: (context, lines) {
                  if (lines.hasError) {
                    return Text(
                      uiTr(context, 'تعذر تحميل الرحلات'),
                      softWrap: true,
                    );
                  }
                  if (!lines.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final l in lines.data!.docs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.id, softWrap: true),
                              Text(
                                '${l.data()['paymentMethod']} · ${l.data()['confidence']} · '
                                'paid ${l.data()['customerPaidMinor']} · net ${l.data()['driverNetMinor']}',
                                softWrap: true,
                                style: theme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              Text(uiTr(context, 'مستبعد'), style: theme.titleMedium),
              for (final e in (d['excluded'] as List? ?? []))
                Text(
                  '• ${e is Map ? e['orderId'] : e} ${e is Map ? e['reason'] : ''}',
                  softWrap: true,
                ),
              const SizedBox(height: 12),
              Text(uiTr(context, 'دفعات غير مخصصة'), style: theme.titleMedium),
              Text(
                uiTr(
                  context,
                  'Legacy company_payments stay UNALLOCATED until an admin selects them explicitly. No heuristic matching.',
                ),
                softWrap: true,
                style: theme.bodySmall,
              ),
              if (d['paymentEvidence'] is Map) ...[
                const SizedBox(height: 12),
                Text(uiTr(context, 'أدلة الدفع'), style: theme.titleMedium),
                Text('${d['paymentEvidence']}', softWrap: true),
              ],
              const SizedBox(height: 12),
              Text(uiTr(context, 'سجل التدقيق'), style: theme.titleMedium),
              if (d['status'] != 'draft')
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _busy ? null : _verifySource,
                    child: Text(uiTr(context, 'التحقق من المصدر الحالي')),
                  ),
                ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('financial_settlements')
                    .doc(id)
                    .collection('events')
                    .limit(100)
                    .snapshots(),
                builder: (context, ev) {
                  if (ev.hasError) {
                    return Text(
                      uiTr(context, 'تعذر تحميل الأحداث'),
                      softWrap: true,
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in docs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.data()['type']}', softWrap: true),
                              Text(
                                '${e.data()['actorRole']} · ${e.data()['beforeStatus']} → ${e.data()['afterStatus']}',
                                softWrap: true,
                                style: theme.bodySmall,
                              ),
                            ],
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

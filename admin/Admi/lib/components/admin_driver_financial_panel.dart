import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/financial_accounting_loader.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/financial_state_labels.dart';
import '/core/finance/settlement_ledger_client.dart';
import '/core/finance/settlement_preview.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// Driver financial tab — trip position + settlement workflow (ledger only).
class AdminDriverFinancialPanel extends StatefulWidget {
  const AdminDriverFinancialPanel({
    super.key,
    required this.driverRef,
    this.countryRef,
  });

  final DocumentReference driverRef;
  final DocumentReference? countryRef;

  @override
  State<AdminDriverFinancialPanel> createState() =>
      _AdminDriverFinancialPanelState();
}

class _AdminDriverFinancialPanelState extends State<AdminDriverFinancialPanel> {
  late Future<FinancialReportResult> _future;
  String _previewCurrency = 'SAR';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = FinancialAccountingLoader.load(
      FinancialReportFilter(
        datePreset: AdminDatePreset.all,
        driverRef: widget.driverRef,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AdminDriverFinancialPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverRef.path != widget.driverRef.path) {
      setState(_load);
    }
  }

  String _money(MoneyAmount? m) {
    if (m == null) return '—';
    return AdminOrderMoneyDisplay.formatMoneyAmount(m);
  }

  MoneyAmount _tripNet(FinancialCurrencyTotals t) {
    final minor = t.cashDriversOweCompany.minorUnits -
        t.cashCompanyOwesDrivers.minorUnits -
        t.onlineCompanyOwesDrivers.minorUnits;
    return MoneyAmount(currency: t.currency, minorUnits: minor);
  }

  Future<void> _saveDraft(BuildContext context, SettlementPreview preview) async {
    final countryId = widget.countryRef?.path;
    if (countryId == null || countryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'الدولة مطلوبة'))),
      );
      return;
    }
    if (preview.includedCount > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiTr(context, 'MAX_SETTLEMENT_LINES=200 — ضيّق الفترة'),
          ),
        ),
      );
      return;
    }
    try {
      final result = await SettlementLedgerClient.createDraft(
        driverId: widget.driverRef.id,
        countryId: countryId,
        currency: _previewCurrency,
        periodStart: DateTime.utc(2020),
        periodEnd: DateTime.now().toUtc().add(const Duration(days: 1)),
        idempotencyKey: SettlementLedgerClient.newIdempotencyKey('draft'),
      );
      if (!context.mounted) return;
      final id = result['settlementId'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result['settlementCode']} saved as draft')),
      );
      if (id != null) {
        context.pushNamed(
          AdminSettlementDetailsWidget.routeName,
          queryParameters: {
            'settlementId': serializeParam(id, ParamType.String),
          }.withoutNulls,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminUserFacingErrors.from(context, e))),
      );
    }
  }

  Future<void> _showSettlementPreview(BuildContext context) async {
    final preview = await FinancialAccountingLoader.loadSettlementPreview(
      driverRef: widget.driverRef,
      currency: _previewCurrency,
      filter: FinancialReportFilter(
        datePreset: AdminDatePreset.all,
        driverRef: widget.driverRef,
        currency: _previewCurrency,
      ),
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = FlutterFlowTheme.of(ctx);
        return AlertDialog(
          title: Text(uiTr(ctx, 'معاينة التسوية')),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    uiTr(
                      ctx,
                      'Preview only — no financial changes will be made',
                    ),
                    style: theme.bodySmall.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${uiTr(ctx, 'العملة')}: ${preview.currency}'),
                  Text(
                    '${uiTr(ctx, 'مشمول')}: ${preview.includedCount} · '
                    '${uiTr(ctx, 'مستبعد')}: ${preview.excludedCount}',
                  ),
                  const Divider(),
                  Text(
                    'Cash held: ${_money(preview.cashHeld)}\n'
                    'Cash entitlement: ${_money(preview.cashDriverEntitlement)}\n'
                    'Driver cash liability: ${_money(preview.driverCashLiability)}\n'
                    'Online entitlement / company owes: ${_money(preview.companyOnlineLiability)}\n'
                    'Net: ${_money(preview.netTripSettlement)}\n'
                    'Direction: ${preview.direction}',
                  ),
                  if (preview.includedLines
                      .where((l) => l.confidence == FinancialConfidence.derived)
                      .isNotEmpty)
                    Text(
                      'This settlement includes ${preview.includedLines.where((l) => l.confidence == FinancialConfidence.derived).length} DERIVED financial records.',
                      style: theme.bodySmall,
                    ),
                  if (preview.exclusionCounts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(uiTr(ctx, 'أسباب الاستبعاد')),
                    for (final e in preview.exclusionCounts.entries)
                      Text('• ${e.key}: ${e.value}'),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(uiTr(ctx, 'إغلاق')),
            ),
            if (AdminRoleService.canWriteSettlements)
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveDraft(context, preview);
                },
                child: Text(uiTr(ctx, 'Save Draft')),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FutureBuilder<FinancialReportResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            '${uiTr(context, 'تعذر تحميل المالية')}: '
            '${AdminUserFacingErrors.from(context, snap.error!)}',
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snap.data!;
        final lines = result.allMatchingLines;
        final cash = lines
            .where((l) => l.channel == FinancialPaymentChannel.cash)
            .length;
        final online = lines
            .where((l) => l.channel == FinancialPaymentChannel.online)
            .length;
        final incomplete = lines
            .where((l) => l.confidence == FinancialConfidence.incomplete)
            .length;

        if (result.byCurrency.isNotEmpty &&
            !result.byCurrency.containsKey(_previewCurrency)) {
          _previewCurrency = result.byCurrency.keys.first;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(uiTr(context, 'الملخص المالي'), style: theme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('financial_settlements')
                  .where('driverId', isEqualTo: widget.driverRef.id)
                  .limit(100)
                  .snapshots(),
              builder: (context, ss) {
                if (!ss.hasData) return const SizedBox.shrink();
                final by = <String, Map<String, int>>{};
                for (final d in ss.data!.docs) {
                  final s = d.data();
                  if (s['status'] == 'draft' || s['status'] == 'voided') continue;
                  final c = (s['currency'] as String?) ?? 'SAR';
                  by[c] ??= {
                    'locked': 0,
                    'partial': 0,
                    'settled': 0,
                    'recv': 0,
                    'pay': 0,
                  };
                  final st = s['status'] as String? ?? '';
                  if (st == 'locked') by[c]!['locked'] = by[c]!['locked']! + 1;
                  if (st == 'partially_paid') {
                    by[c]!['partial'] = by[c]!['partial']! + 1;
                  }
                  if (st == 'settled') by[c]!['settled'] = by[c]!['settled']! + 1;
                  final out = (s['outstandingMinor'] as num?)?.toInt() ?? 0;
                  if (s['direction'] == 'DRIVER_PAYS_COMPANY') {
                    by[c]!['recv'] = by[c]!['recv']! + out;
                  } else if (s['direction'] == 'COMPANY_PAYS_DRIVER') {
                    by[c]!['pay'] = by[c]!['pay']! + out;
                  }
                }
                if (by.isEmpty) return const SizedBox.shrink();
                return AdminContentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(uiTr(context, 'ملخص التسويات'),
                          style: theme.titleSmall),
                      for (final e in by.entries)
                        Text(
                          '${e.key}: locked ${e.value['locked']} · '
                          'partial ${e.value['partial']} · settled ${e.value['settled']} · '
                          'driver→company ${e.value['recv']} · company→driver ${e.value['pay']}',
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            AdminContentCard(
              child: Column(
                children: [
                  _kv(uiTr(context, 'رحلات مؤهلة للتحليل'), '${lines.length}'),
                  _kv(uiTr(context, 'نقدي'), '$cash'),
                  _kv(uiTr(context, 'أونلاين'), '$online'),
                  _kv(
                    uiTr(context, 'مؤكد'),
                    '${lines.where((l) => l.confidence == FinancialConfidence.high).length}',
                  ),
                  _kv(
                    uiTr(context, 'مشتق'),
                    '${lines.where((l) => l.confidence == FinancialConfidence.derived).length}',
                  ),
                  _kv(
                    uiTr(context, 'ناقص'),
                    '$incomplete',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: result.byCurrency.keys.contains(_previewCurrency)
                      ? _previewCurrency
                      : (result.byCurrency.keys.isEmpty
                          ? 'SAR'
                          : result.byCurrency.keys.first),
                  items: [
                    for (final c in (result.byCurrency.keys.isEmpty
                        ? ['SAR']
                        : result.byCurrency.keys))
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _previewCurrency = v);
                  },
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () => _showSettlementPreview(context),
                  child: Text(uiTr(context, 'Preview Settlement')),
                ),
              ],
            ),
            Text(
              uiTr(
                context,
                '1 Preview → 2 Save Draft → 3 Review → 4 Lock → 5 Mark Settled. Ledger only — no wallet movement.',
              ),
              style: theme.labelSmall.copyWith(color: Colors.orange.shade800),
            ),
            const SizedBox(height: 12),
            if (result.byCurrency.isEmpty)
              Text(uiTr(context, 'لا توجد بيانات مالية')),
            for (final entry in result.byCurrency.entries) ...[
              AdminContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(entry.key, style: theme.titleSmall),
                    _kv(
                      uiTr(context, 'نقد محصّل'),
                      _money(entry.value.cashCustomerCollected),
                    ),
                    _kv(
                      uiTr(context, 'استحقاق المندوب (نقد)'),
                      _money(entry.value.cashDriverEntitlements),
                    ),
                    _kv(
                      uiTr(context, 'المندوب يدين للشركة'),
                      _money(entry.value.cashDriversOweCompany),
                    ),
                    _kv(
                      uiTr(context, 'أونلاين محصّل'),
                      _money(entry.value.onlineCustomerPaid),
                    ),
                    _kv(
                      uiTr(context, 'الشركة تدين للمندوب (أونلاين)'),
                      _money(entry.value.onlineCompanyOwesDrivers),
                    ),
                    _kv(
                      uiTr(context, 'Trip Net Position'),
                      _money(_tripNet(entry.value)),
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: FinanceControlsClient.driverStatement(
                        driverId: widget.driverRef.id,
                        currency: entry.key,
                      ),
                      builder: (context, st) {
                        if (!st.hasData) {
                          return const SizedBox.shrink();
                        }
                        final s = st.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(),
                            Text(
                              uiTr(context, 'Driver Account Balance'),
                              style: theme.titleSmall,
                            ),
                            Text(
                              '${s['convention']}',
                              style: theme.labelSmall,
                            ),
                            _kv(
                              uiTr(context, 'Trip Position'),
                              '${s['tripPositionMinor']} ${entry.key}',
                            ),
                            _kv(
                              uiTr(context, 'Settlement Payments'),
                              '${s['settlementPaymentsMinor']} ${entry.key}',
                            ),
                            _kv(
                              uiTr(context, 'Approved Adjustments'),
                              '${s['approvedAdjustmentsMinor']} ${entry.key}',
                            ),
                            _kv(
                              uiTr(context, 'Opening Balance'),
                              '${s['openingBalanceMinor']} ${entry.key}',
                            ),
                            _kv(
                              uiTr(context, 'Outstanding'),
                              '${s['outstandingMinor']} ${entry.key} · ${s['outstandingLabel']}',
                            ),
                            Text(
                              uiTr(context, 'Wallet Balance غير مستخدم هنا'),
                              style: theme.labelSmall,
                            ),
                          ],
                        );
                      },
                    ),
                    _kv(
                      uiTr(context, 'رسوم المنصة'),
                      _money(entry.value.platformFeeAll),
                    ),
                    _kv(
                      uiTr(context, 'ضريبة مسجّلة'),
                      _money(entry.value.recordedVatAll),
                    ),
                    Text(
                      uiTr(
                        context,
                        'Unallocated company_payments غير محسوبة هنا',
                      ),
                      style: theme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Text(uiTr(context, 'بنود الرحلات'), style: theme.titleSmall),
            for (final line in lines.take(40))
              ListTile(
                dense: true,
                title: Text(
                  '${line.orderId} · ${line.channel.name} · ${_confLabel(line.confidence)}',
                ),
                subtitle: Text(
                  '${_money(line.customerPaid)} → net ${_money(line.driverNet)}'
                  '${line.settlementEligible ? ' · Eligible' : ' · ${line.exclusionReason ?? 'Excluded'}'}',
                ),
              ),
          ],
        );
      },
    );
  }

  String _confLabel(FinancialConfidence c) =>
      FinancialStateLabels.confidenceAr(c);

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

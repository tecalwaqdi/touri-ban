import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/financial_accounting_loader.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ops_filter_bar.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/finance/admin_finance_date_range.dart';
import '/core/finance/csv_export.dart';
import '/core/finance/finance_comparable_kpis.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Accounting reports — V2 trip summaries + separate settlement-ledger types.
class AdminFinanceReportsWidget extends StatefulWidget {
  const AdminFinanceReportsWidget({super.key});

  static const String routeName = 'AdminFinanceReports';
  static const String routePath = '/adminFinanceReports';

  @override
  State<AdminFinanceReportsWidget> createState() =>
      _AdminFinanceReportsWidgetState();
}

class _AdminFinanceReportsWidgetState extends State<AdminFinanceReportsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;

  /// V2 trip-accounting report families (same engine as Hub/Profits).
  static const _v2Types = <String, String>{
    'revenue_summary': 'ملخص الإيرادات',
    'platform_fee': 'عمولة الشركة',
    'driver_net': 'أرباح المناديب',
    'vat': 'ضريبة القيمة المضافة',
    'cash_vs_online': 'نقدي مقابل إلكتروني',
    'by_country': 'حسب الدولة',
    'receivables_trip': 'المستحقات (رحلات)',
  };

  /// Settlement ledger reports (different semantics — not forced equal to Hub).
  static const _ledgerTypes = <String, String>{
    'settlement_statement': 'كشف التسويات',
    'payment_register': 'سجل المدفوعات',
    'aging': 'أعمار المستحقات',
    'reconciliation_exceptions': 'استثناءات المطابقة',
  };

  String _type = 'revenue_summary';
  FinancialReportFilter _filter = const FinancialReportFilter();
  FinancialReportResult? _v2Result;
  Map<String, dynamic>? _ledgerReport;
  bool _busy = false;
  String? _error;

  bool get _isV2 => _v2Types.containsKey(_type);

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_filter.datePreset == AdminDatePreset.custom &&
        AdminFinanceDateRangeResolver.isInvalidCustom(
          customStart: _filter.customStart,
          customEnd: _filter.customEnd,
        )) {
      setState(() {
        _error = 'نطاق التاريخ غير صالح: تاريخ البداية بعد النهاية';
        _v2Result = null;
        _ledgerReport = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isV2) {
        final data = await FinancialAccountingLoader.load(_filter);
        setState(() {
          _v2Result = data;
          _ledgerReport = null;
        });
      } else {
        final data = await FinanceControlsClient.report({
          'type': _type,
        });
        setState(() {
          _ledgerReport = data;
          _v2Result = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = AdminUserFacingErrors.from(context, e);
        _v2Result = null;
        _ledgerReport = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _typeLabel(String key) =>
      _v2Types[key] ?? _ledgerTypes[key] ?? key;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'التقارير المحاسبية'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(
            uiTr(context, 'التقارير المحاسبية'),
            style: theme.headlineSmall,
          ),
          Text(
            uiTr(
              context,
              'تقارير الإيرادات والعمولات وأرباح المناديب والتسويات حسب الفترة.',
            ),
            softWrap: true,
            style: theme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(uiTr(context, 'نوع التقرير'), style: theme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _type,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (final e in _v2Types.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
              for (final e in _ledgerTypes.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text('${e.value} (${uiTr(context, 'دفتر تسويات')})'),
                ),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          if (_isV2) ...[
            Text(uiTr(context, 'الفترة والفلاتر'), style: theme.titleSmall),
            const SizedBox(height: 8),
            AdminOpsFilterBar(
              value: AdminOpsFilterState(
                datePreset: _filter.datePreset,
                customStart: _filter.customStart,
                customEnd: _filter.customEnd,
                countryRef: _filter.countryRef,
              ),
              config: const AdminOpsFilterConfig(
                showDate: true,
                showCountry: true,
                showOrderLifecycle: false,
                showDriverActivation: false,
                showSupportStatus: false,
                showSearch: false,
              ),
              onChanged: (next) {
                setState(() {
                  _filter = FinancialReportFilter(
                    datePreset: next.datePreset,
                    customStart: next.customStart,
                    customEnd: next.customEnd,
                    countryRef: next.countryRef,
                    channel: _filter.channel,
                    lifecycle: _filter.lifecycle,
                    payment: _filter.payment,
                    confidence: _filter.confidence,
                    currency: _filter.currency,
                    driverRef: _filter.driverRef,
                  );
                });
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(uiTr(context, 'الكل')),
                  selected: _filter.channel == null,
                  onSelected: (_) => setState(() {
                    _filter = FinancialReportFilter(
                      datePreset: _filter.datePreset,
                      customStart: _filter.customStart,
                      customEnd: _filter.customEnd,
                      countryRef: _filter.countryRef,
                    );
                  }),
                ),
                ChoiceChip(
                  label: Text(uiTr(context, 'نقدًا')),
                  selected: _filter.channel == FinancialPaymentChannel.cash,
                  onSelected: (_) => setState(() {
                    _filter = FinancialReportFilter(
                      datePreset: _filter.datePreset,
                      customStart: _filter.customStart,
                      customEnd: _filter.customEnd,
                      countryRef: _filter.countryRef,
                      channel: FinancialPaymentChannel.cash,
                    );
                  }),
                ),
                ChoiceChip(
                  label: Text(uiTr(context, 'إلكتروني')),
                  selected: _filter.channel == FinancialPaymentChannel.online,
                  onSelected: (_) => setState(() {
                    _filter = FinancialReportFilter(
                      datePreset: _filter.datePreset,
                      customStart: _filter.customStart,
                      customEnd: _filter.customEnd,
                      countryRef: _filter.countryRef,
                      channel: FinancialPaymentChannel.online,
                    );
                  }),
                ),
              ],
            ),
          ] else
            Text(
              uiTr(
                context,
                'تقارير دفتر التسويات مستقلة عن ملخص رحلات المحاسبة V2.',
              ),
              style: theme.bodySmall,
            ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: _busy ? null : _run,
              child: Text(uiTr(context, 'تشغيل التقرير')),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.error)),
          ],
          if (_v2Result != null) ..._buildV2Body(context, theme, _v2Result!),
          if (_ledgerReport != null)
            ..._buildLedgerBody(context, theme, _ledgerReport!),
        ],
      ),
    );
  }

  List<Widget> _buildV2Body(
    BuildContext context,
    FlutterFlowTheme theme,
    FinancialReportResult result,
  ) {
    final kpis = FinanceComparableKpis.fromReportResult(result);
    final range = AdminFinanceDateRangeResolver.resolve(
      preset: _filter.datePreset,
      customStart: _filter.customStart,
      customEnd: _filter.customEnd,
    );
    final generated = AdminFinanceRiyadhClock.formatDateTime(result.loadedAt);

    if (result.byCurrency.isEmpty) {
      return [
        const SizedBox(height: 16),
        AdminEmptyState(
          title: uiTr(
            context,
            'لا توجد عمليات مالية مطابقة للفترة والفلاتر المحددة.',
          ),
          icon: Icons.inbox_outlined,
        ),
      ];
    }

    final rows = <List<String>>[];
    for (final e in result.byCurrency.entries) {
      final t = e.value;
      rows.add([
        e.key,
        t.customerPaidAll.majorUnits.toStringAsFixed(2),
        t.platformFeeAll.majorUnits.toStringAsFixed(2),
        t.recordedVatAll.majorUnits.toStringAsFixed(2),
        t.driverEntitlementAll.majorUnits.toStringAsFixed(2),
        t.cashDriversOweCompany.majorUnits.toStringAsFixed(2),
        '${t.completedAndCollected}',
        '${t.completedButNotCollected}',
      ]);
    }

    return [
      const SizedBox(height: 16),
      Text(
        '${uiTr(context, 'التقرير')}: ${_typeLabel(_type)}',
        style: theme.titleMedium,
      ),
      Text(
        '${uiTr(context, 'الفترة')}: ${range?.displayLabelAr ?? uiTr(context, 'الكل')}',
        style: theme.bodySmall,
      ),
      Text(
        '${uiTr(context, 'تم إنشاء التقرير')}: $generated',
        style: theme.labelSmall,
      ),
      Text(
        '${uiTr(context, 'دولة الحجز')}: Rev_dolh · ${uiTr(context, 'المصدر')}: ${result.totalsSource}',
        style: theme.labelSmall,
      ),
      const SizedBox(height: 12),
      AdminKpiStrip(
        items: [
          (
            label: uiTr(context, 'إجمالي قيمة الرحلات المكتملة'),
            value: kpis.moneyLabel(kpis.collectedTripValue),
            icon: Icons.trending_up_rounded,
            color: AdminUi.brandTeal,
          ),
          (
            label: uiTr(context, 'عمولة الشركة'),
            value: kpis.moneyLabel(kpis.platformFees),
            icon: Icons.savings_rounded,
            color: const Color(0xFF0F7A4A),
          ),
          (
            label: uiTr(context, 'ضريبة القيمة المضافة'),
            value: kpis.moneyLabel(kpis.recordedVat),
            icon: Icons.receipt_outlined,
            color: const Color(0xFF5B6B7A),
          ),
          (
            label: uiTr(context, 'صافي أرباح المناديب'),
            value: kpis.moneyLabel(kpis.driverNet),
            icon: Icons.payments_rounded,
            color: const Color(0xFFB06A00),
          ),
          (
            label: uiTr(context, 'المستحق المؤهل للتسوية'),
            value: kpis.moneyLabel(kpis.settlementEligibleDue),
            icon: Icons.account_balance_rounded,
            color: theme.error,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '${uiTr(context, 'رحلات نقدية بانتظار إثبات التحصيل')}: ${kpis.completedButNotCollected}',
        style: theme.bodySmall,
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () async {
          final header = [
            'العملة',
            'إجمالي المحصّل',
            'عمولة الشركة',
            'VAT',
            'صافي المناديب',
            'المستحق المؤهل',
            'محصّل',
            'بانتظار التحصيل',
          ].map(financeCsvEscape).join(',');
          final body = [
            header,
            for (final r in rows) r.map(financeCsvEscape).join(','),
          ].join('\n');
          final csv = financeCsvDocument(
            preparedBy: currentUserUid,
            filters:
                '${_typeLabel(_type)} | ${range?.displayLabelAr ?? 'الكل'} | ${_filter.channel?.name ?? 'all'}',
            currency: kpis.currency,
            body: body,
            generatedAtUtc: result.loadedAt,
          );
          await copyFinanceCsv(csv);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uiTr(context, 'تم نسخ CSV'))),
          );
        },
        child: Text(uiTr(context, 'نسخ CSV')),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(uiTr(context, 'العملة'))),
            DataColumn(label: Text(uiTr(context, 'إجمالي المحصّل'))),
            DataColumn(label: Text(uiTr(context, 'عمولة الشركة'))),
            DataColumn(label: Text(uiTr(context, 'VAT'))),
            DataColumn(label: Text(uiTr(context, 'صافي المناديب'))),
            DataColumn(label: Text(uiTr(context, 'المستحق المؤهل'))),
            DataColumn(label: Text(uiTr(context, 'محصّل'))),
            DataColumn(label: Text(uiTr(context, 'بانتظار'))),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                cells: [
                  for (final c in r) DataCell(Text(c, softWrap: false)),
                ],
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildLedgerBody(
    BuildContext context,
    FlutterFlowTheme theme,
    Map<String, dynamic> report,
  ) {
    final rows = (report['rows'] as List?) ?? [];
    final cols = (report['columns'] as List?) ?? [];
    return [
      const SizedBox(height: 16),
      Text(
        '${uiTr(context, 'تم إنشاء التقرير')}: ${AdminFinanceRiyadhClock.formatDateTime(DateTime.now().toUtc())}',
        style: theme.labelSmall,
      ),
      Text(
        uiTr(context, 'دفتر تسويات — ليس ملخص رحلات V2'),
        style: theme.bodySmall,
      ),
      if (rows.isEmpty)
        AdminEmptyState(
          title: uiTr(
            context,
            'لا توجد عمليات مالية مطابقة للفترة والفلاتر المحددة.',
          ),
        )
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              for (final c in cols) DataColumn(label: Text('$c')),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    for (final c in (r as List))
                      DataCell(Text('$c', softWrap: false)),
                  ],
                ),
            ],
          ),
        ),
    ];
  }
}

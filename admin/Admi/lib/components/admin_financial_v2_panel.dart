import '/backend/admin_ops_filters.dart';
import '/backend/backend.dart';
import '/backend/financial_accounting_loader.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_ops_filter_bar.dart';
import '/components/admin_ui.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// Admin Financial Reporting V2 — read-only accounting view.
class AdminFinancialV2Panel extends StatefulWidget {
  const AdminFinancialV2Panel({super.key});

  @override
  State<AdminFinancialV2Panel> createState() => _AdminFinancialV2PanelState();
}

class _AdminFinancialV2PanelState extends State<AdminFinancialV2Panel> {
  FinancialReportFilter _filter = const FinancialReportFilter();
  Future<FinancialReportResult>? _future;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loading = true;
      _future = FinancialAccountingLoader.load(_filter).whenComplete(() {
        if (mounted) setState(() => _loading = false);
      });
    });
  }

  FinancialReportFilter _copy({
    AdminDatePreset? datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    FinancialPaymentChannel? channel,
    FinancialLifecycle? lifecycle,
    FinancialPaymentState? payment,
    FinancialConfidence? confidence,
    String? currency,
    bool clearChannel = false,
    bool clearLifecycle = false,
    bool clearPayment = false,
    bool clearConfidence = false,
    bool clearCurrency = false,
  }) {
    return FinancialReportFilter(
      datePreset: datePreset ?? _filter.datePreset,
      customStart: customStart ?? _filter.customStart,
      customEnd: customEnd ?? _filter.customEnd,
      countryRef: countryRef ?? _filter.countryRef,
      driverRef: driverRef ?? _filter.driverRef,
      channel: clearChannel ? null : (channel ?? _filter.channel),
      lifecycle: clearLifecycle ? null : (lifecycle ?? _filter.lifecycle),
      payment: clearPayment ? null : (payment ?? _filter.payment),
      confidence: clearConfidence ? null : (confidence ?? _filter.confidence),
      currency: clearCurrency ? null : (currency ?? _filter.currency),
    );
  }

  String _money(MoneyAmount? m) {
    if (m == null) return '—';
    return '${m.majorUnits.toStringAsFixed(2)} ${m.code}';
  }

  String _confLabel(FinancialConfidence c) => switch (c) {
        FinancialConfidence.high => 'HIGH',
        FinancialConfidence.derived => 'DERIVED',
        FinancialConfidence.incomplete => 'INCOMPLETE',
      };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            _filter = _copy(
              datePreset: next.datePreset,
              customStart: next.customStart,
              customEnd: next.customEnd,
              countryRef: next.countryRef,
            );
            _reload();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              label: uiTr(context, 'الكل'),
              selected: _filter.channel == null &&
                  _filter.lifecycle == null &&
                  _filter.payment == null &&
                  _filter.confidence == null,
              onTap: () {
                _filter = _copy(
                  clearChannel: true,
                  clearLifecycle: true,
                  clearPayment: true,
                  clearConfidence: true,
                  clearCurrency: true,
                );
                _reload();
              },
            ),
            _chip(
              label: 'Cash',
              selected: _filter.channel == FinancialPaymentChannel.cash,
              onTap: () {
                _filter = _copy(channel: FinancialPaymentChannel.cash);
                _reload();
              },
            ),
            _chip(
              label: 'Online',
              selected: _filter.channel == FinancialPaymentChannel.online,
              onTap: () {
                _filter = _copy(channel: FinancialPaymentChannel.online);
                _reload();
              },
            ),
            _chip(
              label: 'Completed',
              selected: _filter.lifecycle == FinancialLifecycle.completed,
              onTap: () {
                _filter = _copy(lifecycle: FinancialLifecycle.completed);
                _reload();
              },
            ),
            _chip(
              label: 'cash_collected',
              selected: _filter.payment == FinancialPaymentState.cashCollected,
              onTap: () {
                _filter = _copy(payment: FinancialPaymentState.cashCollected);
                _reload();
              },
            ),
            _chip(
              label: 'pending_cash',
              selected: _filter.payment == FinancialPaymentState.pendingCash,
              onTap: () {
                _filter = _copy(payment: FinancialPaymentState.pendingCash);
                _reload();
              },
            ),
            _chip(
              label: 'HIGH',
              selected: _filter.confidence == FinancialConfidence.high,
              onTap: () {
                _filter = _copy(confidence: FinancialConfidence.high);
                _reload();
              },
            ),
            _chip(
              label: 'DERIVED',
              selected: _filter.confidence == FinancialConfidence.derived,
              onTap: () {
                _filter = _copy(confidence: FinancialConfidence.derived);
                _reload();
              },
            ),
            _chip(
              label: 'INCOMPLETE',
              selected: _filter.confidence == FinancialConfidence.incomplete,
              onTap: () {
                _filter = _copy(confidence: FinancialConfidence.incomplete);
                _reload();
              },
            ),
            _chip(
              label: 'SAR',
              selected: _filter.currency == 'SAR',
              onTap: () {
                _filter = _copy(currency: 'SAR');
                _reload();
              },
            ),
            TextButton.icon(
              onPressed: _loading ? null : _reload,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(uiTr(context, 'تحديث')),
            ),
          ],
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 12),
        FutureBuilder<FinancialReportResult>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return AdminContentCard(
                child: Text(
                  '${uiTr(context, 'تعذر تحميل التقرير المالي')}: ${snap.error}',
                ),
              );
            }
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final result = snap.data!;
            return _buildReport(context, theme, result);
          },
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildReport(
    BuildContext context,
    FlutterFlowTheme theme,
    FinancialReportResult result,
  ) {
    final currencies = result.byCurrency.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${uiTr(context, 'آخر تحديث')}: ${dateTimeFormat('Hm', result.loadedAt)}'
          ' · ${result.docsScanned} ${uiTr(context, 'مستندات')}'
          ' · totals=${result.totalsSource}'
          ' · sig=${result.filterSignature.split('|').take(3).join('|')}…'
          '${result.truncated ? ' · truncated' : ''}',
          style: theme.labelSmall,
        ),
        const SizedBox(height: 8),
        _qualityBanner(context, result),
        const SizedBox(height: 8),
        _exposureBanner(context, result),
        const SizedBox(height: 12),
        if (currencies.isEmpty)
          AdminEmptyState(
            title: uiTr(context, 'لا توجد بيانات مالية لهذه الفترة'),
            message: uiTr(context, 'جرّب توسيع نطاق التاريخ'),
            icon: Icons.account_balance_wallet_outlined,
          )
        else
          for (final code in currencies) ...[
            _currencySection(context, theme, code, result.byCurrency[code]!),
            const SizedBox(height: 16),
          ],
        Text(
          uiTr(context, 'الجدول المالي'),
          style: theme.titleMedium,
        ),
        const SizedBox(height: 8),
        _ordersTable(context, theme, result.tableRows),
      ],
    );
  }

  Widget _qualityBanner(BuildContext context, FinancialReportResult result) {
    final q = result.quality;
    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'جودة البيانات المالية'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Total ${q.totalLines}'),
              Text('HIGH ${q.high}'),
              Text('DERIVED ${q.derived}'),
              Text(
                'INCOMPLETE ${q.incomplete}',
                style: TextStyle(
                  color: q.incomplete > 0 ? Colors.orange.shade800 : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('Reconciled ${q.reconciled}'),
              Text('ReconΔ ${q.reconciliationDifference}'),
              Text('Missing pay ${q.missingPaymentStatus}'),
              Text('Missing life ${q.missingLifecycle}'),
              Text('Missing driver ${q.missingDriver}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exposureBanner(BuildContext context, FinancialReportResult result) {
    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'Company Exposure (Trip)'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          for (final e in result.byCurrency.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${e.key}: Drivers owe ${_money(e.value.cashDriversOweCompany)} · '
                'Company owes ${_money(MoneyAmount(currency: e.key, minorUnits: e.value.cashCompanyOwesDrivers.minorUnits + e.value.onlineCompanyOwesDrivers.minorUnits))} · '
                'Net ${_money(MoneyAmount(currency: e.key, minorUnits: e.value.cashDriversOweCompany.minorUnits - e.value.cashCompanyOwesDrivers.minorUnits - e.value.onlineCompanyOwesDrivers.minorUnits))}',
              ),
            ),
          Text(
            uiTr(
              context,
              'Unallocated company_payments — منفصلة عن Trip Position',
            ),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _currencySection(
    BuildContext context,
    FlutterFlowTheme theme,
    String code,
    FinancialCurrencyTotals t,
  ) {
    return AdminContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$code — ${uiTr(context, 'التقرير المالي')}',
              style: theme.titleMedium),
          const SizedBox(height: 10),
          Text(uiTr(context, 'التحصيل'), style: theme.titleSmall),
          _kv(uiTr(context, 'نقدي محصّل'), _money(t.cashCustomerCollected)),
          _kv(uiTr(context, 'إلكتروني محصّل'), _money(t.onlineCustomerPaid)),
          const Divider(),
          Text(uiTr(context, 'اقتصاد الرحلة'), style: theme.titleSmall),
          _kv(uiTr(context, 'الأجرة الأساسية'), _money(t.grossBaseFare)),
          _kv(uiTr(context, 'دفع العميل'), _money(t.customerPaidAll)),
          _kv(uiTr(context, 'عمولة المنصة'), _money(t.platformFeeAll)),
          _kv(uiTr(context, 'ضريبة مسجّلة'), _money(t.recordedVatAll)),
          _kv(uiTr(context, 'مستحق المندوب'), _money(t.driverEntitlementAll)),
          _kv(uiTr(context, 'خصم مسجّل'), _money(t.recordedDiscountsAll)),
          const Divider(),
          Text('CASH', style: theme.titleSmall),
          _kv(uiTr(context, 'رحلات نقدية محصّلة'), '${t.cashCollectedTrips}'),
          _kv(uiTr(context, 'نقد بيد المندوبين'), _money(t.cashHeldByDrivers)),
          _kv(uiTr(context, 'المندوب مدين للشركة'),
              _money(t.cashDriversOweCompany)),
          _kv(uiTr(context, 'الشركة مدينة للمندوب'),
              _money(t.cashCompanyOwesDrivers)),
          if (t.cashUnreconciled.minorUnits != 0)
            _kv('RECONCILIATION_DIFFERENCE', _money(t.cashUnreconciled)),
          const Divider(),
          Text('ONLINE', style: theme.titleSmall),
          if (t.onlinePaidTrips == 0)
            Text(uiTr(context, 'لا رحلات أونلاين مكتملة ومدفوعة مؤهلة'))
          else ...[
            _kv(uiTr(context, 'رحلات أونلاين مدفوعة'), '${t.onlinePaidTrips}'),
            _kv(uiTr(context, 'لدى الشركة/البوابة'),
                _money(t.onlineHeldByCompany)),
            _kv(uiTr(context, 'متبقي قبل رسوم البوابة'),
                _money(t.onlineRemainingPosition)),
            _kv(uiTr(context, 'الشركة مدينة للمندوب'),
                _money(t.onlineCompanyOwesDrivers)),
          ],
          const Divider(),
          Text(uiTr(context, 'التصنيفات'), style: theme.titleSmall),
          _kv('Completed & Collected', '${t.completedAndCollected}'),
          _kv('Paid Not Completed', '${t.paidButNotCompleted}'),
          _kv('Completed Not Collected', '${t.completedButNotCollected}'),
          _kv('Pending Payment', '${t.pendingPayment}'),
          _kv('Cancelled / Expired', '${t.cancelledOrExpired}'),
          _kv('INCOMPLETE', '${t.incompleteLines}'),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _ordersTable(
    BuildContext context,
    FlutterFlowTheme theme,
    List<FinancialReportRow> rows,
  ) {
    if (rows.isEmpty) {
      return AdminEmptyState(
        title: uiTr(context, 'لا توجد طلبات'),
        message: '',
        icon: Icons.receipt_long_outlined,
      );
    }
    final show = rows.take(40).toList();
    return AdminContentCard(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(uiTr(context, 'التاريخ'))),
            DataColumn(label: Text(uiTr(context, 'الطلب'))),
            DataColumn(label: Text(uiTr(context, 'العملة'))),
            DataColumn(label: Text(uiTr(context, 'الطريقة'))),
            DataColumn(label: Text(uiTr(context, 'دورة'))),
            DataColumn(label: Text(uiTr(context, 'دفع'))),
            DataColumn(label: Text(uiTr(context, 'دفع العميل'))),
            DataColumn(label: Text(uiTr(context, 'عمولة المنصة'))),
            DataColumn(label: Text(uiTr(context, 'ضريبة مسجّلة'))),
            DataColumn(label: Text(uiTr(context, 'خصم مسجّل'))),
            DataColumn(label: Text(uiTr(context, 'صافي المندوب'))),
            DataColumn(label: Text('Confidence')),
          ],
          rows: [
            for (final r in show)
              DataRow(
                cells: [
                  DataCell(Text(
                    r.order.dataOrder == null
                        ? '—'
                        : dateTimeFormat('yMd', r.order.dataOrder),
                  )),
                  DataCell(
                    InkWell(
                      onTap: () => _openDetails(context, r),
                      child: Text(
                        r.order.iDorder.isNotEmpty
                            ? r.order.iDorder
                            : r.line.orderId.substring(0, 8),
                        style: TextStyle(color: theme.primary),
                      ),
                    ),
                  ),
                  DataCell(Text(r.line.currency)),
                  DataCell(Text(r.line.channel.name)),
                  DataCell(Text(r.line.lifecycle.name)),
                  DataCell(Text(r.line.payment.name)),
                  DataCell(Text(_money(r.line.customerPaid))),
                  DataCell(Text(_money(r.line.platformFee))),
                  DataCell(Text(_money(r.line.recordedVat))),
                  DataCell(Text(_money(r.line.recordedDiscount))),
                  DataCell(Text(_money(r.line.driverNet))),
                  DataCell(Text(_confLabel(r.line.confidence))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, FinancialReportRow r) {
    final line = r.line;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(uiTr(context, 'تفاصيل التسوية المحاسبية'),
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              _kv(uiTr(context, 'دفع العميل'), _money(line.customerPaid)),
              _kv(uiTr(context, 'الأجرة الأساسية'), _money(line.grossBase)),
              _kv(uiTr(context, 'خصم مسجّل'), _money(line.recordedDiscount)),
              _kv(uiTr(context, 'عمولة المنصة'), _money(line.platformFee)),
              _kv(uiTr(context, 'ضريبة مسجّلة'), _money(line.recordedVat)),
              _kv(uiTr(context, 'صافي المندوب'), _money(line.driverNet)),
              if (line.signedCashPosition != null)
                _kv(uiTr(context, 'المركز النقدي'),
                    _money(line.signedCashPosition)),
              if (line.onlineRemainingPosition != null)
                _kv(uiTr(context, 'مركز الأونلاين'),
                    _money(line.onlineRemainingPosition)),
              if (line.reconciliationDifference != null)
                _kv('RECONCILIATION_DIFFERENCE',
                    _money(line.reconciliationDifference)),
              if (line.notes.isNotEmpty) Text('Notes: ${line.notes.join(', ')}'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pushNamed(
                    AdminBookingDetailsWidget.routeName,
                    queryParameters: {
                      'idbokeng': serializeParam(
                        r.order.reference,
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Text(uiTr(context, 'فتح الطلب')),
              ),
            ],
          ),
        );
      },
    );
  }
}

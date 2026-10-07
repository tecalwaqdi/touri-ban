import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/components/accountant_trip_details_drawer.dart';
import '/components/admin_layout_widget.dart';
import '/components/menu2_model.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_control_facade.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Canonical Trip Ledger — bounded page from FinanceControlFacade (FIN V2 only).
class AdminFinanceTripLedgerWidget extends StatefulWidget {
  const AdminFinanceTripLedgerWidget({super.key});

  static const String routeName = 'AdminFinanceTripLedger';
  static const String routePath = '/adminFinanceTripLedger';

  @override
  State<AdminFinanceTripLedgerWidget> createState() =>
      _AdminFinanceTripLedgerWidgetState();
}

class _AdminFinanceTripLedgerWidgetState
    extends State<AdminFinanceTripLedgerWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  AdminDatePreset _preset = AdminDatePreset.thisMonth;
  String _channel = 'all';
  FinancialDataQuality? _quality;
  String _search = '';
  Future<List<AccountantTripRow>>? _future;

  static const _presetLabels = <AdminDatePreset, String>{
    AdminDatePreset.today: 'اليوم',
    AdminDatePreset.yesterday: 'أمس',
    AdminDatePreset.last7Days: 'آخر 7 أيام',
    AdminDatePreset.thisMonth: 'هذا الشهر',
    AdminDatePreset.last30Days: 'آخر 30 يومًا',
    AdminDatePreset.lastMonth: 'الشهر السابق',
    AdminDatePreset.thisYear: 'هذه السنة',
  };

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _reload();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = FinanceControlFacade.loadTripLedgerPage(
        datePreset: _preset,
        countryRef: AdminRoleService.usesCountryFinanceScope
            ? AdminRoleService.scopedCountryRef
            : null,
        forceRefresh: true,
      );
    });
  }

  List<AccountantTripRow> _filter(List<AccountantTripRow> rows) {
    return rows.where((r) {
      if (AdminQaFixture.isFixtureId(r.orderId)) return false;
      if (_channel == 'cash' && r.paymentChannelLabel != 'نقدي') return false;
      if (_channel == 'online' && r.paymentChannelLabel != 'إلكتروني') {
        return false;
      }
      if (_quality != null && r.dataQuality != _quality) return false;
      final q = _search.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.orderId.toLowerCase().contains(q) ||
          r.driverLabel.toLowerCase().contains(q) ||
          r.tripRefLabel.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => setState(() {}),
      title: uiTr(context, 'دفتر الرحلات المالية'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<AdminDatePreset>(
                  value: _preset,
                  items: _presetLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _preset = v);
                    _reload();
                  },
                ),
                DropdownButton<String>(
                  value: _channel,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(uiTr(context, 'كل القنوات'))),
                    DropdownMenuItem(value: 'cash', child: Text(uiTr(context, 'نقدي'))),
                    DropdownMenuItem(value: 'online', child: Text(uiTr(context, 'إلكتروني'))),
                  ],
                  onChanged: (v) => setState(() => _channel = v ?? 'all'),
                ),
                DropdownButton<FinancialDataQuality?>(
                  value: _quality,
                  items: [
                    DropdownMenuItem(value: null, child: Text(uiTr(context, 'كل الجودة'))),
                    DropdownMenuItem(
                      value: FinancialDataQuality.complete,
                      child: Text(uiTr(context, 'مكتمل')),
                    ),
                    DropdownMenuItem(
                      value: FinancialDataQuality.partial,
                      child: Text(uiTr(context, 'جزئي')),
                    ),
                    DropdownMenuItem(
                      value: FinancialDataQuality.unresolved,
                      child: Text(uiTr(context, 'غير محلول')),
                    ),
                  ],
                  onChanged: (v) => setState(() => _quality = v),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: uiTr(context, 'بحث رحلة / مندوب'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(uiTr(context, 'تحديث')),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              uiTr(context, 'القيم الناقصة تُعرض كـ — · لا تُجمَع العملات · مصدر FIN V2 فقط'),
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<AccountantTripRow>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                final rows = _filter(snap.data ?? const []);
                if (rows.isEmpty) {
                  return Center(child: Text(uiTr(context, 'لا توجد رحلات في النطاق')));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 40,
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 48,
                      showCheckboxColumn: false,
                      columns: [
                        DataColumn(label: Text(uiTr(context, 'الرحلة'))),
                        DataColumn(label: Text(uiTr(context, 'التاريخ'))),
                        DataColumn(label: Text(uiTr(context, 'البلد'))),
                        DataColumn(label: Text(uiTr(context, 'العملة'))),
                        DataColumn(label: Text(uiTr(context, 'المندوب'))),
                        DataColumn(label: Text(uiTr(context, 'القناة'))),
                        DataColumn(label: Text(uiTr(context, 'تشغيلي'))),
                        DataColumn(label: Text(uiTr(context, 'دفع'))),
                        DataColumn(label: Text(uiTr(context, 'تحصيل'))),
                        DataColumn(label: Text(uiTr(context, 'تسوية'))),
                        DataColumn(label: Text(uiTr(context, 'أساسي'))),
                        DataColumn(label: Text(uiTr(context, 'عمولة'))),
                        DataColumn(label: Text(uiTr(context, 'ضريبة'))),
                        DataColumn(label: Text(uiTr(context, 'صافي مندوب'))),
                        DataColumn(label: Text(uiTr(context, 'وكيل'))),
                        DataColumn(label: Text(uiTr(context, 'جودة'))),
                      ],
                      rows: rows
                          .map(
                            (r) => DataRow(
                              onSelectChanged: (_) {
                                showAccountantTripDetailsDrawer(context, r);
                              },
                              cells: [
                                DataCell(Text(r.tripRefLabel)),
                                DataCell(Text(
                                  r.orderedAt == null
                                      ? AccountantFinanceLabels.emDash()
                                      : dateTimeFormat('yMd', r.orderedAt!),
                                )),
                                DataCell(Text(r.countryLabel)),
                                DataCell(Text(r.currency)),
                                DataCell(Text(r.driverLabel)),
                                DataCell(Text(r.paymentChannelLabel)),
                                DataCell(Text(r.tripStatusLabel)),
                                DataCell(Text(r.paymentStatusLabel)),
                                DataCell(Text(r.collectionStatusLabel)),
                                DataCell(Text(r.settlementStatusLabel)),
                                DataCell(Text(r.grossDisplay)),
                                DataCell(Text(r.companyCommissionDisplay)),
                                DataCell(Text(r.vatDisplay)),
                                DataCell(Text(r.driverNetDisplay)),
                                DataCell(Text(r.agentAmountDisplay)),
                                DataCell(Text(r.dataQualityLabel)),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

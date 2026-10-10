import 'package:flutter/material.dart';

import '/backend/admin_finance_route_trace.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/finance_reconciliation_labels.dart';
import '/core/finance/finance_reconciliation_read_model.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// F3-B2 Accountant Workspace — uses B1 [FinanceReconciliationReadModel] only.
class AdminFinanceReconciliationWidget extends StatefulWidget {
  const AdminFinanceReconciliationWidget({super.key});

  static const String routeName = 'AdminFinanceReconciliation';
  static const String routePath = '/adminFinanceReconciliation';

  @override
  State<AdminFinanceReconciliationWidget> createState() =>
      _AdminFinanceReconciliationWidgetState();
}

class _AdminFinanceReconciliationWidgetState
    extends State<AdminFinanceReconciliationWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  Future<FinanceReconciliationResult>? _future;
  /// First-page B1 with settlement membership — not period summary.
  FinanceReconciliationResult? _earlyPartial;
  bool _rowsLoading = false;
  bool _summaryLoading = false;
  Object? _rowsError;
  Object? _summaryError;
  bool _firstBuildMarked = false;

  @override
  void initState() {
    super.initState();
    AdminFinanceRouteTrace.begin('reconciliation');
    AdminFinanceRouteTrace.mark('FIRST_BUILD_START');
    _menu2Model = createModel(context, () => Menu2Model());
    _future = _load();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<FinanceReconciliationResult> _load({bool forceRefresh = false}) async {
    if (forceRefresh) {
      AdminFinanceRouteTrace.begin('reconciliation');
    }
    setState(() {
      _rowsLoading = true;
      _summaryLoading = true;
      if (forceRefresh) _earlyPartial = null;
      _rowsError = null;
      _summaryError = null;
    });

    // CRITICAL PATH — modern page + settlement maps, then B1 once.
    AccountantFinanceLoader.loadReconciliationFirstPage(
      forceRefresh: forceRefresh,
    ).then((partial) {
      if (!mounted) return;
      setState(() {
        _earlyPartial = partial;
        _rowsLoading = false;
        AdminFinanceRouteTrace.markStateEmitAndSchedulePaint();
      });
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _rowsError = e;
        _rowsLoading = false;
      });
    });

    AdminFinanceRouteTrace.mark('SUMMARY_START');
    return AccountantFinanceLoader.loadReconciliation(
      forceRefresh: forceRefresh,
    ).then((full) {
      AdminFinanceRouteTrace.mark('SUMMARY_COMPLETE');
      if (mounted) {
        setState(() => _earlyPartial = full);
      }
      return full;
    }).catchError((Object e) {
      if (mounted) {
        setState(() => _summaryError = e);
      } else {
        _summaryError = e;
      }
      throw e;
    }).whenComplete(() {
      if (mounted) {
        setState(() => _summaryLoading = false);
      } else {
        _summaryLoading = false;
      }
    });
  }

  String _moneyOrDash(MoneyAmount? m) {
    if (m == null) return 'غير متوفر';
    return '${m.majorUnits.toStringAsFixed(2)} ${m.code}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstBuildMarked) {
      _firstBuildMarked = true;
      AdminFinanceRouteTrace.mark('FIRST_BUILD_END');
    }
    final theme = FlutterFlowTheme.of(context);
    final canAccess = AdminRoleService.canAccessRoute(
      AdminFinanceReconciliationWidget.routeName,
    );

    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'المصالحة المالية'),
      child: !canAccess
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  uiTr(context, 'ليس لديك صلاحية لعرض هذه الصفحة'),
                  style: AccountantFinanceText.body(theme),
                ),
              ),
            )
          : FutureBuilder<FinanceReconciliationResult>(
              future: _future,
              builder: (context, snap) {
                final full = snap.data;
                final rowsSource = full ?? _earlyPartial;
                final summaryReady = full != null;
                if (rowsSource == null &&
                    (_rowsLoading ||
                        snap.connectionState != ConnectionState.done)) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          uiTr(context, 'جاري تحميل البيانات المالية...'),
                          style: AccountantFinanceText.body(theme),
                        ),
                      ],
                    ),
                  );
                }
                if ((_rowsError != null || snap.hasError) &&
                    rowsSource == null) {
                  return Center(
                    child: Text(
                      uiTr(context, 'تعذر تحميل بيانات المصالحة المالية'),
                      style: AccountantFinanceText.body(theme),
                    ),
                  );
                }
                if (rowsSource == null) {
                  return Center(
                    child: Text(
                      uiTr(context, 'لا توجد بيانات'),
                      style: AccountantFinanceText.body(theme),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _load(forceRefresh: true));
                    await _future;
                  },
                  child: Column(
                    children: [
                      if (_summaryLoading && !summaryReady)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Text(
                            uiTr(context, 'صفوف أولية جاهزة — جاري إكمال ملخص الفترة…'),
                            style: AccountantFinanceText.label(theme),
                          ),
                        ),
                      if (_summaryError != null && !summaryReady)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Text(
                            uiTr(context, 'تعذر تحميل ملخص الفترة — السجل الأولي متاح.'),
                            style: AccountantFinanceText.label(theme).copyWith(
                              color: theme.error,
                            ),
                          ),
                        ),
                      Expanded(
                        child: _WorkspaceBody(
                          result: rowsSource,
                          summaryReady: summaryReady,
                          moneyOrDash: _moneyOrDash,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _WorkspaceBody extends StatelessWidget {
  const _WorkspaceBody({
    required this.result,
    required this.summaryReady,
    required this.moneyOrDash,
  });

  final FinanceReconciliationResult result;
  /// When false, metric cards show loading/— (never first-page-only totals).
  final bool summaryReady;
  final String Function(MoneyAmount?) moneyOrDash;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final s = result.summary;
    final completedOnly = result.records
        .where((r) => r.operationalStatus == RecOperationalStatus.completed)
        .toList();
    final gross = summaryReady ? moneyOrDash(s.completedGross) : null;
    final companyDue =
        summaryReady ? moneyOrDash(s.companyReceivableTotal) : null;
    final companyOwes =
        summaryReady ? moneyOrDash(s.companyPayableTotal) : null;
    final moneyCards = <Widget>[
      if (gross != null && gross != '—' && gross != 'غير متوفر')
        _MoneyCard(label: uiTr(context, 'قيمة الرحلات المكتملة'), value: gross),
      if (companyDue != null && companyDue != '—' && companyDue != 'غير متوفر')
        _MoneyCard(label: uiTr(context, 'مستحق للشركة'), value: companyDue),
      if (companyOwes != null &&
          companyOwes != '—' &&
          companyOwes != 'غير متوفر')
        _MoneyCard(label: uiTr(context, 'مستحق على الشركة'), value: companyOwes),
    ];

    return ListView(
      padding: AdminUi.pagePadding(context),
      children: [
        AdminPageHeader(
          title: uiTr(context, 'المصالحة المالية'),
          subtitle: uiTr(
            context,
            'رحلات الفترة التي لا يمكن اعتماد مبلغها، والسبب.',
          ),
        ),
        if (!summaryReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              uiTr(context, 'جاري حساب ملخص الفترة…'),
              style: AccountantFinanceText.label(theme).copyWith(
                color: AdminUi.brandTeal,
              ),
            ),
          ),
        if (summaryReady)
          Text(
            uiTr(
              context,
              'مكتملة: {done}. بياناتها كافية للحساب: {ok}. ناقصة ولا تُجمع: {bad}.',
            )
                .replaceAll('{done}', '${s.completedTrips}')
                .replaceAll('{ok}', '${s.financialComplete}')
                .replaceAll('{bad}', '${s.moneyOmittedIncompleteCount}'),
            style: AccountantFinanceText.body(theme),
          ),
        if (moneyCards.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: moneyCards),
        ],
        const SizedBox(height: 20),
        Text(
          uiTr(context, 'استثناءات تحتاج المراجعة'),
          style: AccountantFinanceText.sectionTitle(theme),
        ),
        const SizedBox(height: 8),
        ..._exceptionTiles(context, theme, completedOnly),
        const SizedBox(height: 20),
        Text(
          uiTr(context, 'سجل المصالحة'),
          style: AccountantFinanceText.sectionTitle(theme),
        ),
        const SizedBox(height: 8),
        if (completedOnly.isEmpty)
          Text(
            uiTr(context, 'لا توجد رحلات مكتملة ضمن النطاق الحالي.'),
            style: AccountantFinanceText.body(theme),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 72,
              columns: [
                DataColumn(label: Text(uiTr(context, 'مرجع الرحلة'))),
                DataColumn(label: Text(uiTr(context, 'الدولة'))),
                DataColumn(label: Text(uiTr(context, 'طريقة الدفع'))),
                DataColumn(label: Text(uiTr(context, 'الحالة المالية'))),
                DataColumn(label: Text(uiTr(context, 'التحصيل'))),
                DataColumn(label: Text(uiTr(context, 'الوكيل'))),
                DataColumn(label: Text(uiTr(context, 'التسوية'))),
                DataColumn(label: Text(uiTr(context, 'المصالحة'))),
                DataColumn(label: Text(uiTr(context, 'المبلغ'))),
                DataColumn(label: Text(uiTr(context, 'الملاحظات'))),
              ],
              rows: [
                for (final r in completedOnly)
                  DataRow(
                    cells: [
                      DataCell(Text(r.displayReference)),
                      DataCell(Text(
                        uiTr(
                          context,
                          AccountantFinanceLabels.countryHumanAr(r.countryPath),
                        ),
                      )),
                      DataCell(Text(
                        uiTr(
                          context,
                          FinanceReconciliationLabels.paymentMethodAr(
                            r.paymentMethod,
                          ),
                        ),
                      )),
                      DataCell(Text(
                        uiTr(
                          context,
                          FinanceReconciliationLabels.financialAr(
                            r.financialSnapshotStatus,
                          ),
                        ),
                      )),
                      DataCell(Text(
                        uiTr(
                          context,
                          FinanceReconciliationLabels.collectionAr(
                            r.collectionStatus,
                          ),
                        ),
                      )),
                      DataCell(Text(
                        uiTr(
                          context,
                          FinanceReconciliationLabels.agentAr(r.agentStatus),
                        ),
                      )),
                      DataCell(Text(
                        uiTr(
                          context,
                          FinanceReconciliationLabels.settlementAr(
                            r.settlementStatus,
                          ),
                        ),
                      )),
                      DataCell(Text(
                        uiTr(
                          context,
                          FinanceReconciliationLabels.reconciliationAr(
                            r.reconciliationStatus,
                          ),
                        ),
                      )),
                      DataCell(Text(moneyOrDash(r.customerTotal ?? r.gross))),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            r.allIssues
                                .where(
                                  FinanceReconciliationLabels.isExceptionWorthy,
                                )
                                .map(
                                  (i) => uiTr(
                                    context,
                                    FinanceReconciliationLabels.issueAr(i.code),
                                  ),
                                )
                                .join(' · '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _exceptionTiles(
    BuildContext context,
    FlutterFlowTheme theme,
    List<FinanceReconciliationRecord> rows,
  ) {
    final tiles = <Widget>[];
    for (final r in rows) {
      if (r.reconciliationStatus == RecReconciliationStatus.reconciled) {
        continue;
      }
      final issues = r.allIssues
          .where(FinanceReconciliationLabels.isExceptionWorthy)
          .toList();
      if (issues.isEmpty &&
          r.reconciliationStatus !=
              RecReconciliationStatus.blockedByMissingData) {
        continue;
      }
      tiles.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: AdminUi.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.displayReference,
                style: AccountantFinanceText.sectionTitle(theme),
              ),
              const SizedBox(height: 4),
              Text(
                uiTr(
                  context,
                  FinanceReconciliationLabels.reconciliationAr(
                    r.reconciliationStatus,
                  ),
                ),
                style: AccountantFinanceText.label(theme),
              ),
              if (issues.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  uiTr(
                    context,
                    'بيانات هذه الرحلة ناقصة، لذلك لا يُحسب مبلغها مع المجاميع.',
                  ),
                  style: AccountantFinanceText.body(theme),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (tiles.isEmpty) {
      return [
        Text(
          uiTr(context, 'لا توجد استثناءات بيانات تتطلب مراجعة فورية.'),
          style: AccountantFinanceText.body(theme),
        ),
      ];
    }
    return tiles;
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: AdminUi.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(uiTr(context, label), style: AccountantFinanceText.label(theme)),
          const SizedBox(height: 6),
          Text(value, style: AccountantFinanceText.money(theme)),
        ],
      ),
    );
  }
}

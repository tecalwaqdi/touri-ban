import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _future = _load();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<FinanceReconciliationResult> _load({bool forceRefresh = false}) async {
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
      });
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _rowsError = e;
        _rowsLoading = false;
      });
    });

    return AccountantFinanceLoader.loadReconciliation(
      forceRefresh: forceRefresh,
    ).then((full) {
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
    if (m == null) return '—';
    return '${m.majorUnits.toStringAsFixed(2)} ${m.code}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canAccess = AdminRoleService.canAccessRoute(
      AdminFinanceReconciliationWidget.routeName,
    );

    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: 'المصالحة المالية',
      child: !canAccess
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'ليس لديك صلاحية لعرض هذه الصفحة',
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
                          'جاري تحميل البيانات المالية...',
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
                      'تعذر تحميل بيانات المصالحة المالية',
                      style: AccountantFinanceText.body(theme),
                    ),
                  );
                }
                if (rowsSource == null) {
                  return Center(
                    child: Text(
                      'لا توجد بيانات',
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
                            'صفوف أولية جاهزة — جاري إكمال ملخص الفترة…',
                            style: AccountantFinanceText.label(theme),
                          ),
                        ),
                      if (_summaryError != null && !summaryReady)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Text(
                            'تعذر تحميل ملخص الفترة — السجل الأولي متاح.',
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
    String metric(String v) => summaryReady ? v : '—';

    return ListView(
      padding: AdminUi.pagePadding(context),
      children: [
        Text(
          'المصالحة المالية',
          style: AccountantFinanceText.pageTitle(theme),
        ),
        const SizedBox(height: 4),
        Text(
          'مراجعة الرحلات المكتملة والحالة المالية والتحصيل والتسويات',
          style: AccountantFinanceText.label(theme),
        ),
        const SizedBox(height: 12),
        if (!summaryReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'جاري حساب ملخص الفترة…',
              style: AccountantFinanceText.label(theme).copyWith(
                color: AdminUi.brandTeal,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip('الرحلات المكتملة', metric('${s.completedTrips}')),
            _MetricChip(
              'بيانات مالية مكتملة',
              metric('${s.financialComplete}'),
            ),
            _MetricChip(
              'بيانات مالية ناقصة',
              metric('${s.financialPartial}'),
            ),
            _MetricChip('تمت المصالحة', metric('${s.reconciled}')),
            _MetricChip('تحتاج مراجعة', metric('${s.needsReview}')),
            _MetricChip(
              'محجوبة بسبب نقص البيانات',
              metric('${s.blockedByMissingData}'),
            ),
            _MetricChip('نقد محصل', metric('${s.cashCollected}')),
            _MetricChip('نقد غير محصل', metric('${s.cashUncollected}')),
            _MetricChip('مسددة', metric('${s.settled}')),
            _MetricChip('غير مسددة', metric('${s.unsettled}')),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MoneyCard(
              label: 'إجمالي مكتمل (موثوق)',
              value: summaryReady ? moneyOrDash(s.completedGross) : '—',
            ),
            _MoneyCard(
              label: 'مستحق للشركة',
              value:
                  summaryReady ? moneyOrDash(s.companyReceivableTotal) : '—',
            ),
            _MoneyCard(
              label: 'مستحق على الشركة',
              value: summaryReady ? moneyOrDash(s.companyPayableTotal) : '—',
            ),
          ],
        ),
        if (summaryReady && s.moneyOmittedIncompleteCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'تم استبعاد ${s.moneyOmittedIncompleteCount} رحلة من مجاميع الأموال لعدم اكتمال البيانات.',
            style: AccountantFinanceText.label(theme),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'استثناءات تحتاج المراجعة',
          style: AccountantFinanceText.sectionTitle(theme),
        ),
        const SizedBox(height: 8),
        ..._exceptionTiles(context, theme, completedOnly),
        const SizedBox(height: 20),
        Text(
          'سجل المصالحة',
          style: AccountantFinanceText.sectionTitle(theme),
        ),
        const SizedBox(height: 8),
        if (completedOnly.isEmpty)
          Text(
            'لا توجد رحلات مكتملة ضمن النطاق الحالي.',
            style: AccountantFinanceText.body(theme),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 72,
              columns: const [
                DataColumn(label: Text('مرجع الرحلة')),
                DataColumn(label: Text('الدولة')),
                DataColumn(label: Text('طريقة الدفع')),
                DataColumn(label: Text('الحالة المالية')),
                DataColumn(label: Text('التحصيل')),
                DataColumn(label: Text('الوكيل')),
                DataColumn(label: Text('التسوية')),
                DataColumn(label: Text('المصالحة')),
                DataColumn(label: Text('المبلغ')),
                DataColumn(label: Text('الملاحظات')),
              ],
              rows: [
                for (final r in completedOnly)
                  DataRow(
                    cells: [
                      DataCell(Text(r.displayReference)),
                      DataCell(Text(
                        AccountantFinanceLabels.countryHumanAr(r.countryPath),
                      )),
                      DataCell(Text(
                        FinanceReconciliationLabels.paymentMethodAr(
                          r.paymentMethod,
                        ),
                      )),
                      DataCell(Text(
                        FinanceReconciliationLabels.financialAr(
                          r.financialSnapshotStatus,
                        ),
                      )),
                      DataCell(Text(
                        FinanceReconciliationLabels.collectionAr(
                          r.collectionStatus,
                        ),
                      )),
                      DataCell(Text(
                        FinanceReconciliationLabels.agentAr(r.agentStatus),
                      )),
                      DataCell(Text(
                        FinanceReconciliationLabels.settlementAr(
                          r.settlementStatus,
                        ),
                      )),
                      DataCell(Text(
                        FinanceReconciliationLabels.reconciliationAr(
                          r.reconciliationStatus,
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
                                  (i) => FinanceReconciliationLabels.issueAr(
                                    i.code,
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
        Text(
          summaryReady
              ? 'مستبعد من العرض العادي: ${result.summary.qaFixturesExcluded} سجل اختبار/ذهبي'
              : 'مستبعد من العرض العادي: —',
          style: AccountantFinanceText.label(theme),
        ),
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
                FinanceReconciliationLabels.reconciliationAr(
                  r.reconciliationStatus,
                ),
                style: AccountantFinanceText.label(theme),
              ),
              if (issues.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  issues
                      .map((i) => FinanceReconciliationLabels.issueAr(i.code))
                      .join('\n'),
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
          'لا توجد استثناءات بيانات تتطلب مراجعة فورية.',
          style: AccountantFinanceText.body(theme),
        ),
      ];
    }
    return tiles;
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AdminUi.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AccountantFinanceText.label(theme)),
          const SizedBox(height: 4),
          Text(value, style: AccountantFinanceText.money(theme)),
        ],
      ),
    );
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
          Text(label, style: AccountantFinanceText.label(theme)),
          const SizedBox(height: 6),
          Text(value, style: AccountantFinanceText.money(theme)),
        ],
      ),
    );
  }
}

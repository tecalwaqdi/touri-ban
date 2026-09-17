import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/financial_accounting_loader.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/finance_dq_classifier.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Financial Data Quality workspace — flag-only; never auto-corrects money.
class AdminFinanceDataQualityWidget extends StatefulWidget {
  const AdminFinanceDataQualityWidget({super.key});

  static const String routeName = 'AdminFinanceDataQuality';
  static const String routePath = '/adminFinanceDataQuality';

  @override
  State<AdminFinanceDataQualityWidget> createState() =>
      _AdminFinanceDataQualityWidgetState();
}

class _AdminFinanceDataQualityWidgetState
    extends State<AdminFinanceDataQualityWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  AdminDatePreset _preset = AdminDatePreset.thisMonth;
  FinanceDqSeverity? _severityFilter;
  Future<_DqBundle>? _future;

  static const _presetLabels = <AdminDatePreset, String>{
    AdminDatePreset.today: 'اليوم',
    AdminDatePreset.yesterday: 'أمس',
    AdminDatePreset.last7Days: 'آخر 7 أيام',
    AdminDatePreset.thisMonth: 'هذا الشهر',
    AdminDatePreset.last30Days: 'آخر 30 يومًا',
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

  void _reload({bool forceRefresh = false}) {
    setState(() {
      _future = _load();
    });
  }

  Future<_DqBundle> _load() async {
    final result = await FinancialAccountingLoader.load(
      FinancialReportFilter(datePreset: _preset),
      requireCanonicalServer: true,
    );
    final lines = result.allMatchingLines.isNotEmpty
        ? result.allMatchingLines
        : result.tableRows.map(_lineFromTable).whereType<FinancialOrderLine>();
    final findings = FinanceDqClassifier.fromLines(lines);
    return _DqBundle(
      findings: findings,
      counts: FinanceDqClassifier.countBySeverity(findings),
      totalsSource: result.totalsSource,
      docsScanned: result.docsScanned,
    );
  }

  FinancialOrderLine? _lineFromTable(dynamic row) {
    // tableRows are OrderRecord-backed lines via loader page — prefer engine.
    try {
      if (row is FinancialOrderLine) return row;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isAr = FFLocalizations.of(context).languageCode.startsWith('ar');

    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'جودة البيانات المالية'),
      child: FutureBuilder<_DqBundle>(
        future: _future,
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting &&
              !snap.hasData;
          final err = snap.hasError
              ? AdminUserFacingErrors.from(context, snap.error!)
              : null;
          final bundle = snap.data;
          final filtered = bundle == null
              ? const <FinanceDqFinding>[]
              : bundle.findings
                  .where((f) =>
                      _severityFilter == null || f.severity == _severityFilter)
                  .toList(growable: false);

          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              AdminPageHeader(
                title: uiTr(context, 'جودة البيانات المالية'),
                subtitle: uiTr(
                  context,
                  'اكتشاف المشاكل فقط — لا يتم تعديل المبالغ التاريخية تلقائيًا.',
                ),
              ),
              AdminPeriodSegmented<AdminDatePreset>(
                values: _presetLabels.keys.toList(growable: false),
                labels: {
                  for (final e in _presetLabels.entries)
                    e.key: uiTr(context, e.value),
                },
                selected: _preset,
                onChanged: (preset) {
                  _preset = preset;
                  _reload();
                },
                onRefresh: () => _reload(forceRefresh: true),
              ),
              const SizedBox(height: 12),
              if (AdminRoleService.isCountryAgent)
                Text(
                  '${uiTr(context, 'النطاق')}: ${AdminRoleService.scopedCountryName.isNotEmpty ? AdminRoleService.scopedCountryName : '—'}',
                  style: AccountantFinanceText.label(theme),
                ),
              if (loading)
                AdminLoadingState(
                  label: uiTr(context, 'جاري فحص جودة البيانات'),
                )
              else if (err != null)
                AdminErrorState(
                  compact: true,
                  title: uiTr(context, 'تعذر فحص الجودة'),
                  message: err,
                  onRetry: _reload,
                )
              else if (bundle != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sevChip(
                      context,
                      label: uiTr(context, 'حرج'),
                      count: bundle.counts[FinanceDqSeverity.critical] ?? 0,
                      selected: _severityFilter == FinanceDqSeverity.critical,
                      color: Colors.red.shade700,
                      onTap: () => setState(() {
                        _severityFilter =
                            _severityFilter == FinanceDqSeverity.critical
                                ? null
                                : FinanceDqSeverity.critical;
                      }),
                    ),
                    _sevChip(
                      context,
                      label: uiTr(context, 'تحذير'),
                      count: bundle.counts[FinanceDqSeverity.warning] ?? 0,
                      selected: _severityFilter == FinanceDqSeverity.warning,
                      color: Colors.orange.shade800,
                      onTap: () => setState(() {
                        _severityFilter =
                            _severityFilter == FinanceDqSeverity.warning
                                ? null
                                : FinanceDqSeverity.warning;
                      }),
                    ),
                    _sevChip(
                      context,
                      label: uiTr(context, 'معلومة'),
                      count: bundle.counts[FinanceDqSeverity.info] ?? 0,
                      selected: _severityFilter == FinanceDqSeverity.info,
                      color: Colors.blueGrey.shade700,
                      onTap: () => setState(() {
                        _severityFilter =
                            _severityFilter == FinanceDqSeverity.info
                                ? null
                                : FinanceDqSeverity.info;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${uiTr(context, 'المصدر')}: ${bundle.totalsSource} · ${uiTr(context, 'مستندات')}: ${bundle.docsScanned}',
                  style: AccountantFinanceText.label(theme),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  AdminEmptyState(
                    compact: true,
                    title: uiTr(context, 'لا توجد مشاكل في هذا النطاق'),
                    icon: Icons.verified_outlined,
                  )
                else
                  AdminContentCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < filtered.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              filtered[i].severity ==
                                      FinanceDqSeverity.critical
                                  ? Icons.error_outline
                                  : filtered[i].severity ==
                                          FinanceDqSeverity.warning
                                      ? Icons.warning_amber_outlined
                                      : Icons.info_outline,
                              color: filtered[i].severity ==
                                      FinanceDqSeverity.critical
                                  ? Colors.red.shade700
                                  : filtered[i].severity ==
                                          FinanceDqSeverity.warning
                                      ? Colors.orange.shade800
                                      : Colors.blueGrey,
                            ),
                            title: Text(
                              isAr
                                  ? filtered[i].titleAr
                                  : filtered[i].titleEn,
                              style: AccountantFinanceText.body(theme),
                            ),
                            subtitle: Text(
                              [
                                filtered[i].orderId,
                                if (filtered[i].detail != null)
                                  filtered[i].detail!,
                              ].join(' · '),
                              style: AccountantFinanceText.label(theme),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sevChip(
    BuildContext context, {
    required String label,
    required int count,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: selected,
      label: Text('$label ($count)'),
      selectedColor: color.withValues(alpha: 0.18),
      checkmarkColor: color,
      onSelected: (_) => onTap(),
    );
  }
}

class _DqBundle {
  const _DqBundle({
    required this.findings,
    required this.counts,
    required this.totalsSource,
    required this.docsScanned,
  });

  final List<FinanceDqFinding> findings;
  final Map<FinanceDqSeverity, int> counts;
  final String totalsSource;
  final int docsScanned;
}

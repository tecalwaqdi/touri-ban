import 'dart:convert';

import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/components/accountant_finance_summary.dart';
import '/components/accountant_money_movement_table.dart';
import '/components/accountant_trip_details_drawer.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_binary_download.dart';
import '/core/finance/finance_company_service.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/finance_export_snapshot.dart';
import '/core/finance/finance_pdf_export.dart';
import '/core/finance/finance_report_csv_builder.dart';
import '/core/finance/finance_xlsx_export.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// On-screen accountant reports — same V2 KPIs + trip lines as Finance Hub.
/// CSV/PDF/XLSX use the same canonical snapshot + trip rows (no independent math).
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
  AdminDatePreset _preset = AdminDatePreset.thisMonth;
  Future<AccountantFinanceViewBundle>? _future;
  AccountantFinanceViewBundle? _lastOk;
  Future<FinanceCompanySnapshot>? _canonicalKpiFuture;
  FinanceCompanySnapshot? _canonicalKpi;
  String? _error;

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

  void _reload({bool forceRefresh = false}) {
    final label = _presetLabels[_preset] ?? _preset.name;
    setState(() {
      _error = null;
      if (forceRefresh) _canonicalKpi = null;
      _canonicalKpiFuture = FinanceCompanyService.load(
        datePreset: _preset,
        periodLabel: label,
      ).then((snap) {
        _canonicalKpi = snap;
        if (mounted) setState(() {});
        return snap;
      });
      _future = AccountantFinanceLoader.load(
        datePreset: _preset,
        periodLabel: label,
        forceRefresh: forceRefresh,
      ).then((b) {
        _lastOk = b;
        return b;
      }).catchError((e) {
        _error = AdminUserFacingErrors.from(context, e);
        throw e;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final countryLabel = AdminRoleService.isCountryAgent
        ? (AdminRoleService.scopedCountryName.isNotEmpty
            ? AdminRoleService.scopedCountryName
            : AccountantFinanceLabels.countryHumanAr(
                AdminRoleService.scopedCountryRef?.path,
              ))
        : uiTr(context, 'كل الدول');

    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'التقارير المحاسبية'),
      child: FutureBuilder<AccountantFinanceViewBundle>(
        future: _future,
        builder: (context, snapshot) {
          final bundle = snapshot.data ?? _lastOk;
          final loading = snapshot.connectionState == ConnectionState.waiting &&
              bundle == null;

          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              AdminPageHeader(
                title: uiTr(context, 'التقارير المحاسبية'),
                subtitle: uiTr(
                  context,
                  'أرقام الفترة نفسها. التصدير من هذه الأرقام، والرحلة الناقصة لا تُحسب صفراً.',
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
              if (bundle != null && bundle.trips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final canonical = _canonicalKpi;
                        if (canonical == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                uiTr(context, 'انتظر اكتمال مؤشرات التقرير'),
                              ),
                            ),
                          );
                          return;
                        }
                        final csv = FinanceReportCsvBuilder.build(
                          snapshot: canonical,
                          trips: bundle.trips,
                          preparedBy: AdminRoleService.currentRole.name,
                          filters:
                              '${_presetLabels[_preset] ?? _preset.name}; $countryLabel',
                        );
                        await FinanceBinaryDownload.download(
                          bytes: Uint8List.fromList(utf8.encode(csv)),
                          filename:
                              'toury_finance_${canonical.currency}_${DateTime.now().millisecondsSinceEpoch}.csv',
                          mime: 'text/csv',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(uiTr(context, 'تم تنزيل CSV')),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_view_outlined, size: 18),
                      label: Text(uiTr(context, 'تصدير CSV')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final canonical = _canonicalKpi;
                        if (canonical == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                uiTr(context, 'انتظر اكتمال مؤشرات التقرير'),
                              ),
                            ),
                          );
                          return;
                        }
                        final snap = FinanceExportSnapshot(
                          generatedAt: DateTime.now().toUtc(),
                          periodLabel: _presetLabels[_preset] ?? _preset.name,
                          currency: canonical.currency,
                          filtersSummary: countryLabel,
                          company: canonical,
                          trips: bundle.trips,
                          localeCode: 'ar',
                        );
                        final bytes = await FinancePdfExport.build(snap);
                        await FinanceBinaryDownload.download(
                          bytes: bytes,
                          filename:
                              'toury_finance_${snap.currency}_${DateTime.now().millisecondsSinceEpoch}.pdf',
                          mime: 'application/pdf',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(uiTr(context, 'تم تنزيل PDF')),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(uiTr(context, 'تصدير PDF')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final canonical = _canonicalKpi;
                        if (canonical == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                uiTr(context, 'انتظر اكتمال مؤشرات التقرير'),
                              ),
                            ),
                          );
                          return;
                        }
                        final snap = FinanceExportSnapshot(
                          generatedAt: DateTime.now().toUtc(),
                          periodLabel: _presetLabels[_preset] ?? _preset.name,
                          currency: canonical.currency,
                          filtersSummary: countryLabel,
                          company: canonical,
                          trips: bundle.trips,
                          localeCode: 'ar',
                        );
                        final bytes = FinanceXlsxExport.build(snap);
                        await FinanceBinaryDownload.download(
                          bytes: bytes,
                          filename:
                              'toury_finance_${snap.currency}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                          mime:
                              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(uiTr(context, 'تم تنزيل Excel')),
                          ),
                        );
                      },
                      icon: const Icon(Icons.grid_on_outlined, size: 18),
                      label: Text(uiTr(context, 'تصدير Excel')),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '$countryLabel · ${_presetLabels[_preset] ?? ''}',
                style: AccountantFinanceText.label(theme),
              ),
              const SizedBox(height: 8),
              if (_error != null)
                AdminErrorState(
                  compact: true,
                  title: uiTr(context, 'تعذر تحميل التقرير'),
                  message: _error,
                  onRetry: _reload,
                ),
              if (loading)
                AdminLoadingState(
                  label: uiTr(context, 'جاري تحميل التقرير'),
                )
              else if (bundle == null && _error == null)
                AdminEmptyState(
                  compact: true,
                  title: uiTr(context, 'لا توجد بيانات'),
                  icon: Icons.inbox_outlined,
                )
              else if (bundle != null && bundle.trips.isEmpty)
                AdminEmptyState(
                  compact: true,
                  title: uiTr(context, 'لا توجد رحلات مكتملة'),
                  message: uiTr(
                    context,
                    'لا يوجد ما يُصدَّر في هذه الفترة.',
                  ),
                  icon: Icons.receipt_long_outlined,
                )
              else if (bundle != null) ...[
                FutureBuilder<FinanceCompanySnapshot>(
                  future: _canonicalKpiFuture,
                  builder: (context, kpiSnap) {
                    final canonical = kpiSnap.data ?? _canonicalKpi;
                    return AccountantFinanceSummaryStrip(
                      bundle: bundle,
                      canonical: canonical,
                    );
                  },
                ),
                const SizedBox(height: 12),
                AccountantMoneyMovementTable(
                  rows: bundle.trips,
                  onOpenDetails: (row) =>
                      showAccountantTripDetailsDrawer(context, row),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

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
import '/core/finance/admin_finance_date_range.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// On-screen accountant reports — same F1 read model as Finance Hub (F2.1).
/// Legacy CSV/PDF exporters remain deferred.
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
                  'ملخص على الشاشة مطابق لشاشة المالية لنفس الفترة والنطاق.',
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
              Text(
                '${uiTr(context, 'نطاق التقرير')}: $countryLabel',
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
              else if (bundle != null) ...[
                Builder(
                  builder: (context) {
                    final range = AdminFinanceDateRangeResolver.resolve(
                      preset: _preset,
                    );
                    return Text(
                      '${uiTr(context, 'الفترة')}: ${range?.displayLabelAr ?? bundle.periodLabel}',
                      style: AccountantFinanceText.label(theme),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AccountantFinanceSummaryStrip(bundle: bundle),
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

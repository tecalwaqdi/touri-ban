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
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Country Agent + Super Admin accountant finance (same F1 read model; scope differs).
class AdminAgentFinanceWidget extends StatefulWidget {
  const AdminAgentFinanceWidget({super.key});

  static const String routeName = 'AdminAgentFinance';
  static const String routePath = '/adminFinanceAgents';

  @override
  State<AdminAgentFinanceWidget> createState() =>
      _AdminAgentFinanceWidgetState();
}

class _AdminAgentFinanceWidgetState extends State<AdminAgentFinanceWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  AdminDatePreset _preset = AdminDatePreset.thisMonth;
  Future<AccountantFinanceViewBundle>? _future;
  AccountantFinanceViewBundle? _lastOk;
  List<AccountantTripRow>? _earlyRows;
  bool _summaryLoading = false;

  static const _presetLabels = <AdminDatePreset, String>{
    AdminDatePreset.today: 'اليوم',
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
    final label = _presetLabels[_preset] ?? _preset.name;
    setState(() {
      if (forceRefresh) {
        _earlyRows = null;
        _lastOk = null;
      }
      _summaryLoading = true;
      _future = null;
    });

    AccountantFinanceLoader.loadFirstPage(
      datePreset: _preset,
      forceRefresh: forceRefresh,
    ).then((rows) {
      if (!mounted) return;
      setState(() {
        _earlyRows = rows;
        _future = AccountantFinanceLoader.load(
          datePreset: _preset,
          periodLabel: label,
          forceRefresh: forceRefresh,
        ).then((b) {
          _lastOk = b;
          if (mounted) {
            setState(() => _earlyRows = b.trips);
          }
          return b;
        }).whenComplete(() {
          if (mounted) {
            setState(() => _summaryLoading = false);
          } else {
            _summaryLoading = false;
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isAgent = AdminRoleService.isCountryAgent;

    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, isAgent ? 'المالية' : 'مالية الوكلاء'),
      child: FutureBuilder<AccountantFinanceViewBundle>(
        future: _future,
        builder: (context, snapshot) {
          final bundle = snapshot.data ?? _lastOk;
          final loading = snapshot.connectionState == ConnectionState.waiting &&
              bundle == null &&
              (_earlyRows == null || _earlyRows!.isEmpty);
          final errored = snapshot.hasError && bundle == null;

          return SingleChildScrollView(
            padding: AdminUi.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  uiTr(context, isAgent ? 'مالية الدولة' : 'مالية الوكلاء'),
                  style: AccountantFinanceText.pageTitle(theme),
                ),
                const SizedBox(height: 4),
                Text(
                  uiTr(
                    context,
                    'نفس الأرقام المحاسبية المعتمدة — النطاق حسب الصلاحية فقط.',
                  ),
                  style: AccountantFinanceText.label(theme),
                ),
                const SizedBox(height: 8),
                AdminFilterBar(
                  hint: uiTr(context, 'الفترة'),
                  chips: [
                    for (final e in _presetLabels.entries)
                      AdminFilterChip(
                        label: uiTr(context, e.value),
                        selected: _preset == e.key,
                        onSelected: (_) {
                          _preset = e.key;
                          _reload();
                        },
                      ),
                  ],
                  trailing: IconButton(
                    tooltip: uiTr(context, 'تحديث'),
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (loading)
                  AdminLoadingState(
                    label: uiTr(context, 'جاري تحميل البيانات المالية'),
                  )
                else if (errored)
                  AdminErrorState(
                    title: uiTr(context, 'تعذر تحميل المالية'),
                    message: uiTr(context, 'يرجى إعادة المحاولة.'),
                    onRetry: _reload,
                  )
                else if (bundle == null &&
                    (_earlyRows == null || _earlyRows!.isEmpty))
                  AdminEmptyState(
                    title: uiTr(context, 'لا توجد بيانات'),
                    message: uiTr(context, 'لا نتائج ضمن الفلاتر الحالية.'),
                  )
                else ...[
                  if (_summaryLoading ||
                      snapshot.connectionState == ConnectionState.waiting)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        uiTr(
                          context,
                          bundle == null
                              ? 'جاري حساب الملخص للفترة… تظهر الصفوف الأولى الآن.'
                              : 'جاري التحديث…',
                        ),
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                    ),
                  if (bundle != null) ...[
                    AccountantFinanceAlertsBanner(alerts: bundle.alerts),
                    if (bundle.alerts.isNotEmpty) const SizedBox(height: 10),
                    AccountantFinanceSummaryStrip(bundle: bundle),
                    const SizedBox(height: 12),
                  ],
                  AccountantMoneyMovementTable(
                    rows: bundle?.trips ?? _earlyRows ?? const [],
                    onOpenDetails: (row) =>
                        showAccountantTripDetailsDrawer(context, row),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

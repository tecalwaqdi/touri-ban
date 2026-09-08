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
import '/core/admin_currency.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/admin_money_presentation.dart';
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
                AdminPageHeader(
                  title: uiTr(context, isAgent ? 'مالية الدولة' : 'مالية الوكلاء'),
                  subtitle: uiTr(
                    context,
                    'نفس الأرقام المحاسبية المعتمدة — النطاق حسب الصلاحية فقط.',
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
                if (loading)
                  AdminLoadingState(
                    label: uiTr(context, 'جاري تحميل البيانات المالية'),
                  )
                else if (errored)
                  AdminErrorState(
                    title: AdminUserFacingErrors.from(
                      context,
                      snapshot.error ?? 'finance_load_failed',
                    ),
                    message: null,
                    onRetry: _reload,
                  )
                else if (bundle == null &&
                    (_earlyRows == null || _earlyRows!.isEmpty))
                  AdminEmptyState(
                    compact: true,
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
                    _AgentFinanceScopeStrip(bundle: bundle),
                    const SizedBox(height: 12),
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

/// Agent-specific scope strip — existing F1 fields only (no invented metrics).
class _AgentFinanceScopeStrip extends StatelessWidget {
  const _AgentFinanceScopeStrip({required this.bundle});

  final AccountantFinanceViewBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final trips = bundle.trips;
    final countries = <String>{
      for (final t in trips)
        if (t.countryLabel.trim().isNotEmpty) t.countryLabel.trim(),
    };
    final agents = <String>{
      for (final t in trips)
        if (t.agentLabel.trim().isNotEmpty && t.agentLabel.trim() != '—')
          t.agentLabel.trim(),
    };

    String countryValue;
    if (AdminRoleService.isCountryAgent &&
        AdminRoleService.scopedCountryName.isNotEmpty) {
      countryValue = AdminRoleService.scopedCountryName;
    } else if (countries.length == 1) {
      countryValue = countries.first;
    } else if (countries.isEmpty) {
      countryValue = '—';
    } else {
      countryValue = uiTr(context, 'عدة دول');
    }

    final agentValue = agents.length == 1
        ? agents.first
        : (agents.isEmpty ? '—' : uiTr(context, '${agents.length} وكلاء'));

    final platformCommission = () {
      final m = bundle.model;
      final sym =
          AdminCurrency.symbolByCode[bundle.currency] ?? bundle.currency;
      if (m.completedTripsWithCompleteFinancialData == 0 &&
          m.companyCommission.minorUnits == 0) {
        return m.completedTripCount == 0 ? '—' : '—';
      }
      return AdminOrderMoneyDisplay.formatMoneyAmount(
        m.companyCommission,
        symbolOverride: sym,
      );
    }();

    final settlementValue = bundle.openSettlementsRemaining > 0
        ? uiTr(
            context,
            'غير مسددة: ${bundle.openSettlementsRemaining}',
          )
        : uiTr(context, 'لا متبقٍ مفتوح');

    final items = <(String, String)>[
      ('الدولة', countryValue),
      ('الوكيل', agentValue),
      ('عدد الرحلات', '${bundle.model.completedTripCount}'),
      // Canonical aggregate for agent share is not on the read model.
      ('حصة الوكيل', '—'),
      ('عمولة المنصة', platformCommission),
      ('حالة التسوية', settlementValue),
    ];

    return AdminContentCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          for (final item in items)
            SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uiTr(context, item.$1),
                    style: AccountantFinanceText.label(theme).copyWith(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AccountantFinanceText.body(theme).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

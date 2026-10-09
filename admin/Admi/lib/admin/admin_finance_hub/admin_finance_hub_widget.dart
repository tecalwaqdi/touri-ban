import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_finance_route_trace.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/components/accountant_money_movement_table.dart';
import '/components/accountant_trip_details_drawer.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/finance_home_overview_cards.dart';
import '/components/menu2_model.dart';
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_text.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/finance_control_facade.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Canonical accountant Finance entry — bounded trip page + CF KPIs only.
///
/// Does **not** run full-history completed scans on the Hub critical path.
class AdminFinanceHubWidget extends StatefulWidget {
  const AdminFinanceHubWidget({super.key});

  static const String routeName = 'AdminFinanceHub';
  static const String routePath = '/adminFinanceHub';

  @override
  State<AdminFinanceHubWidget> createState() => _AdminFinanceHubWidgetState();
}

class _AdminFinanceHubWidgetState extends State<AdminFinanceHubWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  AdminDatePreset _preset = AdminDatePreset.thisMonth;
  Future<FinanceCompanySnapshot>? _canonicalKpiFuture;
  FinanceCompanySnapshot? _canonicalKpi;
  /// PERF-P4A: first modern page independent of period summary.
  List<AccountantTripRow>? _earlyRows;
  bool _rowsLoading = false;
  bool _summaryLoading = false;
  Object? _rowsError;
  Object? _summaryError;
  bool _advancedOpen = false;
  bool _firstBuildMarked = false;

  String? _paymentMethod;
  String? _collectionStatus;
  String? _settlementStatus;
  FinancialDataQuality? _quality;
  String _channel = 'all';
  String _search = '';

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
    AdminFinanceRouteTrace.begin('finance_hub');
    AdminFinanceRouteTrace.mark('FIRST_BUILD_START');
    _menu2Model = createModel(context, () => Menu2Model());
    // Soft claim sync for settlement-map membership + CF-adjacent surfaces.
    refreshAuthClaims(source: 'finance_hub.init').whenComplete(() {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  void _reload({bool forceRefresh = false}) {
    final label = _presetLabels[_preset] ?? _preset.name;
    if (AdminFinanceRouteTrace.activeTraceId == null || forceRefresh) {
      AdminFinanceRouteTrace.begin('finance_hub');
    }
    setState(() {
      if (forceRefresh) {
        _earlyRows = null;
        _canonicalKpi = null;
      }
      _rowsLoading = true;
      _summaryLoading = true;
      _rowsError = null;
      _summaryError = null;
      _canonicalKpiFuture = null;
    });

    // CRITICAL PATH: bounded first page only — no full-history scan on Hub.
    FinanceControlFacade.loadTripLedgerPage(
      datePreset: _preset,
      forceRefresh: forceRefresh,
    ).then((rows) {
      if (!mounted) return;
      setState(() {
        _earlyRows = rows;
        _rowsLoading = false;
        AdminFinanceRouteTrace.markStateEmitAndSchedulePaint();
        AdminFinanceRouteTrace.mark('SUMMARY_START');
        _canonicalKpiFuture = FinanceControlFacade.loadCompanyKpis(
          datePreset: _preset,
          periodLabel: label,
        ).then((snap) {
          _canonicalKpi = snap;
          AdminFinanceRouteTrace.mark('SUMMARY_COMPLETE');
          if (mounted) {
            setState(() => _summaryLoading = false);
          } else {
            _summaryLoading = false;
          }
          return snap;
        }).catchError((Object e) {
          if (mounted) {
            setState(() {
              _summaryError = e;
              _summaryLoading = false;
            });
          } else {
            _summaryError = e;
            _summaryLoading = false;
          }
          throw e;
        });
      });
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _rowsError = e;
        _rowsLoading = false;
        _summaryLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstBuildMarked) {
      _firstBuildMarked = true;
      AdminFinanceRouteTrace.mark('FIRST_BUILD_END');
    }
    final theme = FlutterFlowTheme.of(context);
    final isAgent = AdminRoleService.isCountryAgent;

    return AdminLayoutWidget(
      padContent: false,
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'المالية'),
      child: Builder(
        builder: (context) {
          final rowsReady = _earlyRows != null;
          final hasRows = _earlyRows?.isNotEmpty ?? false;
          final loading = _rowsLoading && !rowsReady && _rowsError == null;
          final errored = _rowsError != null && !rowsReady;
          var tableRows = AccountantTripFilters.apply(
            _earlyRows ?? const [],
            paymentMethod: _paymentMethod,
            collectionStatus: _collectionStatus,
            settlementStatus: _settlementStatus,
            quality: _quality,
            search: _search,
          );
          if (_channel == 'cash') {
            tableRows = tableRows
                .where((r) => r.paymentChannelLabel == 'نقدي')
                .toList();
          } else if (_channel == 'online') {
            tableRows = tableRows
                .where((r) => r.paymentChannelLabel == 'إلكتروني')
                .toList();
          }

          return SingleChildScrollView(
            padding: AdminUi.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPageHeader(
                  title: uiTr(context, 'المالية'),
                  subtitle: uiTr(
                    context,
                    isAgent
                        ? 'ملخص محاسبي لدولتك — قراءة فقط.'
                        : 'ملخص محاسبي موحّد — رحلات مكتملة، تحصيل، ومستحقات.',
                  ),
                  trailing: null,
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
                    _earlyRows = null;
                    _reload();
                  },
                  onRefresh: () => _reload(forceRefresh: true),
                  refreshTooltip: uiTr(context, 'تحديث'),
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: _advancedOpen,
                    onExpansionChanged: (v) =>
                        setState(() => _advancedOpen = v),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: Text(
                      uiTr(context, 'الفلاتر المتقدمة'),
                      style: AccountantFinanceText.sectionTitle(theme),
                    ),
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 220,
                            child: TextField(
                              decoration: AccountantFinanceText.fieldDecoration(
                                context,
                                labelText: uiTr(
                                  context,
                                  'بحث برقم الرحلة أو اسم السائق...',
                                ),
                              ),
                              style: AccountantFinanceText.body(theme),
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                          _drop(
                            context,
                            label: uiTr(context, 'طريقة الدفع'),
                            value: _paymentMethod,
                            items: const ['نقدي', 'إلكتروني'],
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v),
                          ),
                          _drop(
                            context,
                            label: uiTr(context, 'حالة التحصيل'),
                            value: _collectionStatus,
                            items: const ['محصّل', 'غير محصّل'],
                            onChanged: (v) =>
                                setState(() => _collectionStatus = v),
                          ),
                          _drop(
                            context,
                            label: uiTr(context, 'حالة التسوية'),
                            value: _settlementStatus,
                            items: const ['مسددة', 'مسددة جزئيًا', 'غير مسددة'],
                            onChanged: (v) =>
                                setState(() => _settlementStatus = v),
                          ),
                          _qualityDrop(context),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (loading)
                  AdminLoadingState(
                    label: uiTr(context, 'جاري تحميل البيانات المالية'),
                  )
                else if (errored)
                  AdminErrorState(
                    title: uiTr(context, 'تعذر تحميل المالية'),
                    message: uiTr(
                      context,
                      'حدث خطأ أثناء جلب البيانات. يرجى إعادة المحاولة.',
                    ),
                    onRetry: _reload,
                  )
                else if (!hasRows && rowsReady)
                  AdminEmptyState(
                    compact: true,
                    title: uiTr(context, 'لا رحلات مكتملة في هذه الفترة'),
                    message: uiTr(
                      context,
                      'غيّر الفترة من الأعلى. الرحلات خارج الفترة لا تُحسب هنا.',
                    ),
                  )
                else if (!rowsReady)
                  AdminLoadingState(
                    label: uiTr(context, 'جاري تحميل البيانات المالية'),
                  )
                else ...[
                  if (_summaryLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        uiTr(
                          context,
                          'جاري حساب الملخص للفترة… تظهر الصفوف الأولى الآن.',
                        ),
                        style: AccountantFinanceText.label(theme).copyWith(
                          color: AdminUi.brandTeal,
                        ),
                      ),
                    ),
                  if (_summaryError != null && _canonicalKpi == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AdminErrorState(
                        title: uiTr(context, 'تعذر تحميل الملخص'),
                        message: uiTr(
                          context,
                          'الجدول متاح — أعد المحاولة للملخص.',
                        ),
                        onRetry: _reload,
                      ),
                    )
                  else
                    FutureBuilder<FinanceCompanySnapshot>(
                      future: _canonicalKpiFuture,
                      builder: (context, kpiSnap) {
                        final canonical = kpiSnap.data ?? _canonicalKpi;
                        if (canonical == null) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AdminLoadingState(
                              label: uiTr(context, 'جاري حساب الملخص المحاسبي'),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FinanceHomeOverviewCards(snapshot: canonical),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  // Channel filter on bounded page (Cash / Online / All).
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(uiTr(context, 'الكل')),
                          selected: _channel == 'all',
                          onSelected: (_) => setState(() => _channel = 'all'),
                        ),
                        ChoiceChip(
                          label: Text(uiTr(context, 'نقدي')),
                          selected: _channel == 'cash',
                          onSelected: (_) => setState(() => _channel = 'cash'),
                        ),
                        ChoiceChip(
                          label: Text(uiTr(context, 'إلكتروني')),
                          selected: _channel == 'online',
                          onSelected: (_) =>
                              setState(() => _channel = 'online'),
                        ),
                      ],
                    ),
                  ),
                  AccountantMoneyMovementTable(
                    rows: tableRows,
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

  Widget _drop(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        decoration: AccountantFinanceText.fieldDecoration(
          context,
          labelText: uiTr(context, label),
        ),
        style: AccountantFinanceText.body(theme),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(uiTr(context, 'الكل')),
          ),
          for (final i in items)
            DropdownMenuItem<String?>(
              value: i,
              child: Text(uiTr(context, i)),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _qualityDrop(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<FinancialDataQuality?>(
        initialValue: _quality,
        decoration: AccountantFinanceText.fieldDecoration(
          context,
          labelText: uiTr(context, 'جودة البيانات المالية'),
        ),
        style: AccountantFinanceText.body(theme),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(uiTr(context, 'الكل')),
          ),
          for (final q in FinancialDataQuality.values)
            DropdownMenuItem(
              value: q,
              child: Text(
                uiTr(context, AccountantFinanceLabels.dataQualityAr(q)),
              ),
            ),
        ],
        onChanged: (v) => setState(() => _quality = v),
      ),
    );
  }
}

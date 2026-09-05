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
import '/core/finance/accountant_finance_labels.dart';
import '/core/finance/accountant_finance_loader.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Canonical accountant Finance entry — F1 [AccountantFinanceReadModel] only.
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
  Future<AccountantFinanceViewBundle>? _future;
  AccountantFinanceViewBundle? _lastOk;

  String? _paymentMethod;
  String? _collectionStatus;
  String? _settlementStatus;
  FinancialDataQuality? _quality;
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
    _menu2Model = createModel(context, () => Menu2Model());
    _reload();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  void _reload() {
    final label = _presetLabels[_preset] ?? _preset.name;
    setState(() {
      _future = AccountantFinanceLoader.load(
        datePreset: _preset,
        periodLabel: label,
      ).then((b) {
        _lastOk = b;
        return b;
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
      title: uiTr(context, 'المالية'),
      child: FutureBuilder<AccountantFinanceViewBundle>(
        future: _future,
        builder: (context, snapshot) {
          final bundle = snapshot.data ?? _lastOk;
          final loading = snapshot.connectionState == ConnectionState.waiting &&
              bundle == null;
          final errored = snapshot.hasError && bundle == null;

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
                ),
                const SizedBox(height: 8),
                if (!isAgent) _secondaryLinks(context),
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
                const SizedBox(height: 8),
                _advancedFilters(context, theme),
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
                else if (bundle == null)
                  AdminEmptyState(
                    title: uiTr(context, 'لا توجد بيانات'),
                    message: uiTr(context, 'لا نتائج ضمن الفلاتر الحالية.'),
                  )
                else ...[
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        uiTr(context, 'جاري التحديث…'),
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                    ),
                  AccountantFinanceAlertsBanner(alerts: bundle.alerts),
                  if (bundle.alerts.isNotEmpty) const SizedBox(height: 10),
                  AccountantFinanceSummaryStrip(bundle: bundle),
                  const SizedBox(height: 12),
                  AccountantMoneyMovementTable(
                    rows: AccountantTripFilters.apply(
                      bundle.trips,
                      paymentMethod: _paymentMethod,
                      collectionStatus: _collectionStatus,
                      settlementStatus: _settlementStatus,
                      quality: _quality,
                      search: _search,
                    ),
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

  Widget _secondaryLinks(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (AdminRoleService.canAccessRoute(AdminSettlementsWidget.routeName))
          AdminPrimaryButton(
            label: uiTr(context, 'التسويات'),
            outlined: true,
            icon: Icons.receipt_long_outlined,
            onPressed: () =>
                context.pushNamed(AdminSettlementsWidget.routeName),
          ),
        if (AdminRoleService.canAccessRoute(
          AdminFinanceReportsWidget.routeName,
        ))
          AdminPrimaryButton(
            label: uiTr(context, 'التقارير'),
            outlined: true,
            onPressed: () =>
                context.pushNamed(AdminFinanceReportsWidget.routeName),
          ),
        if (AdminRoleService.canAccessRoute(AdminAgentFinanceWidget.routeName))
          AdminPrimaryButton(
            label: uiTr(context, 'مالية الوكلاء'),
            outlined: true,
            onPressed: () =>
                context.pushNamed(AdminAgentFinanceWidget.routeName),
          ),
        if (AdminRoleService.isSuperAdmin &&
            AdminRoleService.canAccessRoute(
              AdminFinanceAuditWidget.routeName,
            ))
          AdminPrimaryButton(
            label: uiTr(context, 'تشخيص تقني'),
            outlined: true,
            onPressed: () =>
                context.pushNamed(AdminFinanceAuditWidget.routeName),
          ),
      ],
    );
  }

  Widget _advancedFilters(BuildContext context, FlutterFlowTheme theme) {
    return AdminContentCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                labelText: uiTr(context, 'بحث'),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          _drop(
            context,
            label: 'طريقة الدفع',
            value: _paymentMethod,
            items: const ['نقدي', 'إلكتروني'],
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          _drop(
            context,
            label: 'حالة التحصيل',
            value: _collectionStatus,
            items: const ['محصّل', 'غير محصّل'],
            onChanged: (v) => setState(() => _collectionStatus = v),
          ),
          _drop(
            context,
            label: 'حالة التسوية',
            value: _settlementStatus,
            items: const ['مسددة', 'مسددة جزئيًا', 'غير مسددة'],
            onChanged: (v) => setState(() => _settlementStatus = v),
          ),
          _qualityDrop(context),
        ],
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
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: uiTr(context, label),
          isDense: true,
          border: const OutlineInputBorder(),
        ),
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
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<FinancialDataQuality?>(
        initialValue: _quality,
        decoration: InputDecoration(
          labelText: uiTr(context, 'جودة البيانات المالية'),
          isDense: true,
          border: const OutlineInputBorder(),
        ),
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

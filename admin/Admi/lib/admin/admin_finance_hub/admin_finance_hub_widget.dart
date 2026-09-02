import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_finance_kpi_groups.dart';
import '/components/admin_layout_widget.dart';
import '/core/admin_currency.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/admin_finance_canonical_ui.dart';
import '/core/finance/admin_finance_date_range.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_company_service.dart';
import '/core/finance/finance_company_snapshot.dart';
import '/core/finance/finance_ledger_service.dart';
import '/core/finance/financial_accounting_unavailable.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// مركز مالي: نظرة موحدة من محاسبة V2 فقط (عرض — بدون كتابة).
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
  Future<({FinanceCompanySnapshot company, FinanceHubSnapshot? wallet})>?
      _future;

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
      _future = _loadBundle(label);
    });
  }

  Future<({FinanceCompanySnapshot company, FinanceHubSnapshot? wallet})>
      _loadBundle(String label) async {
    final company = await FinanceCompanyService.load(
      datePreset: _preset,
      periodLabel: label,
    );
    FinanceHubSnapshot? wallet;
    try {
      wallet = await FinanceLedgerService.load(
        datePreset: _preset,
        periodLabel: label,
      );
    } catch (_) {}
    return (company: company, wallet: wallet);
  }

  String _money(MoneyAmount? m, String symbol) =>
      AdminOrderMoneyDisplay.formatMoneyAmount(m, symbolOverride: symbol);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'المالية'),
      child: FutureBuilder<
          ({FinanceCompanySnapshot company, FinanceHubSnapshot? wallet})>(
        future: _future,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            padding: AdminUi.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPageHeader(
                  title: uiTr(context, 'المالية'),
                  subtitle: uiTr(
                    context,
                    'مركز التحكم المحاسبي — المبيعات مقابل الإيراد المحقق.',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminPrimaryButton(
                      label: uiTr(context, 'التقرير المالي'),
                      outlined: true,
                      icon: Icons.open_in_new_rounded,
                      onPressed: () => context.pushNamed(
                        AdminProfitsWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'النقدي / الإلكتروني'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminFinanceChannelsWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'التسويات'),
                      outlined: true,
                      icon: Icons.receipt_long_outlined,
                      onPressed: () => context.pushNamed(
                        AdminSettlementsWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'المطابقة'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminReconciliationWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'مالية الوكلاء'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminAgentFinanceWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'سجل التدقيق'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminFinanceAuditWidget.routeName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                if (!snapshot.hasData && !snapshot.hasError)
                  AdminLoadingState(
                    label: uiTr(context, 'جاري تحميل البيانات المالية'),
                  )
                else if (snapshot.hasError)
                  snapshot.error is FinancialAccountingUnavailableException
                      ? AdminFinanceCanonicalUnavailablePanel(
                          onRetry: _reload,
                        )
                      : AdminEmptyState(
                          title: uiTr(context, 'تعذر تحميل المركز المالي'),
                          message: '${snapshot.error}',
                          icon: Icons.error_outline,
                          action: AdminPrimaryButton(
                            label: uiTr(context, 'إعادة المحاولة'),
                            onPressed: _reload,
                          ),
                        )
                else
                  _buildBody(
                    context,
                    theme,
                    snapshot.data!.company,
                    snapshot.data!.wallet,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FlutterFlowTheme theme,
    FinanceCompanySnapshot data,
    FinanceHubSnapshot? wallet,
  ) {
    final sym = AdminCurrency.symbolByCode[data.currency] ?? data.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${uiTr(context, 'الفترة')}: ${data.periodLabel} · ${uiTr(context, 'توقيت الرياض')}',
                style: theme.labelLarge.override(
                  fontFamily: theme.labelLargeFamily,
                  color: AdminUi.brandTeal,
                  fontWeight: FontWeight.w700,
                  useGoogleFonts: !theme.labelLargeIsCustom,
                ),
              ),
            ),
            Tooltip(
              message: uiTr(
                context,
                'الإيراد المحقق = رحلات مكتملة ومحصّلة فقط. غير المحصّل ≠ إيراد.',
              ),
              child: AdminStatusBadge(
                label: data.isApproximate
                    ? uiTr(context, 'مصدر تقريبي (مسح عميل)')
                    : uiTr(context, 'المصدر: المحاسبة V2'),
                tone: data.isApproximate
                    ? AdminBadgeTone.warning
                    : AdminBadgeTone.success,
              ),
            ),
          ],
        ),
        Text(
          '${uiTr(context, 'تم الإنشاء')}: ${AdminFinanceRiyadhClock.formatDateTime(DateTime.now().toUtc())}',
          style: theme.labelSmall,
        ),
        const SizedBox(height: 12),
        if (data.realizedRevenue.minorUnits == 0 &&
            (data.completedButNotCollected > 0 ||
                data.cancelledOrExpired > 0 ||
                data.financiallyIncomplete > 0))
          AdminContentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  uiTr(context, 'لماذا تظهر الأرقام 0.00؟'),
                  style: theme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  uiTr(
                    context,
                    'الإيراد المحقق يعرض فقط الرحلات المكتملة والمحصّلة. الرحلات الملغاة أو بانتظار التحصيل لا تُحسب كإيراد.',
                  ),
                  style: theme.bodySmall,
                ),
                if (data.completedButNotCollected > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${uiTr(context, 'رحلات نقدية بانتظار إثبات التحصيل')}: '
                    '${data.completedButNotCollected} · '
                    '${_money(data.unCollectedTripValue, sym)}',
                    style: theme.labelMedium,
                  ),
                ],
                if (data.financiallyIncomplete > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${uiTr(context, 'بيانات مالية تاريخية ناقصة')}: '
                    '${data.financiallyIncomplete}',
                    style: theme.labelMedium.copyWith(
                      color: theme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (data.realizedRevenue.minorUnits == 0 &&
            (data.completedButNotCollected > 0 ||
                data.cancelledOrExpired > 0 ||
                data.financiallyIncomplete > 0))
          const SizedBox(height: 12),
        AdminFinanceKpiGroups(snapshot: data, symbol: sym),
        const SizedBox(height: 12),
        AdminContentCard(
          title: uiTr(context, 'حالة التحصيل'),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _chip(
                uiTr(context, 'محصّل ومكتمل'),
                '${data.completedAndCollected}',
                AdminBadgeTone.success,
              ),
              _chip(
                uiTr(context, 'بانتظار التحصيل'),
                '${data.completedButNotCollected}',
                AdminBadgeTone.warning,
              ),
              _chip(
                uiTr(context, 'ملغى / منتهي'),
                '${data.cancelledOrExpired}',
                AdminBadgeTone.danger,
              ),
              _chip(
                uiTr(context, 'رحلات تحتاج مراجعة'),
                '${data.financiallyIncomplete}',
                AdminBadgeTone.info,
              ),
            ],
          ),
        ),
        if (wallet != null) ...[
          const SizedBox(height: 16),
          AdminContentCard(
            title: uiTr(context, 'المحفظة (دفتر منفصل)'),
            child: Text(
              uiTr(
                context,
                'رصيد المحفظة ليس صافي أرباح الرحلات. المحافظ: ${wallet.driverBalances.length}',
              ),
              style: theme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 12),
        AdminContentCard(
          title: uiTr(context, 'روابط سريعة'),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (AdminRoleService.canAccessRoute(
                AdminReportsHubWidget.routeName,
              ))
                AdminPrimaryButton(
                  label: uiTr(context, 'التقارير التشغيلية'),
                  outlined: true,
                  onPressed: () => context.pushNamed(
                    AdminReportsHubWidget.routeName,
                  ),
                ),
              AdminPrimaryButton(
                label: uiTr(context, 'الحجوزات'),
                outlined: true,
                onPressed: () => context.pushNamed(
                  AdminALLhgZWidget.routeName,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value, AdminBadgeTone tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AdminUi.cardDecoration(context, elevated: false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminStatusBadge(label: label, tone: tone),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_ledger_service.dart';
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
  String _period = 'month';
  Future<FinanceHubSnapshot>? _future;

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

  (AdminDatePreset, String) _preset() {
    switch (_period) {
      case 'day':
        return (AdminDatePreset.today, 'ent_period_today');
      case 'year':
        return (AdminDatePreset.thisYear, 'ent_period_this_year');
      case 'month':
      default:
        return (AdminDatePreset.thisMonth, 'ent_period_this_month');
    }
  }

  void _reload() {
    final p = _preset();
    setState(() {
      _future = FinanceLedgerService.load(
        datePreset: p.$1,
        periodLabel: p.$2,
      );
    });
  }

  String _money(MoneyAmount? m, String symbol) =>
      financeHubMoneyLabel(m, symbol);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'المالية'),
      child: FutureBuilder<FinanceHubSnapshot>(
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
                    'نظرة موحدة على الإيرادات والعمولات وصافي أرباح المناديب والتسويات.',
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
                      label: uiTr(context, 'الفترات المحاسبية'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminFinancialPeriodsWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'التقارير المحاسبية'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminFinanceReportsWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'سجل التدقيق'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminFinanceAuditWidget.routeName,
                      ),
                    ),
                    AdminPrimaryButton(
                      label: uiTr(context, 'المحافظ'),
                      outlined: true,
                      onPressed: () => context.pushNamed(
                        AdminDriverWalletsWidget.routeName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdminFilterBar(
                  hint: uiTr(context, 'الفترة'),
                  chips: [
                    AdminFilterChip(
                      label: uiTr(context, 'اليوم'),
                      selected: _period == 'day',
                      onSelected: (_) {
                        _period = 'day';
                        _reload();
                      },
                    ),
                    AdminFilterChip(
                      label: uiTr(context, 'هذا الشهر'),
                      selected: _period == 'month',
                      onSelected: (_) {
                        _period = 'month';
                        _reload();
                      },
                    ),
                    AdminFilterChip(
                      label: uiTr(context, 'هذه السنة'),
                      selected: _period == 'year',
                      onSelected: (_) {
                        _period = 'year';
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
                  AdminEmptyState(
                    title: uiTr(context, 'تعذر تحميل المركز المالي'),
                    message: '${snapshot.error}',
                    icon: Icons.error_outline,
                    action: AdminPrimaryButton(
                      label: uiTr(context, 'إعادة المحاولة'),
                      onPressed: _reload,
                    ),
                  )
                else
                  _buildBody(context, theme, snapshot.data!),
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
    FinanceHubSnapshot data,
  ) {
    final sym = data.currencySymbol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                appTrFormat(
                  context,
                  'ent_period_label',
                  appTr(context, data.periodLabel),
                ),
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
                'الأرقام المعروضة للمحصّل والمؤهل للتسوية فقط. الرحلات المكتملة بانتظار إثبات التحصيل تُعرض كعدد منفصل.',
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
        const SizedBox(height: 12),
        AdminKpiStrip(
          items: [
            (
              label: uiTr(context, 'إجمالي المحصّل'),
              value: _money(data.collectedTripValue, sym),
              icon: Icons.trending_up_rounded,
              color: AdminUi.brandTeal,
            ),
            (
              label: uiTr(context, 'عمولة الشركة'),
              value: _money(data.platformFees, sym),
              icon: Icons.savings_rounded,
              color: const Color(0xFF0F7A4A),
            ),
            (
              label: uiTr(context, 'ضريبة القيمة المضافة'),
              value: _money(data.recordedVat, sym),
              icon: Icons.receipt_outlined,
              color: const Color(0xFF5B6B7A),
            ),
            (
              label: uiTr(context, 'صافي أرباح المناديب'),
              value: _money(data.driverNet, sym),
              icon: Icons.payments_rounded,
              color: const Color(0xFFB06A00),
            ),
            (
              label: uiTr(context, 'المستحق المؤهل للتسوية'),
              value: _money(data.settlementEligibleDue, sym),
              icon: Icons.account_balance_rounded,
              color: theme.error,
            ),
            (
              label: uiTr(context, 'مستحق للمناديب'),
              value: _money(data.companyOwesDrivers, sym),
              icon: Icons.outbound_rounded,
              color: const Color(0xFF2F6FED),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdminContentCard(
          title: uiTr(context, 'حالة التحصيل والتسوية'),
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
                uiTr(context, 'رحلات نقدية بانتظار إثبات التحصيل'),
                '${data.completedButNotCollected}',
                AdminBadgeTone.warning,
              ),
              _chip(
                uiTr(context, 'بانتظار الدفع'),
                '${data.pendingPayment}',
                AdminBadgeTone.info,
              ),
              _chip(
                uiTr(context, 'ملغى / منتهي'),
                '${data.cancelledOrExpired}',
                AdminBadgeTone.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          uiTr(
            context,
            'المستحق المؤهل للتسوية يعتمد على الرحلات المحصّلة فقط. لا يُحسب إجمالي الرحلات غير المحصّلة كمستحق دفتر.',
          ),
          softWrap: true,
          style: theme.labelSmall,
        ),
        const SizedBox(height: 16),
        AdminContentCard(
          title: uiTr(context, 'أرصدة المحافظ (دفتر منفصل)'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                uiTr(
                  context,
                  'رصيد المحفظة ليس صافي أرباح الرحلات. المحفظة دفتر منفصل عن محاسبة الرحلات والتسويات.',
                ),
                softWrap: true,
                style: theme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${uiTr(context, 'محافظ محمّلة')}: ${data.driverBalances.length}',
                style: theme.titleSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminDataTable(
          emptyTitle: uiTr(context, 'لا توجد عمليات محفظة حديثة'),
          columns: [
            AdminTableColumn(
              label: uiTr(context, 'النوع'),
              flex: 2,
            ),
            AdminTableColumn(
              label: uiTr(context, 'المبلغ'),
              flex: 2,
            ),
            AdminTableColumn(
              label: uiTr(context, 'الطرف'),
              flex: 2,
            ),
            AdminTableColumn(
              label: uiTr(context, 'ملاحظة'),
              flex: 3,
            ),
          ],
          rows: [
            for (final e in data.ledger.take(40))
              [
                Text(e.type),
                Text(_money(
                  MoneyAmount.fromMajor(data.primaryCurrency, e.amount),
                  sym,
                )),
                Text(e.partyLabel, overflow: TextOverflow.ellipsis),
                Text(
                  e.note.startsWith('ent_')
                      ? appTr(context, e.note)
                      : (e.note.isEmpty ? '—' : e.note),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
          ],
        ),
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

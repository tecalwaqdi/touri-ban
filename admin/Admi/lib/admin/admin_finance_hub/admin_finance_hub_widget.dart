import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_ledger_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// مركز مالي Enterprise: إيرادات، عمولات، أرصدة، سجل عمليات، فواتير.
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

  (DateTime, DateTime, String) _range() {
    final now = DateTime.now();
    switch (_period) {
      case 'day':
        final from = DateTime(now.year, now.month, now.day);
        return (from, now, 'ent_period_today');
      case 'year':
        final from = DateTime(now.year, 1, 1);
        return (from, now, 'ent_period_this_year');
      case 'month':
      default:
        final from = DateTime(now.year, now.month, 1);
        return (from, now, 'ent_period_this_month');
    }
  }

  void _reload() {
    final r = _range();
    setState(() {
      _future = FinanceLedgerService.load(
        from: r.$1,
        to: r.$2,
        periodLabel: r.$3,
      );
    });
  }

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: appTr(context, 'ent_finance_title'),
      child: FutureBuilder<FinanceHubSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPageHeader(
                  title: appTr(context, 'ent_finance_title'),
                  subtitle: appTr(context, 'ent_finance_subtitle'),
                  trailing: AdminPrimaryButton(
                    label: appTr(context, 'ent_finance_detailed_profits'),
                    outlined: true,
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => context.pushNamed(
                      AdminProfitsWidget.routeName,
                    ),
                  ),
                ),
                AdminFilterBar(
                  hint: appTr(context, 'ent_period'),
                  chips: [
                    AdminFilterChip(
                      label: appTr(context, 'ent_daily'),
                      selected: _period == 'day',
                      onSelected: (_) {
                        _period = 'day';
                        _reload();
                      },
                    ),
                    AdminFilterChip(
                      label: appTr(context, 'ent_monthly'),
                      selected: _period == 'month',
                      onSelected: (_) {
                        _period = 'month';
                        _reload();
                      },
                    ),
                    AdminFilterChip(
                      label: appTr(context, 'ent_yearly'),
                      selected: _period == 'year',
                      onSelected: (_) {
                        _period = 'year';
                        _reload();
                      },
                    ),
                  ],
                  trailing: IconButton(
                    tooltip: appTr(context, 'ent_refresh'),
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                if (!snapshot.hasData && !snapshot.hasError)
                  AdminLoadingState(
                      label: appTr(context, 'ent_finance_loading'))
                else if (snapshot.hasError)
                  AdminEmptyState(
                    title: appTr(context, 'ent_finance_load_failed'),
                    message: '${snapshot.error}',
                    icon: Icons.error_outline,
                    action: AdminPrimaryButton(
                      label: appTr(context, 'ent_retry'),
                      onPressed: _reload,
                    ),
                  )
                else ...[
                  Builder(
                    builder: (context) {
                      final data = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
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
                          if (data.isApproximate) ...[
                            const SizedBox(height: 8),
                            AdminStatusBadge(
                              label: uiTr(
                                context,
                                'بيانات تقريبية (عيّنة محلية — تعذر الاتصال بالخادم)',
                              ),
                              tone: AdminBadgeTone.warning,
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            AdminStatusBadge(
                              label: uiTr(context, 'بيانات من الخادم'),
                              tone: AdminBadgeTone.success,
                            ),
                          ],
                          const SizedBox(height: 12),
                          AdminKpiStrip(
                            items: [
                              (
                                label: appTr(context, 'ent_finance_revenue'),
                                value: _fmt(data.revenue),
                                icon: Icons.trending_up_rounded,
                                color: AdminUi.brandTeal,
                              ),
                              (
                                label: appTr(context, 'ent_finance_app_profit'),
                                value: _fmt(data.appProfit),
                                icon: Icons.savings_rounded,
                                color: const Color(0xFF0F7A4A),
                              ),
                              (
                                label:
                                    appTr(context, 'ent_finance_commissions'),
                                value: _fmt(data.commissions),
                                icon: Icons.payments_rounded,
                                color: const Color(0xFFB06A00),
                              ),
                              (
                                label: appTr(
                                    context, 'ent_finance_pending_settlement'),
                                value: _fmt(data.pendingSettlements),
                                icon: Icons.hourglass_top_rounded,
                                color: theme.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AdminContentCard(
                            title:
                                appTr(context, 'ent_finance_bookings_summary'),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _chip(
                                    appTr(context, 'ent_finance_paid'),
                                    '${data.paidOrders}',
                                    AdminBadgeTone.success),
                                _chip(
                                    appTr(context, 'ent_finance_pending'),
                                    '${data.pendingOrders}',
                                    AdminBadgeTone.warning),
                                _chip(
                                    appTr(context, 'ent_finance_canceled'),
                                    '${data.canceledOrders}',
                                    AdminBadgeTone.danger),
                                _chip(
                                  appTr(
                                      context, 'ent_finance_driver_balances'),
                                  '${data.driverBalances.length}',
                                  AdminBadgeTone.info,
                                ),
                                _chip(
                                  appTr(
                                      context, 'ent_finance_company_balances'),
                                  '${data.companyBalances.length}',
                                  AdminBadgeTone.info,
                                ),
                                _chip(
                                  appTr(
                                      context, 'ent_finance_agent_balances'),
                                  '${data.agentBalances.length}',
                                  AdminBadgeTone.info,
                                ),
                              ],
                            ),
                          ),
                          AdminDataTable(
                            emptyTitle: appTr(context, 'ent_finance_no_ops'),
                            columns: [
                              AdminTableColumn(
                                  label: appTr(
                                      context, 'ent_finance_col_type'),
                                  flex: 2),
                              AdminTableColumn(
                                  label: appTr(
                                      context, 'ent_finance_col_amount'),
                                  flex: 2),
                              AdminTableColumn(
                                  label: appTr(
                                      context, 'ent_finance_col_party'),
                                  flex: 2),
                              AdminTableColumn(
                                  label: appTr(
                                      context, 'ent_finance_col_note'),
                                  flex: 3),
                            ],
                            rows: [
                              for (final e in data.ledger.take(40))
                                [
                                  Text(e.type),
                                  Text(_fmt(e.amount)),
                                  Text(e.partyLabel,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    e.note.startsWith('ent_')
                                        ? appTr(context, e.note)
                                        : (e.note.isEmpty ? '—' : e.note),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                            ],
                          ),
                          AdminContentCard(
                            title: appTr(context, 'ent_finance_quick_links'),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (AdminRoleService.canAccessRoute(
                                  AdminReportsHubWidget.routeName,
                                ))
                                  AdminPrimaryButton(
                                    label: appTr(
                                        context, 'ent_finance_admin_reports'),
                                    outlined: true,
                                    onPressed: () => context.pushNamed(
                                      AdminReportsHubWidget.routeName,
                                    ),
                                  ),
                                AdminPrimaryButton(
                                  label:
                                      appTr(context, 'ent_finance_bookings'),
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
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
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

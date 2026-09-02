import 'package:flutter/material.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/financial_accounting_loader.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_currency.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_agent_account.dart';
import '/core/finance/finance_agent_attribution.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// FIN-4 — Agent finance (scope-based; no fabricated historical commission).
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
  Future<List<AgentFinanceAccount>>? _future;

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
    setState(() {
      _future = _loadAgents();
    });
  }

  Future<List<AgentFinanceAccount>> _loadAgents() async {
    final agents = await queryUserRecordOnce(
      queryBuilder: (q) => q.where('Isagent', isEqualTo: true),
      limit: 50,
    );
    final scoped = AdminRoleService.isCountryAgent
        ? agents.where((a) {
            final scope = AdminRoleService.scopedCountryRef?.path;
            return scope != null && a.revDlohAgent?.path == scope;
          }).toList()
        : agents;

    final byCountry = <String, int>{};
    for (final a in scoped) {
      final p = a.revDlohAgent?.path;
      if (p != null) byCountry[p] = (byCountry[p] ?? 0) + 1;
    }

    final accounts = <AgentFinanceAccount>[];
    for (final agent in scoped) {
      final countryRef = agent.revDlohAgent;
      if (countryRef == null) continue;

      final result = await FinancialAccountingLoader.load(
        FinancialReportFilter(
          datePreset: AdminDatePreset.all,
          countryRef: countryRef,
        ),
      );
      final lines = result.allMatchingLines;
      if (lines.isEmpty) {
        final t = result.byCurrency['SAR'] ??
            (result.byCurrency.values.isEmpty
                ? FinancialCurrencyTotals(currency: 'SAR')
                : result.byCurrency.values.first);
        accounts.add(
          AgentFinanceAccount(
            agentId: agent.reference.id,
            agentName: agent.displayName,
            countryPath: countryRef.path,
            scope: byCountry[countryRef.path] == 1
                ? AgentAttributionScope.countryExclusive
                : AgentAttributionScope.countryScopeOnly,
            attributionConfidence: byCountry[countryRef.path] == 1 &&
                    agent.agentTotal > 0
                ? AgentAttributionConfidence.provable
                : AgentAttributionConfidence.scopeOnly,
            commissionRatePercent: agent.agentTotal,
            attributedTrips: t.completedAndCollected + t.completedButNotCollected,
            completedTrips: t.lifecycleCompleted,
            cancelledTrips: t.lifecycleCancelled + t.lifecycleExpired,
            attributedSales: MoneyAmount(
              currency: t.currency,
              minorUnits: t.completedAndCollectedMinor.minorUnits +
                  t.completedButNotCollectedMinor.minorUnits,
            ),
            cashSales: MoneyAmount(
              currency: t.currency,
              minorUnits: t.cashCustomerCollected.minorUnits +
                  t.cashCompletedPendingMinor.minorUnits,
            ),
            onlineSales: MoneyAmount(
              currency: t.currency,
              minorUnits: t.onlineCustomerPaid.minorUnits +
                  t.onlineCompletedPendingMinor.minorUnits,
            ),
            provableCommission: byCountry[countryRef.path] == 1 &&
                    agent.agentTotal > 0
                ? MoneyAmount(
                    currency: t.currency,
                    minorUnits: (t.completedAndCollectedMinor.minorUnits *
                            agent.agentTotal /
                            100)
                        .round(),
                  )
                : MoneyAmount.zero(t.currency),
            dueMinor: 0,
            paidMinor: 0,
            outstandingMinor: 0,
            statementRows: const [],
            unprovableHistorical: byCountry[countryRef.path] != 1,
          ),
        );
        continue;
      }

      accounts.add(
        AgentFinanceAccount.fromAgentAndLines(
          agent: agent,
          countryLines: lines,
          currency: 'SAR',
          exclusiveCountryAgent: byCountry[countryRef.path] == 1,
        ),
      );
    }
    return accounts;
  }

  String _m(MoneyAmount? m, String symbol) =>
      AdminOrderMoneyDisplay.formatMoneyAmount(m, symbolOverride: symbol);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final contract = AgentAttributionContract.canonical;
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'مالية الوكلاء'),
      child: FutureBuilder<List<AgentFinanceAccount>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snap.data!;
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              AdminPageHeader(
                title: uiTr(context, 'حسابات الوكلاء'),
                subtitle: uiTr(
                  context,
                  'العمولة التاريخية تُثبت فقط عند وكيل حصري للدولة. وإلا: غير منسوب.',
                ),
              ),
              AdminContentCard(
                child: Text(
                  '${uiTr(context, 'نموذج الإسناد')}: ${contract.orderCountryField} → '
                  '${contract.agentCountryField} · '
                  '${uiTr(context, 'النسبة')}: ${contract.rateSourceField}',
                  style: theme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              if (accounts.isEmpty)
                AdminEmptyState(
                  title: uiTr(context, 'لا يوجد وكلاء في النطاق'),
                  message: uiTr(context, 'تحقق من صلاحيات الدولة'),
                  icon: Icons.person_off_outlined,
                ),
              for (final a in accounts) ...[
                AdminContentCard(
                  title: a.agentName,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (a.unprovableHistorical)
                        Text(
                          uiTr(
                            context,
                            'غير منسوب / لا يمكن إثبات العمولة تاريخيًا',
                          ),
                          style: theme.labelMedium.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      _kv(theme, uiTr(context, 'الدولة'), a.countryPath ?? '—'),
                      _kv(
                        theme,
                        uiTr(context, 'الرحلات المنسوبة'),
                        '${a.attributedTrips}',
                      ),
                      _kv(
                        theme,
                        uiTr(context, 'المكتملة'),
                        '${a.completedTrips}',
                      ),
                      _kv(
                        theme,
                        uiTr(context, 'عمولة الوكيل (محققة فقط)'),
                        _m(
                          a.provableCommission,
                          AdminCurrency.symbolByCode['SAR'] ?? 'SAR',
                        ),
                      ),
                      _kv(
                        theme,
                        uiTr(context, 'المتبقي'),
                        '${a.outstandingMinor}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _kv(FlutterFlowTheme theme, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k, style: theme.bodyMedium)),
          Text(v, style: theme.titleSmall),
        ],
      ),
    );
  }
}

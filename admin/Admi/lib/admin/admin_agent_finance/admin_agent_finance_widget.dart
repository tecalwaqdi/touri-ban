import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
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

  static const _maxConcurrentLoads = 3;

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
            if (scope == null || a.revDlohAgent?.path != scope) {
              return false;
            }
            // Agent accounts only see their own finance — not peer agents.
            if (AdminRoleService.isAgentAccount) {
              final me = currentUserUid;
              return me.isNotEmpty && a.reference.id == me;
            }
            return true;
          }).toList()
        : agents;

    final byCountry = <String, int>{};
    for (final a in scoped) {
      final p = a.revDlohAgent?.path;
      if (p != null) byCountry[p] = (byCountry[p] ?? 0) + 1;
    }

    final withCountry =
        scoped.where((a) => a.revDlohAgent != null).toList(growable: false);
    final accounts = <AgentFinanceAccount>[];
    for (var i = 0; i < withCountry.length; i += _maxConcurrentLoads) {
      final chunk = withCountry.skip(i).take(_maxConcurrentLoads);
      final chunkResults = await Future.wait(
        chunk.map(
          (agent) => _loadOneAgentAccount(
            agent: agent,
            exclusiveCountry: byCountry[agent.revDlohAgent!.path] == 1,
          ),
        ),
      );
      for (final a in chunkResults) {
        if (a != null) accounts.add(a);
      }
    }
    return accounts;
  }

  /// Per-agent isolation: one CF/query failure must not blank the whole page.
  Future<AgentFinanceAccount?> _loadOneAgentAccount({
    required UserRecord agent,
    required bool exclusiveCountry,
  }) async {
    final countryRef = agent.revDlohAgent;
    if (countryRef == null) return null;
    try {
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
        return AgentFinanceAccount(
          agentId: agent.reference.id,
          agentName: agent.displayName,
          countryPath: countryRef.path,
          scope: exclusiveCountry
              ? AgentAttributionScope.countryExclusive
              : AgentAttributionScope.countryScopeOnly,
          attributionConfidence:
              exclusiveCountry && agent.agentTotal > 0
                  ? AgentAttributionConfidence.provable
                  : AgentAttributionConfidence.scopeOnly,
          commissionRatePercent: agent.agentTotal,
          attributedTrips:
              t.completedAndCollected + t.completedButNotCollected,
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
          provableCommission: exclusiveCountry && agent.agentTotal > 0
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
          unprovableHistorical: !exclusiveCountry,
        );
      }

      return AgentFinanceAccount.fromAgentAndLines(
        agent: agent,
        countryLines: lines,
        currency: 'SAR',
        exclusiveCountryAgent: exclusiveCountry,
      );
    } catch (_) {
      // Surface a zero-activity / unavailable card rather than hanging forever.
      // Totals stay 0 — never invent confirmed commission after a load failure.
      return AgentFinanceAccount(
        agentId: agent.reference.id,
        agentName: agent.displayName.isNotEmpty
            ? agent.displayName
            : agent.email,
        countryPath: countryRef.path,
        scope: exclusiveCountry
            ? AgentAttributionScope.countryExclusive
            : AgentAttributionScope.countryScopeOnly,
        attributionConfidence: AgentAttributionConfidence.scopeOnly,
        commissionRatePercent: agent.agentTotal,
        attributedTrips: 0,
        completedTrips: 0,
        cancelledTrips: 0,
        attributedSales: MoneyAmount.zero('SAR'),
        cashSales: MoneyAmount.zero('SAR'),
        onlineSales: MoneyAmount.zero('SAR'),
        provableCommission: MoneyAmount.zero('SAR'),
        dueMinor: 0,
        paidMinor: 0,
        outstandingMinor: 0,
        statementRows: const [],
        unprovableHistorical: true,
      );
    }
  }

  String _m(MoneyAmount? m) => AdminOrderMoneyDisplay.formatMoneyAmount(
        m,
        symbolOverride: AdminCurrency.symbolByCode[m?.code ?? 'SAR'] ?? 'ر.س',
      );

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
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: AdminUi.pagePadding(context),
              child: AdminEmptyState(
                title: uiTr(context, 'تعذر تحميل البيانات'),
                message: uiTr(
                  context,
                  'فشل تحميل مالية الوكلاء. أعد المحاولة.',
                ),
                icon: Icons.error_outline,
                action: FilledButton(
                  onPressed: _reload,
                  child: Text(uiTr(context, 'إعادة المحاولة')),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return Padding(
              padding: AdminUi.pagePadding(context),
              child: AdminEmptyState(
                title: uiTr(context, 'تعذر تحميل البيانات'),
                message: uiTr(context, 'لا توجد بيانات للعرض'),
                icon: Icons.cloud_off_outlined,
                action: FilledButton(
                  onPressed: _reload,
                  child: Text(uiTr(context, 'إعادة المحاولة')),
                ),
              ),
            );
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
                  action: FilledButton(
                    onPressed: _reload,
                    child: Text(uiTr(context, 'إعادة المحاولة')),
                  ),
                ),
              for (final a in accounts) ...[
                AdminContentCard(
                  title: a.agentName.isNotEmpty
                      ? a.agentName
                      : a.agentId,
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
                      _kv(
                        theme,
                        uiTr(context, 'الدولة'),
                        a.countryPath ?? '—',
                      ),
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
                        _m(a.provableCommission),
                      ),
                      _kv(
                        theme,
                        uiTr(context, 'المتبقي'),
                        _m(
                          MoneyAmount(
                            currency: a.provableCommission.code,
                            minorUnits: a.outstandingMinor,
                          ),
                        ),
                      ),
                      if (a.attributedTrips == 0 &&
                          a.completedTrips == 0 &&
                          a.provableCommission.minorUnits == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            uiTr(context, 'لا نشاط مالي مثبت لهذا الوكيل'),
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
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

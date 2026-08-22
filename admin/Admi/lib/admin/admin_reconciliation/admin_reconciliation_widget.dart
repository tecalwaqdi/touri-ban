import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_controls_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminReconciliationWidget extends StatefulWidget {
  const AdminReconciliationWidget({super.key});

  static const String routeName = 'AdminReconciliation';
  static const String routePath = '/adminReconciliation';

  @override
  State<AdminReconciliationWidget> createState() =>
      _AdminReconciliationWidgetState();
}

class _AdminReconciliationWidgetState extends State<AdminReconciliationWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _future = FinanceControlsClient.scanExceptions();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Color _tone(String severity, FlutterFlowTheme theme) {
    switch (severity) {
      case 'critical':
        return theme.error;
      case 'high':
        return Colors.orange.shade800;
      case 'medium':
        return AdminUi.brandTeal;
      default:
        return theme.secondaryText;
    }
  }

  Future<void> _openIncomplete() async {
    final data = await FinanceControlsClient.listIncomplete();
    if (!mounted) return;
    final orders = (data['orders'] as List?) ?? [];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'INCOMPLETE = ${data['count']}',
                  style: FlutterFlowTheme.of(ctx).titleMedium,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final o = Map<String, dynamic>.from(orders[i] as Map);
                    final missing = (o['missingFields'] as List?) ?? [];
                    return ListTile(
                      title: Text('${o['orderId']}'),
                      subtitle: Text(
                        '${o['reason']} · ${o['currency']} · '
                        'driver ${o['driverId'] ?? '—'} · '
                        '${o['paymentMethod']} · ${o['lifecycle']}\n'
                        'missing: ${missing.join(', ')}\n'
                        'blocks settlement: ${o['blocksSettlement']}',
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'Financial Reconciliation'),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data!['items'] as List?) ?? [];
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              Text(
                uiTr(context, 'مركز مراجعة المحاسب — مشاكل فقط'),
                style: theme.headlineSmall,
              ),
              Text(
                uiTr(context, 'Read-only. Orders are not edited from this page.'),
                style: theme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Text(uiTr(context, 'لا توجد استثناءات')),
              for (final raw in items)
                Builder(
                  builder: (context) {
                    final it = Map<String, dynamic>.from(raw as Map);
                    final code = '${it['code']}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(code),
                      subtitle: Text(
                        '${it['severity']} · ${it['count']}'
                        '${it['blocksClose'] == true ? ' · close blocker' : ''}',
                      ),
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: _tone('${it['severity']}', theme),
                      ),
                      onTap: code == 'INCOMPLETE_FINANCIAL_RECORD'
                          ? _openIncomplete
                          : () {
                              final sample = (it['sample'] as List?) ?? [];
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(code),
                                  content: SizedBox(
                                    width: 480,
                                    child: SingleChildScrollView(
                                      child: Text(sample.join('\n')),
                                    ),
                                  ),
                                ),
                              );
                            },
                    );
                  },
                ),
              if (AdminRoleService.canWriteSettlements) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final o = await FinanceControlsClient.detectOrphans();
                    if (!context.mounted) return;
                    final items = (o['items'] as List?) ?? [];
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(uiTr(ctx, 'Orphan Detection')),
                        content: Text(
                          'Report only — no auto-repair.\n'
                          '${items.map((e) => e is Map ? '${e['code']}: ${e['count']}' : e).join('\n')}',
                        ),
                      ),
                    );
                  },
                  child: Text(uiTr(context, 'Orphan report')),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

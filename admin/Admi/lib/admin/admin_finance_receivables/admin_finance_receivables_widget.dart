import 'package:flutter/material.dart';

import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/money_amount.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// FIN-8 — Company receivables / payables (server aggregate, read-only).
class AdminFinanceReceivablesWidget extends StatefulWidget {
  const AdminFinanceReceivablesWidget({super.key});

  static const String routeName = 'AdminFinanceReceivables';
  static const String routePath = '/adminFinanceReceivables';

  @override
  State<AdminFinanceReceivablesWidget> createState() =>
      _AdminFinanceReceivablesWidgetState();
}

class _AdminFinanceReceivablesWidgetState
    extends State<AdminFinanceReceivablesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  Future<Map<String, dynamic>>? _future;

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
      _future = CloudFunctionsClient.aggregateSettlementExposureV2();
    });
  }

  String _m(int minor, String currency) =>
      AdminOrderMoneyDisplay.formatMoneyAmount(
        MoneyAmount(currency: currency, minorUnits: minor),
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'الذمم المالية'),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final raw = snap.data!['byCurrency'];
          final by =
              raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          return ListView(
            padding: AdminUi.pagePadding(context),
            children: [
              AdminPageHeader(
                title: uiTr(context, 'ذمم مستحقة للشركة / على الشركة'),
                subtitle: uiTr(
                  context,
                  'مصدر الخادم — التسويات المقفلة والمدفوعة جزئيًا فقط.',
                ),
              ),
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              for (final e in by.entries) ...[
                AdminContentCard(
                  title: e.key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _row(
                        theme,
                        uiTr(context, 'مستحق للشركة (ذمم مدينة)'),
                        _m(
                          (e.value['receivablesOutstandingMinor'] as num?)
                                  ?.toInt() ??
                              0,
                          e.key,
                        ),
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مستحق على الشركة (ذمم دائنة)'),
                        _m(
                          (e.value['payablesOutstandingMinor'] as num?)
                                  ?.toInt() ??
                              0,
                          e.key,
                        ),
                      ),
                      _row(
                        theme,
                        uiTr(context, 'المحصّل'),
                        _m(
                          (e.value['collectedMinor'] as num?)?.toInt() ?? 0,
                          e.key,
                        ),
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مسدد'),
                        '${e.value['settledCount'] ?? 0}',
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مدفوع جزئيًا'),
                        '${e.value['partiallyPaidCount'] ?? 0}',
                      ),
                      _row(
                        theme,
                        uiTr(context, 'مقفل'),
                        '${e.value['lockedCount'] ?? 0}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (by.isEmpty)
                AdminEmptyState(
                  title: uiTr(context, 'لا توجد تسويات نشطة'),
                  message: uiTr(context, 'لا ذمم مفتوحة بعد'),
                  icon: Icons.account_balance_outlined,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(FlutterFlowTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.bodyMedium)),
          Text(value, style: theme.titleSmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/components/menu2_model.dart';
import '/core/finance/csv_export.dart';
import '/core/finance/finance_controls_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminFinanceReportsWidget extends StatefulWidget {
  const AdminFinanceReportsWidget({super.key});

  static const String routeName = 'AdminFinanceReports';
  static const String routePath = '/adminFinanceReports';

  @override
  State<AdminFinanceReportsWidget> createState() =>
      _AdminFinanceReportsWidgetState();
}

class _AdminFinanceReportsWidgetState extends State<AdminFinanceReportsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  String _type = 'settlement_statement';
  String _currency = '';
  String _driverId = '';
  String _status = '';
  Map<String, dynamic>? _report;
  bool _busy = false;

  static const _types = [
    'driver_statement',
    'settlement_statement',
    'payment_register',
    'receivables',
    'payables',
    'aging',
    'adjustments_register',
    'period_closing',
    'reconciliation_exceptions',
  ];

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final data = await FinanceControlsClient.report({
        'type': _type,
        if (_currency.trim().isNotEmpty) 'currency': _currency.trim().toUpperCase(),
        if (_driverId.trim().isNotEmpty) 'driverId': _driverId.trim(),
        if (_status.trim().isNotEmpty) 'status': _status.trim(),
      });
      setState(() => _report = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdminUserFacingErrors.from(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final rows = (_report?['rows'] as List?) ?? [];
    final cols = (_report?['columns'] as List?) ?? [];
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'التقارير المحاسبية'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(uiTr(context, 'التقارير المحاسبية'), style: theme.headlineSmall),
          Text(
            uiTr(
              context,
              'Internal reports only — not a tax invoice. Copies CSV to clipboard (not a file download). PDF: DEFERRED_PDF (no pdf package).',
            ),
            softWrap: true,
            style: theme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: _type,
            isExpanded: true,
            items: [
              for (final t in _types) DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          TextField(
            decoration: InputDecoration(labelText: uiTr(context, 'العملة')),
            onChanged: (v) => _currency = v,
          ),
          TextField(
            decoration: InputDecoration(labelText: uiTr(context, 'المندوب')),
            onChanged: (v) => _driverId = v,
          ),
          TextField(
            decoration: InputDecoration(labelText: uiTr(context, 'الحالة')),
            onChanged: (v) => _status = v,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: _busy ? null : _run,
              child: Text(uiTr(context, 'تشغيل')),
            ),
          ),
          if (_report != null) ...[
            const SizedBox(height: 12),
            Text(
              'Generated at ${_report!['generatedAt']} · Prepared by ${_report!['preparedBy']}',
              softWrap: true,
              style: theme.labelSmall,
            ),
            Text(
              '${_report!['disclaimer']}',
              softWrap: true,
              style: theme.labelSmall,
            ),
            TextButton(
              onPressed: () async {
                final csv = '${_report!['csv'] ?? ''}';
                await copyFinanceCsv(
                  csv.isEmpty
                      ? financeCsvDocument(
                          preparedBy: currentUserUid,
                          filters: '$_type $_currency $_driverId',
                          currency: _currency.isEmpty ? 'per-row' : _currency,
                          body: rows.join('\n'),
                        )
                      : csv,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(uiTr(context, 'CSV copied'))),
                );
              },
              child: Text(uiTr(context, 'Copy CSV')),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: DataTable(
                      columns: [
                        for (final c in cols) DataColumn(label: Text('$c')),
                      ],
                      rows: [
                        for (final r in rows)
                          DataRow(
                            cells: [
                              for (final c in (r as List))
                                DataCell(
                                  Text('$c', softWrap: false),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

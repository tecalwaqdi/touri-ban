import 'package:flutter/material.dart';

import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/components/menu2_model.dart';
import '/core/finance/finance_controls_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminFinanceAuditWidget extends StatefulWidget {
  const AdminFinanceAuditWidget({super.key});

  static const String routeName = 'AdminFinanceAudit';
  static const String routePath = '/adminFinanceAudit';

  @override
  State<AdminFinanceAuditWidget> createState() =>
      _AdminFinanceAuditWidgetState();
}

class _AdminFinanceAuditWidgetState extends State<AdminFinanceAuditWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  final _code = TextEditingController();
  final _receipt = TextEditingController();
  final _driver = TextEditingController();
  final _actor = TextEditingController();
  final _type = TextEditingController();
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    _code.dispose();
    _receipt.dispose();
    _driver.dispose();
    _actor.dispose();
    _type.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    try {
      final r = await FinanceControlsClient.searchAudit({
        if (_code.text.trim().isNotEmpty) 'settlementCode': _code.text.trim(),
        if (_receipt.text.trim().isNotEmpty) 'paymentReceipt': _receipt.text.trim(),
        if (_driver.text.trim().isNotEmpty) 'driverId': _driver.text.trim(),
        if (_actor.text.trim().isNotEmpty) 'actorUid': _actor.text.trim(),
        if (_type.text.trim().isNotEmpty) 'eventType': _type.text.trim(),
      });
      setState(() => _events = (r['events'] as List?) ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdminUserFacingErrors.from(context, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'بحث التدقيق المالي'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(uiTr(context, 'من فعل ماذا ومتى'), style: theme.headlineSmall),
          TextField(controller: _code, decoration: const InputDecoration(labelText: 'Settlement code')),
          TextField(controller: _receipt, decoration: const InputDecoration(labelText: 'Payment receipt')),
          TextField(controller: _driver, decoration: const InputDecoration(labelText: 'Driver')),
          TextField(controller: _actor, decoration: const InputDecoration(labelText: 'Actor / admin')),
          TextField(controller: _type, decoration: const InputDecoration(labelText: 'Event type')),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _search,
              child: Text(uiTr(context, 'بحث')),
            ),
          ),
          const SizedBox(height: 12),
          for (final raw in _events)
            Builder(
              builder: (context) {
                final e = Map<String, dynamic>.from(raw as Map);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${e['eventType']} · ${e['settlementCode'] ?? e['periodId'] ?? ''}'),
                  subtitle: Text(
                    '${e['timestamp']}\n'
                    'actor ${e['actorUid']} · driver ${e['driverId'] ?? '—'} · '
                    'receipt ${e['paymentReceipt'] ?? '—'}'
                    '${e['selfApproved'] == true ? ' · SELF_APPROVAL' : ''}',
                  ),
                  isThreeLine: true,
                );
              },
            ),
        ],
      ),
    );
  }
}

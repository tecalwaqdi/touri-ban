import 'package:flutter/material.dart';

import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_user_facing_errors.dart';
import '/components/menu2_model.dart';
import '/core/finance/admin_finance_ui_labels.dart';
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
  bool _busy = false;

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
    setState(() => _busy = true);
    try {
      final r = await FinanceControlsClient.searchAudit({
        if (_code.text.trim().isNotEmpty) 'settlementCode': _code.text.trim(),
        if (_receipt.text.trim().isNotEmpty)
          'paymentReceipt': _receipt.text.trim(),
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    _code.clear();
    _receipt.clear();
    _driver.clear();
    _actor.clear();
    _type.clear();
    setState(() => _events = []);
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'بحث التدقيق المالي'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          Text(uiTr(context, 'من فعل ماذا ومتى'), style: theme.headlineSmall),
          Text(
            uiTr(context, 'فلاتر مدمجة — بدون حقول عملاقة.'),
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: wide ? 200 : double.infinity,
                child: TextField(
                  controller: _code,
                  decoration: _dec(uiTr(context, 'رقم التسوية')),
                ),
              ),
              SizedBox(
                width: wide ? 200 : double.infinity,
                child: TextField(
                  controller: _receipt,
                  decoration: _dec(uiTr(context, 'مرجع الدفعة')),
                ),
              ),
              SizedBox(
                width: wide ? 180 : double.infinity,
                child: TextField(
                  controller: _driver,
                  decoration: _dec(uiTr(context, 'المندوب')),
                ),
              ),
              SizedBox(
                width: wide ? 180 : double.infinity,
                child: TextField(
                  controller: _actor,
                  decoration: _dec(uiTr(context, 'المنفذ')),
                ),
              ),
              SizedBox(
                width: wide ? 180 : double.infinity,
                child: TextField(
                  controller: _type,
                  decoration: _dec(uiTr(context, 'نوع العملية')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : _search,
                child: Text(uiTr(context, 'بحث')),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _reset,
                child: Text(AdminFinanceUiLabels.resetActionAr()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_events.isEmpty)
            Text(
              uiTr(context, 'لا توجد نتائج — اضبط الفلاتر ثم ابحث.'),
              style: theme.bodyMedium,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(uiTr(context, 'التاريخ والوقت'))),
                  DataColumn(label: Text(uiTr(context, 'المنفذ'))),
                  DataColumn(label: Text(uiTr(context, 'العملية'))),
                  DataColumn(label: Text(uiTr(context, 'المرجع'))),
                  DataColumn(label: Text(uiTr(context, 'النتيجة'))),
                ],
                rows: [
                  for (final raw in _events)
                    () {
                      final e = Map<String, dynamic>.from(raw as Map);
                      final self = e['selfApproved'] == true;
                      return DataRow(
                        cells: [
                          DataCell(Text('${e['timestamp'] ?? '—'}')),
                          DataCell(Text('${e['actorUid'] ?? '—'}')),
                          DataCell(Text('${e['eventType'] ?? '—'}')),
                          DataCell(Text(
                            '${e['settlementCode'] ?? e['periodId'] ?? e['paymentReceipt'] ?? '—'}',
                          )),
                          DataCell(Text(
                            self
                                ? uiTr(context, 'اعتماد ذاتي')
                                : uiTr(context, 'مسجّل'),
                          )),
                        ],
                      );
                    }(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

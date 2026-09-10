import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/core/admin_error_messages.dart';
import '/core/admin_currency.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_controls_client.dart';
import '/core/finance/finance_runtime_gate.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Adjustments + opening balances for finance staff / SuperAdmin.
class AdminFinanceAdjustmentsWidget extends StatefulWidget {
  const AdminFinanceAdjustmentsWidget({super.key});

  static const String routeName = 'AdminFinanceAdjustments';
  static const String routePath = '/adminFinanceAdjustments';

  @override
  State<AdminFinanceAdjustmentsWidget> createState() =>
      _AdminFinanceAdjustmentsWidgetState();
}

class _AdminFinanceAdjustmentsWidgetState
    extends State<AdminFinanceAdjustmentsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  bool _busy = false;

  static const _reasons = <String>[
    'correction',
    'manual_credit',
    'manual_debit',
    'rounding',
    'legacy_balance',
    'opening_balance',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    _ensureGate();
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  Future<void> _ensureGate() async {
    if (FinanceRuntimeGate.canAttemptFinanceWrites) return;
    try {
      await FinanceControlsClient.accountantHome();
      FinanceRuntimeGate.markAuthoritativeBackendData();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _createDialog({required bool openingBalance}) async {
    if (!AdminRoleService.canWriteSettlements) return;
    final driverCtrl = TextEditingController();
    final countryCtrl = TextEditingController(text: 'countries/');
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var currency = 'SAR';
    var direction = 'DRIVER_TO_COMPANY';
    var reason = openingBalance ? 'opening_balance' : 'correction';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            uiTr(
              ctx,
              openingBalance ? 'رصيد افتتاحي' : 'مسودة تعديل',
            ),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: driverCtrl,
                    decoration: InputDecoration(
                      labelText: uiTr(ctx, 'معرّف المندوب (اختياري)'),
                    ),
                  ),
                  TextField(
                    controller: countryCtrl,
                    decoration: InputDecoration(
                      labelText: uiTr(ctx, 'مسار الدولة'),
                    ),
                  ),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: uiTr(ctx, 'المبلغ (رئيسي)'),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: currency,
                    items: const [
                      DropdownMenuItem(value: 'SAR', child: Text('SAR')),
                      DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                      DropdownMenuItem(value: 'XOF', child: Text('XOF')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: (v) => setLocal(() => currency = v ?? currency),
                    decoration: InputDecoration(labelText: uiTr(ctx, 'العملة')),
                  ),
                  DropdownButtonFormField<String>(
                    value: direction,
                    items: const [
                      DropdownMenuItem(
                        value: 'DRIVER_TO_COMPANY',
                        child: Text('DRIVER_TO_COMPANY'),
                      ),
                      DropdownMenuItem(
                        value: 'COMPANY_TO_DRIVER',
                        child: Text('COMPANY_TO_DRIVER'),
                      ),
                    ],
                    onChanged: (v) =>
                        setLocal(() => direction = v ?? direction),
                    decoration:
                        InputDecoration(labelText: uiTr(ctx, 'الاتجاه')),
                  ),
                  if (!openingBalance)
                    DropdownButtonFormField<String>(
                      value: reason,
                      items: [
                        for (final r in _reasons)
                          DropdownMenuItem(value: r, child: Text(r)),
                      ],
                      onChanged: (v) => setLocal(() => reason = v ?? reason),
                      decoration:
                          InputDecoration(labelText: uiTr(ctx, 'سبب التعديل')),
                    ),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration:
                        InputDecoration(labelText: uiTr(ctx, 'ملاحظات')),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(uiTr(ctx, 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(uiTr(ctx, 'حفظ')),
            ),
          ],
        ),
      ),
    );

    final major = double.tryParse(amountCtrl.text.trim());
    final driverId = driverCtrl.text.trim();
    final countryRef = countryCtrl.text.trim();
    final notes = notesCtrl.text.trim();
    driverCtrl.dispose();
    countryCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    if (ok != true || !mounted) return;
    if (major == null || major <= 0 || countryRef.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'المبلغ والدولة مطلوبان'))),
      );
      return;
    }
    final amountMinor = (major * 100).round();

    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{
        'driverId': driverId,
        'countryRef': countryRef,
        'currency': currency,
        'amountMinor': amountMinor,
        'direction': direction,
        if (notes.isNotEmpty) 'notes': notes,
        if (openingBalance) 'reference': 'OB-${DateTime.now().millisecondsSinceEpoch}',
        if (!openingBalance) 'reasonCode': reason,
      };
      final result = openingBalance
          ? await FinanceControlsClient.createOpeningBalance(payload)
          : await FinanceControlsClient.createAdjustment({
              ...payload,
              'reasonCode': reason,
            });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${uiTr(context, 'تم الإنشاء')}: ${result['adjustmentId'] ?? ''}',
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminFriendlyError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _busy = true);
    try {
      await FinanceControlsClient.approveAdjustment(id);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminFriendlyError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reverse(String id) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(ctx, 'عكس التعديل')),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(labelText: uiTr(ctx, 'السبب')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(uiTr(ctx, 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(uiTr(ctx, 'عكس')),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (ok != true || reason.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      await FinanceControlsClient.reverseAdjustment(
        adjustmentId: id,
        reason: reason,
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminFriendlyError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = AdminRoleService.canWriteSettlements;

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'التعديلات المالية'),
      child: ListView(
        padding: AdminUi.pagePadding(context),
        children: [
          AdminPageHeader(
            title: uiTr(context, 'التعديلات والرصيد الافتتاحي'),
            subtitle: uiTr(
              context,
              'قيود محاسبية فقط — لا حركة محفظة. الموافقة تتطلب maker-checker عند تفعيل الأعلام.',
            ),
          ),
          if (canWrite)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AdminPrimaryButton(
                  label: uiTr(context, 'مسودة تعديل'),
                  icon: Icons.edit_note,
                  isLoading: _busy,
                  onPressed: _busy ? null : () => _createDialog(openingBalance: false),
                ),
                AdminPrimaryButton(
                  label: uiTr(context, 'رصيد افتتاحي'),
                  outlined: true,
                  onPressed: _busy ? null : () => _createDialog(openingBalance: true),
                ),
              ],
            ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('financial_adjustments')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text(adminFriendlyError(context, snap.error!));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return AdminEmptyState(
                  title: uiTr(context, 'لا توجد تعديلات'),
                  message: uiTr(context, 'أنشئ مسودة تعديل أو رصيد افتتاحي.'),
                  icon: Icons.tune,
                );
              }
              return Column(
                children: [
                  for (final d in docs)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${d.data()['reasonCode'] ?? '—'} · ${d.data()['status']}',
                        ),
                        subtitle: Text(
                          '${d.data()['currency']} · '
                          '${AdminOrderMoneyDisplay.formatMajor(((d.data()['amountMinor'] as num?)?.toInt() ?? 0) / 100.0, symbol: AdminCurrency.symbolByCode['${d.data()['currency']}'] ?? '${d.data()['currency']}')} · '
                          '${d.data()['direction']} · '
                          '${d.data()['driverId'] ?? '—'}',
                        ),
                        trailing: canWrite
                            ? Wrap(
                                children: [
                                  if (d.data()['status'] == 'draft')
                                    IconButton(
                                      tooltip: uiTr(context, 'موافقة'),
                                      icon: const Icon(Icons.check_circle_outline),
                                      onPressed: _busy
                                          ? null
                                          : () => _approve(d.id),
                                    ),
                                  if (d.data()['status'] == 'approved')
                                    IconButton(
                                      tooltip: uiTr(context, 'عكس'),
                                      icon: const Icon(Icons.undo),
                                      onPressed: _busy
                                          ? null
                                          : () => _reverse(d.id),
                                    ),
                                ],
                              )
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

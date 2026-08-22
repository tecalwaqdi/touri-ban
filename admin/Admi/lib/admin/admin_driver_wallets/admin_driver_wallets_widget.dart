import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_layout_widget.dart';
import '/components/menu2_model.dart';
import '/core/admin_user_facing_errors.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Admin view: driver wallets, top-ups, company payments, ledger.
///
/// LEGACY wallet tool — NOT settlement. Adjust is SuperAdmin-only.
class AdminDriverWalletsWidget extends StatefulWidget {
  const AdminDriverWalletsWidget({super.key});

  static const String routeName = 'AdminDriverWallets';
  static const String routePath = '/adminDriverWallets';

  @override
  State<AdminDriverWalletsWidget> createState() =>
      _AdminDriverWalletsWidgetState();
}

class _AdminDriverWalletsWidgetState extends State<AdminDriverWalletsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;
  final _df = DateFormat('yyyy-MM-dd HH:mm');
  String _tab = 'wallets';
  bool _adjusting = false;

  /// LEGACY wallet adjust — SuperAdmin only (not Finance / settlement).
  bool get _canAdjust => AdminRoleService.isSuperAdmin;

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

  Future<void> _adjustWallet({
    required String driverId,
    required String currency,
    required double currentBalance,
  }) async {
    if (!_canAdjust || _adjusting) return;

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formOk = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(context, 'تعديل رصيد المحفظة')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${uiTr(context, 'المندوب')}: $driverId\n'
              '${uiTr(context, 'الرصيد الحالي')}: '
              '${currentBalance.toStringAsFixed(2)} $currency',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: uiTr(context, 'المبلغ (+ شحن / − خصم)'),
                hintText: '100 أو -50',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: uiTr(context, 'ملاحظة التعديل'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(uiTr(context, 'متابعة')),
          ),
        ],
      ),
    );

    if (formOk != true || !mounted) {
      amountCtrl.dispose();
      noteCtrl.dispose();
      return;
    }

    final amount = double.tryParse(amountCtrl.text.trim());
    final note = noteCtrl.text.trim();
    amountCtrl.dispose();
    noteCtrl.dispose();

    if (amount == null || amount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'أدخل مبلغاً غير صفري'))),
      );
      return;
    }

    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'تأكيد تعديل المحفظة'),
      whatHappens: uiTr(
        context,
        'LEGACY wallet adjust — NOT a settlement. Changes driver wallet balance directly.',
      ),
      subject: driverId,
      impact:
          '${uiTr(context, 'الرصيد الحالي')}: ${currentBalance.toStringAsFixed(2)} $currency',
      confirmLabel: uiTr(context, 'تأكيد التعديل'),
      destructive: amount < 0,
      irreversible: true,
      currency: currency,
      amount: '${amount.toStringAsFixed(2)} $currency',
      direction: amount >= 0 ? 'credit' : 'debit',
      reference: note.isEmpty ? driverId : note,
    );
    if (!confirmed || !mounted) return;

    setState(() => _adjusting = true);
    try {
      final result = await CloudFunctionsClient.adminAdjustDriverWallet(
        driverId: driverId,
        amount: amount,
        note: note,
        currency: currency,
      );
      if (!mounted) return;
      final after = (result['balanceAfter'] as num?)?.toDouble();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            after == null
                ? uiTr(context, 'تم تعديل الرصيد')
                : '${uiTr(context, 'تم تعديل الرصيد')}: ${after.toStringAsFixed(2)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(
        context,
        '${uiTr(context, 'تعذر تعديل الرصيد')}: ${AdminUserFacingErrors.from(context, e)}',
      );
    } finally {
      if (mounted) setState(() => _adjusting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'محافظ المندوبين'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.warning.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      uiTr(
                        context,
                        'LEGACY wallet tool — NOT settlement. Only SuperAdmin can adjust.',
                      ),
                      style: theme.bodySmall.override(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_canAdjust)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                uiTr(context, 'Wallet adjust is disabled for your role.'),
                style: theme.bodySmall.override(
                  fontFamily: 'Cairo',
                  color: theme.secondaryText,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(uiTr(context, 'الأرصدة')),
                  selected: _tab == 'wallets',
                  onSelected: (_) => setState(() => _tab = 'wallets'),
                ),
                ChoiceChip(
                  label: Text(uiTr(context, 'الشحن')),
                  selected: _tab == 'topups',
                  onSelected: (_) => setState(() => _tab = 'topups'),
                ),
                ChoiceChip(
                  label: Text(uiTr(context, 'دفعات الشركة')),
                  selected: _tab == 'company',
                  onSelected: (_) => setState(() => _tab = 'company'),
                ),
                ChoiceChip(
                  label: Text(uiTr(context, 'السجل')),
                  selected: _tab == 'ledger',
                  onSelected: (_) => setState(() => _tab = 'ledger'),
                ),
              ],
            ),
          ),
          if (_adjusting) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(FlutterFlowTheme theme) {
    switch (_tab) {
      case 'topups':
        return _txStream(
          query: FirebaseFirestore.instance
              .collection('transactions')
              .where('type', whereIn: ['top_up', 'credit'])
              .orderBy('createdAt', descending: true)
              .limit(100),
        );
      case 'company':
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('company_payments')
              .orderBy('createdAt', descending: true)
              .limit(100)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Text(uiTr(context, 'لا توجد دفعات')));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i].data();
                return ListTile(
                  title: Text(
                    '${uiTr(context, 'مندوب')}: ${d['driverId'] ?? d['userRef'] ?? '—'}',
                  ),
                  subtitle: Text(
                    '${_dfFmt(d['createdAt'] ?? d['paidAt'])} · ${d['status'] ?? ''}',
                  ),
                  trailing: Text(
                    '${(d['amountAbs'] ?? d['amount'] ?? 0)} ر.س',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          },
        );
      case 'ledger':
        return _txStream(
          query: FirebaseFirestore.instance
              .collection('transactions')
              .orderBy('createdAt', descending: true)
              .limit(150),
        );
      case 'wallets':
      default:
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance.collection('wallets').limit(200).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs.toList()
              ..sort((a, b) {
                final ba =
                    (a.data()['currentBalance'] as num?)?.toDouble() ?? 0;
                final bb =
                    (b.data()['currentBalance'] as num?)?.toDouble() ?? 0;
                return bb.compareTo(ba);
              });
            if (docs.isEmpty) {
              return Center(child: Text(uiTr(context, 'لا توجد محافظ')));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i].data();
                final bal = (d['currentBalance'] as num?)?.toDouble() ?? 0;
                final currency = (d['currency'] ?? 'SAR').toString();
                final uid = (d['userRef'] is DocumentReference)
                    ? (d['userRef'] as DocumentReference).id
                    : (d['driverId'] ?? docs[i].id).toString();
                return ListTile(
                  title: Text('${uiTr(context, 'مندوب')}: $uid'),
                  subtitle: Text(
                    '${uiTr(context, 'عملة')}: $currency · '
                    '${bal >= 200 ? uiTr(context, 'مؤهل نقدي') : uiTr(context, 'غير مؤهل نقدي')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${bal.toStringAsFixed(2)} $currency',
                        style: theme.bodyMedium.override(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: bal >= 200 ? Colors.green.shade700 : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: _canAdjust
                            ? uiTr(context, 'تعديل رصيد المحفظة')
                            : uiTr(context, 'Wallet adjust disabled'),
                        onPressed: (!_canAdjust || _adjusting)
                            ? null
                            : () => _adjustWallet(
                                  driverId: uid,
                                  currency: currency,
                                  currentBalance: bal,
                                ),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
    }
  }

  Widget _txStream({
    required Query<Map<String, dynamic>> query,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text(uiTr(context, 'لا توجد عمليات')));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final uid = (d['userRef'] is DocumentReference)
                ? (d['userRef'] as DocumentReference).id
                : (d['driverId'] ?? '—').toString();
            return ListTile(
              title: Text('${d['type'] ?? 'tx'} · $uid'),
              subtitle: Text(
                '${_dfFmt(d['createdAt'])} · '
                '${uiTr(context, 'قبل')} ${(d['balanceBefore'] ?? '—')} → '
                '${uiTr(context, 'بعد')} ${(d['balanceAfter'] ?? '—')}',
              ),
              trailing: Text('${d['amount'] ?? 0}'),
            );
          },
        );
      },
    );
  }

  String _dfFmt(dynamic v) {
    if (v is Timestamp) return _df.format(v.toDate());
    if (v is DateTime) return _df.format(v);
    return '—';
  }
}

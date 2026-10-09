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
import '/core/finance/admin_money_presentation.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Admin view: driver wallets, top-ups, company payments, ledger.
///
/// LEGACY wallet tool — NOT settlement. Adjust is SuperAdmin-only.
/// Wallet balance is NOT trip earnings.
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
  final Map<String, String> _driverLabels = {};
  final Set<String> _namePending = {};

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

  Future<void> _resolveDriverLabels(Iterable<String> uids) async {
    final missing = uids
        .where(
          (id) =>
              id.isNotEmpty &&
              !_driverLabels.containsKey(id) &&
              !_namePending.contains(id),
        )
        .toList();
    if (missing.isEmpty) return;
    _namePending.addAll(missing);
    for (var i = 0; i < missing.length; i += 10) {
      final end = i + 10 > missing.length ? missing.length : i + 10;
      final chunk = missing.sublist(i, end);
      try {
        final snap = await FirebaseFirestore.instance
            .collection('user')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        if (!mounted) return;
        setState(() {
          for (final doc in snap.docs) {
            final data = doc.data();
            final name = (data['display_name'] ?? '').toString().trim();
            final phone = (data['phone_number'] ?? '').toString().trim();
            _driverLabels[doc.id] =
                name.isNotEmpty ? name : phone;
          }
          for (final id in chunk) {
            _driverLabels.putIfAbsent(id, () => '');
            _namePending.remove(id);
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          for (final id in chunk) {
            _driverLabels.putIfAbsent(id, () => '');
            _namePending.remove(id);
          }
        });
      }
    }
  }

  String _driverTitle(String uid) {
    final label = _driverLabels[uid]?.trim() ?? '';
    if (label.isNotEmpty) return label;
    return uiTr(context, 'مندوب');
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
              '${_driverTitle(driverId)}\n'
              '${uiTr(context, 'رصيد المحفظة')}: '
              '${AdminOrderMoneyDisplay.formatMajor(currentBalance, symbol: currency == 'SAR' ? 'ر.س' : currency)}',
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
                hintText: uiTr(context, '100 أو -50'),
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
        'يعدّل رصيد المحفظة مباشرة. هذا ليس تسوية رحلات ولا أرباح المندوب.',
      ),
      subject: _driverTitle(driverId),
      impact:
          '${uiTr(context, 'الرصيد الحالي')}: ${AdminOrderMoneyDisplay.formatMajor(currentBalance, symbol: currency == 'SAR' ? 'ر.س' : currency)}',
      confirmLabel: uiTr(context, 'تأكيد التعديل'),
      destructive: amount < 0,
      irreversible: true,
      currency: currency,
      amount: AdminOrderMoneyDisplay.formatMajor(amount, symbol: currency == 'SAR' ? 'ر.س' : currency),
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
                : '${uiTr(context, 'تم تعديل الرصيد')}: ${AdminOrderMoneyDisplay.formatMajor(after, symbol: currency == 'SAR' ? 'ر.س' : currency)}',
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
                        'هذا رصيد المحفظة، وليس أرباح الرحلات. التعديل للمسؤول الأعلى فقط.',
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
          if (!_canAdjust && !AdminRoleService.isRoleResolving)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                uiTr(context, 'تعديل المحفظة غير متاح لدورك.'),
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
            _resolveDriverLabels([
              for (final doc in docs)
                (doc.data()['userRef'] is DocumentReference)
                    ? (doc.data()['userRef'] as DocumentReference).id
                    : (doc.data()['driverId'] ?? '').toString(),
            ]);
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i].data();
                final uid = (d['userRef'] is DocumentReference)
                    ? (d['userRef'] as DocumentReference).id
                    : (d['driverId'] ?? '').toString();
                final amount = d['amountAbs'] ?? d['amount'];
                return ListTile(
                  title: Text(_driverTitle(uid)),
                  subtitle: Text(_dfFmt(d['createdAt'] ?? d['paidAt'])),
                  trailing: Text(
                    amount is num
                        ? AdminOrderMoneyDisplay.formatMajor(
                            amount.toDouble(),
                            symbol: 'ر.س',
                          )
                        : 'غير متوفر',
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AdminUserFacingErrors.from(context, snap.error!),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
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
            final uids = <String>[
              for (final doc in docs) _walletUid(doc),
            ];
            _resolveDriverLabels(uids);
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i].data();
                final bal = (d['currentBalance'] as num?)?.toDouble() ?? 0;
                final currency = (d['currency'] ?? 'SAR').toString();
                final uid = _walletUid(docs[i]);
                final symbol = currency == 'SAR' ? 'ر.س' : currency;
                return ListTile(
                  title: Text(_driverTitle(uid)),
                  subtitle: Text(
                    bal >= 200
                        ? uiTr(context, 'يمكنه استلام النقد')
                        : uiTr(context, 'رصيد المحفظة'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AdminOrderMoneyDisplay.formatMajor(bal, symbol: symbol),
                        style: theme.bodyMedium.override(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: bal < 0
                              ? Colors.red
                              : theme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: _canAdjust
                            ? uiTr(context, 'تعديل رصيد المحفظة')
                            : uiTr(context, 'تعديل المحفظة غير متاح لدورك.'),
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AdminUserFacingErrors.from(context, snap.error!),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text(uiTr(context, 'لا توجد عمليات')));
        }
        _resolveDriverLabels([
          for (final doc in docs)
            (doc.data()['userRef'] is DocumentReference)
                ? (doc.data()['userRef'] as DocumentReference).id
                : (doc.data()['driverId'] ?? '').toString(),
        ]);
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final uid = (d['userRef'] is DocumentReference)
                ? (d['userRef'] as DocumentReference).id
                : (d['driverId'] ?? '').toString();
            final before = d['balanceBefore'];
            final after = d['balanceAfter'];
            final amount = d['amount'];
            return ListTile(
              title: Text(
                '${_txTypeAr('${d['type'] ?? ''}')} · ${_driverTitle(uid)}',
              ),
              subtitle: Text(
                '${_dfFmt(d['createdAt'])} · '
                '${uiTr(context, 'قبل')} ${before ?? 'غير متوفر'} · '
                '${uiTr(context, 'بعد')} ${after ?? 'غير متوفر'}',
              ),
              trailing: Text(
                amount == null ? 'غير متوفر' : '$amount',
              ),
            );
          },
        );
      },
    );
  }

  String _walletUid(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d['userRef'] is DocumentReference) {
      return (d['userRef'] as DocumentReference).id;
    }
    final driverId = (d['driverId'] ?? '').toString();
    if (driverId.isNotEmpty) return driverId;
    return doc.id;
  }

  String _txTypeAr(String raw) {
    switch (raw) {
      case 'top_up':
      case 'credit':
        return uiTr(context, 'شحن');
      case 'debit':
        return uiTr(context, 'خصم');
      case 'admin_adjust':
      case 'wallet_adjust':
        return uiTr(context, 'تعديل يدوي');
      default:
        return uiTr(context, 'حركة محفظة');
    }
  }

  String _dfFmt(dynamic v) {
    if (v is Timestamp) return _df.format(v.toDate());
    if (v is DateTime) return _df.format(v);
    return 'غير متوفر';
  }
}

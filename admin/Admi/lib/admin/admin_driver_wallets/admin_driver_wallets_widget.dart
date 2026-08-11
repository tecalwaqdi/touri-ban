import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/components/admin_layout_widget.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Admin view: driver wallets, top-ups, company payments, ledger.
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: 'محافظ المندوبين',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('الأرصدة'),
                  selected: _tab == 'wallets',
                  onSelected: (_) => setState(() => _tab = 'wallets'),
                ),
                ChoiceChip(
                  label: const Text('الشحن'),
                  selected: _tab == 'topups',
                  onSelected: (_) => setState(() => _tab = 'topups'),
                ),
                ChoiceChip(
                  label: const Text('دفعات الشركة'),
                  selected: _tab == 'company',
                  onSelected: (_) => setState(() => _tab = 'company'),
                ),
                ChoiceChip(
                  label: const Text('Ledger'),
                  selected: _tab == 'ledger',
                  onSelected: (_) => setState(() => _tab = 'ledger'),
                ),
              ],
            ),
          ),
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
              return const Center(child: Text('لا توجد دفعات'));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i].data();
                return ListTile(
                  title: Text(
                    'مندوب: ${d['driverId'] ?? d['userRef'] ?? '—'}',
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
              return const Center(child: Text('لا توجد محافظ'));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i].data();
                final bal = (d['currentBalance'] as num?)?.toDouble() ?? 0;
                final uid = (d['userRef'] is DocumentReference)
                    ? (d['userRef'] as DocumentReference).id
                    : (d['driverId'] ?? docs[i].id).toString();
                return ListTile(
                  title: Text('مندوب: $uid'),
                  subtitle: Text(
                    'عملة: ${d['currency'] ?? 'SAR'} · ${bal >= 200 ? 'مؤهل نقدي' : 'غير مؤهل نقدي'}',
                  ),
                  trailing: Text(
                    '${bal.toStringAsFixed(2)} ر.س',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: bal >= 200 ? Colors.green.shade700 : Colors.red,
                    ),
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
          return const Center(child: Text('لا توجد عمليات'));
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
                '${_dfFmt(d['createdAt'])} · قبل ${(d['balanceBefore'] ?? '—')} → بعد ${(d['balanceAfter'] ?? '—')}',
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

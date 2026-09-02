import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/components/admin_enterprise_kit.dart';
import '/components/admin_ui.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/financial_state_labels.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-only legacy [company_payments] — isolated from V2 trip KPIs.
class AdminLegacyFinancePanel extends StatelessWidget {
  const AdminLegacyFinancePanel({super.key, this.limit = 50});

  final int limit;

  @override
  Widget build(BuildContext context) {
    return AdminContentCard(
      title: uiTr(context, 'سجل مالي قديم / غير مخصص للرحلات'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminStatusBadge(
            label: uiTr(
              context,
              'هذه القيود ليست جزءًا من دفتر الرحلات V2 ما لم تُربط بتسوية معتمدة',
            ),
            tone: AdminBadgeTone.warning,
          ),
          const SizedBox(height: 10),
          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('company_payments')
                .orderBy('createdAt', descending: true)
                .limit(limit)
                .get(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text(
                  uiTr(context, 'تعذر تحميل السجل القديم'),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return AdminEmptyState(
                  title: uiTr(context, 'لا توجد قيود قديمة'),
                  message: '',
                  icon: Icons.history_rounded,
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(uiTr(context, 'التاريخ'))),
                    DataColumn(label: Text(uiTr(context, 'النوع'))),
                    DataColumn(label: Text(uiTr(context, 'المبلغ'))),
                    DataColumn(label: Text(uiTr(context, 'الطرف'))),
                    DataColumn(label: Text(uiTr(context, 'ملاحظة'))),
                  ],
                  rows: [
                    for (final doc in docs)
                      DataRow(cells: [
                        DataCell(Text(_date(doc.data()['createdAt']))),
                        DataCell(Text(
                          FinancialStateLabels.legacyLedgerTypeAr(
                            (doc.data()['type'] ?? doc.data()['kind'] ?? '')
                                .toString(),
                          ),
                        )),
                        DataCell(Text(_amount(doc.data()))),
                        DataCell(Text(
                          _party(doc.data()),
                          style: const TextStyle(fontFamily: 'monospace'),
                        )),
                        DataCell(Text(
                          (doc.data()['note'] ??
                                  doc.data()['description'] ??
                                  '—')
                              .toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ]),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _date(dynamic ts) {
    if (ts is Timestamp) {
      return ts.toDate().toIso8601String().substring(0, 10);
    }
    return '—';
  }

  String _amount(Map<String, dynamic> d) {
    final amt = (d['amount'] as num?)?.toDouble();
    if (amt == null) return '—';
    return AdminOrderMoneyDisplay.formatMajor(amt, symbol: 'ر.س');
  }

  String _party(Map<String, dynamic> d) {
    final ref = d['driverRef'] ?? d['userRef'] ?? d['agentRef'];
    if (ref is DocumentReference) return ref.id;
    return (d['driverId'] ?? d['partyId'] ?? '—').toString();
  }
}

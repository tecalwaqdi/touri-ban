import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/admin_driver_status_l10n.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-only review history from `admin_audit_log` (newest first).
class AdminDriverReviewHistoryPanel extends StatelessWidget {
  const AdminDriverReviewHistoryPanel({super.key, required this.driverId});

  final String driverId;

  static const _actions = <String>{
    'DRIVER_APPLICATION_SUBMITTED',
    'DRIVER_APPLICATION_RESUBMITTED',
    'DRIVER_APPLICATION_APPROVED',
    'DRIVER_APPLICATION_OVERRIDE_APPROVED',
    'DRIVER_APPLICATION_REJECTED',
    'DRIVER_CHANGES_REQUESTED',
    'DRIVER_SUSPENDED',
    'DRIVER_REACTIVATED',
  };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Semantics(
      identifier: 'qa-driver-review-history',
      label: 'qa-driver-review-history',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('admin_audit_log')
                .where('driverId', isEqualTo: driverId)
                .orderBy('createdAt', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text(uiTr(context, 'تعذر تحميل السجل'));
              }
              if (!snap.hasData) {
                return const LinearProgressIndicator(minHeight: 2);
              }
              final docs = snap.data!.docs.where((d) {
                final a = (d.data()['action'] ?? '').toString();
                return _actions.contains(a);
              }).toList();
              if (docs.isEmpty) {
                return Text(
                  uiTr(context, 'لا أحداث مراجعة بعد'),
                  style: theme.labelMedium,
                );
              }
              return Column(
                children: [
                  for (final d in docs) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AdminDriverStatusL10n.auditAction(
                          context,
                          '${d.data()['action']}',
                        ),
                      ),
                      subtitle: Text(
                        [
                              AdminDriverStatusL10n.statusTransition(
                                context,
                                oldStatus: d.data()['oldStatus'],
                                newStatus: d.data()['newStatus'],
                              ),
                              if ((d.data()['reason'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                '${d.data()['reason']}',
                            ]
                            .where((e) => e.toString().trim().isNotEmpty)
                            .join(' · '),
                        softWrap: true,
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

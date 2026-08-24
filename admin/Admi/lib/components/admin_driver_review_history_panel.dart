import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Read-only review history from `admin_audit_log` (newest first).
class AdminDriverReviewHistoryPanel extends StatelessWidget {
  const AdminDriverReviewHistoryPanel({
    super.key,
    required this.driverId,
  });

  final String driverId;

  static const _actions = <String>{
    'DRIVER_APPLICATION_SUBMITTED',
    'DRIVER_APPLICATION_RESUBMITTED',
    'DRIVER_APPLICATION_APPROVED',
    'DRIVER_APPLICATION_REJECTED',
    'DRIVER_CHANGES_REQUESTED',
    'DRIVER_SUSPENDED',
    'DRIVER_REACTIVATED',
  };

  String _label(BuildContext context, String action) {
    switch (action) {
      case 'DRIVER_APPLICATION_SUBMITTED':
        return uiTr(context, 'Submitted');
      case 'DRIVER_APPLICATION_RESUBMITTED':
        return uiTr(context, 'Resubmitted');
      case 'DRIVER_APPLICATION_APPROVED':
        return uiTr(context, 'Approved');
      case 'DRIVER_APPLICATION_REJECTED':
        return uiTr(context, 'Rejected');
      case 'DRIVER_CHANGES_REQUESTED':
        return uiTr(context, 'Changes requested');
      case 'DRIVER_SUSPENDED':
        return uiTr(context, 'Suspended');
      case 'DRIVER_REACTIVATED':
        return uiTr(context, 'Reactivated');
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Semantics(
      identifier: 'qa-driver-review-history',
      label: 'qa-driver-review-history',
      child: AdminContentCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            uiTr(context, 'سجل المراجعة'),
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w800,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(height: 8),
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
                      title: Text(_label(context, '${d.data()['action']}')),
                      subtitle: Text(
                        [
                          if (d.data()['oldStatus'] != null)
                            '${d.data()['oldStatus']} → ${d.data()['newStatus']}',
                          if ((d.data()['reason'] ?? '').toString().isNotEmpty)
                            '${d.data()['reason']}',
                          if (d.data()['metadata'] is Map &&
                              (d.data()['metadata'] as Map)['reviewVersion'] !=
                                  null)
                            'v${(d.data()['metadata'] as Map)['reviewVersion']}',
                        ].where((e) => e.toString().trim().isNotEmpty).join(' · '),
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
    ),
    );
  }
}

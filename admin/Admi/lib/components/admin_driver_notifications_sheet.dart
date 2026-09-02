import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/driver_admin_stats_loader.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Persistent admin notifications for driver registration reviews.
class AdminDriverNotificationsSheet extends StatelessWidget {
  const AdminDriverNotificationsSheet({super.key});

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AdminDriverNotificationsSheet(),
    );
  }

  Query<Map<String, dynamic>> _query() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('admin_panel_notifications')
        .orderBy('createdAt', descending: true)
        .limit(40);
    if (AdminRoleService.isCountryAgent &&
        AdminRoleService.scopedCountryRef != null) {
      q = q.where(
        'countryRef',
        isEqualTo: AdminRoleService.scopedCountryRef,
      );
    }
    return q;
  }

  Future<void> _openDriver(BuildContext context, String driverId) async {
    final ref = FirebaseFirestore.instance.collection('user').doc(driverId);
    final snap = await ref.get();
    if (!context.mounted) return;
    if (!snap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'السجل غير موجود'))),
      );
      return;
    }
    Navigator.pop(context);
    context.pushNamed(
      DriverActivationWidget.routeName,
      queryParameters: {
        'dre': serializeParam(ref, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  Future<void> _markRead(DocumentReference ref) async {
    try {
      await ref.update({
        'unread': false,
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      AdminUi.logDiagnostic('notification_sheet_mark_read', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                uiTr(context, 'إشعارات مراجعة المناديب'),
                style: theme.titleMedium.override(
                  fontFamily: theme.titleMediumFamily,
                  fontWeight: FontWeight.w800,
                  useGoogleFonts: !theme.titleMediumIsCustom,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _query().snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text(uiTr(context, 'تعذر تحميل الإشعارات')),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(uiTr(context, 'لا توجد إشعارات')),
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final d = doc.data();
                      final type = (d['type'] ?? '').toString();
                      final driverId = (d['driverId'] ?? '').toString();
                      final unread = d['unread'] == true;
                      final title = type.contains('resubmit')
                          ? uiTr(context, 'أعاد المندوب إرسال طلبه للمراجعة')
                          : uiTr(context, 'طلب مندوب جديد بانتظار المراجعة');
                      return ListTile(
                        leading: Icon(
                          unread
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                          color: unread ? theme.primary : theme.secondaryText,
                        ),
                        title: Text(title),
                        subtitle: Text(
                          [
                            if (driverId.isNotEmpty) 'ID: $driverId',
                            if (d['reviewAttemptCount'] != null)
                              'attempt: ${d['reviewAttemptCount']}',
                          ].join(' · '),
                        ),
                        onTap: () async {
                          await _markRead(doc.reference);
                          if (driverId.isEmpty) return;
                          await _openDriver(context, driverId);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge count from authoritative aggregate (pending_review), not list length.
class AdminPendingDriverReviewBadge extends StatefulWidget {
  const AdminPendingDriverReviewBadge({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<AdminPendingDriverReviewBadge> createState() =>
      _AdminPendingDriverReviewBadgeState();
}

class _AdminPendingDriverReviewBadgeState
    extends State<AdminPendingDriverReviewBadge> {
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final stats = await DriverAdminStatsLoader.load(
      countryRef: AdminRoleService.isCountryAgent
          ? AdminRoleService.scopedCountryRef
          : null,
    );
    if (!mounted) return;
    setState(() => _pending = stats.pendingReview);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Badge(
        isLabelVisible: _pending > 0,
        label: Text('$_pending'),
        child: widget.child,
      ),
    );
  }
}

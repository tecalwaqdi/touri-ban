import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_role_service.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/core/admin_notification_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admin_notifications_model.dart';
export 'admin_notifications_model.dart';

/// Admin notification center — `admin_panel_notifications` collection.
class AdminNotificationsWidget extends StatefulWidget {
  const AdminNotificationsWidget({super.key});

  static const String routeName = 'AdminNotifications';
  static const String routePath = '/adminNotifications';

  @override
  State<AdminNotificationsWidget> createState() =>
      _AdminNotificationsWidgetState();
}

class _AdminNotificationsWidgetState extends State<AdminNotificationsWidget> {
  late AdminNotificationsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  AdminNotificationCategory? _categoryFilter;
  bool _unreadOnly = false;
  bool _markAllBusy = false;
  int _markGen = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminNotificationsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('admin_panel_notifications')
        .orderBy('createdAt', descending: true);
    if (AdminRoleService.isCountryAgent &&
        AdminRoleService.scopedCountryRef != null) {
      q = q.where(
        'countryRef',
        isEqualTo: AdminRoleService.scopedCountryRef,
      );
    }
    return q;
  }

  List<AdminPanelNotification> _filter(List<AdminPanelNotification> items) {
    var out = items;
    if (_categoryFilter != null) {
      out = out.where((n) => n.category == _categoryFilter).toList();
    }
    if (_unreadOnly) {
      out = out.where((n) => n.unread).toList();
    }
    return AdminPanelNotification.dedupe(out);
  }

  Future<void> _markRead(AdminPanelNotification n) async {
    if (!n.unread) return;
    final gen = ++_markGen;
    try {
      await n.reference.update({
        'unread': false,
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      AdminUi.logDiagnostic('notification_mark_read', e, st);
      if (!mounted || gen != _markGen) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تعذر تحديث الإشعار'))),
      );
    }
  }

  Future<void> _markAllRead(List<AdminPanelNotification> unread) async {
    if (_markAllBusy || unread.isEmpty) return;
    setState(() => _markAllBusy = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      var count = 0;
      for (final n in unread) {
        if (!n.unread) continue;
        batch.update(n.reference, {
          'unread': false,
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
        count++;
        if (count >= 20) break;
      }
      if (count > 0) await batch.commit();
      if (!mounted) return;
      AdminListRefresh.notify('admin_notifications');
    } catch (e, st) {
      AdminUi.logDiagnostic('notification_mark_all', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تعذر تحديث الإشعارات'))),
      );
    } finally {
      if (mounted) setState(() => _markAllBusy = false);
    }
  }

  Future<void> _openDeepLink(AdminPanelNotification n) async {
    await _markRead(n);
    if (!mounted) return;

    if (n.driverId.isNotEmpty) {
      final ref = FirebaseFirestore.instance.collection('user').doc(n.driverId);
      final snap = await ref.get();
      if (!mounted) return;
      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'السجل لم يعد متوفرًا'))),
        );
        return;
      }
      context.pushNamed(
        DriverActivationWidget.routeName,
        queryParameters: {
          'dre': serializeParam(ref, ParamType.DocumentReference),
        }.withoutNulls,
      );
      return;
    }

    if (n.bookingId.isNotEmpty) {
      final ref =
          FirebaseFirestore.instance.collection('order').doc(n.bookingId);
      final snap = await ref.get();
      if (!mounted) return;
      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'السجل لم يعد متوفرًا'))),
        );
        return;
      }
      context.pushNamed(
        AdminBookingDetailsWidget.routeName,
        queryParameters: {
          'idbokeng': serializeParam(ref, ParamType.DocumentReference),
        }.withoutNulls,
      );
      return;
    }

    if (n.supportId.isNotEmpty) {
      context.pushNamed(AdminSuportWidget.routeName);
      return;
    }

    switch (n.category) {
      case AdminNotificationCategory.drivers:
        context.pushNamed(AdmindreverWidget.routeName);
      case AdminNotificationCategory.operations:
        context.pushNamed(AdminALLhgZWidget.routeName);
      case AdminNotificationCategory.support:
        context.pushNamed(AdminSuportWidget.routeName);
      case AdminNotificationCategory.finance:
        context.pushNamed(AdminReconciliationWidget.routeName);
      case AdminNotificationCategory.system:
        break;
    }
  }

  String _categoryLabel(AdminNotificationCategory c) {
    return switch (c) {
      AdminNotificationCategory.drivers => uiTr(context, 'المناديب'),
      AdminNotificationCategory.operations => uiTr(context, 'العمليات'),
      AdminNotificationCategory.support => uiTr(context, 'الدعم'),
      AdminNotificationCategory.finance => uiTr(context, 'المالية'),
      AdminNotificationCategory.system => uiTr(context, 'النظام'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      padContent: false,
      title: uiTr(context, 'الإشعارات'),
      child: AdminPageBody(
        title: uiTr(context, 'مركز الإشعارات'),
        subtitle: uiTr(context, 'تنبيهات التشغيل والمراجعة والدعم'),
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminContentCard(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(uiTr(context, 'غير المقروء فقط')),
                    selected: _unreadOnly,
                    onSelected: (v) => setState(() => _unreadOnly = v),
                  ),
                  for (final c in AdminNotificationCategory.values)
                    FilterChip(
                      label: Text(_categoryLabel(c)),
                      selected: _categoryFilter == c,
                      onSelected: (selected) => setState(
                        () => _categoryFilter = selected ? c : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AdminFirestoreList<AdminPanelNotification>(
              key: ValueKey('notif_${_categoryFilter}_$_unreadOnly'),
              reloadKey: '${_categoryFilter}_$_unreadOnly',
              refreshScope: 'admin_notifications',
              pageSize: 25,
              liveUpdates: true,
              query: _baseQuery(),
              recordBuilder: (doc) => AdminPanelNotification.fromDoc(
                doc as QueryDocumentSnapshot<Map<String, dynamic>>,
                tr: (k) => uiTr(context, k),
              ),
              loading: const AdminLoadingState(),
              empty: AdminEmptyState(
                title: uiTr(context, 'لا توجد إشعارات'),
                message: _unreadOnly || _categoryFilter != null
                    ? uiTr(context, 'لا توجد نتائج للفلتر الحالي')
                    : null,
                icon: Icons.notifications_none_rounded,
              ),
              builder: (context, items, listState) {
                final visible = _filter(items);
                final unread = visible.where((n) => n.unread).toList();

                if (listState.hasError) {
                  return AdminErrorState(
                    title: uiTr(context, 'تعذر تحميل الإشعارات'),
                    onRetry: listState.refresh,
                  );
                }

                return AdminContentCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (unread.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _markAllBusy
                                  ? null
                                  : () => _markAllRead(unread),
                              child:
                                  Text(uiTr(context, 'تعيين المعروض كمقروء')),
                            ),
                          ),
                        ),
                      if (visible.isEmpty)
                        AdminEmptyState(
                          title: uiTr(context, 'لا توجد نتائج للفلتر'),
                          icon: Icons.filter_alt_off_rounded,
                          compact: true,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: theme.alternate.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (context, i) {
                            final n = visible[i];
                            final time = n.createdAt != null
                                ? dateTimeFormat(
                                    'yMMMd – HH:mm',
                                    n.createdAt!,
                                    locale: FFLocalizations.of(context)
                                        .languageCode,
                                  )
                                : uiTr(context, '—');
                            return ListTile(
                              leading: Icon(
                                n.unread
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                color: n.unread
                                    ? AdminUi.brandTeal
                                    : theme.secondaryText,
                              ),
                              title: Text(
                                n.title,
                                style: theme.titleSmall.override(
                                  fontFamily: theme.titleSmallFamily,
                                  fontWeight: n.unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  useGoogleFonts: !theme.titleSmallIsCustom,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (n.subtitle.isNotEmpty)
                                    Text(
                                      n.subtitle,
                                      style: theme.bodySmall,
                                    ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      AdminStatusBadge(
                                        label: _categoryLabel(n.category),
                                        tone: AdminBadgeTone.neutral,
                                      ),
                                      Text(
                                        time,
                                        style: theme.labelSmall.override(
                                          fontFamily: theme.labelSmallFamily,
                                          color: theme.secondaryText,
                                          useGoogleFonts:
                                              !theme.labelSmallIsCustom,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _openDeepLink(n),
                            );
                          },
                        ),
                      if (listState.hasMore)
                        AdminListLoadMoreFooter(state: listState),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_audit_log.dart';
import '/components/admin_enterprise_kit.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/core/admin_notification_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'admin_audit_log_model.dart';
export 'admin_audit_log_model.dart';

/// سجل عمليات الإدارة الحساسة (سوبر أدمن فقط).
class AdminAuditLogWidget extends StatefulWidget {
  const AdminAuditLogWidget({super.key});

  static String routeName = 'AdminAuditLog';
  static String routePath = '/adminAuditLog';

  @override
  State<AdminAuditLogWidget> createState() => _AdminAuditLogWidgetState();
}

class _AdminAuditLogWidgetState extends State<AdminAuditLogWidget> {
  late AdminAuditLogModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _actionFilter = TextEditingController();
  String _actionQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAuditLogModel());
  }

  @override
  void dispose() {
    _actionFilter.dispose();
    _model.dispose();
    super.dispose();
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'delete':
        return uiTr(context, 'حذف');
      case 'activate':
        return uiTr(context, 'تفعيل');
      case 'deactivate':
        return uiTr(context, 'إيقاف');
      case 'cancel':
        return uiTr(context, 'إلغاء');
      case 'driver_approve':
        return uiTr(context, 'اعتماد مندوب');
      case 'driver_reject':
        return uiTr(context, 'رفض مندوب');
      default:
        return action;
    }
  }

  Color _actionColor(String action, FlutterFlowTheme theme) {
    switch (action) {
      case 'delete':
      case 'cancel':
      case 'driver_reject':
        return theme.error;
      case 'activate':
      case 'driver_approve':
        return theme.success;
      case 'deactivate':
        return Colors.orange;
      default:
        return theme.primary;
    }
  }

  List<AuditLogEntry> _filterLogs(List<AuditLogEntry> logs) {
    final q = _actionQuery.trim().toLowerCase();
    if (q.isEmpty) return logs;
    return logs
        .where((l) =>
            l.action.toLowerCase().contains(q) ||
            l.targetType.toLowerCase().contains(q) ||
            l.targetLabel.toLowerCase().contains(q) ||
            l.actorEmail.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _openTarget(AuditLogEntry log) async {
    final type = log.targetType.toLowerCase();
    final id = log.targetId;
    if (id.isEmpty) return;

    if (type.contains('user') || type.contains('driver')) {
      final ref = FirebaseFirestore.instance.collection('user').doc(id);
      final snap = await ref.get();
      if (!mounted) return;
      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'السجل لم يعد متوفرًا'))),
        );
        return;
      }
      context.pushNamed(
        DriverProfileWidget.routeName,
        queryParameters: {
          'dre': serializeParam(ref, ParamType.DocumentReference),
        }.withoutNulls,
      );
      return;
    }

    if (type.contains('booking') || type.contains('order')) {
      final ref = FirebaseFirestore.instance.collection('order').doc(id);
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

    if (type.contains('support')) {
      context.pushNamed(AdminSuportWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final blocked = AdminSuperAdminGate.guardLayout(
      context: context,
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: appTr(context, 'nav_audit_log'),
      feature: appTr(context, 'nav_audit_log'),
    );
    if (blocked != null) return blocked;

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      padContent: false,
      title: appTr(context, 'nav_audit_log'),
      child: AdminPageBody(
        title: appTr(context, 'scr_audit_title'),
        subtitle: appTr(context, 'scr_audit_subtitle'),
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminContentCard(
              padding: const EdgeInsets.all(10),
              child: AdminSearchField(
                debounceTag: 'audit_action_filter',
                hint: uiTr(context, 'بحث بالإجراء / الكيان / البريد'),
                initialValue: _actionQuery,
                onChanged: (v) => setState(() => _actionQuery = v),
              ),
            ),
            const SizedBox(height: 10),
            AdminFirestoreList<AuditLogEntry>(
              key: ValueKey('audit_$_actionQuery'),
              reloadKey: _actionQuery,
              pageSize: 30,
              query: AdminAuditLog.collection,
              recordBuilder: AuditLogEntry.fromSnapshot,
              queryBuilder: (q) => (q as Query<Map<String, dynamic>>)
                  .orderBy('created_at', descending: true),
              loading: const AdminLoadingState(),
              empty: AdminEmptyState(
                title: uiTr(context, 'لا توجد عمليات مسجّلة بعد'),
                icon: Icons.history_rounded,
              ),
              builder: (context, logs, listState) {
                if (listState.hasError) {
                  return AdminErrorState(
                    title: uiTr(context, 'تعذر تحميل سجل التدقيق'),
                    onRetry: listState.refresh,
                  );
                }

                final visible = _filterLogs(logs);
                if (visible.isEmpty && logs.isNotEmpty) {
                  return AdminEmptyState(
                    title: uiTr(context, 'لا توجد نتائج للبحث'),
                    icon: Icons.search_off_rounded,
                    compact: true,
                  );
                }

                return AdminContentCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = visible[index];
                          final action = log.action;
                          final targetType = log.targetType;
                          final targetLabel = log.targetLabel;
                          final actorEmail = log.actorEmail;
                          final actorRole = log.actorRole;
                          final createdAt = log.createdAt;
                          final meta = adminMaskSensitiveText(log.metadataRaw);
                          final timeLabel = createdAt != null
                              ? dateTimeFormat(
                                  'yMMMd – HH:mm',
                                  createdAt.toDate(),
                                  locale:
                                      FFLocalizations.of(context).languageCode,
                                )
                              : uiTr(context, '—');

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.alternate),
                              borderRadius:
                                  BorderRadius.circular(AdminUi.radiusSm),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _actionColor(action, theme)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _actionLabel(action),
                                        style: theme.labelMedium.override(
                                          fontFamily: theme.labelMediumFamily,
                                          color: _actionColor(action, theme),
                                          fontWeight: FontWeight.w700,
                                          useGoogleFonts:
                                              !theme.labelMediumIsCustom,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$targetType${targetLabel.isNotEmpty ? ': $targetLabel' : ''}',
                                        style: theme.titleSmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (log.targetId.isNotEmpty)
                                      IconButton(
                                        tooltip: uiTr(context, 'فتح السجل'),
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 18,
                                        ),
                                        onPressed: () => _openTarget(log),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$actorRole — $actorEmail',
                                  style: theme.labelMedium.override(
                                    fontFamily: theme.labelMediumFamily,
                                    color: theme.secondaryText,
                                    useGoogleFonts: !theme.labelMediumIsCustom,
                                  ),
                                ),
                                if (log.targetId.isNotEmpty)
                                  Text(
                                    'ID: ${log.targetId}',
                                    style: theme.labelSmall.override(
                                      fontFamily: 'monospace',
                                      color: theme.secondaryText,
                                      useGoogleFonts: false,
                                    ),
                                  ),
                                Text(
                                  timeLabel,
                                  style: theme.labelSmall.override(
                                    fontFamily: theme.labelSmallFamily,
                                    color: theme.secondaryText,
                                    useGoogleFonts: !theme.labelSmallIsCustom,
                                  ),
                                ),
                                if (meta.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    meta,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.bodySmall.override(
                                      fontFamily: theme.bodySmallFamily,
                                      color: theme.secondaryText,
                                      useGoogleFonts: !theme.labelSmallIsCustom,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      if (visible.isNotEmpty)
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

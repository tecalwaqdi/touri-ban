import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_audit_log.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAuditLogModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'delete':
        return 'حذف';
      case 'activate':
        return 'تفعيل';
      case 'deactivate':
        return 'إيقاف';
      case 'cancel':
        return 'إلغاء';
      default:
        return action;
    }
  }

  Color _actionColor(String action, FlutterFlowTheme theme) {
    switch (action) {
      case 'delete':
      case 'cancel':
        return theme.error;
      case 'activate':
        return theme.success;
      case 'deactivate':
        return Colors.orange;
      default:
        return theme.primary;
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
        child: AdminFirestoreList<AuditLogEntry>(
          query: AdminAuditLog.collection,
          recordBuilder: AuditLogEntry.fromSnapshot,
          queryBuilder: (q) => (q as Query<Map<String, dynamic>>)
              .orderBy('created_at', descending: true),
          builder: (context, logs, listState) {
            return AdminContentCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'لا توجد عمليات مسجّلة بعد',
                        textAlign: TextAlign.center,
                        style: theme.titleMedium,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final action = log.action;
                        final targetType = log.targetType;
                        final targetLabel = log.targetLabel;
                        final actorEmail = log.actorEmail;
                        final actorRole = log.actorRole;
                        final createdAt = log.createdAt;
                        final timeLabel = createdAt is Timestamp
                            ? dateTimeFormat(
                                'yMMMd – HH:mm',
                                createdAt.toDate(),
                                locale: FFLocalizations.of(context)
                                    .languageCode,
                              )
                            : '—';

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
                              Text(
                                timeLabel,
                                style: theme.labelSmall.override(
                                  fontFamily: theme.labelSmallFamily,
                                  color: theme.secondaryText,
                                  useGoogleFonts: !theme.labelSmallIsCustom,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (logs.isNotEmpty)
                    AdminListLoadMoreFooter(state: listState),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

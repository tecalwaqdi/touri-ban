import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';
import '/components/admin_confirm_dialog.dart';
import '/components/admin_crud_feedback.dart';
import '/components/add_yser_widget.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'admin_user_management_system_model.dart';
export 'admin_user_management_system_model.dart';

/// إدارة جميع المستخدمين (شاشة legacy محسّنة — paginated).
class AdminUserManagementSystemWidget extends StatefulWidget {
  const AdminUserManagementSystemWidget({super.key});

  static String routeName = 'AdminUserManagementSystem';
  static String routePath = '/adminUserManagementSystem';

  @override
  State<AdminUserManagementSystemWidget> createState() =>
      _AdminUserManagementSystemWidgetState();
}

class _AdminUserManagementSystemWidgetState
    extends State<AdminUserManagementSystemWidget> {
  late AdminUserManagementSystemModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminUserManagementSystemModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<UserRecord> _filterUsers(List<UserRecord> users) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phoneNumber.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggleActivation(UserRecord user,
      {required bool activate}) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: activate
          ? uiTr(context, 'تفعيل المستخدم')
          : uiTr(context, 'إيقاف المستخدم'),
      whatHappens:
          '${uiTr(context, 'هل تريد')} ${activate ? uiTr(context, 'تفعيل') : uiTr(context, 'إيقاف')}',
      subject: user.displayName.isNotEmpty ? user.displayName : user.reference.id,
      impact: activate
          ? uiTr(context, 'User can sign in again')
          : uiTr(context, 'User account will be disabled'),
      confirmLabel: uiTr(context, 'تأكيد'),
      cancelLabel: appTr(context, 'adm_cancel'),
      destructive: !activate,
      reference: user.reference.id,
    );

    if (!confirmed) return;

    try {
      await user.reference.update(
        createUserRecordData(actevUser: activate),
      );
      if (!mounted) return;
      await AdminAuditLog.recordToggle(
        targetType: 'user',
        targetId: user.reference.id,
        targetLabel: user.displayName,
        activated: activate,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate ? uiTr(context, 'تم تفعيل المستخدم') : uiTr(context, 'تم إيقاف المستخدم'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.updateFailed(context, e))),
      );
    }
  }

  Future<void> _deleteUser(UserRecord user) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: uiTr(context, 'حذف مستخدم'),
      whatHappens: appTrFormat(context, 'adm_delete_confirm_body', user.displayName),
      subject: user.displayName.isNotEmpty ? user.displayName : user.reference.id,
      impact: uiTr(context, 'User document will be permanently deleted'),
      confirmLabel: uiTr(context, 'تأكيد الحذف'),
      cancelLabel: appTr(context, 'adm_cancel'),
      destructive: true,
      irreversible: true,
      reference: user.reference.id,
    );

    if (!confirmed) return;

    try {
      await AdminFirestoreDelete.deleteDocument(user.reference);
      if (!mounted) return;
      await AdminAuditLog.recordDelete(
        targetType: 'user',
        targetId: user.reference.id,
        targetLabel: user.displayName,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: appTrFormat(
          context,
          'adm_user_deleted_fmt',
          user.displayName,
        ),
        refreshScope: AdminListScope.users,
        removedDocumentId: user.reference.id,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    }
  }

  Future<void> _openAddUserSheet() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(top: 8),
              child: const AddYserWidget(),
            ),
          ),
        );
      },
    );
    safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);
    final isWide = AdminUi.useTableLayout(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        padContent: false,
        title: l10n.getText('jdbe4eok'),
        child: AdminPageBody(
          title: appTr(context, 'scr_user_mgmt'),
          subtitle: uiTr(context, 'جميع حسابات النظام — تفعيل، إيقاف، وحذف'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildSearch(l10n)),
                          const SizedBox(width: 12),
                          AdminPrimaryButton(
                            label: l10n.getText('g29y1pt0'),
                            icon: Icons.person_add_rounded,
                            onPressed: _openAddUserSheet,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearch(l10n),
                          const SizedBox(height: 12),
                          AdminPrimaryButton(
                            label: l10n.getText('g29y1pt0'),
                            icon: Icons.person_add_rounded,
                            onPressed: _openAddUserSheet,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              AdminFirestoreList<UserRecord>(
                refreshScope: AdminListScope.users,
                query: UserRecord.collection,
                recordBuilder: UserRecord.fromSnapshot,
                queryBuilder: (q) => AdminCountryScope.applyAllUsersQuery(q),
                builder: (context, allUsers, listState) {
                  final users = _filterUsers(allUsers);

                  return AdminContentCard(
                    padding: users.isEmpty
                        ? const EdgeInsets.all(16)
                        : const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (users.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              adminListCountLabel(context, listState, visibleCount: users.length, pageFetched: allUsers.length),
                              style: theme.labelLarge.override(
                                fontFamily: theme.labelLargeFamily,
                                color: theme.secondaryText,
                                useGoogleFonts: !theme.labelLargeIsCustom,
                              ),
                            ),
                          ),
                        if (users.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? uiTr(context, 'لا يوجد مستخدمون')
                                  : uiTr(context, 'لا توجد نتائج للبحث'),
                              textAlign: TextAlign.center,
                              style: theme.titleMedium,
                            ),
                          )
                        else if (isWide)
                          _UsersTable(
                            users: users,
                            onToggle: _toggleActivation,
                            onDelete: _deleteUser,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => _UserRow(
                              user: users[index],
                              onToggle: _toggleActivation,
                              onDelete: _deleteUser,
                            ),
                          ),
                        if (users.isNotEmpty)
                          AdminListLoadMoreFooter(state: listState),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(FFLocalizations l10n) {
    return TextFormField(
      controller: _model.textController,
      focusNode: _model.textFieldFocusNode,
      onChanged: (_) => EasyDebounce.debounce(
        '_admin_user_mgmt_search',
        const Duration(milliseconds: 300),
        () {
          if (mounted) {
            setState(() {
              _searchQuery = _model.textController?.text ?? '';
            });
          }
        },
      ),
      decoration: AdminUi.inputDecoration(
        context,
        label: uiTr(context, 'بحث'),
        hint: l10n.getText('mqx7pmcq'),
        prefixIcon: Icons.search_rounded,
      ),
      validator: _model.textControllerValidator.asValidator(context),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.onToggle,
    required this.onDelete,
  });

  final List<UserRecord> users;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;
  final Future<void> Function(UserRecord user) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: AdminUi.adminTableMinWidth(context),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  _HeaderCell(label: uiTr(context, 'الاسم'), flex: 3, theme: theme),
                  _HeaderCell(label: uiTr(context, 'البريد'), flex: 3, theme: theme),
                  _HeaderCell(label: uiTr(context, 'الجوال'), flex: 2, theme: theme),
                  _HeaderCell(label: uiTr(context, 'الحالة'), flex: 2, theme: theme),
                  _HeaderCell(label: uiTr(context, 'إجراءات'), flex: 2, theme: theme),
                ],
              ),
            ),
            ...users.map(
              (user) => _UserRow(
                user: user,
                onToggle: onToggle,
                onDelete: onDelete,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
    required this.theme,
  });

  final String label;
  final int flex;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: theme.labelLarge.override(
          fontFamily: theme.labelLargeFamily,
          fontWeight: FontWeight.w700,
          useGoogleFonts: !theme.labelLargeIsCustom,
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onToggle,
    required this.onDelete,
    this.dense = false,
  });

  final UserRecord user;
  final Future<void> Function(UserRecord user, {required bool activate})
      onToggle;
  final Future<void> Function(UserRecord user) onDelete;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final active = user.actevUser;

    final content = Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(user.displayName, style: theme.bodyMedium),
        ),
        Expanded(
          flex: 3,
          child: Text(user.email, style: theme.bodyMedium),
        ),
        Expanded(
          flex: 2,
          child: Text(user.phoneNumber, style: theme.bodyMedium),
        ),
        Expanded(
          flex: 2,
          child: Text(
            active ? uiTr(context, 'مفعّل') : uiTr(context, 'موقوف'),
            style: theme.labelMedium.override(
              fontFamily: theme.labelMediumFamily,
              color: active ? theme.success : theme.error,
              useGoogleFonts: !theme.labelMediumIsCustom,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              FlutterFlowIconButton(
                borderRadius: 8,
                buttonSize: 35,
                fillColor: const Color(0xFFE8F5E9),
                icon: Icon(
                  active ? Icons.pause_circle_outline : Icons.check_circle,
                  color: theme.success,
                  size: 18,
                ),
                onPressed: () => onToggle(user, activate: !active),
              ),
              const SizedBox(width: 8),
              FlutterFlowIconButton(
                borderRadius: 8,
                buttonSize: 35,
                fillColor: const Color(0xFFFFEBEE),
                icon: Icon(Icons.delete_outline, color: theme.error, size: 18),
                onPressed: () => onDelete(user),
              ),
            ],
          ),
        ),
      ],
    );

    if (dense) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: content,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.alternate),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
      ),
      child: content,
    );
  }
}

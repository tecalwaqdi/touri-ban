import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_country_scope.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'admin_super_admins_model.dart';
export 'admin_super_admins_model.dart';

class AdminSuperAdminsWidget extends StatefulWidget {
  const AdminSuperAdminsWidget({super.key});

  static String routeName = 'AdminSuperAdmins';
  static String routePath = '/adminSuperAdmins';

  @override
  State<AdminSuperAdminsWidget> createState() => _AdminSuperAdminsWidgetState();
}

class _AdminSuperAdminsWidgetState extends State<AdminSuperAdminsWidget> {
  late AdminSuperAdminsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminSuperAdminsModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  List<UserRecord> _filterAdmins(List<UserRecord> admins) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return admins;
    return admins.where((u) {
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phoneNumber.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteAdmin(UserRecord admin) async {
    if (admin.reference.id == currentUserUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'لا يمكنك حذف حسابك الحالي'))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appTr(context, 'adm_delete_confirm_title')),
            content: Text(
              'هل أنت متأكد من حذف السوبر أدمن "${admin.displayName}"؟\n'
              'سيتم حذف بياناته من قاعدة البيانات فقط.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(appTr(context, 'adm_delete'), style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await AdminFirestoreDelete.deleteDocument(admin.reference);
      await AdminAuditLog.recordDelete(
        targetType: 'super_admin',
        targetId: admin.reference.id,
        targetLabel: admin.displayName,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف السوبر أدمن'),
        refreshScope: AdminListScope.superAdmins,
        removedDocumentId: admin.reference.id,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    }
  }

  void _openEdit(UserRecord admin) {
    context.pushNamed(
      EdetSuperAdminWidget.routeName,
      queryParameters: {
        'superAdminRef': serializeParam(
          admin.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isWide = AdminUi.useTableLayout(context);

    if (!AdminSuperAdminGate.isAllowed) {
      final blocked = AdminSuperAdminGate.guardLayout(
        context: context,
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        title: appTr(context, 'nav_super_admin'),
        feature: appTr(context, 'scr_super_admin_mgmt'),
      );
      if (blocked != null) return blocked;
    }

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
        title: appTr(context, 'nav_super_admin'),
        child: AdminPageBody(
          title: appTr(context, 'nav_super_admin'),
          subtitle: appTr(context, 'scr_super_admin_subtitle'),
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminContentCard(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildSearch()),
                          const SizedBox(width: 12),
                          _buildAddButton(),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearch(),
                          const SizedBox(height: 12),
                          _buildAddButton(),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              AdminFirestoreList<UserRecord>(
                refreshScope: AdminListScope.superAdmins,
                query: UserRecord.collection,
                recordBuilder: UserRecord.fromSnapshot,
                queryBuilder: AdminCountryScope.applySuperAdminUserQuery,
                builder: (context, allAdmins, listState) {
                  final admins = _filterAdmins(allAdmins);

                  if (admins.isEmpty) {
                    return AdminContentCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 48,
                            color: AdminUi.brandTeal.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'لا يوجد سوبر أدمن مسجل'
                                : 'لا توجد نتائج للبحث',
                            style: theme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return AdminContentCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Text(
                            'العدد: ${admins.length}'
                            '${admins.length != allAdmins.length ? ' من ${allAdmins.length}' : ''}'
                            '${listState.hasMore ? '+' : ''}',
                            style: theme.labelLarge.override(
                              fontFamily: theme.labelLargeFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.labelLargeIsCustom,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isWide)
                          _SuperAdminsTable(
                            admins: admins,
                            onEdit: _openEdit,
                            onDelete: _deleteAdmin,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: admins.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _SuperAdminCard(
                              admin: admins[index],
                              onEdit: () => _openEdit(admins[index]),
                              onDelete: () => _deleteAdmin(admins[index]),
                            ),
                          ),
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

  Widget _buildSearch() {
    return TextFormField(
      controller: _model.textController,
      focusNode: _model.textFieldFocusNode,
      onChanged: (_) => EasyDebounce.debounce(
        '_admin_super_admins_search',
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
        hint: 'الاسم، البريد، أو الجوال',
        prefixIcon: Icons.search_rounded,
      ),
    );
  }

  Widget _buildAddButton() {
    return AdminPrimaryButton(
      label: uiTr(context, 'إضافة سوبر أدمن'),
      icon: Icons.person_add_alt_1_rounded,
      onPressed: () => context.pushNamed(AdminAddSuperAdminWidget.routeName),
    );
  }
}

class _SuperAdminsTable extends StatelessWidget {
  const _SuperAdminsTable({
    required this.admins,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UserRecord> admins;
  final void Function(UserRecord) onEdit;
  final void Function(UserRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AdminUi.brandTeal.withValues(alpha: 0.06),
        ),
        columns: [
          DataColumn(label: Text(uiTr(context, 'الاسم'))),
          DataColumn(label: Text(uiTr(context, 'البريد'))),
          DataColumn(label: Text(uiTr(context, 'الجوال'))),
          DataColumn(label: Text(uiTr(context, 'الحالة'))),
          DataColumn(label: Text(uiTr(context, 'إجراءات'))),
        ],
        rows: admins.map((admin) {
          final isSelf = admin.reference.id == currentUserUid;
          return DataRow(
            cells: [
              DataCell(Text(admin.displayName.isNotEmpty ? admin.displayName : '—')),
              DataCell(Text(admin.email.isNotEmpty ? admin.email : '—')),
              DataCell(Text(admin.phoneNumber.isNotEmpty ? admin.phoneNumber : '—')),
              DataCell(
                _StatusChip(active: admin.actevUser),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'تعديل',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => onEdit(admin),
                    ),
                    IconButton(
                      tooltip: isSelf ? 'لا يمكن حذف حسابك' : 'حذف',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: isSelf ? theme.secondaryText : Colors.red,
                      ),
                      onPressed: isSelf ? null : () => onDelete(admin),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SuperAdminCard extends StatelessWidget {
  const _SuperAdminCard({
    required this.admin,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRecord admin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSelf = admin.reference.id == currentUserUid;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AdminUi.brandTeal.withValues(alpha: 0.12),
                child: const Icon(Icons.shield_rounded, color: AdminUi.brandTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.displayName.isNotEmpty ? admin.displayName : '—',
                      style: theme.titleSmall.override(
                        fontFamily: theme.titleSmallFamily,
                        fontWeight: FontWeight.w700,
                        useGoogleFonts: !theme.titleSmallIsCustom,
                      ),
                    ),
                    if (isSelf)
                      Text(
                        'حسابك الحالي',
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: AdminUi.brandTeal,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      admin.email,
                      style: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        color: theme.secondaryText,
                        useGoogleFonts: !theme.bodySmallIsCustom,
                      ),
                    ),
                    if (admin.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        admin.phoneNumber,
                        style: theme.bodySmall.override(
                          fontFamily: theme.bodySmallFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.bodySmallIsCustom,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusChip(active: admin.actevUser),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(uiTr(context, 'تعديل')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSelf ? null : onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: isSelf ? theme.secondaryText : Colors.red,
                  ),
                  label: Text(
                    'حذف',
                    style: TextStyle(
                      color: isSelf ? theme.secondaryText : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? Colors.green : Colors.grey).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'مفعّل' : 'موقوف',
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

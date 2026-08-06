import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'edet_super_admin_model.dart';
export 'edet_super_admin_model.dart';

class EdetSuperAdminWidget extends StatefulWidget {
  const EdetSuperAdminWidget({
    super.key,
    required this.superAdminRef,
  });

  final DocumentReference? superAdminRef;

  static String routeName = 'EdetSuperAdmin';
  static String routePath = '/edetSuperAdmin';

  @override
  State<EdetSuperAdminWidget> createState() => _EdetSuperAdminWidgetState();
}

class _EdetSuperAdminWidgetState extends State<EdetSuperAdminWidget> {
  late EdetSuperAdminModel _model;
  UserRecord? _admin;
  bool get _isSelf => widget.superAdminRef?.id == currentUserUid;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetSuperAdminModel());
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final ref = widget.superAdminRef;
    if (ref == null) {
      if (mounted) setState(() => _model.isLoading = false);
      return;
    }

    try {
      final admin = await UserRecord.getDocumentOnce(ref);
      if (!mounted) return;

      if (!AdminRoleService.isSuperAdminUser(admin)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'هذا الحساب ليس سوبر أدمن'))),
        );
        context.safePop();
        return;
      }

      _admin = admin;
      _model.nameTextController =
          TextEditingController(text: admin.displayName);
      _model.phoneTextController =
          TextEditingController(text: admin.phoneNumber);
      _model.emailTextController = TextEditingController(text: admin.email);
      _model.activeValue = admin.actevUser;

      setState(() => _model.isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _model.isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!AdminSuperAdminGate.isAllowed) return;
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    final ref = widget.superAdminRef;
    if (ref == null || _admin == null) return;

    setState(() => _model.isSubmitting = true);
    try {
      final displayName = _model.nameTextController!.text.trim();
      final activating = _model.activeValue && !_admin!.actevUser;

      await AdminFirestoreDelete.updateDocument(
        ref,
        createUserRecordData(
          displayName: displayName,
          phoneNumber: _model.phoneTextController!.text.trim(),
          actevUser: _model.activeValue,
          isAdmin: true,
          isAdminRule: AdminRoleService.ruleSuperAdmin,
        ),
      );

      await AdminAuditLog.record(
        action: 'update',
        targetType: 'super_admin',
        targetId: ref.id,
        targetLabel: displayName,
      );

      if (activating) {
        await AdminAuditLog.recordToggle(
          targetType: 'super_admin',
          targetId: ref.id,
          targetLabel: displayName,
          activated: true,
        );
      } else if (!_model.activeValue && _admin!.actevUser) {
        await AdminAuditLog.recordToggle(
          targetType: 'super_admin',
          targetId: ref.id,
          targetLabel: displayName,
          activated: false,
        );
      }

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم تحديث بيانات السوبر أدمن'),
        refreshScope: AdminListScope.superAdmins,
        popPage: true,
        deferHeavyWork: false,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.saveFailed(context, e));
    } finally {
      if (mounted) setState(() => _model.isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    if (!AdminSuperAdminGate.isAllowed) return;
    if (_isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'لا يمكنك حذف حسابك الحالي'))),
      );
      return;
    }

    final ref = widget.superAdminRef;
    if (ref == null || _admin == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(context, 'حذف السوبر أدمن')),
        content: Text(
          '${uiTr(context, 'هل أنت متأكد من حذف')} "${_admin!.displayName}"؟\n' +
          uiTr(context, 'سيتم حذف بياناته من قاعدة البيانات فقط.'),
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
    );
    if (confirmed != true || !mounted) return;

    setState(() => _model.isSubmitting = true);
    try {
      await AdminFirestoreDelete.deleteDocument(ref);
      await AdminAuditLog.recordDelete(
        targetType: 'super_admin',
        targetId: ref.id,
        targetLabel: _admin!.displayName,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف السوبر أدمن'),
        refreshScope: AdminListScope.superAdmins,
        removedDocumentId: ref.id,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    } finally {
      if (mounted) setState(() => _model.isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminSuperAdminGate.isAllowed) {
      return AdminSuperAdminGate.deniedEditScaffold(
        context: context,
        title: appTr(context, 'scr_edit_super_admin'),
      );
    }

    if (_model.isLoading) {
      return AdminEditScaffold(
        title: appTr(context, 'scr_edit_super_admin'),
        isLoading: true,
        child: const SizedBox.shrink(),
      );
    }

    if (_admin == null) {
      return AdminEditScaffold(
        title: appTr(context, 'scr_edit_super_admin'),
        child: AdminContentCard(
          child: Text(
            uiTr(context, 'تعذر تحميل بيانات السوبر أدمن'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AdminEditScaffold(
      title: appTr(context, 'scr_edit_super_admin'),
      subtitle: _isSelf ? uiTr(context, 'حسابك الحالي') : null,
      isLoading: _model.isSubmitting,
      floatingAction: AdminPrimaryButton(
        label: uiTr(context, 'حفظ التعديلات'),
        icon: Icons.save_rounded,
        isLoading: _model.isSubmitting,
        onPressed: _model.isSubmitting ? null : _save,
      ),
      child: Form(
        key: _model.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'بيانات السوبر أدمن'),
              children: [
                TextFormField(
                  controller: _model.nameTextController,
                  focusNode: _model.nameFocusNode,
                  decoration: InputDecoration(labelText: uiTr(context, 'الاسم الكامل')),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? uiTr(context, 'مطلوب') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model.phoneTextController,
                  focusNode: _model.phoneFocusNode,
                  decoration: InputDecoration(labelText: uiTr(context, 'رقم الجوال')),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model.emailTextController,
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'البريد الإلكتروني'),
                    helperText: appTr(context, 'adm_email_readonly_hint'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'الحالة'),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(uiTr(context, 'تفعيل الحساب')),
                  subtitle: Text(
                    _isSelf && !_model.activeValue
                        ? appTr(context, 'adm_self_deactivate_warn')
                        : uiTr(context, 'يمكن للسوبر أدمن تسجيل الدخول عند التفعيل'),
                  ),
                  value: _model.activeValue,
                  onChanged: _model.isSubmitting
                      ? null
                      : (v) => setState(() => _model.activeValue = v),
                ),
              ],
            ),
            if (!_isSelf) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _model.isSubmitting ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                label: Text(uiTr(context, 'حذف السوبر أدمن'),
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

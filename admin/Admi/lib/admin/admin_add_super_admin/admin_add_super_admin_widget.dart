import '/backend/admin_audit_log.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_user_creation.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'admin_add_super_admin_model.dart';
export 'admin_add_super_admin_model.dart';

class AdminAddSuperAdminWidget extends StatefulWidget {
  const AdminAddSuperAdminWidget({super.key});

  static String routeName = 'AdminAddSuperAdmin';
  static String routePath = '/adminAddSuperAdmin';

  @override
  State<AdminAddSuperAdminWidget> createState() =>
      _AdminAddSuperAdminWidgetState();
}

class _AdminAddSuperAdminWidgetState extends State<AdminAddSuperAdminWidget> {
  late AdminAddSuperAdminModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAddSuperAdminModel());

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.phoneTextController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();
    _model.confirmPasswordTextController ??= TextEditingController();
    _model.confirmPasswordFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!AdminSuperAdminGate.isAllowed) return;
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    final password = _model.passwordTextController!.text;
    final confirm = _model.confirmPasswordTextController!.text;

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'))),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'كلمتا المرور غير متطابقتين'))),
      );
      return;
    }

    setState(() => _model.isSubmitting = true);

    try {
      final email = _model.emailTextController!.text.trim();
      final displayName = _model.nameTextController!.text.trim();

      final uid = await AdminUserCreation.createEmailUser(
        email: email,
        password: password,
        userData: {
          'display_name': displayName,
          'phone_number': _model.phoneTextController!.text.trim(),
          'actev_user': _model.activeValue,
          'IsAdmin': true,
          'isAdminRule': AdminRoleService.ruleSuperAdmin,
        },
      );

      await AdminAuditLog.record(
        action: 'create',
        targetType: 'super_admin',
        targetId: uid,
        targetLabel: displayName,
      );

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.add,
        message: uiTr(context, 'تم إضافة السوبر أدمن بنجاح'),
        refreshScope: AdminListScope.superAdmins,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, 'تعذر الإضافة: $e');
    } finally {
      if (mounted) setState(() => _model.isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminSuperAdminGate.isAllowed) {
      return AdminSuperAdminGate.deniedEditScaffold(
        context: context,
        title: appTr(context, 'scr_add_super_admin'),
      );
    }

    return AdminEditScaffold(
      title: appTr(context, 'scr_add_super_admin'),
      subtitle: uiTr(context, 'إنشاء حساب جديد بصلاحيات كاملة على النظام'),
      isLoading: _model.isSubmitting,
      floatingAction: AdminPrimaryButton(
        label: uiTr(context, 'حفظ السوبر أدمن'),
        icon: Icons.person_add_alt_1_rounded,
        isLoading: _model.isSubmitting,
        onPressed: _model.isSubmitting ? null : _submit,
      ),
      child: Form(
        key: _model.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'البيانات الأساسية'),
              children: [
                TextFormField(
                  controller: _model.nameTextController,
                  focusNode: _model.nameFocusNode,
                  decoration: InputDecoration(labelText: uiTr(context, 'الاسم الكامل')),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
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
                  focusNode: _model.emailFocusNode,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'البريد الإلكتروني'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    if (!v.contains('@')) return 'بريد غير صالح';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'كلمة المرور'),
              children: [
                TextFormField(
                  controller: _model.passwordTextController,
                  focusNode: _model.passwordFocusNode,
                  decoration: InputDecoration(labelText: uiTr(context, 'كلمة المرور')),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return '6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model.confirmPasswordTextController,
                  focusNode: _model.confirmPasswordFocusNode,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'تأكيد كلمة المرور'),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'مطلوب';
                    return null;
                  },
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
                  subtitle: Text(uiTr(context, 'يمكن للسوبر أدمن تسجيل الدخول عند التفعيل')),
                  value: _model.activeValue,
                  onChanged: _model.isSubmitting
                      ? null
                      : (v) => setState(() => _model.activeValue = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

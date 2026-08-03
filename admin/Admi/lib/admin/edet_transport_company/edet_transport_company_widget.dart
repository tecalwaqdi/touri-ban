import '/backend/admin_resource_guard.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'edet_transport_company_model.dart';
export 'edet_transport_company_model.dart';

class EdetTransportCompanyWidget extends StatefulWidget {
  const EdetTransportCompanyWidget({
    super.key,
    required this.companyRef,
  });

  final DocumentReference? companyRef;

  static String routeName = 'EdetTransportCompany';
  static String routePath = '/edetTransportCompany';

  @override
  State<EdetTransportCompanyWidget> createState() =>
      _EdetTransportCompanyWidgetState();
}

class _EdetTransportCompanyWidgetState
    extends State<EdetTransportCompanyWidget> {
  late EdetTransportCompanyModel _model;
  TransportCompanyRecord? _company;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetTransportCompanyModel());
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final ref = widget.companyRef;
    if (ref == null) {
      if (mounted) setState(() => _model.isLoading = false);
      return;
    }

    try {
      final company = await TransportCompanyRecord.getDocumentOnce(ref);
      if (!mounted) return;
      if (!AdminResourceGuard.canEditTransportCompany(company)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'لا تملك صلاحية تعديل هذه الشركة'))),
        );
        context.safePop();
        return;
      }
      _company = company;
      _model.nameTextController = TextEditingController(text: company.naim);
      _model.licenseTextController =
          TextEditingController(text: company.licenseNumber);
      _model.phoneTextController = TextEditingController(text: company.phone);
      _model.emailTextController = TextEditingController(text: company.email);
      _model.activeValue = company.actev;
      setState(() => _model.isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _model.isLoading = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_model.formKey.currentState?.validate() ?? false)) return;
    final ref = widget.companyRef;
    if (ref == null) return;

    setState(() => _model.isSubmitting = true);
    try {
      await AdminFirestoreDelete.updateDocument(
        ref,
        createTransportCompanyRecordData(
          naim: _model.nameTextController!.text.trim(),
          licenseNumber: _model.licenseTextController!.text.trim(),
          phone: _model.phoneTextController!.text.trim(),
          email: _model.emailTextController!.text.trim(),
          actev: _model.activeValue,
        ),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم تحديث بيانات الشركة'),
        refreshScope: AdminListScope.transportCompanies,
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
    final ref = widget.companyRef;
    if (ref == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(context, 'حذف شركة النقل')),
        content: const Text(
          'هل أنت متأكد من حذف هذه الشركة؟ لن يُحذف حساب المدير تلقائياً.',
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
        targetType: 'transport_company',
        targetId: ref.id,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف الشركة'),
        refreshScope: AdminListScope.transportCompanies,
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
  Widget build(BuildContext context) {
    if (_model.isLoading) {
      return AdminEditScaffold(
        title: appTr(context, 'scr_edit_transport'),
        isLoading: true,
        child: SizedBox.shrink(),
      );
    }

    if (_company == null) {
      return AdminEditScaffold(
        title: appTr(context, 'scr_edit_transport'),
        child: AdminContentCard(
          child: Text(
            'تعذر تحميل بيانات الشركة',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AdminEditScaffold(
      title: appTr(context, 'scr_edit_transport'),
      subtitle: _company!.dolhText.isNotEmpty
          ? 'الدولة: ${_company!.dolhText}'
          : null,
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
            AdminContentCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _model.nameTextController,
                    focusNode: _model.nameFocusNode,
                    decoration: InputDecoration(
                      labelText: uiTr(context, 'اسم الشركة'),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _model.licenseTextController,
                    focusNode: _model.licenseFocusNode,
                    decoration: InputDecoration(
                      labelText: uiTr(context, 'رقم ترخيص هيئة النقل'),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _model.phoneTextController,
                    focusNode: _model.phoneFocusNode,
                    decoration: InputDecoration(labelText: uiTr(context, 'جوال')),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _model.emailTextController,
                    focusNode: _model.emailFocusNode,
                    decoration: InputDecoration(
                      labelText: uiTr(context, 'بريد مدير الشركة'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(uiTr(context, 'الشركة مفعّلة')),
                    value: _model.activeValue,
                    onChanged: _model.isSubmitting
                        ? null
                        : (v) => setState(() => _model.activeValue = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _model.isSubmitting ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              label: const Text(
                'حذف الشركة',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

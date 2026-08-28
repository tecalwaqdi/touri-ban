
import '/backend/admin_audit_log.dart';
import '/backend/admin_cascade_delete.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/backend.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_driver_requirements_editor.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'edet_dolh_model.dart';
export 'edet_dolh_model.dart';

class EdetDolhWidget extends StatefulWidget {
  const EdetDolhWidget({
    super.key,
    required this.iddolhe,
  });

  final DocumentReference? iddolhe;

  static String routeName = 'EdetDolh';
  static String routePath = '/edetDolh';

  @override
  State<EdetDolhWidget> createState() => _EdetDolhWidgetState();
}

class _EdetDolhWidgetState extends State<EdetDolhWidget> {
  late EdetDolhModel _model;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isInitializingRequirements = false;
  Map<String, dynamic> _driverRequirements = {};
  String? _boundRequirementsCountryId;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetDolhModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickCountryImage() async {
    setState(() => _model.isDataUploading_uploadDataX8m = true);
    try {
      final url = await pickAndUploadAdminImage(
        context: context,
        storageFolder: 'countries/uploads',
        onLocalPreview: (bytes) {
          if (!mounted) return;
          setState(() {
            _model.uploadedLocalFile_uploadDataX8m =
                FFUploadedFile(bytes: bytes);
          });
        },
      );
      if (url == null) return;
      setState(() {
        _model.uploadedFileUrl_uploadDataX8m = url;
        _model.uploadedLocalFile_uploadDataX8m =
            FFUploadedFile(bytes: Uint8List.fromList([]));
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_image_selected'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.uploadFailed(context, e))),
      );
    } finally {
      if (mounted) {
        setState(() => _model.isDataUploading_uploadDataX8m = false);
      }
    }
  }

  Future<void> _save(CountriesRecord record) async {
    final name = _model.textController1!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى إدخال اسم الدولة'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AdminFirestoreDelete.updateDocument(
        widget.iddolhe!,
        createCountriesRecordData(
          naim: name,
          osf: _model.textController2!.text.trim(),
          img: await resolveImageForFirestoreSave(
            pickedUrl: _model.uploadedFileUrl_uploadDataX8m,
            existingUrl: record.img,
            localBytes: _model.uploadedLocalFile_uploadDataX8m.bytes,
          ),
          acctev: _model.switchValue ?? record.acctev,
          vatPercent:
              double.tryParse(_model.textController3!.text.trim()) ??
                  record.vatPercent,
          appCommissionPercent:
              double.tryParse(_model.textController4!.text.trim()) ??
                  record.appCommissionPercent,
          currencyCode: _model.textControllerCurrencyCode!.text.trim().toUpperCase(),
          currencySymbol: _model.textControllerCurrencySymbol!.text.trim(),
          driverRequirements: (!AdminSuperAdminGate.isAllowed ||
                  _driverRequirements.isEmpty)
              ? null
              : Map<String, dynamic>.from(_driverRequirements),
        ),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم حفظ التعديلات بنجاح'),
        refreshScope: AdminListScope.countries,
        popPage: true,
        deferHeavyWork: false,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.saveFailed(context, e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _initializeDriverRequirements(CountriesRecord record) async {
    if (!AdminSuperAdminGate.isAllowed) return;
    setState(() => _isInitializingRequirements = true);
    try {
      await CloudFunctionsClient.ensureDriverCountryConfigs(
        countryPath: record.reference.path,
      );
      final snap = await record.reference.get();
      if (!mounted) return;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final raw = data['driver_requirements'];
      setState(() {
        _driverRequirements = raw is Map
            ? Map<String, dynamic>.from(raw)
            : AdminDriverRequirementsEditor.operationalAutoBaselineConfig();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تم تهيئة متطلبات المندوب'))),
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(
        context,
        AdminCrudFeedback.saveFailed(context, e),
      );
    } finally {
      if (mounted) setState(() => _isInitializingRequirements = false);
    }
  }

  Future<void> _delete(CountriesRecord record) async {
    if (!AdminSuperAdminGate.isAllowed) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appTr(context, 'adm_delete_confirm_title')),
            content: Text(
              '${uiTr(context, 'هل أنت متأكد من حذف')} "${record.naim}"؟\n' +
              uiTr(context, 'سيتم حذف كل المناطق والمدن والمعالم المرتبطة.'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appTr(context, 'adm_no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(appTr(context, 'adm_yes_delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isDeleting = true);
    try {
      await deleteCountryCascade(record.reference);
      await AdminAuditLog.recordDelete(
        targetType: 'country',
        targetId: record.reference.id,
        targetLabel: record.naim,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف الدولة وكل البيانات المرتبطة'),
        refreshScope: AdminListScope.countries,
        removedDocumentId: record.reference.id,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.iddolhe == null) {
      return AdminMissingDocumentScaffold(
        title: uiTr(context, 'تعديل الدولة'),
        message: uiTr(context, 'تعذر تحميل البيانات. الرابط ناقص أو غير صالح.'),
      );
    }

    return StreamBuilder<CountriesRecord>(
      stream: CountriesRecord.getDocument(widget.iddolhe!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AdminEditScaffold(
            title: uiTr(context, 'تعديل الدولة'),
            isLoading: true,
            child: SizedBox.shrink(),
          );
        }

        final record = snapshot.data!;
        _model.bindCountriesRecord(record);
        final countryId = record.reference.id;
        if (_boundRequirementsCountryId != countryId) {
          _boundRequirementsCountryId = countryId;
          _driverRequirements = record.hasDriverRequirements()
              ? Map<String, dynamic>.from(record.driverRequirements)
              : <String, dynamic>{};
        }

        return AdminEditScaffold(
          title: uiTr(context, 'تعديل الدولة'),
          subtitle: uiTr(context, 'حدّث بيانات الدولة وصورتها وحالة التفعيل'),
          child: AdminEditFormCard(
            children: [
              AdminEditableImageCard(
                imageUrl: _model.uploadedFileUrl_uploadDataX8m,
                localBytes: _model.uploadedLocalFile_uploadDataX8m.bytes,
                isUploading: _model.isDataUploading_uploadDataX8m,
                hint: uiTr(context, 'اضغط لاختيار صورة العلم من المعرض أو الكاميرا'),
                onPick: _pickCountryImage,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController1!,
                focusNode: _model.textFieldFocusNode1,
                label: uiTr(context, 'اسم الدولة'),
                icon: Icons.flag_rounded,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController2!,
                focusNode: _model.textFieldFocusNode2,
                label: uiTr(context, 'وصف الدولة'),
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController3!,
                focusNode: _model.textFieldFocusNode3,
                label: uiTr(context, 'نسبة الضريبة (%)'),
                icon: Icons.percent_rounded,
                keyboardType: TextInputType.number,
                hint: uiTr(context, 'مثال: 15'),
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController4!,
                focusNode: _model.textFieldFocusNode4,
                label: uiTr(context, 'نسبة أرباح التطبيق (%)'),
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                hint: uiTr(context, 'مثال: 10'),
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textControllerCurrencyCode!,
                focusNode: _model.textFieldFocusNodeCurrencyCode,
                label: uiTr(context, 'رمز العملة (ISO)'),
                icon: Icons.payments_outlined,
                hint: uiTr(context, 'مثال: SAR أو KGS'),
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textControllerCurrencySymbol!,
                focusNode: _model.textFieldFocusNodeCurrencySymbol,
                label: uiTr(context, 'رمز عرض العملة'),
                icon: Icons.attach_money_rounded,
                hint: uiTr(context, 'مثال: ر.س أو сом'),
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminDriverRequirementsEditor(
                value: _driverRequirements,
                readOnly: !AdminSuperAdminGate.isAllowed,
                onChanged: (next) => setState(() => _driverRequirements = next),
              ),
              if (AdminSuperAdminGate.isAllowed &&
                  !record.hasDriverRequirements()) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isInitializingRequirements
                      ? null
                      : () => _initializeDriverRequirements(record),
                  icon: _isInitializingRequirements
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high_outlined),
                  label: Text(uiTr(context, 'تهيئة متطلبات المندوب')),
                ),
              ],
              const SizedBox(height: AdminUi.fieldGap),
              AdminEditSwitchRow(
                label: uiTr(context, 'تفعيل الدولة'),
                subtitle: uiTr(context, 'عند التفعيل تظهر الدولة في التطبيق'),
                value: _model.switchValue ?? record.acctev,
                onChanged: (v) => setState(() => _model.switchValue = v),
              ),
            ],
          ),
          floatingAction: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (AdminSuperAdminGate.isAllowed) ...[
                OutlinedButton.icon(
                  onPressed: (_isSaving || _isDeleting)
                      ? null
                      : () => _delete(record),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  label: Text(uiTr(context, 'حذف الدولة'),
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              AdminPrimaryButton(
                label: uiTr(context, 'حفظ التعديلات'),
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: () => _save(record),
              ),
            ],
          ),
        );
      },
    );
  }
}

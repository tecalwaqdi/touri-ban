
import '/backend/admin_audit_log.dart';
import '/backend/admin_cascade_delete.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_ui.dart';
import '/components/admin_region_picker.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edet_reg_model.dart';
export 'edet_reg_model.dart';

class EdetRegWidget extends StatefulWidget {
  const EdetRegWidget({
    super.key,
    required this.idreg,
  });

  final DocumentReference? idreg;

  static String routeName = 'edetReg';
  static String routePath = '/edetReg';

  @override
  State<EdetRegWidget> createState() => _EdetRegWidgetState();
}

class _EdetRegWidgetState extends State<EdetRegWidget> {
  late EdetRegModel _model;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetRegModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _syncCountryFromRecord(CitiesRecord record) {
    if (record.dolh != null) {
      FFAppState().RevDolh = record.dolh;
      if (_model.countryLabel == null) {
        CountriesRecord.getDocumentOnce(record.dolh!).then((country) {
          if (!mounted) return;
          setState(() {
            _model.countryLabel = country.naim;
            FFAppState().RevdolhTEXT = country.naim;
          });
        });
      }
    }
  }

  Future<void> _pickRegionImage() async {
    setState(() => _model.isDataUploading_uploadDataO6s = true);
    try {
      final url = await pickAndUploadAdminImage(
        context: context,
        storageFolder: 'regions/uploads',
        onLocalPreview: (bytes) {
          if (!mounted) return;
          setState(() {
            _model.uploadedLocalFile_uploadDataO6s =
                FFUploadedFile(bytes: bytes);
          });
        },
      );
      if (url == null) return;
      setState(() {
        _model.uploadedFileUrl_uploadDataO6s = url;
        _model.uploadedLocalFile_uploadDataO6s =
            FFUploadedFile(bytes: Uint8List.fromList([]));
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_image_selected'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.uploadFailed(context, uploadErrorMessage(e)))),
      );
    } finally {
      if (mounted) {
        setState(() => _model.isDataUploading_uploadDataO6s = false);
      }
    }
  }

  Future<void> _save(CitiesRecord record) async {
    final name = _model.textFieldnaimTextController!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى إدخال اسم المنطقة'))),
      );
      return;
    }
    if (FFAppState().RevDolh == null && record.dolh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى اختيار الدولة'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AdminFirestoreDelete.updateDocument(
        widget.idreg!,
        createCitiesRecordData(
          naim: name,
          osf: _model.textFieldDescTextController!.text.trim(),
          dolh: FFAppState().RevDolh ?? record.dolh,
          acctev: _model.switchValue ?? record.acctev,
          img: await resolveImageForFirestoreSave(
            pickedUrl: _model.uploadedFileUrl_uploadDataO6s,
            existingUrl: record.img,
            localBytes: _model.uploadedLocalFile_uploadDataO6s.bytes,
          ),
        ),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم حفظ التعديلات بنجاح'),
        refreshScope: AdminListScope.regions,
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

  Future<void> _delete(CitiesRecord record) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appTr(context, 'adm_delete_confirm_title')),
            content: const Text(
              'عند حذف المنطقة سيتم حذف كل المدن والمعالم المرتبطة. هل أنت متأكد؟',
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
      await deleteRegionCascade(record.reference);
      await AdminAuditLog.recordDelete(
        targetType: 'region',
        targetId: record.reference.id,
        targetLabel: record.naim,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف المنطقة وكل البيانات المرتبطة'),
        refreshScope: AdminListScope.regions,
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
    context.watch<FFAppState>();

    return StreamBuilder<CitiesRecord>(
      stream: CitiesRecord.getDocument(widget.idreg!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AdminEditScaffold(
            title: uiTr(context, 'تعديل المنطقة'),
            isLoading: true,
            child: SizedBox.shrink(),
          );
        }

        final record = snapshot.data!;
        _model.bindCitiesRecord(record);
        _syncCountryFromRecord(record);

        final countryLabel = FFAppState().RevdolhTEXT.isNotEmpty
            ? FFAppState().RevdolhTEXT
            : (_model.countryLabel ?? '');

        return AdminEditScaffold(
          title: uiTr(context, 'تعديل المنطقة'),
          subtitle: uiTr(context, 'حدّث بيانات المنطقة وربطها بالدولة'),
          child: AdminEditFormCard(
            children: [
              AdminEditPickerRow(
                label: uiTr(context, 'الدولة'),
                value: countryLabel,
                placeholder: uiTr(context, 'اختر الدولة'),
                onTap: () async {
                  await showAdminPickerSheet(
                    context: context,
                    child: const AdminCountryPickerSheet(),
                  );
                  if (mounted) {
                    setState(() {
                      _model.countryLabel = FFAppState().RevdolhTEXT;
                    });
                  }
                },
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textFieldnaimTextController!,
                focusNode: _model.textFieldnaimFocusNode,
                label: uiTr(context, 'اسم المنطقة'),
                icon: Icons.filter_hdr_rounded,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textFieldDescTextController!,
                focusNode: _model.textFieldDescFocusNode,
                label: uiTr(context, 'وصف المنطقة'),
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminEditSwitchRow(
                label: uiTr(context, 'تفعيل المنطقة'),
                subtitle: uiTr(context, 'تظهر المنطقة للمستخدمين عند التفعيل'),
                value: _model.switchValue ?? record.acctev,
                onChanged: (v) => setState(() => _model.switchValue = v),
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminEditableImageCard(
                imageUrl: _model.uploadedFileUrl_uploadDataO6s,
                localBytes: _model.uploadedLocalFile_uploadDataO6s.bytes,
                isUploading: _model.isDataUploading_uploadDataO6s,
                hint: 'اختر صورة المنطقة من المعرض أو الكاميرا',
                onPick: _pickRegionImage,
              ),
            ],
          ),
          floatingAction: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: (_isSaving || _isDeleting)
                    ? null
                    : () => _delete(record),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                label: const Text(
                  'حذف المنطقة',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
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

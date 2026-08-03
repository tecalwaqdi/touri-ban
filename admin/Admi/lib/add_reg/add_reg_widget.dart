import '/core/i18n/admin_i18n_save_helper.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_reg_model.dart';
export 'add_reg_model.dart';

class AddRegWidget extends StatefulWidget {
  const AddRegWidget({super.key});

  static String routeName = 'AddReg';
  static String routePath = '/addReg';

  @override
  State<AddRegWidget> createState() => _AddRegWidgetState();
}

class _AddRegWidgetState extends State<AddRegWidget> {
  late AddRegModel _model;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddRegModel());

    _model.textFieldnaimTextController ??= TextEditingController();
    _model.textFieldnaimFocusNode ??= FocusNode();
    _model.textFieldDescTextController ??= TextEditingController();
    _model.textFieldDescFocusNode ??= FocusNode();
    _model.switchValue = true;

    AdminAgentCountryLock.applyToAppState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AdminAgentCountryLock.ensureCountryResolved();
      if (mounted) safeSetState(() {});
    });
  }

  bool get _countryLocked => AdminRoleService.isCountryAgent;

  String get _countryDisplay =>
      FFAppState().RevdolhTEXT.trim().isNotEmpty
          ? FFAppState().RevdolhTEXT
          : '';

  Future<void> _pickCountry() async {
    await showAdminPickerSheet(
      context: context,
      child: const AdminCountryPickerSheet(),
    );
    if (mounted) safeSetState(() {});
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickRegionImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'regions/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataO6sc = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataO6sc = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataO6sc = url),
      );

  Future<void> _saveRegion() async {
    final name = _model.textFieldnaimTextController!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_enter_region_name'))),
      );
      return;
    }
    if (FFAppState().RevDolh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_select_country'))),
      );
      return;
    }

    final countryRef =
        AdminCountryScope.mkanCountryRefForSave() ?? FFAppState().RevDolh;

    if (_model.isDataUploading_uploadDataO6sc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_wait_image_upload'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final img = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_uploadDataO6sc,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_uploadDataO6sc.bytes,
      );

      final desc = _model.textFieldDescTextController!.text.trim();
      final namesMap = await adminEnsureI18nMap(
        context: context,
        sourceText: name,
        fieldLabel: 'region name',
      );
      final osfMap = await adminEnsureI18nMap(
        context: context,
        sourceText: desc,
        fieldLabel: 'region description',
      );

      await CitiesRecord.collection.doc().set(
            createCitiesRecordData(
              naim: adminLegacyFromI18n(namesMap, name),
              osf: adminLegacyFromI18n(osfMap, desc),
              namesI18n: namesMap,
              osfI18n: osfMap,
              dolh: countryRef,
              img: img,
              acctev: _model.switchValue,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_region_added'))),
      );
      context.safePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminCrudFeedback.saveFailed(context, e))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminEditScaffold(
        title: appTr(context, 'adm_add_region_title'),
        subtitle: _countryLocked
            ? appTr(context, 'adm_add_region_subtitle_agent')
            : appTr(context, 'adm_add_region_subtitle'),
        isLoading: _isSaving,
        floatingAction: AdminPrimaryButton(
          label: appTr(context, 'adm_save_region'),
          icon: Icons.map_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveRegion,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: appTr(context, 'adm_country'),
              children: [
                AdminEditPickerRow(
                  label: appTr(context, 'adm_country'),
                  value: _countryDisplay,
                  placeholder: appTr(context, 'adm_pick_country'),
                  locked: _countryLocked,
                  onTap: _pickCountry,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: appTr(context, 'adm_region_image'),
              children: [
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_uploadDataO6sc,
                  localBytes: _model.uploadedLocalFile_uploadDataO6sc.bytes,
                  isUploading: _model.isDataUploading_uploadDataO6sc,
                  hint: appTr(context, 'adm_pick_region_image'),
                  onPick: _pickRegionImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: appTr(context, 'adm_basic_data'),
              children: [
                TextFormField(
                  controller: _model.textFieldnaimTextController,
                  focusNode: _model.textFieldnaimFocusNode,
                  decoration: InputDecoration(
                    labelText: appTr(context, 'adm_region_name_label'),
                    hintText: appTr(context, 'adm_region_name_hint'),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textFieldDescTextController,
                  focusNode: _model.textFieldDescFocusNode,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: appTr(context, 'adm_region_desc_label'),
                    hintText: appTr(context, 'adm_short_desc'),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                AdminEditSwitchRow(
                  label: appTr(context, 'adm_activate_region'),
                  subtitle: appTr(context, 'adm_region_visible_hint'),
                  value: _model.switchValue ?? true,
                  onChanged: (v) => safeSetState(() => _model.switchValue = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

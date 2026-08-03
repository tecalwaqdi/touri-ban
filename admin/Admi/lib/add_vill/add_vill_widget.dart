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
import 'add_vill_model.dart';
export 'add_vill_model.dart';

class AddVillWidget extends StatefulWidget {
  const AddVillWidget({super.key});

  static String routeName = 'addVill';
  static String routePath = '/addVill';

  @override
  State<AddVillWidget> createState() => _AddVillWidgetState();
}

class _AddVillWidgetState extends State<AddVillWidget> {
  late AddVillModel _model;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddVillModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.switchValue = true;

    AdminAgentCountryLock.applyToAppState();
    FFAppState().Revreg = null;
    FFAppState().RevRegTEXT = '';
    clearCitySelection();

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

  String get _regionDisplay =>
      FFAppState().Revreg != null ? FFAppState().RevRegTEXT : '';

  DocumentReference? get _activeCountryRef =>
      FFAppState().RevDolh ?? AdminCountryScope.activeCountryRef;

  Future<void> _pickCountry() async {
    await showAdminPickerSheet(
      context: context,
      child: const AdminCountryPickerSheet(),
    );
    if (mounted) safeSetState(() {});
  }

  Future<void> _pickRegion() async {
    final country = _activeCountryRef;
    if (country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_select_country_first'))),
      );
      return;
    }
    await showAdminPickerSheet(
      context: context,
      child: AdminRegionPickerSheet(countryRef: country),
    );
    if (mounted) safeSetState(() {});
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickCityImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'cities/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataWt55 = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataWt55 = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataWt55 = url),
      );

  Future<void> _saveCity() async {
    if (FFAppState().RevDolh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_select_country'))),
      );
      return;
    }
    if (FFAppState().Revreg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_select_region'))),
      );
      return;
    }

    final name = _model.textController1!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_enter_city_name'))),
      );
      return;
    }

    if (_model.isDataUploading_uploadDataWt55) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_wait_image_upload'))),
      );
      return;
    }

    final countryRef =
        AdminCountryScope.mkanCountryRefForSave() ?? FFAppState().RevDolh;

    setState(() => _isSaving = true);

    try {
      final img = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_uploadDataWt55,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_uploadDataWt55.bytes,
      );

      final desc = _model.textController2!.text.trim();
      final namesMap = await adminEnsureI18nMap(
        context: context,
        sourceText: name,
        fieldLabel: 'city name',
      );
      final osfMap = await adminEnsureI18nMap(
        context: context,
        sourceText: desc,
        fieldLabel: 'city description',
      );

      await VillagesRecord.collection.doc().set(
            createVillagesRecordData(
              cities: FFAppState().Revreg,
              dolh: countryRef,
              naim: adminLegacyFromI18n(namesMap, name),
              osf: adminLegacyFromI18n(osfMap, desc),
              namesI18n: namesMap,
              osfI18n: osfMap,
              acctev: _model.switchValue,
              img: img,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appTr(context, 'adm_city_added'))),
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
        title: appTr(context, 'adm_add_city_title'),
        subtitle: _countryLocked
            ? appTr(context, 'adm_add_city_subtitle_agent')
            : appTr(context, 'adm_add_city_subtitle'),
        isLoading: _isSaving,
        floatingAction: AdminPrimaryButton(
          label: appTr(context, 'adm_save_city'),
          icon: Icons.location_city_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveCity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: appTr(context, 'adm_location'),
              children: [
                AdminEditPickerRow(
                  label: appTr(context, 'adm_country'),
                  value: _countryDisplay,
                  placeholder: appTr(context, 'adm_pick_country'),
                  locked: _countryLocked,
                  onTap: _pickCountry,
                ),
                const SizedBox(height: 14),
                AdminEditPickerRow(
                  label: appTr(context, 'adm_region'),
                  value: _regionDisplay,
                  placeholder: appTr(context, 'adm_pick_region'),
                  onTap: _pickRegion,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: appTr(context, 'adm_city_image'),
              children: [
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_uploadDataWt55,
                  localBytes: _model.uploadedLocalFile_uploadDataWt55.bytes,
                  isUploading: _model.isDataUploading_uploadDataWt55,
                  hint: appTr(context, 'adm_pick_city_image'),
                  onPick: _pickCityImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: appTr(context, 'adm_basic_data'),
              children: [
                TextFormField(
                  controller: _model.textController1,
                  focusNode: _model.textFieldFocusNode1,
                  decoration: InputDecoration(
                    labelText: appTr(context, 'adm_city_name_label'),
                    hintText: appTr(context, 'adm_city_name_hint'),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController2,
                  focusNode: _model.textFieldFocusNode2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: appTr(context, 'adm_city_desc_label'),
                    hintText: appTr(context, 'adm_city_desc_hint'),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                AdminEditSwitchRow(
                  label: appTr(context, 'adm_activate_city'),
                  subtitle: appTr(context, 'adm_city_visible_hint'),
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

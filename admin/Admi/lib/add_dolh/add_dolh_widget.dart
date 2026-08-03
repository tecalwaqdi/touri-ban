import 'dart:async';

import '/core/i18n/admin_i18n_save_helper.dart';
import '/backend/admin_country_geo_service.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import 'package:flutter/material.dart';
import 'add_dolh_model.dart';
export 'add_dolh_model.dart';

class AddDolhWidget extends StatefulWidget {
  const AddDolhWidget({super.key});

  static String routeName = 'AddDolh';
  static String routePath = '/addDolh';

  @override
  State<AddDolhWidget> createState() => _AddDolhWidgetState();
}

class _AddDolhWidgetState extends State<AddDolhWidget> {
  late AddDolhModel _model;
  bool _isSaving = false;
  bool _isResolvingGeo = false;
  AdminCountryGeoData? _resolvedGeo;
  final _countryMapController = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddDolhModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textController3 ??= TextEditingController(text: '0');
    _model.textFieldFocusNode3 ??= FocusNode();
    _model.textController4 ??= TextEditingController(text: '0');
    _model.textFieldFocusNode4 ??= FocusNode();
    _model.textController5 ??= TextEditingController();
    _model.textFieldFocusNode5 ??= FocusNode();
    _model.switchValue = true;

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickCountryImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'countries/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataX8mc = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataX8mc = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataX8mc = url),
      );

  Future<AdminCountryGeoData?> _resolveCountryGeo({
    bool showError = true,
  }) async {
    final name = _model.textController1!.text.trim();
    final isoRaw = _model.textController5!.text.trim();
    if (name.isEmpty && isoRaw.length != 2) return null;

    setState(() => _isResolvingGeo = true);
    try {
      final geo = isoRaw.length == 2
          ? await AdminCountryGeoService.fetchForIsoCode(isoRaw)
          : await AdminCountryGeoService.fetchForCountryName(name);
      if (geo?.center == null || geo?.hasBounds != true) {
        if (showError && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                uiTr(context,
                    'تعذر تحميل خريطة الدولة. أدخل رمز ISO الصحيح ثم حاول مرة أخرى.'),
              ),
            ),
          );
        }
        return null;
      }
      if (mounted) setState(() => _resolvedGeo = geo);
      return geo;
    } finally {
      if (mounted) setState(() => _isResolvingGeo = false);
    }
  }

  Future<void> _saveCountry() async {
    final name = _model.textController1!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى إدخال اسم الدولة'))),
      );
      return;
    }

    if (_model.isDataUploading_uploadDataX8mc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(uiTr(context, 'انتظر اكتمال رفع الصورة ثم احفظ'))),
      );
      return;
    }

    final geo = await _resolveCountryGeo();
    if (geo == null) return;

    setState(() => _isSaving = true);

    try {
      final img = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_uploadDataX8mc,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_uploadDataX8mc.bytes,
      );

      final namesMap = await adminEnsureI18nMap(
        context: context,
        sourceText: name,
        fieldLabel: 'country name',
        existing: {
          if (geo.englishName != null && geo.englishName!.trim().isNotEmpty)
            'en': geo.englishName!.trim(),
        },
      );

      final countryData = createCountriesRecordData(
        naim: adminLegacyFromI18n(namesMap, name),
        osf: _model.textController2!.text.trim(),
        acctev: _model.switchValue,
        img: img,
        vatPercent: double.tryParse(_model.textController3!.text.trim()) ?? 0,
        appCommissionPercent:
            double.tryParse(_model.textController4!.text.trim()) ?? 0,
        naimEnglesh: geo.englishName,
        isoCode: geo.isoCode,
        geoCenter: geo.center,
        boundsSw: geo.boundsSouthWest,
        boundsNe: geo.boundsNorthEast,
        namesI18n: namesMap,
      );

      await CountriesRecord.collection.doc().set(countryData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'تم إضافة الدولة بنجاح'))),
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
    if (AdminSuperAdminGate.isProfileLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(uiTr(context, 'إضافة دولة'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!AdminSuperAdminGate.isAllowed) {
      return AdminSuperAdminGate.deniedEditScaffold(
        context: context,
        title: uiTr(context, 'إضافة دولة'),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminEditScaffold(
        title: uiTr(context, 'إضافة دولة جديدة'),
        subtitle: uiTr(context, 'أدخل بيانات الدولة لإضافتها إلى النظام'),
        isLoading: _isSaving,
        floatingAction: AdminPrimaryButton(
          label: uiTr(context, 'حفظ الدولة'),
          icon: Icons.public_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveCountry,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'صورة الدولة'),
              children: [
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_uploadDataX8mc,
                  localBytes: _model.uploadedLocalFile_uploadDataX8mc.bytes,
                  isUploading: _model.isDataUploading_uploadDataX8mc,
                  hint: 'اضغط لاختيار صورة الدولة',
                  onPick: _pickCountryImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: uiTr(context, 'البيانات الأساسية'),
              children: [
                TextFormField(
                  controller: _model.textController1,
                  focusNode: _model.textFieldFocusNode1,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'اسم الدولة'),
                    hintText: uiTr(context, 'مثال: المملكة العربية السعودية'),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isResolvingGeo
                      ? null
                      : () async {
                          await _resolveCountryGeo();
                        },
                  icon: _isResolvingGeo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.map_rounded),
                  label: Text(uiTr(context, 'تحميل ومعاينة خريطة الدولة')),
                ),
                if (_resolvedGeo?.center != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 220,
                      child: FlutterFlowGoogleMap(
                        controller: _countryMapController,
                        initialLocation: _resolvedGeo!.center,
                        markers: const [],
                        markerColor: GoogleMarkerColor.red,
                        mapType: MapType.normal,
                        style: GoogleMapStyle.standard,
                        initialZoom: 4,
                        allowInteraction: true,
                        allowZoom: true,
                        showZoomControls: true,
                        showLocation: false,
                        showCompass: true,
                        showMapToolbar: false,
                        showTraffic: false,
                        centerMapOnMarkerTap: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${uiTr(context, 'مركز الخريطة')}: '
                    '${_resolvedGeo!.center!.latitude.toStringAsFixed(4)}, '
                    '${_resolvedGeo!.center!.longitude.toStringAsFixed(4)}',
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController2,
                  focusNode: _model.textFieldFocusNode2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'وصف الدولة (اختياري)'),
                    hintText: uiTr(context, 'وصف مختصر عن الدولة'),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController5,
                  focusNode: _model.textFieldFocusNode5,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'رمز الدولة ISO (اختياري)'),
                    hintText: uiTr(context, 'مثال: SA أو AE'),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController3,
                  focusNode: _model.textFieldFocusNode3,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'نسبة الضريبة (%)'),
                    hintText: uiTr(context, 'مثال: 15'),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController4,
                  focusNode: _model.textFieldFocusNode4,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: uiTr(context, 'نسبة أرباح التطبيق (%)'),
                    hintText: uiTr(context, 'مثال: 10'),
                  ),
                ),
                const SizedBox(height: 14),
                AdminEditSwitchRow(
                  label: uiTr(context, 'تفعيل الدولة'),
                  subtitle: uiTr(context, 'تظهر الدولة في التطبيق عند التفعيل'),
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

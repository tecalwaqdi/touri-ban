import '/backend/admin_agent_country_lock.dart';
import '/core/admin_content_locale.dart';
import '/components/admin_i18n_fields.dart';
import '/core/i18n/toury_i18n_text.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_location_section.dart';
import '/components/admin_location_service.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'adminadd_mkan_model.dart';
export 'adminadd_mkan_model.dart';

class AdminaddMkanWidget extends StatefulWidget {
  const AdminaddMkanWidget({super.key});

  static String routeName = 'AdminaddMkan';
  static String routePath = '/adminaddMkan';

  @override
  State<AdminaddMkanWidget> createState() => _AdminaddMkanWidgetState();
}

class _AdminaddMkanWidgetState extends State<AdminaddMkanWidget> {
  late AdminaddMkanModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSaving = false;
  late final AdminI18nFieldsController _nameI18n;
  late final AdminI18nFieldsController _descI18n;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminaddMkanModel());
    _nameI18n = AdminI18nFieldsController();
    _descI18n = AdminI18nFieldsController();

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.switchMosqueValue = true;
    _model.switchRestroomValue = true;
    _model.switchrestaurantValue = true;
    _model.switchValue = true;
    _model.switchACCTEVValue = true;

    AdminAgentCountryLock.applyToAppState();
    clearCitySelection();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AdminAgentCountryLock.ensureCountryResolved();
      if (mounted) safeSetState(() {});
    });
  }

  String _cityPickerLabel() {
    if (FFAppState().REvCITE != null &&
        FFAppState().RevciteTEXT.trim().isNotEmpty) {
      return FFAppState().RevciteTEXT;
    }
    return 'اختر المدينة';
  }

  Widget _buildCountryField(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final countryLabel = valueOrDefault<String>(
      FFAppState().RevdolhTEXT,
      'يرجى تحديد الدولة',
    );
    final lockedForAgent = AdminRoleService.isCountryAgent;

    final fieldBody = Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                countryLabel,
                style: theme.bodyLarge.override(
                  fontFamily: theme.bodyLargeFamily,
                  letterSpacing: 0.0,
                  useGoogleFonts: !theme.bodyLargeIsCustom,
                ),
              ),
            ),
            Icon(
              lockedForAgent ? Icons.lock_outline : Icons.arrow_drop_down,
              color: theme.secondaryText,
              size: 24.0,
            ),
          ],
        ),
      ),
    );

    if (lockedForAgent) {
      return fieldBody;
    }

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        await showAdminPickerSheet(
          context: context,
          child: const AdminCountryPickerSheet(),
        );
        if (mounted) safeSetState(() {});
      },
      child: fieldBody,
    );
  }

  @override
  void dispose() {
    _nameI18n.dispose();
    _descI18n.dispose();
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickMkanImage1() => handleAdminImagePick(
        context: context,
        storageFolder: 'landmarks/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataCanhome = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataCanhome = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataCanhome = url),
      );

  Future<void> _pickMkanImage2() => handleAdminImagePick(
        context: context,
        storageFolder: 'landmarks/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataP4b = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataP4b = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataP4b = url),
      );

  Future<void> _pickMkanImage3() => handleAdminImagePick(
        context: context,
        storageFolder: 'landmarks/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadData8dqs = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadData8dqs = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadData8dqs = url),
      );

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: true,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            buttonSize: 48.0,
            icon: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).info,
              size: 24.0,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'hstjsbt4' /* Add Tourism Landmark */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                  color: FlutterFlowTheme.of(context).info,
                  letterSpacing: 0.0,
                  useGoogleFonts:
                      !FlutterFlowTheme.of(context).headlineMediumIsCustom,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: AdminSafeScrollBody(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 20.0, 20.0, 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                '0cda3xf5' /* Basic Information */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            TextFormField(
                              controller: _model.textController1,
                              focusNode: _model.textFieldFocusNode1,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  '38g8lj6w' /* Landmark Name */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              minLines: 1,
                              validator: _model.textController1Validator
                                  .asValidator(context),
                            ),
                            TextFormField(
                              controller: _model.textController2,
                              focusNode: _model.textFieldFocusNode2,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: FFLocalizations.of(context).getText(
                                  '4clqokaq' /* Description */,
                                ),
                                labelStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyLargeFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyLargeIsCustom,
                                  ),
                              maxLines: 5,
                              minLines: 3,
                              validator: _model.textController2Validator
                                  .asValidator(context),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                    child: AdminI18nFieldsSection(
                      title: uiTr(context, 'اسم المعلم — جميع اللغات'),
                      hint: uiTr(context, 'اسم المعلم'),
                      controller: _nameI18n,
                      legacyController: _model.textController1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                    child: AdminI18nFieldsSection(
                      title: uiTr(context, 'وصف المعلم — جميع اللغات'),
                      hint: uiTr(context, 'وصف المعلم'),
                      controller: _descI18n,
                      legacyController: _model.textController2,
                      minLines: 2,
                      maxLines: 6,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 20.0, 20.0, 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'okgekccp' /* Images */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                'tg2kf523' /* الصورة الرئيسية */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .bodyMediumFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .bodyMediumIsCustom,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                adminImagePreview(
                                  imageUrl:
                                      _model.uploadedFileUrl_uploadDataCanhome,
                                  localBytes: _model
                                      .uploadedLocalFile_uploadDataCanhome.bytes,
                                  width: 200,
                                  height: 200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ],
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: _pickMkanImage1,
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  '8x03e9zw' /* Edet */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .bodyMediumFamily,
                                      letterSpacing: 0.0,
                                      decoration: TextDecoration.underline,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .bodyMediumIsCustom,
                                    ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: _pickMkanImage2,
                                  child: Stack(
                                    alignment: AlignmentDirectional(0, 0),
                                    children: [
                                      Container(
                                        width: 100.0,
                                        height: 100.0,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF5F5F5),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: adminImagePreview(
                                          imageUrl: _model
                                              .uploadedFileUrl_uploadDataP4b,
                                          localBytes: _model
                                              .uploadedLocalFile_uploadDataP4b
                                              .bytes,
                                          width: 100,
                                          height: 100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      if (_model.uploadedFileUrl_uploadDataP4b
                                              .isEmpty &&
                                          (_model.uploadedLocalFile_uploadDataP4b
                                                  .bytes?.isEmpty ??
                                              true))
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 32.0,
                                        ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: _pickMkanImage3,
                                  child: Stack(
                                    alignment: AlignmentDirectional(0, 0),
                                    children: [
                                      Container(
                                        width: 100.0,
                                        height: 100.0,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF5F5F5),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: adminImagePreview(
                                          imageUrl: _model
                                              .uploadedFileUrl_uploadData8dqs,
                                          localBytes: _model
                                              .uploadedLocalFile_uploadData8dqs
                                              .bytes,
                                          width: 100,
                                          height: 100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      if (_model.uploadedFileUrl_uploadData8dqs
                                              .isEmpty &&
                                          (_model
                                                  .uploadedLocalFile_uploadData8dqs
                                                  .bytes
                                                  ?.isEmpty ??
                                              true))
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 32.0,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 20.0, 20.0, 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'c5c1wogi' /* Location */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            AdminLocationSection(
                              place: _model.placePickerValue,
                              mapController: _model.googleMapsController,
                              initialCenter: _model.googleMapsCenter,
                              onPlaceChanged: (place) {
                                safeSetState(() {
                                  _model.placePickerValue = place;
                                  _model.googleMapsCenter = place.latLng;
                                });
                              },
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 20.0, 20.0, 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                '1p8e445v' /* Features & Amenities */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: FlutterFlowTheme.of(context)
                                        .headlineSmallFamily,
                                    letterSpacing: 0.0,
                                    useGoogleFonts:
                                        !FlutterFlowTheme.of(context)
                                            .headlineSmallIsCustom,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'ea50zwow' /* Has Mosque */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyLargeFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyLargeIsCustom,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchMosqueValue!,
                                  onChanged: (newValue) async {
                                    safeSetState(() =>
                                        _model.switchMosqueValue = newValue);
                                  },
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  activeTrackColor: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  inactiveTrackColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  inactiveThumbColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'vdq40u4i' /* Has Restroom */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyLargeFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyLargeIsCustom,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchRestroomValue!,
                                  onChanged: (newValue) async {
                                    safeSetState(() =>
                                        _model.switchRestroomValue = newValue);
                                  },
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  activeTrackColor: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  inactiveTrackColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  inactiveThumbColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'sopmyks6' /* Has Restaurant */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyLargeFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyLargeIsCustom,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchrestaurantValue!,
                                  onChanged: (newValue) async {
                                    safeSetState(() => _model
                                        .switchrestaurantValue = newValue);
                                  },
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  activeTrackColor: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  inactiveTrackColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  inactiveThumbColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '7385vkay' /* Is it an advertisement? */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyLargeFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyLargeIsCustom,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchValue!,
                                  onChanged: (newValue) async {
                                    safeSetState(
                                        () => _model.switchValue = newValue);
                                  },
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  activeTrackColor: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  inactiveTrackColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  inactiveThumbColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryText,
                                ),
                              ],
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 20.0, 20.0, 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'msl7rlmm' /* Additional Details */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      fontFamily: FlutterFlowTheme.of(context)
                                          .headlineSmallFamily,
                                      letterSpacing: 0.0,
                                      useGoogleFonts:
                                          !FlutterFlowTheme.of(context)
                                              .headlineSmallIsCustom,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: _buildCountryField(context),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (FFAppState().RevDolh == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(uiTr(context, 'يرجى اختيار الدولة أولاً')),
                                      ),
                                    );
                                    return;
                                  }
                                  await showAdminPickerSheet(
                                    context: context,
                                    child: AdminRegionPickerSheet(
                                      countryRef: FFAppState().RevDolh,
                                    ),
                                  );
                                  if (mounted) safeSetState(() {});
                                },
                                child: Container(
                                  width: MediaQuery.sizeOf(context).width * 1.0,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 16.0, 16.0, 16.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          valueOrDefault<String>(
                                            FFAppState().RevRegTEXT,
                                            'يرجى تحديد المنطقة / المحافظة',
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLargeFamily,
                                                letterSpacing: 0.0,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyLargeIsCustom,
                                              ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 24.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  await showAdminPickerSheet(
                                    context: context,
                                    child: AdminCityPickerSheet(
                                      countryRef: FFAppState().RevDolh,
                                    ),
                                  );
                                  if (mounted) safeSetState(() {});
                                },
                                child: Container(
                                  width: MediaQuery.sizeOf(context).width * 1.0,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 16.0, 16.0, 16.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _cityPickerLabel(),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLargeFamily,
                                                letterSpacing: 0.0,
                                                color: FFAppState().REvCITE ==
                                                        null
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText
                                                    : FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                useGoogleFonts:
                                                    !FlutterFlowTheme.of(
                                                            context)
                                                        .bodyLargeIsCustom,
                                              ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 24.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'cni6ckkq' /* Active Status */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLargeFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .bodyLargeIsCustom,
                                        ),
                                  ),
                                  Switch(
                                    value: _model.switchACCTEVValue!,
                                    onChanged: (newValue) async {
                                      safeSetState(() =>
                                          _model.switchACCTEVValue = newValue);
                                    },
                                    activeColor:
                                        FlutterFlowTheme.of(context).primary,
                                    activeTrackColor:
                                        FlutterFlowTheme.of(context)
                                            .secondaryText,
                                    inactiveTrackColor:
                                        FlutterFlowTheme.of(context)
                                            .secondaryText,
                                    inactiveThumbColor:
                                        FlutterFlowTheme.of(context)
                                            .secondaryText,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'li0w5pwl' /* Rating */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLargeFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .bodyLargeIsCustom,
                                        ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: List.generate(5, (index) {
                                      final starValue = index + 1;
                                      final filled =
                                          _model.ratingValue >= starValue;
                                      return InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          safeSetState(() {
                                            if (_model.ratingValue ==
                                                starValue.toDouble()) {
                                              _model.ratingValue =
                                                  (starValue - 1).toDouble();
                                            } else {
                                              _model.ratingValue =
                                                  starValue.toDouble();
                                            }
                                          });
                                        },
                                        child: Icon(
                                          filled
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Color(0xFFFFD700),
                                          size: 32.0,
                                        ),
                                      );
                                    }).divide(SizedBox(width: 4.0)),
                                  ),
                                ].divide(SizedBox(width: 8.0)),
                              ),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  FFButtonWidget(
                    onPressed: _isSaving
                        ? null
                        : () async {
                      final name = _model.textController1.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(uiTr(context, 'يرجى إدخال اسم المعلم')),
                          ),
                        );
                        return;
                      }
                      if (FFAppState().REvCITE == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(uiTr(context, 'يرجى اختيار المدينة')),
                          ),
                        );
                        return;
                      }

                      if (_model.isDataUploading_uploadDataCanhome ||
                          _model.isDataUploading_uploadDataP4b ||
                          _model.isDataUploading_uploadData8dqs) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(uiTr(context, 'انتظر اكتمال رفع الصور ثم احفظ')),
                          ),
                        );
                        return;
                      }

                      final location = AdminLocationService.isValidLocation(
                            _model.placePickerValue.latLng)
                        ? _model.placePickerValue.latLng
                        : _model.googleMapsCenter;
                      if (location == null ||
                          !AdminLocationService.isValidLocation(location)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(uiTr(context, 'يرجى تحديد موقع المعلم على الخريطة')),
                          ),
                        );
                        return;
                      }

                      try {
                        setState(() => _isSaving = true);
                        await AdminAgentCountryLock.ensureCountryResolved();
                        final countryRef = AdminCountryScope.mkanCountryRefForSave();
                        if (countryRef == null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(uiTr(context, 'يرجى اختيار الدولة أولاً')),
                              ),
                            );
                            setState(() => _isSaving = false);
                          }
                          return;
                        }
                        final img1 = await resolveImageForFirestoreSave(
                          pickedUrl:
                              _model.uploadedFileUrl_uploadDataCanhome,
                          existingUrl: '',
                          localBytes: _model
                              .uploadedLocalFile_uploadDataCanhome.bytes,
                        );
                        final img2 = await resolveImageForFirestoreSave(
                          pickedUrl: _model.uploadedFileUrl_uploadDataP4b,
                          existingUrl: '',
                          localBytes:
                              _model.uploadedLocalFile_uploadDataP4b.bytes,
                        );
                        final img3 = await resolveImageForFirestoreSave(
                          pickedUrl: _model.uploadedFileUrl_uploadData8dqs,
                          existingUrl: '',
                          localBytes:
                              _model.uploadedLocalFile_uploadData8dqs.bytes,
                        );

                        final sourceLocale = adminContentLocaleKey(context);
                        _nameI18n.syncPrimary(sourceLocale, name);
                        _descI18n.syncPrimary(
                          sourceLocale,
                          _model.textController2.text.trim(),
                        );
                        final namesMap = touryBuildI18nMap(
                          values: _nameI18n.toMap(),
                          sourceLocale: sourceLocale,
                          sourceText: name,
                        );
                        final osfMap = touryBuildI18nMap(
                          values: _descI18n.toMap(),
                          sourceLocale: sourceLocale,
                          sourceText: _model.textController2.text.trim(),
                        );
                        final legacyNaim = touryPrimaryLegacyText(namesMap, name);
                        final legacyOsf = touryPrimaryLegacyText(
                          osfMap,
                          _model.textController2.text.trim(),
                        );

                        final ref = MkanRecord.collection.doc();
                        await AdminFirestoreDelete.setDocument(
                          ref,
                          {
                            ...createMkanRecordData(
                                naim: legacyNaim,
                                osf: legacyOsf,
                                namesI18n: namesMap,
                                osfI18n: osfMap,
                                img1: img1,
                                ismsgd: _model.switchMosqueValue,
                                idVill: FFAppState().REvCITE,
                                idCit: FFAppState().Revreg,
                                revDolh: countryRef,
                                location: location,
                                address: _model.placePickerValue.address.isNotEmpty
                                    ? _model.placePickerValue.address
                                    : AdminLocationService.formatCoordinates(
                                        location,
                                      ),
                                asAds: _model.switchValue,
                                isfood: _model.switchrestaurantValue,
                                ishmam: _model.switchRestroomValue,
                                img2: img2,
                                img3: img3,
                                acctev: _model.switchACCTEVValue,
                                rate: _model.ratingValue,
                                contentLocale: sourceLocale,
                              ),
                          },
                        );
                        if (!context.mounted) return;
                        await AdminCrudFeedback.success(
                          context,
                          action: AdminCrudAction.add,
                          message: uiTr(context, 'تم إضافة المعلم بنجاح'),
                          refreshScope: AdminListScope.landmarks,
                          popPage: true,
                          deferHeavyWork: false,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        AdminCrudFeedback.error(context, AdminCrudFeedback.saveFailed(context, e));
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                    text: _isSaving
                        ? 'جاري الحفظ...'
                        : FFLocalizations.of(context).getText(
                      'yi8yug3m' /* Add Landmark */,
                    ),
                    options: FFButtonOptions(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 56.0,
                      padding: EdgeInsets.all(8.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle: FlutterFlowTheme.of(context)
                          .titleLarge
                          .override(
                            fontFamily:
                                FlutterFlowTheme.of(context).titleLargeFamily,
                            color: FlutterFlowTheme.of(context).info,
                            letterSpacing: 0.0,
                            useGoogleFonts: !FlutterFlowTheme.of(context)
                                .titleLargeIsCustom,
                          ),
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                  ),
                ].divide(SizedBox(height: 24.0)),
              ),
        ),
      ),
    );
  }
}


import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_landmark_search.dart';
import '/backend/admin_resource_guard.dart';
import '/components/admin_crud_feedback.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/backend.dart';
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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'adminadd_mkan_copy_model.dart';
export 'adminadd_mkan_copy_model.dart';

class AdminaddMkanCopyWidget extends StatefulWidget {
  const AdminaddMkanCopyWidget({
    super.key,
    required this.idmkan,
  });

  final DocumentReference? idmkan;

  static String routeName = 'AdminaddMkanCopy';
  static String routePath = '/adminEdetMkan';

  @override
  State<AdminaddMkanCopyWidget> createState() => _AdminaddMkanCopyWidgetState();
}

class _AdminaddMkanCopyWidgetState extends State<AdminaddMkanCopyWidget> {
  late AdminaddMkanCopyModel _model;
  bool _isSaving = false;
  bool _isDeleting = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminaddMkanCopyModel());
    AdminAgentCountryLock.applyToAppState();

    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textFieldFocusNode2 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _saveMkan(MkanRecord record) async {
    final name = _model.textController1?.text.trim() ?? '';
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'يرجى إدخال اسم المعلم'))),
      );
      return;
    }

      if (FFAppState().REvCITE == null && record.idVill == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiTr(context, 'يرجى اختيار المدينة'))),
        );
        return;
      }

      setState(() => _isSaving = true);
    try {
      await AdminAgentCountryLock.ensureCountryResolved();
      final countryRef = AdminCountryScope.mkanCountryRefForSave();
      final img1 = _model.mainImageRemoved
          ? ''
          : await resolveImageForFirestoreSave(
              pickedUrl: _model.uploadedFileUrl_uploadDataCni,
              existingUrl: record.img1,
              localBytes: _model.uploadedLocalFile_uploadDataCni.bytes,
            );
      final img2 = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_uploadData8dq,
        existingUrl: record.img2,
        localBytes: _model.uploadedLocalFile_uploadData8dq.bytes,
      );

      await AdminFirestoreDelete.updateDocument(
        widget.idmkan!,
        createMkanRecordData(
          naim: name,
          osf: _model.textController2?.text.trim(),
          namesI18n: {
            ...record.namesI18n,
            'ar': name,
          },
          osfI18n: {
            ...record.osfI18n,
            if ((_model.textController2?.text.trim() ?? '').isNotEmpty)
              'ar': _model.textController2!.text.trim(),
          },
          img1: img1,
          img2: img2,
          img3: record.img3,
          sr: record.sr,
          ismsgd: _model.switchMosqueValue ?? record.ismsgd,
          isfood: _model.switchrestaurantValue ?? record.isfood,
          ishmam: _model.switchRestroomValue ?? record.ishmam,
          acctev: _model.switchACCTEVValue ?? record.acctev,
          asAds: _model.switchValue ?? record.asAds,
          isShrek: record.isShrek,
          idclassification: record.idclassification,
          idCit: FFAppState().Revreg ?? record.idCit,
          idVill: FFAppState().REvCITE ?? record.idVill,
          location: AdminLocationService.isValidLocation(
                _model.placePickerValue.latLng)
            ? _model.placePickerValue.latLng
            : (_model.googleMapsCenter ?? record.location),
          userMalk: record.userMalk,
          ser: record.ser,
          address: _model.placePickerValue.address.isNotEmpty
              ? _model.placePickerValue.address
              : (_model.googleMapsCenter != null
                  ? AdminLocationService.formatCoordinates(
                      _model.googleMapsCenter!,
                    )
                  : record.address),
          mdh: record.mdh,
          tsnef: record.tsnef,
          catgory: record.catgory,
          rate: _model.ratingValue,
          addSaat: record.addSaat,
          ismzod: record.ismzod,
          revDolh: countryRef ?? record.revDolh,
        ),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: uiTr(context, 'تم حفظ التعديلات بنجاح'),
        refreshScope: AdminListScope.landmarks,
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

  Future<void> _pickMainImage() async {
    setState(() => _model.isDataUploading_uploadDataCni = true);
    try {
      final url = await pickAndUploadAdminImage(
        context: context,
        storageFolder: 'landmarks/uploads',
        useContentCompression: true,
        onLocalPreview: (bytes) {
          if (!mounted) return;
          safeSetState(() {
            _model.uploadedLocalFile_uploadDataCni =
                FFUploadedFile(bytes: bytes);
          });
        },
      );
      if (url == null) return;
      safeSetState(() {
        _model.uploadedFileUrl_uploadDataCni = url;
        _model.uploadedLocalFile_uploadDataCni =
            FFUploadedFile(bytes: Uint8List.fromList([]));
        _model.mainImageRemoved = false;
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
        safeSetState(() => _model.isDataUploading_uploadDataCni = false);
      }
    }
  }

  Future<void> _confirmDeleteMainImage() async {
    final localBytes = _model.uploadedLocalFile_uploadDataCni.bytes;
    final hasImage = !_model.mainImageRemoved &&
        (_model.uploadedFileUrl_uploadDataCni.isNotEmpty ||
            (localBytes != null && localBytes.isNotEmpty));
    if (!hasImage) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(uiTr(context, 'حذف الصورة')),
        content: Text(uiTr(context, 'هل تريد حذف الصورة الرئيسية للمعلم؟')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(appTr(context, 'adm_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(uiTr(context, 'حذف')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    safeSetState(() {
      _model.uploadedFileUrl_uploadDataCni = '';
      _model.uploadedLocalFile_uploadDataCni =
          FFUploadedFile(bytes: Uint8List.fromList([]));
      _model.mainImageRemoved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uiTr(context, 'تم حذف الصورة — احفظ التعديلات لتأكيد الحذف'))),
    );
  }

  Future<void> _deleteLandmark(MkanRecord record) async {
    if (!AdminResourceGuard.canEditMkan(record)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr(context, 'لا تملك صلاحية حذف هذا المعلم'))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appTr(context, 'adm_delete_confirm_title')),
            content: Text(uiTr(context, 'هل أنت متأكد من حذف هذا المعلم من قاعدة البيانات؟')),
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
      await AdminFirestoreDelete.deleteDocument(record.reference);
      AdminLandmarkIndex.removeRecord(record);
      await AdminAuditLog.recordDelete(
        targetType: 'landmark',
        targetId: record.reference.id,
        targetLabel: record.naim,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: uiTr(context, 'تم حذف المعلم بنجاح'),
        refreshScope: AdminListScope.landmarks,
        removedDocumentId: record.reference.id,
        popPage: true,
        invalidateStats: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, AdminCrudFeedback.deleteFailed(context, e));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String _mainImageUrl(MkanRecord record) {
    if (_model.mainImageRemoved) return '';
    return _model.uploadedFileUrl_uploadDataCni;
  }

  Future<void> _loadCityLabel(MkanRecord record) async {
    if (_model.cityLabelLoaded || record.idVill == null) {
      return;
    }
    try {
      final city = await VillagesRecord.getDocumentOnce(record.idVill!);
      if (!mounted) return;
      FFAppState().RevciteTEXT = city.naim;
      if (city.cities != null) {
        FFAppState().Revreg = city.cities;
      }
      setState(() => _model.cityLabelLoaded = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return StreamBuilder<MkanRecord>(
      stream: MkanRecord.getDocument(widget.idmkan!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 55.0,
                height: 55.0,
                child: SpinKitThreeBounce(
                  color: FlutterFlowTheme.of(context).primary,
                  size: 55.0,
                ),
              ),
            ),
          );
        }

        final adminaddMkanCopyMkanRecord = snapshot.data!;
        if (!AdminResourceGuard.canEditMkan(adminaddMkanCopyMkanRecord)) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              title: Text(uiTr(context, 'تعديل معلم')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.safePop(),
              ),
            ),
            body: Center(
              child: Text(uiTr(context, 'لا تملك صلاحية تعديل هذا المعلم')),
            ),
          );
        }
        _model.bindMkanRecord(adminaddMkanCopyMkanRecord);
        // ignore: unawaited_futures
        _loadCityLabel(adminaddMkanCopyMkanRecord);

        final cityLabel = FFAppState().RevciteTEXT.isNotEmpty
            ? FFAppState().RevciteTEXT
            : 'اختر المدينة';

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
              backgroundColor: AdminUi.brandTeal,
              automaticallyImplyLeading: false,
              leading: FlutterFlowIconButton(
                buttonSize: 48.0,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24.0,
                ),
                onPressed: () async {
                  context.safePop();
                },
              ),
              title: Text(
                FFLocalizations.of(context).getText(
                  'dfub5lfu' /* Edit location  */,
                ),
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily:
                          FlutterFlowTheme.of(context).headlineMediumFamily,
                      color: Colors.white,
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
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
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
                                    'fhvcl8cg' /* Basic Information */,
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
                                  controller: _model.textController1!,
                                  focusNode: _model.textFieldFocusNode1,
                                  autofocus: false,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText:
                                        FFLocalizations.of(context).getText(
                                      '65gdbbce' /* Landmark Name */,
                                    ),
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .bodyMediumIsCustom,
                                        ),
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
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
                                  controller: _model.textController2!,
                                  focusNode: _model.textFieldFocusNode2,
                                  autofocus: false,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText:
                                        FFLocalizations.of(context).getText(
                                      '17qvg0lb' /* Description */,
                                    ),
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .bodyMediumIsCustom,
                                        ),
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
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
                      Material(
                        color: Colors.transparent,
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Container(
                          width: MediaQuery.sizeOf(context).width * 1.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                20.0, 20.0, 20.0, 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'الصورة الرئيسية',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .titleMediumFamily,
                                        fontWeight: FontWeight.w700,
                                        color: AdminUi.brandTeal,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .titleMediumIsCustom,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                AdminEditableImageCard(
                                  imageUrl: _mainImageUrl(
                                      adminaddMkanCopyMkanRecord),
                                  localBytes: _model
                                      .uploadedLocalFile_uploadDataCni.bytes,
                                  isUploading:
                                      _model.isDataUploading_uploadDataCni,
                                  hint:
                                      'اختر الصورة الرئيسية من المعرض أو الكاميرا',
                                  onPick: _pickMainImage,
                                  onDelete: _confirmDeleteMainImage,
                                  height: 220,
                                ),
                              ],
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
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                20.0, 20.0, 20.0, 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  'الموقع',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .headlineSmallFamily,
                                        fontWeight: FontWeight.w700,
                                        color: AdminUi.brandTeal,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .headlineSmallIsCustom,
                                      ),
                                ),
                                AdminEditPickerRow(
                                  label: uiTr(context, 'المدينة'),
                                  value: cityLabel == 'اختر المدينة'
                                      ? ''
                                      : cityLabel,
                                  placeholder: uiTr(context, 'اختر المدينة'),
                                  onTap: () async {
                                    await showAdminPickerSheet(
                                      context: context,
                                      child: AdminCityPickerSheet(
                                        countryRef: FFAppState().RevDolh,
                                      ),
                                    );
                                    if (mounted) safeSetState(() {});
                                  },
                                ),
                                AdminLocationSection(
                                  place: _model.placePickerValue,
                                  mapController: _model.googleMapsController,
                                  initialCenter: _model.googleMapsCenter ??
                                      adminaddMkanCopyMkanRecord.location,
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
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
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
                                    'p7mzb5r4' /* Features & Amenities */,
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
                                        '9drbsjw2' /* Has Mosque */,
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
                                      value: _model.switchMosqueValue ?? false,
                                      onChanged: (newValue) async {
                                        safeSetState(() => _model
                                            .switchMosqueValue = newValue);
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
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        '703th0to' /* Has Restroom */,
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
                                      value: _model.switchRestroomValue ?? false,
                                      onChanged: (newValue) async {
                                        safeSetState(() => _model
                                            .switchRestroomValue = newValue);
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
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'sd5207uw' /* Has Restaurant */,
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
                                      value: _model.switchrestaurantValue ?? false,
                                      onChanged: (newValue) async {
                                        safeSetState(() => _model
                                            .switchrestaurantValue = newValue);
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
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'm16dquwk' /* Is it an advertisement? */,
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
                                      value: _model.switchValue ?? false,
                                      onChanged: (newValue) async {
                                        safeSetState(() =>
                                            _model.switchValue = newValue);
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
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
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
                                      'uyfp43cd' /* Additional Details */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        FFLocalizations.of(context).getText(
                                          '87gm1qgy' /* Rating */,
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
                                                      (starValue - 1)
                                                          .toDouble();
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
                                          's1u6tug7' /* Active Status */,
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
                                        value: _model.switchACCTEVValue ?? false,
                                        onChanged: (newValue) async {
                                          safeSetState(() => _model
                                              .switchACCTEVValue = newValue);
                                        },
                                        activeColor:
                                            FlutterFlowTheme.of(context)
                                                .primary,
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
                              ].divide(SizedBox(height: 16.0)),
                            ),
                          ),
                        ),
                      ),
                      FFButtonWidget(
                        onPressed: _isSaving
                            ? null
                            : () => _saveMkan(adminaddMkanCopyMkanRecord),
                        text: _isSaving
                            ? 'جاري الحفظ...'
                            : FFLocalizations.of(context).getText(
                                'tsww06ru' /* Edit location  */,
                              ),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsets.all(8.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color: AdminUi.brandTeal,
                          textStyle: FlutterFlowTheme.of(context)
                              .titleLarge
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .titleLargeFamily,
                                color: FlutterFlowTheme.of(context).info,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .titleLargeIsCustom,
                              ),
                          elevation: 3.0,
                          borderRadius: BorderRadius.circular(28.0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: (_isSaving || _isDeleting)
                            ? null
                            : () => _deleteLandmark(adminaddMkanCopyMkanRecord),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red),
                        label: const Text(
                          'حذف المعلم من قاعدة البيانات',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ].divide(SizedBox(height: 24.0)),
                  ),
            ),
          ),
        );
      },
    );
  }
}

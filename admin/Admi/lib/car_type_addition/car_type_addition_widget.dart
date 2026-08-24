import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'car_type_addition_model.dart';
export 'car_type_addition_model.dart';

/// Car Type Addition Form:
///
/// Car Name
/// Hourly Rate
/// Minimum Booking Hours
/// Service Area
class CarTypeAdditionWidget extends StatefulWidget {
  const CarTypeAdditionWidget({super.key});

  static String routeName = 'CarTypeAddition';
  static String routePath = '/carTypeAddition';

  @override
  State<CarTypeAdditionWidget> createState() => _CarTypeAdditionWidgetState();
}

class _CarTypeAdditionWidgetState extends State<CarTypeAdditionWidget> {
  late CarTypeAdditionModel _model;
  late final TextEditingController _englishNameController;
  late final TextEditingController _russianNameController;
  late final TextEditingController _kyrgyzNameController;
  late final TextEditingController _codeController;
  DocumentReference? _selectedCountryRef;
  String _selectedCountryIso = '';

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CarTypeAdditionModel());
    _englishNameController = TextEditingController();
    _russianNameController = TextEditingController();
    _kyrgyzNameController = TextEditingController();
    _codeController = TextEditingController();

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    _model.switchValue1 = true;
    _model.switchValue2 = true;
    _model.switchValue3 = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    _englishNameController.dispose();
    _russianNameController.dispose();
    _kyrgyzNameController.dispose();
    _codeController.dispose();

    super.dispose();
  }

  Future<void> _pickCarImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'type_car/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_carImage = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_carImage = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_carImage = url),
      );

  String _carFeaturesNote() {
    final parts = <String>[];
    if (_model.switchValue2 == true) {
      parts.add('GPS');
    }
    if (_model.switchValue3 == true) {
      parts.add('Bluetooth');
    }
    return parts.join(', ');
  }

  String _slugifyCode(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized;
  }

  Map<String, String> _buildNamesI18n(String ar, String en, String ru, String ky) {
    return <String, String>{
      if (ar.isNotEmpty) 'ar': ar,
      if (en.isNotEmpty) 'en': en,
      if (ru.isNotEmpty) 'ru': ru,
      if (ky.isNotEmpty) 'ky': ky,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              '8t3b7zsr' /* Add Car Type */,
            ),
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).labelMediumFamily,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  useGoogleFonts:
                      !FlutterFlowTheme.of(context).labelMediumIsCustom,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        resizeToAvoidBottomInset: true,
        body: AdminSafeScrollBody(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            'el95zyo9' /* Car Information */,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .headlineSmallFamily,
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .headlineSmallIsCustom,
                              ),
                        ),
                        StreamBuilder<List<CountriesRecord>>(
                          stream: queryCountriesRecord(
                            queryBuilder: (q) =>
                                q.where('acctev', isEqualTo: true),
                          ),
                          builder: (context, snapshot) {
                            final countries = snapshot.data ?? const [];
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: uiTr(context, 'الدولة *'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<DocumentReference>(
                                  isExpanded: true,
                                  value: _selectedCountryRef,
                                  hint: Text(uiTr(context, 'اختر الدولة')),
                                  items: countries.map((c) {
                                    final iso = (c.isoCode).trim().toUpperCase();
                                    final label = c.naimEnglesh.isNotEmpty
                                        ? c.naimEnglesh
                                        : c.naim;
                                    return DropdownMenuItem(
                                      value: c.reference,
                                      child: Text(
                                        iso.isEmpty
                                            ? label
                                            : '$label ($iso)',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (ref) {
                                    if (ref == null) return;
                                    final match = countries
                                        .where((c) => c.reference == ref)
                                        .firstOrNull;
                                    safeSetState(() {
                                      _selectedCountryRef = ref;
                                      _selectedCountryIso =
                                          (match?.isoCode ?? '')
                                              .trim()
                                              .toUpperCase();
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        TextFormField(
                          controller: _model.textController1,
                          focusNode: _model.textFieldFocusNode1,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: FFLocalizations.of(context).getText(
                              '6647a2tr' /* Car Name */,
                            ),
                            hintStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .bodyMediumIsCustom,
                                ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
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
                            contentPadding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 12.0),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .bodyMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .bodyMediumIsCustom,
                              ),
                          validator: _model.textController1Validator
                              .asValidator(context),
                        ),
                        TextFormField(
                          controller: _englishNameController,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: appTr(context, 'adm_car_name_en'),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 12.0),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .bodyMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .bodyMediumIsCustom,
                              ),
                        ),
                        TextFormField(
                          controller: _russianNameController,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: appTr(context, 'adm_car_name_ru'),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 12.0),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .bodyMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .bodyMediumIsCustom,
                              ),
                        ),
                        TextFormField(
                          controller: _kyrgyzNameController,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: appTr(context, 'adm_car_name_ky'),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 12.0),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .bodyMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .bodyMediumIsCustom,
                              ),
                        ),
                        TextFormField(
                          controller: _codeController,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: appTr(context, 'adm_vehicle_code'),
                            hintText: 'sedan_standard',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 12.0),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .bodyMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .bodyMediumIsCustom,
                              ),
                        ),
                        TextFormField(
                          controller: _model.textController2,
                          focusNode: _model.textFieldFocusNode2,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: uiTr(context, 'السعر بالساعة'),
                            hintStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .bodyMediumIsCustom,
                                ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
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
                            contentPadding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 12.0),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .bodyMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .bodyMediumIsCustom,
                              ),
                          keyboardType: TextInputType.number,
                          validator: _model.textController2Validator
                              .asValidator(context),
                        ),
                        AdminEditableImageCard(
                          imageUrl: _model.uploadedFileUrl_carImage,
                          localBytes:
                              _model.uploadedLocalFile_carImage.bytes,
                          isUploading: _model.isDataUploading_carImage,
                          hint: FFLocalizations.of(context).getText(
                            '2nmvngw3' /* Car Image URL */,
                          ),
                          onPick: _pickCarImage,
                          onDelete: _model.uploadedFileUrl_carImage.isNotEmpty ||
                                  (_model.uploadedLocalFile_carImage.bytes
                                          ?.isNotEmpty ??
                                      false)
                              ? () => safeSetState(() {
                                    _model.uploadedFileUrl_carImage = '';
                                    _model.uploadedLocalFile_carImage =
                                        FFUploadedFile(
                                      bytes: Uint8List.fromList([]),
                                      originalFilename: '',
                                    );
                                  })
                              : null,
                        ),
                        TextFormField(
                          controller: _model.textController4,
                          focusNode: _model.textFieldFocusNode4,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: FFLocalizations.of(context).getText(
                              '9h0bsr4f' /* Minimum Booking Hours */,
                            ),
                            hintStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: FlutterFlowTheme.of(context)
                                      .bodyMediumFamily,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: !FlutterFlowTheme.of(context)
                                      .bodyMediumIsCustom,
                                ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
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
                            contentPadding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 12.0, 16.0, 12.0),
                          ),
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .bodyMediumFamily,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .bodyMediumIsCustom,
                              ),
                          keyboardType: TextInputType.number,
                          validator: _model.textController4Validator
                              .asValidator(context),
                        ),
                      ].divide(SizedBox(height: 12.0)),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            'cyrag9xi' /* Car Features */,
                          ),
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                fontFamily: FlutterFlowTheme.of(context)
                                    .headlineSmallFamily,
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                useGoogleFonts: !FlutterFlowTheme.of(context)
                                    .headlineSmallIsCustom,
                              ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'oefvlb20' /* Leather Seats */,
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
                            Switch(
                              value: _model.switchValue1!,
                              onChanged: (newValue) async {
                                safeSetState(
                                    () => _model.switchValue1 = newValue);
                              },
                              activeThumbColor: FlutterFlowTheme.of(context).primary,
                              activeTrackColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              inactiveTrackColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              inactiveThumbColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'x1pwuz6z' /* GPS Navigation */,
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
                            Switch(
                              value: _model.switchValue2!,
                              onChanged: (newValue) async {
                                safeSetState(
                                    () => _model.switchValue2 = newValue);
                              },
                              activeThumbColor: FlutterFlowTheme.of(context).primary,
                              activeTrackColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              inactiveTrackColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              inactiveThumbColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                '6p2xc1zp' /* Bluetooth */,
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
                            Switch(
                              value: _model.switchValue3!,
                              onChanged: (newValue) async {
                                safeSetState(
                                    () => _model.switchValue3 = newValue);
                              },
                              activeThumbColor: FlutterFlowTheme.of(context).primary,
                              activeTrackColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              inactiveTrackColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                              inactiveThumbColor:
                                  FlutterFlowTheme.of(context).secondaryText,
                            ),
                          ],
                        ),
                      ].divide(SizedBox(height: 12.0)),
                    ),
                  ),
                ),
              ),
              FFButtonWidget(
                onPressed: () async {
                  if (_selectedCountryRef == null ||
                      _selectedCountryIso.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(uiTr(context, 'يرجى اختيار الدولة')),
                      ),
                    );
                    return;
                  }
                  final arName = _model.textController1.text.trim();
                  final enName = _englishNameController.text.trim();
                  final ruName = _russianNameController.text.trim();
                  final kyName = _kyrgyzNameController.text.trim();
                  final code = _slugifyCode(
                    _codeController.text.trim().isNotEmpty
                        ? _codeController.text.trim()
                        : (enName.isNotEmpty ? enName : arName),
                  );
                  if (arName.isEmpty && enName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          uiTr(context, 'أدخل الاسم العربي أو الإنجليزي على الأقل'),
                        ),
                      ),
                    );
                    return;
                  }
                  final rate = int.tryParse(_model.textController2.text.trim());
                  if (rate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(uiTr(context, 'يرجى إدخال سعر صحيح'))),
                    );
                    return;
                  }
                  final imgUrl = await resolveImageForFirestoreSave(
                    pickedUrl: _model.uploadedFileUrl_carImage,
                    existingUrl: '',
                    localBytes: _model.uploadedLocalFile_carImage.bytes,
                  );
                  try {
                    await TypeCarRecord.collection.doc().set(
                          createTypeCarRecordData(
                            naim: arName.isNotEmpty ? arName : enName,
                            namesI18n:
                                _buildNamesI18n(arName, enName, ruName, kyName),
                            sr: rate,
                            actev: true,
                            img: imgUrl,
                            ishafelh: _model.switchValue1 ?? false,
                            not: _carFeaturesNote(),
                            aglSaat: int.tryParse(
                              _model.textController4.text.trim(),
                            ),
                            codeCar: code,
                            dolh: _selectedCountryRef,
                            countryIso2: _selectedCountryIso,
                          ),
                        );
                    if (!context.mounted) return;
                    context.safePop();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AdminCrudFeedback.saveFailed(context, e))),
                    );
                  }
                },
                text: FFLocalizations.of(context).getText(
                  '29xike2b' /* Add Car Type */,
                ),
                icon: Icon(
                  Icons.car_rental_sharp,
                  size: 15.0,
                ),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 50.0,
                  padding: EdgeInsets.all(8.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily:
                            FlutterFlowTheme.of(context).titleMediumFamily,
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        letterSpacing: 0.0,
                        useGoogleFonts:
                            !FlutterFlowTheme.of(context).titleMediumIsCustom,
                      ),
                  elevation: 3.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

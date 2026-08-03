import '/auth/firebase_auth/auth_util.dart';
import 'package:easy_localization/easy_localization.dart';
import '/backend/backend.dart';
import '/core/toury_content_locale.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/list_dol_widget.dart';
import '/components/list_region_widget.dart';
import '/components/list_vill_widget.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/core/toury_maps_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'reg_com_model.dart';
export 'reg_com_model.dart';

/// نموذج تسجيل الشركات
class RegComWidget extends StatefulWidget {
  const RegComWidget({super.key});

  static String routeName = 'RegCom';
  static String routePath = '/regCom';

  @override
  State<RegComWidget> createState() => _RegComWidgetState();
}

class _RegComWidgetState extends State<RegComWidget> {
  late RegComModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegComModel());

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.phoneTextController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();

    _model.osfTextController ??= TextEditingController();
    _model.osfFocusNode ??= FocusNode();

    _model.servesTextController ??= TextEditingController();
    _model.servesFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    OutlineInputBorder border(Color color, {double width = 1.0}) =>
        OutlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
          borderRadius: DsRadius.medium,
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: typography.bodyMedium.copyWith(color: colors.hint),
      filled: true,
      fillColor: colors.surface,
      contentPadding: DsSpacing.inputContentPadding,
      enabledBorder: border(colors.border),
      focusedBorder: border(colors.focus, width: 1.6),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, width: 1.6),
    );
  }

  Widget _selectorTile(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: DsConstants.buttonHeightLg,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: DsRadius.medium,
          border: Border.all(color: colors.border, width: 1.0),
        ),
        child: Padding(
          padding: DsSpacing.inputContentPadding,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: colors.icon,
                size: DsConstants.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: colors.scaffold,
              appBar: DsAppBar(
                title: FFLocalizations.of(context).getText(
                  'r6dt23i9' /* Company Information -  Step 3 ... */,
                ),
                automaticallyImplyLeading: false,
                actions: const [],
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DsSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.lg),
                          child: DsFadeSlide(
                            child: DsCard(
                              elevated: true,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'r7rvvlkz' /* Company Information */,
                                    ),
                                    style: typography.headlineSmall.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _model.nameTextController,
                                    focusNode: _model.nameFocusNode,
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: _fieldDecoration(
                                      context,
                                      FFLocalizations.of(context).getText(
                                        'vcqwtkkv' /* Enter company name * */,
                                      ),
                                    ),
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    cursorColor: colors.primary,
                                    validator: _model
                                        .nameTextControllerValidator
                                        .asValidator(context),
                                  ),
                                  TextFormField(
                                    controller: _model.phoneTextController,
                                    focusNode: _model.phoneFocusNode,
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: _fieldDecoration(
                                      context,
                                      FFLocalizations.of(context).getText(
                                        'd4i07i2p' /* Enter phone number * */,
                                      ),
                                    ),
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    cursorColor: colors.primary,
                                    validator: _model
                                        .phoneTextControllerValidator
                                        .asValidator(context),
                                  ),
                                  _selectorTile(
                                    context,
                                    label: valueOrDefault<String>(
                                      FFAppState().ShrekNCountryText,
                                      ' *حدد الدولة',
                                    ),
                                    onTap: () async {
                                      await showModalBottomSheet(
                                        isScrollControlled: true,
                                        backgroundColor: colors.surface,
                                        context: context,
                                        builder: (context) {
                                          return WebViewAware(
                                            child: GestureDetector(
                                              onTap: () {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                              },
                                              child: Padding(
                                                padding:
                                                    MediaQuery.viewInsetsOf(
                                                        context),
                                                child: SizedBox(
                                                  height:
                                                      MediaQuery.sizeOf(context)
                                                              .height *
                                                          0.77,
                                                  child: const ListDolWidget(),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ).then((value) => safeSetState(() {}));
                                    },
                                  ),
                                  if (FFAppState().ShrekNCountry != null)
                                    _selectorTile(
                                      context,
                                      label: valueOrDefault<String>(
                                        FFAppState().ShrekNRegionText,
                                        '*حدد المنطقة',
                                      ),
                                      onTap: () async {
                                        await showModalBottomSheet(
                                          isScrollControlled: true,
                                          backgroundColor: colors.surface,
                                          context: context,
                                          builder: (context) {
                                            return WebViewAware(
                                              child: GestureDetector(
                                                onTap: () {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                },
                                                child: Padding(
                                                  padding:
                                                      MediaQuery.viewInsetsOf(
                                                          context),
                                                  child: SizedBox(
                                                    height: MediaQuery.sizeOf(
                                                                context)
                                                            .height *
                                                        0.77,
                                                    child:
                                                        const ListRegionWidget(),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ).then((value) => safeSetState(() {}));
                                      },
                                    ),
                                  if (FFAppState().ShrekNRegionRev != null)
                                    _selectorTile(
                                      context,
                                      label: valueOrDefault<String>(
                                        FFAppState().ShrekNCiteText,
                                        '*حدد المدينة',
                                      ),
                                      onTap: () async {
                                        await showModalBottomSheet(
                                          isScrollControlled: true,
                                          backgroundColor: colors.surface,
                                          context: context,
                                          builder: (context) {
                                            return WebViewAware(
                                              child: GestureDetector(
                                                onTap: () {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                },
                                                child: Padding(
                                                  padding:
                                                      MediaQuery.viewInsetsOf(
                                                          context),
                                                  child: SizedBox(
                                                    height: MediaQuery.sizeOf(
                                                                context)
                                                            .height *
                                                        0.77,
                                                    child:
                                                        const ListVillWidget(),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ).then((value) => safeSetState(() {}));
                                      },
                                    ),
                                  FlutterFlowPlacePicker(
                                    iOSGoogleMapsApiKey:
                                        TouryMapsConfig.googleMapsApiKey,
                                    androidGoogleMapsApiKey:
                                        TouryMapsConfig.googleMapsApiKey,
                                    webGoogleMapsApiKey:
                                        TouryMapsConfig.googleMapsApiKey,
                                    onSelect: (place) async {
                                      safeSetState(
                                          () => _model.placePickerValue = place);
                                    },
                                    defaultText:
                                        FFLocalizations.of(context).getText(
                                      'w15dqn50' /* Set Location * */,
                                    ),
                                    icon: Icon(
                                      DsIcons.location,
                                      color: colors.primary,
                                      size: DsConstants.iconSm,
                                    ),
                                    buttonOptions: FFButtonOptions(
                                      width: double.infinity,
                                      height: DsConstants.buttonHeightLg,
                                      color: colors.surface,
                                      textAlign: TextAlign.center,
                                      textStyle:
                                          typography.bodyMedium.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                      borderSide: BorderSide(
                                        color: colors.border,
                                        width: 1.0,
                                      ),
                                      borderRadius: DsRadius.medium,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _model.osfTextController,
                                    focusNode: _model.osfFocusNode,
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: _fieldDecoration(
                                      context,
                                      FFLocalizations.of(context).getText(
                                        'pccrhybm' /* Enter business description * */,
                                      ),
                                    ),
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    cursorColor: colors.primary,
                                    maxLines: 4,
                                    validator: _model.osfTextControllerValidator
                                        .asValidator(context),
                                  ),
                                ].divide(const SizedBox(height: DsSpacing.md)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.lg),
                          child: DsFadeSlide(
                            delay: const Duration(milliseconds: 60),
                            child: DsCard(
                              elevated: true,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      'm4lvrquz' /* Documents */,
                                    ),
                                    style: typography.headlineSmall.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 181.32,
                                    decoration: BoxDecoration(
                                      color: colors.primarySoft,
                                      borderRadius: DsRadius.medium,
                                      border: Border.all(
                                        color: colors.border,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          DsSpacing.md),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          final selectedMedia =
                                              await selectMediaWithSourceBottomSheet(
                                            context: context,
                                            allowPhoto: true,
                                          );
                                          if (selectedMedia != null &&
                                              selectedMedia.every((m) =>
                                                  validateFileFormat(
                                                      m.storagePath, context))) {
                                            safeSetState(() => _model
                                                .isDataUploading_uploadDataY60 =
                                                true);
                                            var selectedUploadedFiles =
                                                <FFUploadedFile>[];

                                            var downloadUrls = <String>[];
                                            try {
                                              selectedUploadedFiles =
                                                  selectedMedia
                                                      .map((m) =>
                                                          FFUploadedFile(
                                                            name: m.storagePath
                                                                .split('/')
                                                                .last,
                                                            bytes: m.bytes,
                                                            height: m.dimensions
                                                                ?.height,
                                                            width: m.dimensions
                                                                ?.width,
                                                            blurHash:
                                                                m.blurHash,
                                                            originalFilename: m
                                                                .originalFilename,
                                                          ))
                                                      .toList();

                                              downloadUrls = (await Future.wait(
                                                selectedMedia.map(
                                                  (m) async => await uploadData(
                                                      m.storagePath, m.bytes),
                                                ),
                                              ))
                                                  .where((u) => u != null)
                                                  .map((u) => u!)
                                                  .toList();
                                            } finally {
                                              _model.isDataUploading_uploadDataY60 =
                                                  false;
                                            }
                                            if (selectedUploadedFiles.length ==
                                                    selectedMedia.length &&
                                                downloadUrls.length ==
                                                    selectedMedia.length) {
                                              safeSetState(() {
                                                _model.uploadedLocalFile_uploadDataY60 =
                                                    selectedUploadedFiles.first;
                                                _model.uploadedFileUrl_uploadDataY60 =
                                                    downloadUrls.first;
                                              });
                                            } else {
                                              safeSetState(() {});
                                              return;
                                            }
                                          }
                                        },
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .add_photo_alternate_rounded,
                                              color: colors.primary,
                                              size: DsConstants.iconXl,
                                            ),
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'nvc9dbke' /* Upload Place Image * */,
                                              ),
                                              style: typography.bodyMedium
                                                  .copyWith(
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                'dofllojk' /* Tap to select image */,
                                              ),
                                              style: typography.labelSmall
                                                  .copyWith(
                                                color: colors.textSecondary,
                                              ),
                                            ),
                                            if (_model
                                                .isDataUploading_uploadDataY60)
                                              Row(
                                                mainAxisSize:
                                                    MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        DsRadius.small,
                                                    child: TouryNetworkImage(
                                                      url: _model
                                                          .uploadedFileUrl_uploadDataY60,
                                                      width: 55.0,
                                                      height: 55.0,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ].divide(
                                              const SizedBox(height: DsSpacing.xs)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: DsConstants.buttonHeightLg,
                                    decoration: BoxDecoration(
                                      color: colors.primarySoft,
                                      borderRadius: DsRadius.medium,
                                      border: Border.all(
                                        color: colors.border,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: DsSpacing.inputContentPadding,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Icon(
                                                  Icons.attach_file_rounded,
                                                  color: colors.primary,
                                                  size: DsConstants.iconMd,
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      final selectedFiles =
                                                          await selectFiles(
                                                        allowedExtensions: [
                                                          'pdf'
                                                        ],
                                                        multiFile: false,
                                                      );
                                                      if (selectedFiles !=
                                                          null) {
                                                        safeSetState(() => _model
                                                                .isDataUploading_uploadDataPdfRks =
                                                            true);
                                                        var selectedUploadedFiles =
                                                            <FFUploadedFile>[];

                                                        var downloadUrls =
                                                            <String>[];
                                                        try {
                                                          showUploadMessage(
                                                            context,
                                                            'Uploading file...',
                                                            showLoading: true,
                                                          );
                                                          selectedUploadedFiles =
                                                              selectedFiles
                                                                  .map((m) =>
                                                                      FFUploadedFile(
                                                                        name: m
                                                                            .storagePath
                                                                            .split('/')
                                                                            .last,
                                                                        bytes: m
                                                                            .bytes,
                                                                        originalFilename:
                                                                            m.originalFilename,
                                                                      ))
                                                                  .toList();

                                                          downloadUrls =
                                                              (await Future
                                                                  .wait(
                                                            selectedFiles.map(
                                                              (f) async =>
                                                                  await uploadData(
                                                                      f.storagePath,
                                                                      f.bytes),
                                                            ),
                                                          ))
                                                                  .where((u) =>
                                                                      u != null)
                                                                  .map((u) => u!)
                                                                  .toList();
                                                        } finally {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .hideCurrentSnackBar();
                                                          _model.isDataUploading_uploadDataPdfRks =
                                                              false;
                                                        }
                                                        if (selectedUploadedFiles
                                                                    .length ==
                                                                selectedFiles
                                                                    .length &&
                                                            downloadUrls
                                                                    .length ==
                                                                selectedFiles
                                                                    .length) {
                                                          safeSetState(() {
                                                            _model.uploadedLocalFile_uploadDataPdfRks =
                                                                selectedUploadedFiles
                                                                    .first;
                                                            _model.uploadedFileUrl_uploadDataPdfRks =
                                                                downloadUrls
                                                                    .first;
                                                          });
                                                          showUploadMessage(
                                                            context,
                                                            'Success!',
                                                          );
                                                        } else {
                                                          safeSetState(() {});
                                                          showUploadMessage(
                                                            context,
                                                            'Failed to upload file',
                                                          );
                                                          return;
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'vxn5u61y' /* Attach License Document * */,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: typography
                                                          .bodyMedium
                                                          .copyWith(
                                                        color: colors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (_model
                                                    .isDataUploading_uploadDataPdfRks)
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'mz6g211j' /* The file has been successfully... */,
                                                    ),
                                                    style: typography.bodySmall
                                                        .copyWith(
                                                      color: colors.success,
                                                    ),
                                                  ),
                                              ].divide(const SizedBox(
                                                  width: DsSpacing.sm)),
                                            ),
                                          ),
                                          Icon(
                                            Icons.upload_file_rounded,
                                            color: colors.primary,
                                            size: DsConstants.iconMd,
                                          ),
                                        ].divide(
                                            const SizedBox(width: DsSpacing.sm)),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: DsConstants.buttonHeightLg,
                                    decoration: BoxDecoration(
                                      color: colors.primarySoft,
                                      borderRadius: DsRadius.medium,
                                      border: Border.all(
                                        color: colors.border,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: DsSpacing.inputContentPadding,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Icon(
                                                  Icons.attach_file_rounded,
                                                  color: colors.primary,
                                                  size: DsConstants.iconMd,
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      final selectedFiles =
                                                          await selectFiles(
                                                        allowedExtensions: [
                                                          'pdf'
                                                        ],
                                                        multiFile: false,
                                                      );
                                                      if (selectedFiles !=
                                                          null) {
                                                        safeSetState(() => _model
                                                                .isDataUploading_uploadDataPdfSJL =
                                                            true);
                                                        var selectedUploadedFiles =
                                                            <FFUploadedFile>[];

                                                        var downloadUrls =
                                                            <String>[];
                                                        try {
                                                          showUploadMessage(
                                                            context,
                                                            'Uploading file...',
                                                            showLoading: true,
                                                          );
                                                          selectedUploadedFiles =
                                                              selectedFiles
                                                                  .map((m) =>
                                                                      FFUploadedFile(
                                                                        name: m
                                                                            .storagePath
                                                                            .split('/')
                                                                            .last,
                                                                        bytes: m
                                                                            .bytes,
                                                                        originalFilename:
                                                                            m.originalFilename,
                                                                      ))
                                                                  .toList();

                                                          downloadUrls =
                                                              (await Future
                                                                  .wait(
                                                            selectedFiles.map(
                                                              (f) async =>
                                                                  await uploadData(
                                                                      f.storagePath,
                                                                      f.bytes),
                                                            ),
                                                          ))
                                                                  .where((u) =>
                                                                      u != null)
                                                                  .map((u) => u!)
                                                                  .toList();
                                                        } finally {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .hideCurrentSnackBar();
                                                          _model.isDataUploading_uploadDataPdfSJL =
                                                              false;
                                                        }
                                                        if (selectedUploadedFiles
                                                                    .length ==
                                                                selectedFiles
                                                                    .length &&
                                                            downloadUrls
                                                                    .length ==
                                                                selectedFiles
                                                                    .length) {
                                                          safeSetState(() {
                                                            _model.uploadedLocalFile_uploadDataPdfSJL =
                                                                selectedUploadedFiles
                                                                    .first;
                                                            _model.uploadedFileUrl_uploadDataPdfSJL =
                                                                downloadUrls
                                                                    .first;
                                                          });
                                                          showUploadMessage(
                                                            context,
                                                            'Success!',
                                                          );
                                                        } else {
                                                          safeSetState(() {});
                                                          showUploadMessage(
                                                            context,
                                                            'Failed to upload file',
                                                          );
                                                          return;
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        '21i7au5i' /* Attach Registration Letter * */,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: typography
                                                          .bodyMedium
                                                          .copyWith(
                                                        color: colors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (_model
                                                    .isDataUploading_uploadDataPdfSJL)
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'jw8l4gwf' /* The file has been successfully... */,
                                                    ),
                                                    style: typography.bodySmall
                                                        .copyWith(
                                                      color: colors.success,
                                                    ),
                                                  ),
                                              ].divide(const SizedBox(
                                                  width: DsSpacing.sm)),
                                            ),
                                          ),
                                          Icon(
                                            Icons.upload_file_rounded,
                                            color: colors.primary,
                                            size: DsConstants.iconMd,
                                          ),
                                        ].divide(
                                            const SizedBox(width: DsSpacing.sm)),
                                      ),
                                    ),
                                  ),
                                ].divide(const SizedBox(height: DsSpacing.md)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.lg),
                          child: DsFadeSlide(
                            delay: const Duration(milliseconds: 120),
                            child: DsCard(
                              elevated: true,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      '7haoqkvs' /* Service Details */,
                                    ),
                                    style: typography.headlineSmall.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _model.servesTextController,
                                    focusNode: _model.servesFocusNode,
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: _fieldDecoration(
                                      context,
                                      FFLocalizations.of(context).getText(
                                        'g20km9my' /* Describe your provided service... */,
                                      ),
                                    ),
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                    cursorColor: colors.primary,
                                    maxLines: 4,
                                    validator: _model
                                        .servesTextControllerValidator
                                        .asValidator(context),
                                  ),
                                ].divide(const SizedBox(height: DsSpacing.md)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.lg),
                          child: DsButton.primary(
                            label: FFLocalizations.of(context).getText(
                              'itmkuzww' /* Register Now */,
                            ),
                            icon: Icons.real_estate_agent_rounded,
                            expanded: true,
                            size: DsButtonSize.lg,
                            onPressed: () async {
                              if ((_model.nameTextController.text != '') &&
                                  (_model.placePickerValue.latLng != null) &&
                                  (_model.osfTextController.text != '') &&
                                  (_model.uploadedFileUrl_uploadDataY60 !=
                                      '') &&
                                  (!_model.isDataUploading_uploadDataPdfRks) &&
                                  (!_model.isDataUploading_uploadDataPdfSJL) &&
                                  (_model.uploadedFileUrl_uploadDataPdfRks !=
                                      '') &&
                                  (_model.uploadedFileUrl_uploadDataPdfSJL !=
                                      '') &&
                                  (_model.servesTextController.text != '') &&
                                  (_model.phoneTextController.text != '')) {
                                final loc =
                                    touryContentLocaleFromContext(context);
                                final partnerName =
                                    _model.nameTextController.text.trim();
                                final partnerDesc =
                                    _model.servesTextController.text.trim();
                                await MkanRecord.collection
                                    .doc()
                                    .set(createMkanRecordData(
                                      naim: partnerName,
                                      osf: partnerDesc,
                                      namesI18n: {loc: partnerName},
                                      osfI18n: {loc: partnerDesc},
                                      acctev: false,
                                      idVill: FFAppState().ShrekNCite,
                                      location: _model.placePickerValue.latLng,
                                      asAds: true,
                                      ismzod: true,
                                      isShrek: true,
                                      idCit: FFAppState().ShrekNRegionRev,
                                      img1: _model
                                          .uploadedFileUrl_uploadDataY60,
                                      pdf: _model
                                          .uploadedFileUrl_uploadDataPdfSJL,
                                      dataAdd: getCurrentTimestamp,
                                      userRev: currentUserReference,
                                      emailUser: currentUserEmail,
                                      pdfKtab: _model
                                          .uploadedFileUrl_uploadDataPdfRks,
                                      contentLocale:
                                          touryContentLocaleFromContext(
                                              context),
                                    ));
                                await showDialog(
                                  context: context,
                                  builder: (alertDialogContext) {
                                    return WebViewAware(
                                      child: AlertDialog(
                                        title:
                                            Text('ui_text_471f24ef6b'.tr()),
                                        content:
                                            Text('ui_text_dbee2e6613'.tr()),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                alertDialogContext),
                                            child: Text(
                                                'ui_text_9072549574'.tr()),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                                FFAppState().ShrekNCountry = null;
                                FFAppState().ShrekNCite = null;
                                FFAppState().ShrekNCountryText = '';
                                FFAppState().ShrekNCiteText = '';
                                FFAppState().ShrekNRegionRev = null;
                                FFAppState().ShrekNRegionText = '';
                                safeSetState(() {});
                                await launchUrl(Uri(
                                    scheme: 'mailto',
                                    path: 'watanara2030@gmail.com',
                                    query: {
                                      'subject': 'تسجيل شركة توري تاكسي',
                                      'body':
                                          'تم طلب تسجيل شركة جديد من ${_model.nameTextController.text} - ${_model.phoneTextController.text}- ${_model.osfTextController.text}',
                                    }
                                        .entries
                                        .map((MapEntry<String, String> e) =>
                                            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                                        .join('&')));

                                context.pushNamed(HomePagWidget.routeName);
                              } else {
                                await showDialog(
                                  context: context,
                                  builder: (alertDialogContext) {
                                    return WebViewAware(
                                      child: AlertDialog(
                                        title:
                                            Text('ui_text_b6f51cadc4'.tr()),
                                        content:
                                            Text('ui_text_095479cd38'.tr()),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                alertDialogContext),
                                            child: Text(
                                                'ui_text_9072549574'.tr()),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DsSpacing.lg,
                            DsSpacing.sm,
                            DsSpacing.lg,
                            DsSpacing.sm,
                          ),
                          child: DsButton.danger(
                            label: FFLocalizations.of(context).getText(
                              'tgyewzd8' /* Cancel Order */,
                            ),
                            icon: Icons.cancel_rounded,
                            expanded: true,
                            size: DsButtonSize.lg,
                            onPressed: () async {
                              var confirmDialogResponse =
                                  await showDialog<bool>(
                                        context: context,
                                        builder: (alertDialogContext) {
                                          return WebViewAware(
                                            child: AlertDialog(
                                              title: Text(
                                                  'ui_text_b4bbf18b10'.tr()),
                                              content: Text(
                                                  'ui_text_cf4d76accb'.tr()),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext,
                                                          false),
                                                  child: Text(
                                                      'ui_text_5c528d9fa3'
                                                          .tr()),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext,
                                                          true),
                                                  child: Text(
                                                      'ui_text_d045bef8e5'
                                                          .tr()),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ) ??
                                      false;
                              if (confirmDialogResponse) {
                                FFAppState().ShrekNCountry = null;
                                FFAppState().ShrekNCite = null;
                                FFAppState().ShrekNCountryText = '';
                                FFAppState().ShrekNCiteText = '';
                                FFAppState().ShrekNRegionRev = null;
                                FFAppState().ShrekNRegionText = '';
                                safeSetState(() {});

                                context.pushNamed(HomePagWidget.routeName);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

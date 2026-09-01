import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'profile_update_page_model.dart';
export 'profile_update_page_model.dart';

class ProfileUpdatePageWidget extends StatefulWidget {
  const ProfileUpdatePageWidget({super.key});

  static String routeName = 'ProfileUpdatePage';
  static String routePath = '/profileUpdatePage';

  @override
  State<ProfileUpdatePageWidget> createState() =>
      _ProfileUpdatePageWidgetState();
}

class _ProfileUpdatePageWidgetState extends State<ProfileUpdatePageWidget> {
  late ProfileUpdatePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileUpdatePageModel());

    _model.textController1 ??=
        TextEditingController(text: currentUserDisplayName);
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController(text: currentUserEmail);
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.nameCarTextController ??= TextEditingController();
    _model.nameCarFocusNode ??= FocusNode();

    _model.modelTextController ??= TextEditingController();
    _model.modelFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Scaffold(
            key: scaffoldKey,
            backgroundColor: colors.scaffold,
            appBar: DriverMainAppBar(
              title: FFLocalizations.of(context).getText(
                '5fieigiq' /* Edit Profile */,
              ),
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: DsSpacing.pagePadding,
                child: DriverFormWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsCard(
                        padding: DsSpacing.cardPadding,
                        child: Column(
                          children: [
                            AuthUserStreamWidget(
                              builder: (context) => InkWell(
                                borderRadius: DsRadius.pill,
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
                                        .isDataUploading_uploadData8h7 = true);
                                    var selectedUploadedFiles =
                                        <FFUploadedFile>[];

                                    var downloadUrls = <String>[];
                                    try {
                                      showUploadMessage(
                                        context,
                                        'Uploading file...',
                                        showLoading: true,
                                      );
                                      selectedUploadedFiles = selectedMedia
                                          .map((m) => FFUploadedFile(
                                                name: m.storagePath
                                                    .split('/')
                                                    .last,
                                                bytes: m.bytes,
                                                height: m.dimensions?.height,
                                                width: m.dimensions?.width,
                                                blurHash: m.blurHash,
                                                originalFilename:
                                                    m.originalFilename,
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
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      _model.isDataUploading_uploadData8h7 =
                                          false;
                                    }
                                    if (selectedUploadedFiles.length ==
                                            selectedMedia.length &&
                                        downloadUrls.length ==
                                            selectedMedia.length) {
                                      safeSetState(() {
                                        _model.uploadedLocalFile_uploadData8h7 =
                                            selectedUploadedFiles.first;
                                        _model.uploadedFileUrl_uploadData8h7 =
                                            downloadUrls.first;
                                      });
                                      showUploadMessage(context, 'Success!');
                                    } else {
                                      safeSetState(() {});
                                      showUploadMessage(
                                          context, 'Failed to upload data');
                                      return;
                                    }
                                  }
                                },
                                child: DsAvatar(
                                  size: 120,
                                  imageUrl: _model
                                              .uploadedFileUrl_uploadData8h7
                                              .isNotEmpty
                                      ? _model.uploadedFileUrl_uploadData8h7
                                      : currentUserPhoto,
                                  name: currentUserDisplayName,
                                ),
                              ),
                            ),
                            const SizedBox(height: DsSpacing.sm),
                            Text(
                              FFLocalizations.of(context).getText(
                                'n9rohd22' /* Tap to change photo */,
                              ),
                              textAlign: TextAlign.center,
                              style: typography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xl),
                      Form(
                        key: _model.formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DsSectionHeader(
                              title: FFLocalizations.of(context).getText(
                                'i0k5njfx' /* Full Name */,
                              ),
                            ),
                            AuthUserStreamWidget(
                              builder: (context) => DsTextField(
                                controller: _model.textController1,
                                focusNode: _model.textFieldFocusNode1,
                                enabled: false,
                                label: FFLocalizations.of(context).getText(
                                  '5m0aofht' /* Enter your full name */,
                                ),
                              ),
                            ),
                            const SizedBox(height: DsSpacing.lg),
                            DsSectionHeader(
                              title: FFLocalizations.of(context).getText(
                                'knkq6gv5' /* Email Address */,
                              ),
                            ),
                            DsTextField.email(
                              controller: _model.textController2,
                              focusNode: _model.textFieldFocusNode2,
                              enabled: false,
                              label: FFLocalizations.of(context).getText(
                                'hyjo1hzj' /* Enter your email address */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.lg),
                            DsSectionHeader(
                              title: FFLocalizations.of(context).getText(
                                'tte9qdb6' /* Vehicle Type */,
                              ),
                            ),
                            DsTextField(
                              controller: _model.nameCarTextController,
                              focusNode: _model.nameCarFocusNode,
                              label: FFLocalizations.of(context).getText(
                                '4vas6x8x' /* Enter your full name */,
                              ),
                            ),
                            const SizedBox(height: DsSpacing.lg),
                            DsSectionHeader(
                              title: FFLocalizations.of(context).getText(
                                '1vt8pppl' /* Vehicle Model */,
                              ),
                            ),
                            DsTextField(
                              controller: _model.modelTextController,
                              focusNode: _model.modelFocusNode,
                              label: FFLocalizations.of(context).getText(
                                'jhtehfbm' /* Enter vehicle model */,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xxl),
                      DriverGradientButton(
                        label: FFLocalizations.of(context).getText(
                          '84nkjru1' /* Update Profile */,
                        ),
                        icon: Icons.check_rounded,
                        onPressed: () async {
                          await currentUserReference!
                              .update(createUserRecordData(
                            nameCar: _model.nameCarTextController.text,
                            modelCar: _model.modelTextController.text,
                            photoUrl: _model.uploadedFileUrl_uploadData8h7,
                          ));
                          DsSnackBar.show(
                            context,
                            message: driverTr(context, 'Data updated successfully'),
                            tone: DsSnackTone.success,
                          );

                          context.pushNamed(NowWidget.routeName);
                        },
                      ),
                    ],
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

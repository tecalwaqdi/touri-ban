import 'package:ara_oatan_app/order/checkout66/checkout66_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_phone_util.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'update_prof_model.dart';

export 'update_prof_model.dart';

class UpdateProfWidget extends StatefulWidget {
  const UpdateProfWidget({super.key});

  static String routeName = 'update_prof';
  static String routePath = '/updateProf';

  @override
  State<UpdateProfWidget> createState() => _UpdateProfWidgetState();
}

class _UpdateProfWidgetState extends State<UpdateProfWidget> {
  late UpdateProfModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UpdateProfModel());

    _model.textController1 ??=
        TextEditingController(text: currentUserDisplayName);
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController(
        text: valueOrDefault(currentUserDocument?.phoneN, 0).toString());
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController(text: currentUserEmail);
    _model.textFieldFocusNode3 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Photo picker offering camera / gallery through a source bottom sheet.
  Future<void> _pickPhotoFromSourceSheet() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );
    if (selectedMedia != null &&
        selectedMedia
            .every((m) => validateFileFormat(m.storagePath, context))) {
      safeSetState(() => _model.isDataUploading_uploadDataMcff1 = true);
      var selectedUploadedFiles = <FFUploadedFile>[];

      var downloadUrls = <String>[];
      try {
        selectedUploadedFiles = selectedMedia
            .map((m) => FFUploadedFile(
                  name: m.storagePath.split('/').last,
                  bytes: m.bytes,
                  height: m.dimensions?.height,
                  width: m.dimensions?.width,
                  blurHash: m.blurHash,
                  originalFilename: m.originalFilename,
                ))
            .toList();

        downloadUrls = (await Future.wait(
          selectedMedia.map(
            (m) async => await uploadData(m.storagePath, m.bytes),
          ),
        ))
            .where((u) => u != null)
            .map((u) => u!)
            .toList();
      } finally {
        _model.isDataUploading_uploadDataMcff1 = false;
      }
      if (selectedUploadedFiles.length == selectedMedia.length &&
          downloadUrls.length == selectedMedia.length) {
        safeSetState(() {
          _model.uploadedLocalFile_uploadDataMcff1 =
              selectedUploadedFiles.first;
          _model.uploadedFileUrl_uploadDataMcff1 = downloadUrls.first;
        });
      } else {
        safeSetState(() {});
        return;
      }
    }

    await currentUserReference!.update(createUserRecordData(
      photoUrl: _model.uploadedFileUrl_uploadDataMcff1,
    ));
  }

  /// Photo picker going straight to the gallery.
  Future<void> _pickPhotoFromGallery() async {
    final selectedMedia = await selectMedia(
      mediaSource: MediaSource.photoGallery,
      multiImage: false,
    );
    if (selectedMedia != null &&
        selectedMedia
            .every((m) => validateFileFormat(m.storagePath, context))) {
      safeSetState(() => _model.isDataUploading_uploadDataMcff = true);
      var selectedUploadedFiles = <FFUploadedFile>[];

      var downloadUrls = <String>[];
      try {
        selectedUploadedFiles = selectedMedia
            .map((m) => FFUploadedFile(
                  name: m.storagePath.split('/').last,
                  bytes: m.bytes,
                  height: m.dimensions?.height,
                  width: m.dimensions?.width,
                  blurHash: m.blurHash,
                  originalFilename: m.originalFilename,
                ))
            .toList();

        downloadUrls = (await Future.wait(
          selectedMedia.map(
            (m) async => await uploadData(m.storagePath, m.bytes),
          ),
        ))
            .where((u) => u != null)
            .map((u) => u!)
            .toList();
      } finally {
        _model.isDataUploading_uploadDataMcff = false;
      }
      if (selectedUploadedFiles.length == selectedMedia.length &&
          downloadUrls.length == selectedMedia.length) {
        safeSetState(() {
          _model.uploadedLocalFile_uploadDataMcff = selectedUploadedFiles.first;
          _model.uploadedFileUrl_uploadDataMcff = downloadUrls.first;
        });
      } else {
        safeSetState(() {});
        return;
      }
    }

    await currentUserReference!.update(createUserRecordData(
      photoUrl: _model.uploadedFileUrl_uploadDataMcff1,
    ));
  }

  Future<void> _submit() async {
    final normalized = TouryPhoneUtil.normalizeForSave(
      _model.textController2.text,
    );
    if (TouryPhoneUtil.digitsOnly(normalized.phoneNumber).length < 7) {
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: 'enter_phone_number'.tr(),
        type: TouryMessageType.error,
      );
      return;
    }
    await currentUserReference!.update(
      createUserRecordData(
        displayName: _model.textController1.text,
        phoneNumber: normalized.phoneNumber,
        phoneN: normalized.phoneN,
      ),
    );
    // Refresh local user doc before returning to checkout.
    final refreshed = await UserRecord.getDocumentOnce(currentUserReference!);
    currentUserDocument = refreshed;
    if (!mounted) return;
    context.pushReplacementNamed(Checkout66Widget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

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
                  '2sn8j2l0' /* Update Profile */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.xxxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsFadeSlide(
                        child: _IdentityCard(
                          onTapAvatar: _pickPhotoFromSourceSheet,
                          onTapBadge: _pickPhotoFromGallery,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 60),
                        child: DsCard(
                          elevated: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthUserStreamWidget(
                                builder: (context) => DsTextField(
                                  controller: _model.textController1,
                                  focusNode: _model.textFieldFocusNode1,
                                  label: FFLocalizations.of(context).getText(
                                    '604pukst' /* Name */,
                                  ),
                                  hint: FFLocalizations.of(context).getText(
                                    '7dplhdxl' /* Enter your full name */,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: DsIcons.sm,
                                    color: colors.iconMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: DsSpacing.md),
                              AuthUserStreamWidget(
                                builder: (context) => DsTextField(
                                  controller: _model.textController2,
                                  focusNode: _model.textFieldFocusNode2,
                                  label: FFLocalizations.of(context).getText(
                                    '1tj0rsix' /* Phone Number */,
                                  ),
                                  hint: FFLocalizations.of(context).getText(
                                    '7j4w94u8' /* Enter your mobile number */,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    size: DsIcons.sm,
                                    color: colors.iconMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: DsSpacing.md),
                              DsTextField(
                                controller: _model.textController3,
                                focusNode: _model.textFieldFocusNode3,
                                readOnly: true,
                                label: FFLocalizations.of(context).getText(
                                  'qft54s75' /* Email */,
                                ),
                                hint: FFLocalizations.of(context).getText(
                                  '3lvbnhv9' /* Enter your mobile number */,
                                ),
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  size: DsIcons.sm,
                                  color: colors.iconMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xl),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 120),
                        child: DsButton.primary(
                          label: FFLocalizations.of(context).getText(
                            'l8rle2rn' /* Update Profile */,
                          ),
                          icon: Icons.check_rounded,
                          size: DsButtonSize.lg,
                          expanded: true,
                          onPressed: _submit,
                        ),
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

/// Avatar header with a camera badge for changing the profile photo.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.onTapAvatar,
    required this.onTapBadge,
  });

  final Future<void> Function() onTapAvatar;
  final Future<void> Function() onTapBadge;

  static const double _avatarSize = 100;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthUserStreamWidget(
            builder: (context) => SizedBox(
              width: _avatarSize + DsSpacing.xs,
              height: _avatarSize + DsSpacing.xs,
              child: Stack(
                children: [
                  DsPressable(
                    onTap: () async => onTapAvatar(),
                    child: Container(
                      width: _avatarSize + DsSpacing.xs,
                      height: _avatarSize + DsSpacing.xs,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primarySoft,
                        border: Border.all(
                          color: colors.primaryMuted,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: TouryAvatarImage(
                          url: currentUserPhoto,
                          size: _avatarSize,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: DsPressable(
                      onTap: () async => onTapBadge(),
                      child: Container(
                        width: DsSpacing.xxl,
                        height: DsSpacing.xxl,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                          border: Border.all(color: colors.card, width: 2),
                          boxShadow: DsShadows.soft(dark: context.dsIsDark),
                        ),
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: DsIcons.xs,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          AuthUserStreamWidget(
            builder: (context) => Text(
              currentUserDisplayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: typography.headlineSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          AuthUserStreamWidget(
            builder: (context) {
              if (currentUserEmail.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: DsSpacing.xxs),
                child: Text(
                  currentUserEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/profile_photo_service.dart';
import '/core/toury_dialogs.dart';
import '/core/toury_async_action_guard.dart';
import '/core/toury_phone_util.dart';
import '/core/toury_profile_errors.dart';
import '/core/toury_profile_state.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'update_prof_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ara_oatan_app/order/checkout66/checkout66_widget.dart';
import 'package:easy_localization/easy_localization.dart';

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UpdateProfModel());

    _model.textController1 ??=
        TextEditingController(text: currentUserDisplayName);
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController(
      text: TouryPhoneUtil.displayPhone(
        phoneNumber: currentUserDocument?.phoneNumber,
        phoneN: currentUserDocument?.phoneN,
        authPhone: currentUser?.phoneNumber,
      ),
    );
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController(text: currentUserEmail);
    _model.textFieldFocusNode3 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  bool _fieldsDirty = false;

  void _syncFieldsFromDocument(UserRecord? user) {
    if (user == null || _fieldsDirty || _isSaving) return;
    if (!_model.textFieldFocusNode1!.hasFocus) {
      final name = user.displayName.trim().isNotEmpty
          ? user.displayName
          : currentUserDisplayName;
      if (_model.textController1!.text != name) {
        _model.textController1!.text = name;
      }
    }
    if (!_model.textFieldFocusNode2!.hasFocus) {
      final phone = TouryPhoneUtil.displayPhone(
        phoneNumber: user.phoneNumber,
        phoneN: user.phoneN,
        authPhone: currentUser?.phoneNumber,
      );
      if (_model.textController2!.text != phone) {
        _model.textController2!.text = phone;
      }
    }
    if (!_model.textFieldFocusNode3!.hasFocus) {
      final email = user.email.trim().isNotEmpty
          ? user.email
          : currentUserEmail;
      if (_model.textController3!.text != email) {
        _model.textController3!.text = email;
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  bool get _isUploading =>
      _model.isDataUploading_uploadDataMcff1 ||
      _model.isDataUploading_uploadDataMcff;

  /// Shared path: pick → compress → single upload → save URL (or keep old).
  Future<void> _changeProfilePhoto({required bool galleryOnly}) async {
    if (_isUploading) return;

    final uid = currentUserUid;
    if (uid.isEmpty || currentUserReference == null) {
      if (!mounted) return;
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: 'يجب تسجيل الدخول قبل رفع الصورة.',
        type: TouryMessageType.error,
      );
      return;
    }

    final selectedMedia = galleryOnly
        ? await selectMedia(
            mediaSource: MediaSource.photoGallery,
            multiImage: false,
            maxWidth: 1280,
            maxHeight: 1280,
            imageQuality: 85,
            storageFolderPath: 'users/$uid',
          )
        : await selectMediaWithSourceBottomSheet(
            context: context,
            allowPhoto: true,
            maxWidth: 1280,
            maxHeight: 1280,
            imageQuality: 85,
            storageFolderPath: 'users/$uid',
          );

    if (selectedMedia == null || selectedMedia.isEmpty) {
      return;
    }
    if (!selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
      return;
    }

    final picked = selectedMedia.first;
    if (picked.bytes.isEmpty) {
      if (!mounted) return;
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: 'لم يتم قراءة الصورة. جرّب صورة أخرى.',
        type: TouryMessageType.error,
      );
      return;
    }

    safeSetState(() {
      _model.isDataUploading_uploadDataMcff1 = true;
      _model.isDataUploading_uploadDataMcff = true;
    });

    try {
      final photoUrl = await uploadUserProfilePhoto(
        uid: uid,
        bytes: picked.bytes,
      );

      try {
        await currentUserReference!.update(<String, dynamic>{
          'photo_url': photoUrl,
          'updated_time': getCurrentTimestamp,
        });
      } catch (e) {
        debugPrint('photo_url_write failed: $e');
        if (!mounted) return;
        await TouryDialogs.showAlert(
          context,
          title: 'dialog_error_title'.tr(),
          message: touryProfileErrorMessage(e, operation: 'photo_url_write'),
          type: TouryMessageType.error,
        );
        return;
      }

      await TouryProfileState.refreshFromServer();

      if (!mounted) return;
      safeSetState(() {
        final local = FFUploadedFile(
          name: 'profile.jpg',
          bytes: picked.bytes,
          originalFilename: picked.originalFilename,
        );
        _model.uploadedLocalFile_uploadDataMcff1 = local;
        _model.uploadedLocalFile_uploadDataMcff = local;
        _model.uploadedFileUrl_uploadDataMcff1 = photoUrl;
        _model.uploadedFileUrl_uploadDataMcff = photoUrl;
      });

      await TouryDialogs.showAlert(
        context,
        title: 'نجاح',
        message: isProfilePhotoDataUrl(photoUrl)
            ? 'تم حفظ الصورة محلياً لأن حصة Firebase Storage ممتلئة. '
                'راجع Console → Storage أو فعّل Blaze.'
            : 'تم تحديث صورة الملف الشخصي بنجاح',
        type: TouryMessageType.success,
      );
    } on StorageUploadException catch (e) {
      if (!mounted) return;
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: e.message.contains('صلاحيات')
            ? 'تعذر رفع الصورة بسبب صلاحيات التخزين.'
            : e.message,
        type: TouryMessageType.error,
      );
    } catch (e) {
      if (!mounted) return;
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: touryProfileErrorMessage(e, operation: 'photo_upload'),
        type: TouryMessageType.error,
      );
    } finally {
      if (mounted) {
        safeSetState(() {
          _model.isDataUploading_uploadDataMcff1 = false;
          _model.isDataUploading_uploadDataMcff = false;
        });
      } else {
        _model.isDataUploading_uploadDataMcff1 = false;
        _model.isDataUploading_uploadDataMcff = false;
      }
    }
  }

  Future<void> _pickPhotoFromSourceSheet() =>
      _changeProfilePhoto(galleryOnly: false);

  Future<void> _pickPhotoFromGallery() =>
      _changeProfilePhoto(galleryOnly: true);

  Future<void> _submit() async {
    if (_isSaving || _isUploading) return;
    final guardKey = 'profile:update:${currentUserUid.isEmpty ? 'anon' : currentUserUid}';
    if (!TouryAsyncActionGuard.tryStart(guardKey)) return;
    safeSetState(() => _isSaving = true);

    try {
      final normalized = TouryPhoneUtil.normalizeForSave(
        _model.textController2.text,
      );
      if (!TouryPhoneUtil.hasUsablePhone(
        phoneNumber: normalized.phoneNumber,
        phoneN: normalized.phoneN,
      )) {
        await TouryDialogs.showAlert(
          context,
          title: 'dialog_error_title'.tr(),
          message: 'enter_phone_number'.tr(),
          type: TouryMessageType.error,
        );
        return;
      }

      final displayName = _model.textController1.text.trim();
      if (displayName.isEmpty) {
        await TouryDialogs.showAlert(
          context,
          title: 'dialog_error_title'.tr(),
          message: 'يرجى إدخال الاسم.',
          type: TouryMessageType.error,
        );
        return;
      }

      final ref = currentUserReference;
      if (ref == null || currentUserUid.isEmpty) {
        await TouryDialogs.showAlert(
          context,
          title: 'dialog_error_title'.tr(),
          message: 'انتهت جلسة تسجيل الدخول. سجّل الدخول مرة أخرى.',
          type: TouryMessageType.error,
        );
        return;
      }

      // Only safe profile fields — never privileged role keys.
      final payload = <String, dynamic>{
        'display_name': displayName,
        'phone_number': normalized.phoneNumber,
        if (normalized.phoneN != null) 'phone_n': normalized.phoneN,
        'updated_time': getCurrentTimestamp,
      };
      debugPrint(
        'profile_save uid=$currentUserUid keys=${payload.keys.toList()}',
      );
      await ref.update(payload);
      final refreshed = await TouryProfileState.refreshFromServer();
      final savedPhone = refreshed?.phoneNumber ?? '';
      if (savedPhone.trim().isEmpty) {
        throw StateError('PROFILE_PHONE_READBACK_EMPTY');
      }
      _fieldsDirty = false;
      if (!mounted) return;
      await TouryDialogs.showAlert(
        context,
        title: 'نجاح',
        message: 'تم حفظ الملف الشخصي بنجاح',
        type: TouryMessageType.success,
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.safePop();
      } else {
        context.pushReplacementNamed(Checkout66Widget.routeName);
      }
    } catch (e) {
      debugPrint('profile_save failed: $e');
      if (!mounted) return;
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: touryProfileErrorMessage(e, operation: 'profile_save'),
        type: TouryMessageType.error,
      );
    } finally {
      TouryAsyncActionGuard.finish(guardKey);
      if (mounted) {
        safeSetState(() => _isSaving = false);
      } else {
        _isSaving = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: AuthUserStreamWidget(
        builder: (context) {
          _syncFieldsFromDocument(currentUserDocument);
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
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => context.safePop(),
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
                                  onChanged: (_) => _fieldsDirty = true,
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
                                  onChanged: (_) => _fieldsDirty = true,
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
                          onPressed: (_isSaving || _isUploading) ? null : _submit,
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

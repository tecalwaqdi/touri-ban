import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/schema/enums/enums.dart';
import '/core/toury_image.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import 'profile05_model.dart';

export 'profile05_model.dart';

class Profile05Widget extends StatefulWidget {
  const Profile05Widget({super.key});

  static String routeName = 'Profile05';
  static String routePath = '/profile05';

  @override
  State<Profile05Widget> createState() => _Profile05WidgetState();
}

class _Profile05WidgetState extends State<Profile05Widget> {
  late Profile05Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Profile05Model());

    _model.switchValue1 = false;
    _model.switchValue2 = false;

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );
    if (selectedMedia != null &&
        selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
      safeSetState(() => _model.isDataUploading_uploadDataMcf = true);
      var selectedUploadedFiles = <FFUploadedFile>[];

      var downloadUrls = <String>[];
      try {
        showUploadMessage(
          context,
          'Uploading file...',
          showLoading: true,
        );
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _model.isDataUploading_uploadDataMcf = false;
      }
      if (selectedUploadedFiles.length == selectedMedia.length &&
          downloadUrls.length == selectedMedia.length) {
        safeSetState(() {
          _model.uploadedLocalFile_uploadDataMcf = selectedUploadedFiles.first;
          _model.uploadedFileUrl_uploadDataMcf = downloadUrls.first;
        });
        showUploadMessage(context, 'Success!');
      } else {
        safeSetState(() {});
        showUploadMessage(context, 'Failed to upload data');
        return;
      }
    }

    await currentUserReference!.update(createUserRecordData(
      photoUrl: _model.uploadedFileUrl_uploadDataMcf,
    ));
  }

  Future<void> _requestAccountDeletion() async {
    final confirmDialogResponse = await TouryDialogs.showConfirm(
      context,
      title: 'dialog_delete_account_title'.tr(),
      message: 'dialog_delete_account_msg'.tr(),
      type: TouryMessageType.warning,
      destructive: true,
    );
    if (confirmDialogResponse) {
      await TouryDialogs.showAlert(
        context,
        title: 'dialog_request_sent_title'.tr(),
        message: 'dialog_request_sent_msg'.tr(),
        type: TouryMessageType.success,
      );

      await SupportRecord.collection.doc().set(createSupportRecordData(
            naim: currentUserDisplayName,
            osf: 'طلب حذف حسابي من التطبيق',
            tsnef: 'حذف حساب',
            refUser: currentUserReference,
            data: getCurrentTimestamp,
            halh: Halhsupport.Open,
          ));
    }
  }

  Future<void> _logout() async {
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    GoRouter.of(context).clearRedirectLocation();

    context.goNamedAuth(HomePagWidget.routeName, context.mounted);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final dsTheme = isDark ? DsTheme.dark() : DsTheme.light();

    return Theme(
      data: dsTheme,
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: Scaffold(
                key: scaffoldKey,
                backgroundColor: colors.scaffold,
                appBar: DsAppBar(
                  automaticallyImplyLeading: false,
                  titleWidget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'My account'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.titleMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'ux_account_sub'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.labelSmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                body: SafeArea(
                  top: true,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: TouryLayout.bottomNavSafe(context) + DsSpacing.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DsFadeSlide(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              DsSpacing.md,
                              DsSpacing.md,
                              DsSpacing.md,
                              DsSpacing.xs,
                            ),
                            child: _IdentityCard(
                              onEditPhoto: _pickAndUploadPhoto,
                            ),
                          ),
                        ),
                        DsSectionHeader(
                          title: 'ux_account_settings'.tr(),
                        ),
                        DsFadeSlide(
                          delay: const Duration(milliseconds: 60),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.md,
                            ),
                            child: _SettingsGroup(
                              children: [
                                _SettingsTile(
                                  icon: Icons.notifications_none_rounded,
                                  label: FFLocalizations.of(context).getText(
                                    '0fsig7jr' /* Enable notifications */,
                                  ),
                                  trailing: Switch.adaptive(
                                    value: _model.switchListTileValue ??= true,
                                    onChanged: (newValue) async {
                                      safeSetState(() =>
                                          _model.switchListTileValue = newValue);
                                    },
                                    activeColor: colors.onPrimary,
                                    activeTrackColor: colors.primary,
                                    inactiveTrackColor: colors.disabled,
                                    inactiveThumbColor: colors.iconMuted,
                                  ),
                                ),
                                _LanguageTile(
                                  onChanged: (lang) =>
                                      setAppLanguage(context, lang),
                                ),
                                if (isDark)
                                  _SettingsTile(
                                    icon: Icons.dark_mode_outlined,
                                    label: FFLocalizations.of(context).getText(
                                      '75sk17tv' /* Night mode */,
                                    ),
                                    trailing: Switch.adaptive(
                                      value: _model.switchValue1!,
                                      onChanged: (newValue) async {
                                        safeSetState(() =>
                                            _model.switchValue1 = newValue);
                                        if (newValue) {
                                          setDarkModeSetting(
                                              context, ThemeMode.light);
                                        }
                                      },
                                      activeColor: colors.onPrimary,
                                      activeTrackColor: colors.primary,
                                      inactiveTrackColor: colors.disabled,
                                      inactiveThumbColor: colors.iconMuted,
                                    ),
                                  ),
                                if (!isDark)
                                  _SettingsTile(
                                    icon: Icons.light_mode_outlined,
                                    label: FFLocalizations.of(context).getText(
                                      'gi6xg6nf' /* Dark  mode */,
                                    ),
                                    trailing: Switch.adaptive(
                                      value: _model.switchValue2!,
                                      onChanged: (newValue) async {
                                        safeSetState(() =>
                                            _model.switchValue2 = newValue);
                                        if (newValue) {
                                          setDarkModeSetting(
                                              context, ThemeMode.dark);
                                        }
                                      },
                                      activeColor: colors.onPrimary,
                                      activeTrackColor: colors.primary,
                                      inactiveTrackColor: colors.disabled,
                                      inactiveThumbColor: colors.iconMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        DsFadeSlide(
                          delay: const Duration(milliseconds: 120),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.md,
                            ),
                            child: _SettingsGroup(
                              children: [
                                _SettingsTile(
                                  icon: Icons.account_circle_outlined,
                                  label: FFLocalizations.of(context).getText(
                                    'hgec0x0r' /* Edit Profile */,
                                  ),
                                  onTap: () async {
                                    context
                                        .pushNamed(UpdateProfWidget.routeName);
                                  },
                                ),
                                if (currentPhoneNumber == '')
                                  AuthUserStreamWidget(
                                    builder: (context) => _SettingsTile(
                                      icon: Icons.mobile_off_rounded,
                                      danger: true,
                                      label:
                                          FFLocalizations.of(context).getText(
                                        '2b0d2f7o' /* Add your phone number */,
                                      ),
                                      onTap: () async {
                                        context.pushNamed(
                                            UpdateProfWidget.routeName);
                                      },
                                    ),
                                  ),
                                _SettingsTile(
                                  icon: Icons.maps_home_work_outlined,
                                  label: FFLocalizations.of(context).getText(
                                    '2t7ky6j7' /* Address list */,
                                  ),
                                  onTap: () async {
                                    context
                                        .pushNamed(ListAdressWidget.routeName);
                                  },
                                ),
                                _SettingsTile(
                                  icon: DsIcons.support,
                                  label: FFLocalizations.of(context).getText(
                                    'co0dquwo' /* Support & Customer Service */,
                                  ),
                                  onTap: () async {
                                    context.pushNamed(SupportWidget.routeName);
                                  },
                                ),
                                _SettingsTile(
                                  icon: DsIcons.payment,
                                  label: FFLocalizations.of(context).getText(
                                    '1bs1q309' /* Electronic Payment History */,
                                  ),
                                  onTap: () async {
                                    context
                                        .pushNamed(PaymetHostreWidget.routeName);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.md),
                        DsFadeSlide(
                          delay: const Duration(milliseconds: 180),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.md,
                            ),
                            child: _SettingsGroup(
                              children: [
                                _SettingsTile(
                                  icon: DsIcons.delete,
                                  danger: true,
                                  label: FFLocalizations.of(context).getText(
                                    'jla4pxzi' /* Request to delete the account. */,
                                  ),
                                  onTap: _requestAccountDeletion,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: DsSpacing.xl),
                        DsFadeSlide(
                          delay: const Duration(milliseconds: 240),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.md,
                            ),
                            child: DsButton(
                              label: FFLocalizations.of(context).getText(
                                '7wmiytjp' /* Log Out */,
                              ),
                              variant: DsButtonVariant.danger,
                              icon: Icons.logout_rounded,
                              expanded: true,
                              onPressed: _logout,
                            ),
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

/// Avatar + display name header with tap-to-change photo.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.onEditPhoto});

  final Future<void> Function() onEditPhoto;

  static const double _avatarSize = 96;

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
            builder: (context) => DsPressable(
              onTap: () async => onEditPhoto(),
              child: SizedBox(
                width: _avatarSize + DsSpacing.xs,
                height: _avatarSize + DsSpacing.xs,
                child: Stack(
                  children: [
                    Container(
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
                      child: TouryAvatarImage(
                        url: currentUserPhoto,
                        size: _avatarSize,
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
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
                  ],
                ),
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
              final secondaryLine = currentPhoneNumber.isNotEmpty
                  ? currentPhoneNumber
                  : currentUserEmail;
              if (secondaryLine.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: DsSpacing.xxs),
                child: Text(
                  secondaryLine,
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

/// Rounded surface grouping a set of settings rows.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      elevated: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: DsRadius.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const DsDivider(
                  indent: DsSpacing.giant,
                  endIndent: DsSpacing.md,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _TileLeading extends StatelessWidget {
  const _TileLeading({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;

    return Container(
      width: DsConstants.avatarMd,
      height: DsConstants.avatarMd,
      decoration: BoxDecoration(
        color: danger ? colors.errorContainer : colors.primarySoft,
        borderRadius: DsRadius.medium,
      ),
      child: Icon(
        icon,
        size: DsIcons.sm,
        color: danger ? colors.error : colors.primary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      child: Row(
        children: [
          _TileLeading(icon: icon, danger: danger),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.titleSmall.copyWith(
                color: danger ? colors.error : colors.textPrimary,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: DsIcons.md,
              color: colors.iconMuted,
            ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async => onTap!(),
        highlightColor: colors.pressed,
        splashColor: colors.hover,
        child: row,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.onChanged});

  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.sm,
      ),
      child: Row(
        children: [
          const _TileLeading(icon: Icons.language_rounded),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FlutterFlowLanguageSelector(
                width: DsConstants.languageSelectorWidth,
                backgroundColor: colors.surface,
                borderColor: colors.border,
                dropdownColor: colors.surfaceElevated,
                dropdownIconColor: colors.primary,
                borderRadius: DsRadius.sm,
                textStyle: typography.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
                hideFlags: true,
                flagSize: DsIcons.md,
                flagTextGap: DsSpacing.xs,
                currentLanguage: FFLocalizations.of(context).languageCode,
                languages: FFLocalizations.languages(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

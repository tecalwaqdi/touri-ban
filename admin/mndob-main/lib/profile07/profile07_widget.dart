import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/driver_theme_mode_card.dart';
import '/core/driver_account_deletion_service.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_logout_service.dart';
import '/core/driver_online_state.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'profile07_model.dart';
export 'profile07_model.dart';

class Profile07Widget extends StatefulWidget {
  const Profile07Widget({super.key});

  static String routeName = 'Profile07';
  static String routePath = '/profile07';

  @override
  State<Profile07Widget> createState() => _Profile07WidgetState();
}

class _Profile07WidgetState extends State<Profile07Widget>
    with TickerProviderStateMixin {
  late Profile07Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Profile07Model());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.6, 0.6),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 20.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 20.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<String?> _askPasswordForReauth() async {
    final controller = TextEditingController();
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(arabic ? 'تأكيد الهوية' : 'Confirm identity'),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: arabic ? 'كلمة المرور' : 'Password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(arabic ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(arabic ? 'متابعة' : 'Continue'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return password;
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    final first = await DriverDialogs.showConfirm(
      context,
      title: arabic ? 'حذف الحساب' : 'Delete account',
      message: arabic
          ? 'سيؤدي حذف حسابك إلى حذف بيانات الحساب الشخصية غير اللازمة (مثل بيانات الملف ورموز الإشعارات). لا يعني ذلك حذف كل البيانات: قد يتم الاحتفاظ بسجلات الرحلات والمعاملات والتسويات والقيود المحاسبية لأغراض المحاسبة والامتثال ومنع الاحتيال والنزاعات والتدقيق. لا يمكن الحذف أثناء رحلة نشطة أو تسوية معلّقة أو رصيد محفظة غير مسوّى.'
          : 'Deleting your account removes unnecessary personal account data (such as profile details and notification tokens). This does not erase all data: trip, transaction, settlement, and accounting records may be retained for accounting, compliance, fraud prevention, disputes, and audit. Deletion is blocked during an active trip, pending settlement, or unsettled wallet balance.',
      type: DriverMessageType.warning,
      destructive: true,
      confirmLabel: arabic ? 'متابعة حذف الحساب' : 'Continue deletion',
      cancelLabel: arabic ? 'إلغاء' : 'Cancel',
    );
    if (!first || !mounted) return;

    final second = await DriverDialogs.showConfirm(
      context,
      title: arabic ? 'تأكيد نهائي' : 'Final confirmation',
      message: arabic
          ? 'هل أنت متأكد أنك تريد حذف حسابك نهائيًا؟'
          : 'Are you sure you want to permanently delete your account?',
      type: DriverMessageType.warning,
      destructive: true,
      confirmLabel: arabic ? 'حذف نهائي' : 'Delete permanently',
      cancelLabel: arabic ? 'إلغاء' : 'Cancel',
    );
    if (!second || !mounted) return;

    final reauthed = await DriverAccountDeletionService.reauthenticate(
      context,
      askPassword: _askPasswordForReauth,
    );
    if (!reauthed) {
      if (!mounted) return;
      await DriverDialogs.showAlert(
        context,
        title: arabic ? 'مطلوب تأكيد الهوية' : 'Identity confirmation required',
        message: arabic
            ? 'لم نتمكن من تأكيد هويتك. سجّل الدخول مجددًا ثم أعد المحاولة.'
            : 'We could not confirm your identity. Sign in again and retry.',
        type: DriverMessageType.warning,
      );
      return;
    }
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    DriverDeletionResult result;
    try {
      result = await DriverAccountDeletionService.requestDeletion();
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) return;

    if (!result.ok) {
      await DriverDialogs.showAlert(
        context,
        title: arabic ? 'تعذر الحذف' : 'Deletion failed',
        message: DriverAccountDeletionService.userFacingMessage(
          result,
          arabic: arabic,
        ),
        type: DriverMessageType.error,
      );
      return;
    }

    GoRouter.of(context).prepareAuthEvent();
    await DriverLogoutService.logout();
    GoRouter.of(context).clearRedirectLocation();
    if (mounted) context.go('/');
  }

  Widget _menuRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      onTap: onTap,
      padding: DsSpacing.cardPadding,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primaryStrong, size: 22),
          ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_left_rounded,
                color: colors.iconMuted,
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              body: SafeArea(
                top: true,
                child: DriverContentWidth(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            DsSpacing.md,
                            DsSpacing.lg,
                            DsSpacing.md,
                            DsSpacing.xl,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.primary.withValues(alpha: 0.18),
                                colors.primaryStrong.withValues(alpha: 0.10),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(DsRadius.xl),
                            ),
                          ),
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
                                      storageFolderPath:
                                          'users/$currentUserUid/uploads',
                                    );
                                    if (selectedMedia == null ||
                                        selectedMedia.isEmpty ||
                                        !selectedMedia.every((m) =>
                                            validateFileFormat(
                                                m.storagePath, context))) {
                                      return;
                                    }
                                    safeSetState(() => _model
                                        .isDataUploading_uploadDataB4x = true);
                                    try {
                                      final selectedUploadedFiles =
                                          selectedMedia
                                              .map((m) => FFUploadedFile(
                                                    name: m.storagePath
                                                        .split('/')
                                                        .last,
                                                    bytes: m.bytes,
                                                    height:
                                                        m.dimensions?.height,
                                                    width: m.dimensions?.width,
                                                    blurHash: m.blurHash,
                                                    originalFilename:
                                                        m.originalFilename,
                                                  ))
                                              .toList();

                                      final downloadUrls = <String>[];
                                      for (final m in selectedMedia) {
                                        final url = await uploadData(
                                            m.storagePath, m.bytes);
                                        if (url != null && url.isNotEmpty) {
                                          downloadUrls.add(url);
                                        }
                                      }

                                      if (selectedUploadedFiles.length !=
                                              selectedMedia.length ||
                                          downloadUrls.length !=
                                              selectedMedia.length) {
                                        if (context.mounted) {
                                          await DriverDialogs.showAlert(
                                            context,
                                            title: driverTr(context, 'Error'),
                                            message: driverTr(
                                              context,
                                              'Could not upload the file. Please try again.',
                                            ),
                                            type: DriverMessageType.error,
                                          );
                                        }
                                        return;
                                      }

                                      await currentUserReference!.update(
                                        createUserRecordData(
                                            photoUrl: downloadUrls.first),
                                      );
                                      try {
                                        currentUserDocument =
                                            await UserRecord.getDocumentOnce(
                                                currentUserReference!);
                                      } catch (_) {}
                                      safeSetState(() {
                                        _model.uploadedLocalFile_uploadDataB4x =
                                            selectedUploadedFiles.first;
                                        _model.uploadedFileUrl_uploadDataB4x =
                                            downloadUrls.first;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              driverTr(
                                                  context, 'Profile updated'),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint(
                                          'Profile photo upload failed: $e');
                                      if (context.mounted) {
                                        await DriverDialogs.showAlert(
                                          context,
                                          title: driverTr(context, 'Error'),
                                          message: driverTr(
                                            context,
                                            'Could not upload the photo. Please try again.',
                                          ),
                                          type: DriverMessageType.error,
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        safeSetState(() => _model
                                                .isDataUploading_uploadDataB4x =
                                            false);
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: colors.primarySoft,
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: (currentUserPhoto.isNotEmpty)
                                            ? NetworkImage(currentUserPhoto)
                                            : const AssetImage(
                                                    'assets/images/avatar.jpg')
                                                as ImageProvider,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.primary,
                                        width: 3,
                                      ),
                                      boxShadow: DsShadows.soft(),
                                    ),
                                  ),
                                ).animateOnPageLoad(
                                  animationsMap[
                                      'containerOnPageLoadAnimation1']!,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              AuthUserStreamWidget(
                                builder: (context) => Text(
                                  currentUserDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.headlineSmall.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ).animateOnPageLoad(
                                  animationsMap['textOnPageLoadAnimation1']!,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xs),
                              AuthUserStreamWidget(
                                builder: (context) => Text(
                                  valueOrDefault(
                                      currentUserDocument?.iDHoyhMNDOB, ''),
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ).animateOnPageLoad(
                                  animationsMap['textOnPageLoadAnimation2']!,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DriverPagePadding(
                          top: DsSpacing.md,
                          bottom: DsSpacing.xxl,
                          child: Column(
                            children: [
                              DsCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DsSpacing.sm,
                                  vertical: DsSpacing.xxs,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors.primarySoft,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.power_settings_new_rounded,
                                        color: colors.primaryStrong,
                                      ),
                                    ),
                                    Expanded(
                                      child: AuthUserStreamWidget(
                                        builder: (context) {
                                          final isOnline = valueOrDefault<bool>(
                                            currentUserDocument?.ngl,
                                            false,
                                          );
                                          return SwitchListTile.adaptive(
                                            value: isOnline,
                                            onChanged: (newValue) async {
                                              final wantOnline =
                                                  newValue == true;
                                              final result = wantOnline
                                                  ? await DriverOnlineState
                                                      .goOnline()
                                                  : await DriverOnlineState
                                                      .goOffline(
                                                      hasActiveTrip:
                                                          FFAppState()
                                                                  .revOrder !=
                                                              null,
                                                    );
                                              if (!result.ok &&
                                                  context.mounted) {
                                                await DriverDialogs.showAlert(
                                                  context,
                                                  title: driverTr(
                                                      context, 'Error'),
                                                  message: driverTrOrFallback(context, result.message, 'Something went wrong. Please try again.'),
                                                  type: DriverMessageType.error,
                                                );
                                              }
                                              if (mounted) {
                                                safeSetState(() {});
                                              }
                                            },
                                            title: Text(
                                              FFLocalizations.of(context)
                                                  .getText(
                                                '11lqnn52' /* Receiving bookings */,
                                              ),
                                              style:
                                                  typography.bodyLarge.copyWith(
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            activeThumbColor: colors.primary,
                                            activeTrackColor: colors.primary
                                                .withValues(alpha: 0.35),
                                            contentPadding:
                                                const EdgeInsetsDirectional
                                                    .fromSTEB(8, 0, 4, 0),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              _menuRow(
                                context: context,
                                icon: Icons.contact_support_outlined,
                                label: FFLocalizations.of(context).getText(
                                  'g5iyasoo' /* Have a problem? Contact us dir... */,
                                ),
                                onTap: () async {
                                  await launchURL(
                                    'https://wa.me/message/LHEPTGBXGS7UJ1',
                                  );
                                },
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              _menuRow(
                                context: context,
                                icon: Icons.account_balance_wallet_rounded,
                                label: driverTr(
                                    context, 'Wallet and transactions'),
                                onTap: () => context
                                    .pushNamed(DriverWalletWidget.routeName),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              _menuRow(
                                context: context,
                                icon: Icons.account_balance_rounded,
                                label: FFLocalizations.of(context).getText(
                                  '4627kcfu' /* Bank account update */,
                                ),
                                onTap: () => context
                                    .pushNamed(UpdetBankWidget.routeName),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              _menuRow(
                                context: context,
                                icon: Icons.edit_note_rounded,
                                label: driverTr(
                                    context, 'Edit Registration Data'),
                                onTap: () => context.pushNamed(
                                  RegdreverWidget.routeName,
                                  queryParameters: const {'mode': 'update'},
                                  extra: const <String, dynamic>{
                                    'mode': 'update',
                                  },
                                ),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              const DriverThemeModeCard(),
                              const SizedBox(height: DsSpacing.sm),
                              DsCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DsSpacing.sm,
                                  vertical: DsSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors.primarySoft,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.language_rounded,
                                        color: colors.primaryStrong,
                                      ),
                                    ),
                                    const SizedBox(width: DsSpacing.sm),
                                    Expanded(
                                      child: FlutterFlowLanguageSelector(
                                        width: 140,
                                        backgroundColor: colors.surface,
                                        borderColor: Colors.transparent,
                                        dropdownIconColor: colors.primary,
                                        borderRadius: DsRadius.sm,
                                        textStyle:
                                            typography.bodySmall.copyWith(
                                          color: colors.primary,
                                        ),
                                        hideFlags: true,
                                        flagSize: 24,
                                        flagTextGap: 8,
                                        currentLanguage:
                                            FFLocalizations.of(context)
                                                .languageCode,
                                        languages: FFLocalizations.languages(),
                                        onChanged: (lang) =>
                                            setAppLanguage(context, lang),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xl),
                              DsButton.outlined(
                                label: FFLocalizations.of(context).getText(
                                  'jso22q9p' /* Log Out */,
                                ),
                                expanded: true,
                                size: DsButtonSize.lg,
                                icon: Icons.logout_rounded,
                                onPressed: () async {
                                  GoRouter.of(context).prepareAuthEvent();
                                  await DriverLogoutService.logout();
                                  GoRouter.of(context).clearRedirectLocation();
                                  if (context.mounted) {
                                    context.go('/');
                                  }
                                },
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              DsButton.danger(
                                label: FFLocalizations.of(context).getText(
                                  'njmac6gm' /* Delete account */,
                                ),
                                expanded: true,
                                size: DsButtonSize.lg,
                                icon: Icons.delete_outline_rounded,
                                onPressed: () => _deleteAccount(context),
                              ),
                            ],
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

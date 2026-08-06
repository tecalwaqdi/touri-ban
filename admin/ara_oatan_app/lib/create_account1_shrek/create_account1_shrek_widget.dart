import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/toury_auth_navigation.dart';
import '/core/toury_brand_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_account1_shrek_model.dart';

export 'create_account1_shrek_model.dart';

class CreateAccount1ShrekWidget extends StatefulWidget {
  const CreateAccount1ShrekWidget({super.key});

  static String routeName = 'CreateAccount1Shrek';
  static String routePath = '/createAccount1Shrek';

  @override
  State<CreateAccount1ShrekWidget> createState() =>
      _CreateAccount1ShrekWidgetState();
}

class _CreateAccount1ShrekWidgetState extends State<CreateAccount1ShrekWidget>
    with TickerProviderStateMixin {
  late CreateAccount1ShrekModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateAccount1ShrekModel());

    _model.emailAddress3TextController ??= TextEditingController();
    _model.emailAddress3FocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    _model.passwordConfirmTextController ??= TextEditingController();
    _model.passwordConfirmFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
          RotateEffect(
            curve: Curves.easeInOut,
            delay: 600.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
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

  Future<void> _createAccount() async {
    GoRouter.of(context).prepareAuthEvent();
    if (_model.passwordTextController.text !=
        _model.passwordConfirmTextController.text) {
      DsSnackBar.show(
        context,
        message: 'ui_text_44134f762b'.tr(),
        tone: DsSnackTone.error,
      );
      return;
    }

    final user = await authManager.createAccountWithEmail(
      context,
      _model.emailAddress3TextController.text,
      _model.passwordTextController.text,
    );
    if (user == null) {
      return;
    }

    try {
      await UserRecord.collection.doc(user.uid).set(
            createUserRecordData(
              createdTime: getCurrentTimestamp,
              ngl: false,
              ismndob: false,
              actevMndob: false,
              actevUser: true,
            ),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('create account profile sync: $e');
    }

    if (!context.mounted) return;
    await tourySyncAuthState(context, user);
    if (!context.mounted) return;
    context.pushNamedAuth(
      RegComWidget.routeName,
      context.mounted,
      ignoreRedirect: true,
    );
  }

  Future<void> _cancelRegistration() async {
    var confirmDialogResponse = await showDialog<bool>(
          context: context,
          builder: (alertDialogContext) {
            return WebViewAware(
              child: AlertDialog(
                title: Text('ui_text_b4bbf18b10'.tr()),
                content: Text('ui_text_cf4d76accb'.tr()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(alertDialogContext, false),
                    child: Text('ui_text_5c528d9fa3'.tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(alertDialogContext, true),
                    child: Text('ui_text_d045bef8e5'.tr()),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
    if (confirmDialogResponse) {
      context.pushNamed(HomePagWidget.routeName);
    }
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
              body: SafeArea(
                top: true,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _StepBanner(),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                DsSpacing.md,
                                DsSpacing.lg,
                                DsSpacing.md,
                                DsSpacing.xxxl,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: DsConstants.maxFormWidth,
                                  ),
                                  child: _buildForm(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (responsiveVisibility(
                      context: context,
                      phone: false,
                      tablet: false,
                    ))
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(DsSpacing.md),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              image: const DecorationImage(
                                fit: BoxFit.contain,
                                image: AssetImage(
                                  'assets/images/WhatsApp_Image_2025-06-18_at_9.38.40_PM.jpeg',
                                ),
                              ),
                              borderRadius: DsRadius.large,
                              boxShadow: DsShadows.card(
                                dark: context.dsIsDark,
                              ),
                            ),
                          ).animateOnPageLoad(
                            animationsMap['containerOnPageLoadAnimation']!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsScaleFade(
          child: Center(
            child: TouryLogo(
              width: DsConstants.authLogoWidth,
              height: DsConstants.authLogoHeight,
              withBackground: false,
            ),
          ),
        ),
        const SizedBox(height: DsSpacing.md),
        const Center(
          child: Vision2030Mark(height: 38, maxWidth: 156),
        ),
        const SizedBox(height: DsSpacing.xl),
        DsFadeSlide(
          child: Text(
            FFLocalizations.of(context).getText(
              'ufwudlm6' /* Create an account */,
            ),
            textAlign: TextAlign.center,
            style: typography.headlineLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: DsSpacing.xs),
        DsFadeSlide(
          delay: DsDurations.instant,
          child: Text(
            FFLocalizations.of(context).getText(
              'li05az6c' /* Let's get started by filling o... */,
            ),
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: DsSpacing.xl),
        DsFadeSlide(
          delay: DsDurations.fast,
          child: DsCard(
            elevated: true,
            bordered: false,
            padding: const EdgeInsets.all(DsSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsTextField.email(
                  controller: _model.emailAddress3TextController,
                  focusNode: _model.emailAddress3FocusNode,
                  label: FFLocalizations.of(context).getText(
                    'nlv1oo7n' /* Email */,
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                DsTextField.password(
                  controller: _model.passwordTextController,
                  focusNode: _model.passwordFocusNode,
                  label: FFLocalizations.of(context).getText(
                    'qnz34oor' /* Password */,
                  ),
                  obscureText: !_model.passwordVisibility,
                  suffixIcon: DsIconButton(
                    icon: _model.passwordVisibility
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onPressed: () => safeSetState(
                      () => _model.passwordVisibility =
                          !_model.passwordVisibility,
                    ),
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                DsTextField.password(
                  controller: _model.passwordConfirmTextController,
                  focusNode: _model.passwordConfirmFocusNode,
                  label: FFLocalizations.of(context).getText(
                    'yapd6iet' /* Confirm Password */,
                  ),
                  obscureText: !_model.passwordConfirmVisibility,
                  suffixIcon: DsIconButton(
                    icon: _model.passwordConfirmVisibility
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onPressed: () => safeSetState(
                      () => _model.passwordConfirmVisibility =
                          !_model.passwordConfirmVisibility,
                    ),
                  ),
                ),
                const SizedBox(height: DsSpacing.xl),
                DsButton.primary(
                  label: FFLocalizations.of(context).getText(
                    'y3h5xljf' /* Next  */,
                  ),
                  icon: Icons.navigate_before_outlined,
                  size: DsButtonSize.lg,
                  expanded: true,
                  onPressed: _createAccount,
                ),
                const SizedBox(height: DsSpacing.sm),
                DsButton.danger(
                  label: FFLocalizations.of(context).getText(
                    'go8pkq43' /* Cancel Order */,
                  ),
                  icon: Icons.cancel_sharp,
                  size: DsButtonSize.lg,
                  expanded: true,
                  onPressed: _cancelRegistration,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Brand-coloured progress banner pinned above the registration form.
class _StepBanner extends StatelessWidget {
  const _StepBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.xl,
        vertical: DsSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.vertical(
          bottom: DsRadius.lgRadius,
        ),
        boxShadow: DsShadows.soft(dark: context.dsIsDark),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        FFLocalizations.of(context).getText(
          'mos06s1x' /* Step 2 of 3 */,
        ),
        style: typography.titleMedium.copyWith(color: colors.onPrimary),
      ),
    );
  }
}

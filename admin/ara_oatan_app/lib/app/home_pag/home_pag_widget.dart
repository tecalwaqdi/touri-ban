import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/toury_auth_navigation.dart';
import '/core/toury_brand_widgets.dart';
import '/core/toury_google_sign_in.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_pag_model.dart';
export 'home_pag_model.dart';

/// Brand mark footprint inside the auth header.
const double _kLogoWidth = DsConstants.logoWidth;
const double _kLogoHeight = DsConstants.logoHeight;

/// Compact language dropdown sitting opposite the brand mark.
const double _kLanguageSelectorWidth = DsConstants.languageSelectorWidth;

/// Segmented auth switcher: outer shell plus the pill height inside it.
const double _kTabBarHeight = DsConstants.authTabBarHeight;
const double _kTabHeight = _kTabBarHeight - DsSpacing.xs;

/// Terms of service / privacy policy destination.
const String _kTermsUrl = 'https://toury-taxi-privacy.web.app/privacy';

/// صفحة تسجيل سائق في تطبيق أرى وطن مع زر التسجيل
class HomePagWidget extends StatefulWidget {
  const HomePagWidget({super.key});

  static String routeName = 'HomePag';
  static String routePath = '/homePag';

  @override
  State<HomePagWidget> createState() => _HomePagWidgetState();
}

class _HomePagWidgetState extends State<HomePagWidget>
    with TickerProviderStateMixin {
  late HomePagModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _googleSignInLoading = false;
  bool _emailLoginLoading = false;
  bool _signUpLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_googleSignInLoading) return;
    safeSetState(() => _googleSignInLoading = true);
    try {
      await tourySignInWithGoogle(context);
    } finally {
      if (mounted) {
        safeSetState(() => _googleSignInLoading = false);
      }
    }
  }

  Future<void> _handleEmailLogin() async {
    if (_emailLoginLoading) return;
    safeSetState(() => _emailLoginLoading = true);
    try {
      GoRouter.of(context).prepareAuthEvent();
      final user = await authManager.signInWithEmail(
        context,
        _model.emailAddressLoginTextController.text,
        _model.passwordLoginTextController.text,
      );
      if (user == null) {
        return;
      }
      await touryFinishSignIn(context, user);
    } finally {
      if (mounted) {
        safeSetState(() => _emailLoginLoading = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (_signUpLoading) return;

    Function() navigate = () {};
    // تحقق من النموذج
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }

    safeSetState(() => _signUpLoading = true);
    try {
      if (_model.switchValue == true) {
        // إنشاء حساب جديد
        GoRouter.of(context).prepareAuthEvent();
        if (_model.passTextController.text !=
            _model.confpassTextController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ui_text_44134f762b'.tr()),
            ),
          );
          return;
        }

        final user = await authManager.createAccountWithEmail(
          context,
          _model.emailTextController.text,
          _model.passTextController.text,
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
          debugPrint('home signup profile sync: $e');
        }

        await tourySyncAuthState(context, user);

        navigate = () => context.pushNamedAuth(
              DemoDWidget.routeName,
              context.mounted,
              ignoreRedirect: true,
            );
      } else {
        await _showTermsRequiredDialog();
      }

      navigate();
    } finally {
      if (mounted) {
        safeSetState(() => _signUpLoading = false);
      }
    }
  }

  /// Overlay routes go to the root navigator, so they never inherit the
  /// page-level Theme — hand them the DS theme explicitly.
  Future<void> _showTermsRequiredDialog() {
    return showDialog(
      context: context,
      builder: (alertDialogContext) {
        return Theme(
          data: _dsThemeFor(alertDialogContext),
          child: Builder(
            builder: (dialogContext) {
              final colors = dialogContext.dsColors;
              final typography = dialogContext.dsTypography;

              return WebViewAware(
                child: AlertDialog(
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: DsRadius.extraLarge,
                  ),
                  title: Text(
                    'ui_text_b6f51cadc4'.tr(),
                    style: typography.headlineSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  content: Text(
                    'ui_text_1a4e87f7a9'.tr(),
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(alertDialogContext),
                      child: Text('ui_text_b0a98216a3'.tr()),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openTerms() => launchURL(_kTermsUrl);

  void _openForgotPassword() =>
      context.pushNamed(ForgotPasswordWidget.routeName);

  void _openPartnerRegistration() =>
      // الإنتقال إلى صفحة
      context.pushNamed(CreateAccount1ShrekWidget.routeName);

  void _openSignIn() => context.pushNamed(HomePagWidget.routeName);

  ThemeData _dsThemeFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? DsTheme.dark()
          : DsTheme.light();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePagModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 3,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    _model.emailAddressLoginTextController ??= TextEditingController();
    _model.emailAddressLoginFocusNode ??= FocusNode();

    _model.passwordLoginTextController ??= TextEditingController();
    _model.passwordLoginFocusNode ??= FocusNode();

    _model.naimTextController ??= TextEditingController();
    _model.naimFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.passTextController ??= TextEditingController();
    _model.passFocusNode ??= FocusNode();

    _model.confpassTextController ??= TextEditingController();
    _model.confpassFocusNode ??= FocusNode();

    _model.switchValue = false;

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dsTheme =
        brightness == Brightness.dark ? DsTheme.dark() : DsTheme.light();

    return Theme(
      data: dsTheme,
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: Scaffold(
                key: scaffoldKey,
                backgroundColor: colors.scaffold,
                body: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: DsConstants.maxContentWidth,
                      ),
                      child: Column(
                        children: [
                          _AuthHeader(
                            onLanguageChanged: (lang) =>
                                setAppLanguage(context, lang),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              DsSpacing.lg,
                              DsSpacing.xs,
                              DsSpacing.lg,
                              DsSpacing.md,
                            ),
                            child: DsFadeSlide(child: _WelcomeHeader()),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.lg,
                            ),
                            child: _AuthTabBar(
                              controller: _model.tabBarController,
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _model.tabBarController,
                              children: [
                                _LoginTabView(
                                  model: _model,
                                  loading: _emailLoginLoading,
                                  googleLoading: _googleSignInLoading,
                                  onLogin: _handleEmailLogin,
                                  onGoogleSignIn: _handleGoogleSignIn,
                                  onForgotPassword: _openForgotPassword,
                                  onTogglePasswordVisibility: () =>
                                      safeSetState(() =>
                                          _model.passwordLoginVisibility =
                                              !_model.passwordLoginVisibility),
                                ),
                                _SignUpTabView(
                                  model: _model,
                                  loading: _signUpLoading,
                                  googleLoading: _googleSignInLoading,
                                  onGoogleSignIn: _handleGoogleSignIn,
                                  onSubmit: _handleSignUp,
                                  onOpenTerms: _openTerms,
                                  onSignIn: _openSignIn,
                                  onTermsChanged: (value) => safeSetState(
                                      () => _model.switchValue = value),
                                  onTogglePassVisibility: () => safeSetState(
                                      () => _model.passVisibility =
                                          !_model.passVisibility),
                                  onToggleConfPassVisibility: () =>
                                      safeSetState(() =>
                                          _model.confpassVisibility =
                                              !_model.confpassVisibility),
                                ),
                                _PartnerTabView(
                                  onRegister: _openPartnerRegistration,
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
            ),
          );
        },
      ),
    );
  }
}

/// Brand mark opposite a compact language switcher.
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.onLanguageChanged});

  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.lg,
        DsSpacing.sm,
        DsSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          const TouryLogo(
            width: _kLogoWidth,
            height: _kLogoHeight,
            withBackground: false,
          ),
          const Spacer(),
          Tooltip(
            message: FFLocalizations.of(context).getText(
              'y9quj14n' /* Select the app language */,
            ),
            child: FlutterFlowLanguageSelector(
              width: _kLanguageSelectorWidth,
              backgroundColor: colors.surface,
              borderColor: colors.border,
              dropdownColor: colors.surface,
              dropdownIconColor: colors.primary,
              borderRadius: DsRadius.sm,
              textStyle: typography.labelMedium.copyWith(
                color: colors.textPrimary,
              ),
              hideFlags: false,
              flagSize: DsSpacing.sm,
              flagTextGap: DsSpacing.xs,
              currentLanguage: FFLocalizations.of(context).languageCode,
              languages: FFLocalizations.languages(),
              onChanged: onLanguageChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Editorial welcome block — accent rule plus title and supporting copy.
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      width: double.infinity,
      padding: DsSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.primarySoft, colors.surface],
        ),
        borderRadius: DsRadius.large,
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        boxShadow: DsShadows.soft(dark: context.dsIsDark),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: DsSpacing.xxs,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: DsRadius.pill,
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ux_welcome_login'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium.copyWith(
                      color: colors.primaryStrong,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Text(
                    'ux_welcome_login_sub'.tr(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented control styling for the three auth entry points.
class _AuthTabBar extends StatelessWidget {
  const _AuthTabBar({required this.controller});

  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      height: _kTabBarHeight,
      padding: const EdgeInsets.all(DsSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: DsRadius.large,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelColor: colors.onPrimary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: typography.labelSmall,
        unselectedLabelStyle: typography.labelSmall,
        indicator: BoxDecoration(
          color: colors.primary,
          borderRadius: DsRadius.medium,
          boxShadow: DsShadows.soft(dark: context.dsIsDark),
        ),
        tabs: [
          Tab(
            height: _kTabHeight,
            child: _AuthTabLabel(
              icon: Icons.login_rounded,
              label: 'Login'.tr(),
            ),
          ),
          Tab(
            height: _kTabHeight,
            child: _AuthTabLabel(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Email Address'.tr(),
            ),
          ),
          Tab(
            height: _kTabHeight,
            child: _AuthTabLabel(
              icon: Icons.handshake_rounded,
              label: 'Success Partner Registration'.tr(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon stacked over a two-line label, tinted by the active TabBar style.
class _AuthTabLabel extends StatelessWidget {
  const _AuthTabLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.xxs,
        vertical: DsSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: DsIcons.sm, color: style.color),
          const SizedBox(height: DsSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// Email + password sign in, Google sign in, and password recovery.
class _LoginTabView extends StatelessWidget {
  const _LoginTabView({
    required this.model,
    required this.loading,
    required this.googleLoading,
    required this.onLogin,
    required this.onGoogleSignIn,
    required this.onForgotPassword,
    required this.onTogglePasswordVisibility,
  });

  final HomePagModel model;
  final bool loading;
  final bool googleLoading;
  final VoidCallback onLogin;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onTogglePasswordVisibility;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.lg,
        DsSpacing.xl,
        DsSpacing.lg,
        DsSpacing.massive,
      ),
      child: DsFadeSlide(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsTextField.email(
              controller: model.emailAddressLoginTextController,
              focusNode: model.emailAddressLoginFocusNode,
              label: 'Email Address'.tr(),
              hint: 'Enter your email...'.tr(),
            ),
            const SizedBox(height: DsSpacing.md),
            DsTextField.password(
              controller: model.passwordLoginTextController,
              focusNode: model.passwordLoginFocusNode,
              label: 'Password'.tr(),
              obscureText: !model.passwordLoginVisibility,
              suffixIcon: _VisibilityToggle(
                visible: model.passwordLoginVisibility,
                onPressed: onTogglePasswordVisibility,
              ),
            ),
            const SizedBox(height: DsSpacing.xl),
            DsButton.primary(
              label: 'Login'.tr(),
              size: DsButtonSize.lg,
              expanded: true,
              loading: loading,
              onPressed: onLogin,
            ),
            const SizedBox(height: DsSpacing.lg),
            const _OrDivider(),
            _GoogleSignInSection(
              loading: googleLoading,
              onPressed: onGoogleSignIn,
            ),
            const SizedBox(height: DsSpacing.lg),
            DsButton.text(
              label: FFLocalizations.of(context).getText(
                'h9t30wk4' /* Forgot Password ? */,
              ),
              onPressed: onForgotPassword,
            ),
          ],
        ),
      ),
    );
  }
}

/// Account creation form — validators and the terms gate live in the model.
class _SignUpTabView extends StatelessWidget {
  const _SignUpTabView({
    required this.model,
    required this.loading,
    required this.googleLoading,
    required this.onGoogleSignIn,
    required this.onSubmit,
    required this.onOpenTerms,
    required this.onSignIn,
    required this.onTermsChanged,
    required this.onTogglePassVisibility,
    required this.onToggleConfPassVisibility,
  });

  final HomePagModel model;
  final bool loading;
  final bool googleLoading;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSubmit;
  final VoidCallback onOpenTerms;
  final VoidCallback onSignIn;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onTogglePassVisibility;
  final VoidCallback onToggleConfPassVisibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.lg,
        DsSpacing.lg,
        DsSpacing.lg,
        DsSpacing.massive,
      ),
      child: DsFadeSlide(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GoogleSignInSection(
              loading: googleLoading,
              onPressed: onGoogleSignIn,
              label: 'Create an account with Google'.tr(),
            ),
            const SizedBox(height: DsSpacing.md),
            const _OrDivider(),
            const SizedBox(height: DsSpacing.lg),
            Text(
              FFLocalizations.of(context).getText(
                'tjrl68rw' /* Please fill in all fields to r... */,
              ),
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: DsSpacing.lg),
            Form(
              key: model.formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DsFormField(
                    controller: model.naimTextController,
                    focusNode: model.naimFocusNode,
                    label: FFLocalizations.of(context).getText(
                      'jkt2g0im' /* Full Name */,
                    ),
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator:
                        model.naimTextControllerValidator.asValidator(context),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  _DsFormField(
                    controller: model.emailTextController,
                    focusNode: model.emailFocusNode,
                    label: FFLocalizations.of(context).getText(
                      'olr4d7yy' /* Email Address */,
                    ),
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator:
                        model.emailTextControllerValidator.asValidator(context),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  _DsFormField(
                    controller: model.passTextController,
                    focusNode: model.passFocusNode,
                    label: FFLocalizations.of(context).getText(
                      'd0nu9j5x' /* Password */,
                    ),
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !model.passVisibility,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    suffixIcon: _VisibilityToggle(
                      visible: model.passVisibility,
                      onPressed: onTogglePassVisibility,
                    ),
                    validator:
                        model.passTextControllerValidator.asValidator(context),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  _DsFormField(
                    controller: model.confpassTextController,
                    focusNode: model.confpassFocusNode,
                    label: FFLocalizations.of(context).getText(
                      '558w2xwl' /* Confirm Password */,
                    ),
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: !model.confpassVisibility,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    suffixIcon: _VisibilityToggle(
                      visible: model.confpassVisibility,
                      onPressed: onToggleConfPassVisibility,
                    ),
                    validator: model.confpassTextControllerValidator
                        .asValidator(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DsPressable(
                onTap: onOpenTerms,
                child: Text(
                  FFLocalizations.of(context).getText(
                    'g2im5b8x' /* Read the Terms of Service and ... */,
                  ),
                  style: typography.bodySmall.copyWith(
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            _TermsAgreementCard(
              value: model.switchValue!,
              onChanged: onTermsChanged,
            ),
            const SizedBox(height: DsSpacing.xl),
            DsButton.primary(
              label: FFLocalizations.of(context).getText(
                'y6zcycni' /* Register */,
              ),
              size: DsButtonSize.lg,
              expanded: true,
              loading: loading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: DsSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  FFLocalizations.of(context).getText(
                    't58lgmpo' /* Already have an account? */,
                  ),
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: DsSpacing.xs),
                DsPressable(
                  onTap: onSignIn,
                  child: Text(
                    FFLocalizations.of(context).getText(
                      'oo3b6ysw' /* Sign In */,
                    ),
                    style: typography.labelLarge.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Success-partner pitch and entry point into the partner registration flow.
class _PartnerTabView extends StatelessWidget {
  const _PartnerTabView({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DsSpacing.lg,
        DsSpacing.xl,
        DsSpacing.lg,
        DsSpacing.massive,
      ),
      child: DsScaleFade(
        child: DsCard(
          elevated: true,
          padding: const EdgeInsets.all(DsSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(DsSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.handshake_rounded,
                  color: colors.primary,
                  size: DsIcons.xl,
                ),
              ),
              const SizedBox(height: DsSpacing.xl),
              Text(
                'Welcome to Become a Success Partner'.tr(),
                textAlign: TextAlign.center,
                style: typography.headlineSmall.copyWith(
                  color: colors.primaryStrong,
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
              Text(
                'Join us as a Success Partner to enhance our service quality and accelerate outreach, whether you are a government entity, a company, or an individual.'
                    .tr(),
                textAlign: TextAlign.center,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: DsSpacing.xl),
              DsButton.primary(
                label: 'Register Now'.tr(),
                size: DsButtonSize.lg,
                expanded: true,
                icon: Icons.arrow_forward_rounded,
                onPressed: onRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google sign in, gated by the `Settings` document with `id == 1`.
class _GoogleSignInSection extends StatelessWidget {
  const _GoogleSignInSection({
    required this.loading,
    required this.onPressed,
    this.label,
  });

  final bool loading;
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SettingsRecord>>(
      stream: TouryFirestoreCache.settingsStream(
        queryBuilder: (settingsRecord) => settingsRecord.where(
          'id',
          isEqualTo: 1,
        ),
        singleRecord: true,
      ),
      builder: (context, snapshot) {
        final settings = snapshot.hasData && snapshot.data!.isNotEmpty
            ? snapshot.data!.first
            : null;

        return Center(
          child: touryGoogleSignInButtonFromSettings(
            context: context,
            settings: settings,
            loading: loading,
            onPressed: onPressed,
            label: label,
          ),
        );
      },
    );
  }
}

/// Hairline rule with a centred "or" caption.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.sm),
          child: Text(
            'auth_google_or'.tr(),
            style: typography.labelMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.divider)),
      ],
    );
  }
}

/// Terms acceptance gate required before an account can be created.
class _TermsAgreementCard extends StatelessWidget {
  const _TermsAgreementCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      color: value ? colors.selected : colors.surface,
      child: Row(
        children: [
          Expanded(
            child: Text(
              FFLocalizations.of(context).getText(
                'ouix0gb1' /* I agree to the Terms & Conditi... */,
              ),
              style: typography.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.disabled,
            inactiveThumbColor: colors.iconMuted,
          ),
        ],
      ),
    );
  }
}

/// Obscure-text toggle kept out of the keyboard focus order.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;

    return ExcludeFocus(
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: colors.iconMuted,
          size: DsIcons.sm,
        ),
      ),
    );
  }
}

/// [DsTextField] styling on a [TextFormField] so `formKey.validate()` still
/// drives the sign-up validators declared in [HomePagModel].
class _DsFormField extends StatelessWidget {
  const _DsFormField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.prefixIcon,
    this.validator,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: DsRadius.medium,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      minLines: 1,
      maxLines: 1,
      cursorColor: colors.primary,
      style: typography.bodyLarge.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, size: DsIcons.sm),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colors.surface,
        contentPadding: DsSpacing.inputContentPadding,
        labelStyle: typography.bodyMedium.copyWith(
          color: colors.textSecondary,
        ),
        hintStyle: typography.bodyMedium.copyWith(color: colors.hint),
        errorStyle: typography.bodySmall.copyWith(color: colors.error),
        border: border(colors.border),
        enabledBorder: border(colors.border),
        focusedBorder: border(colors.focus, 1.6),
        errorBorder: border(colors.error),
        focusedErrorBorder: border(colors.error, 1.6),
        disabledBorder: border(colors.disabled),
      ),
    );
  }
}

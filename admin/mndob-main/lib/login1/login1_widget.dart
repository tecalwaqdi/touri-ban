import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_auth_errors.dart';
import '/core/driver_auth_validation_service.dart';
import '/core/driver_bootstrap.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_i18n.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'login1_model.dart';

export 'login1_model.dart';

class Login1Widget extends StatefulWidget {
  const Login1Widget({super.key});

  static String routeName = 'Login1';
  static String routePath = '/login1';

  @override
  State<Login1Widget> createState() => _Login1WidgetState();
}

class _Login1WidgetState extends State<Login1Widget> {
  late Login1Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Login1Model());

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DriverBootstrap.clearAnonymousSession();
      if (mounted) safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = DriverAuthValidationService.normalizeEmail(
      _model.emailAddressTextController.text,
    );
    final emailError = DriverAuthValidationService.validateEmail(
      _model.emailAddressTextController.text,
    );
    if (emailError != null || email == null) {
      await DriverDialogs.showAlert(
        context,
        title: driverTr(context, 'Error'),
        message: driverTr(
          context,
          emailError ?? 'Please enter a valid email',
        ),
        type: DriverMessageType.warning,
      );
      return;
    }
    safeSetState(() => _model.isResettingPassword = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      DriverAuthErrors.logSafely(e);
    } catch (e) {
      DriverAuthErrors.logSafely(e);
    } finally {
      if (mounted) {
        safeSetState(() => _model.isResettingPassword = false);
      }
    }
    if (!mounted) return;
    await DriverDialogs.showAlert(
      context,
      title: driverTr(context, 'Success'),
      message: driverTr(
        context,
        'If an account exists for this email, a reset link has been sent.',
      ),
      type: DriverMessageType.success,
    );
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    final email = DriverAuthValidationService.normalizeEmail(
      _model.emailAddressTextController.text,
    );
    final password = _model.passwordTextController.text;
    final emailError = DriverAuthValidationService.validateEmail(
      _model.emailAddressTextController.text,
    );
    final passwordError = DriverAuthValidationService.validatePassword(
      password,
    );
    if (emailError != null || passwordError != null || email == null) {
      _model.formKey.currentState?.validate();
      await DriverDialogs.showAlert(
        context,
        title: driverTr(context, 'Error'),
        message: driverTr(
          context,
          emailError ?? passwordError ?? 'Please enter a valid email',
        ),
        type: DriverMessageType.warning,
      );
      return;
    }

    safeSetState(() => _model.isSigningIn = true);
    try {
      GoRouter.of(context).prepareAuthEvent();

      final user = await authManager.signInWithEmail(
        context,
        email,
        password,
      );
      if (user == null) {
        return;
      }

      UserRecord? doc = currentUserDocument;
      if (doc == null && currentUserReference != null) {
        try {
          doc = await UserRecord.getDocumentOnce(
            currentUserReference!,
          ).timeout(const Duration(seconds: 10));
          currentUserDocument = doc;
        } catch (e) {
          DriverAuthErrors.logSafely(e);
          if (mounted) {
            await DriverDialogs.showAlert(
              context,
              title: driverTr(context, 'Error'),
              message: driverTr(
                context,
                'Could not load your driver profile. Please try again.',
              ),
              type: DriverMessageType.error,
            );
          }
          return;
        }
      }

      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      DriverAuthErrors.logSafely(e);
      if (mounted) {
        await DriverDialogs.showAlert(
          context,
          title: driverTr(context, 'Error'),
          message: DriverAuthErrors.localized(context, e),
          type: DriverMessageType.error,
        );
      }
    } catch (e) {
      DriverAuthErrors.logSafely(e);
      if (mounted) {
        await DriverDialogs.showAlert(
          context,
          title: driverTr(context, 'Error'),
          message: DriverAuthErrors.localized(context, e),
          type: DriverMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        safeSetState(() => _model.isSigningIn = false);
      }
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final form = SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.md,
                        vertical: DsSpacing.lg,
                      ),
                      child: DriverFormWidth(
                        child: _buildLoginCard(context),
                      ),
                    );

                    if (constraints.maxWidth < 700) {
                      return form;
                    }

                    return Row(
                      children: [
                        Expanded(flex: 4, child: form),
                        Expanded(flex: 6, child: _BrandPanel(colors: colors)),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: Form(
        key: _model.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: DsRadius.small,
                child: Image.asset(
                  'assets/images/logoTor.png',
                  width: DsConstants.logoWidth,
                  height: DsConstants.heroHeight / 2,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    FFLocalizations.of(context).getText(
                      'fl8vzh1e' /* Welcome Back */,
                    ),
                    style: typography.headlineMedium.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.xs,
                      vertical: DsSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.info),
                      borderRadius: DsRadius.small,
                    ),
                    child: FlutterFlowLanguageSelector(
                      width: 140,
                      backgroundColor: colors.surface,
                      borderColor: Colors.transparent,
                      dropdownIconColor: colors.primary,
                      borderRadius: DsRadius.sm,
                      textStyle: typography.bodySmall.copyWith(
                        color: colors.primary,
                      ),
                      hideFlags: true,
                      flagSize: 24,
                      flagTextGap: 8,
                      currentLanguage:
                          FFLocalizations.of(context).languageCode,
                      languages: FFLocalizations.languages(),
                      onChanged: (lang) => setAppLanguage(context, lang),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(
              FFLocalizations.of(context).getText(
                '5xhefls4' /* Let's get started by filling o... */,
              ),
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: DsSpacing.xl),
            DsTextField.email(
              controller: _model.emailAddressTextController,
              focusNode: _model.emailAddressFocusNode,
              label: FFLocalizations.of(context).getText(
                '7cawtif0' /* Email */,
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            DsTextField.password(
              controller: _model.passwordTextController,
              focusNode: _model.passwordFocusNode,
              label: FFLocalizations.of(context).getText(
                'owolsfc8' /* Password */,
              ),
              obscureText: !_model.passwordVisibility,
              suffixIcon: DsIconButton(
                icon: _model.passwordVisibility
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: DsIcons.md,
                onPressed: () => safeSetState(
                  () => _model.passwordVisibility = !_model.passwordVisibility,
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DsButton.text(
                label: driverTr(context, 'Forgot password?'),
                enabled: !_model.isResettingPassword,
                onPressed: _handleForgotPassword,
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            DsButton.primary(
              label: _model.isSigningIn
                  ? driverTr(context, 'Signing in…')
                  : FFLocalizations.of(context).getText(
                      'me4pz27r' /* Sign In */,
                    ),
              loading: _model.isSigningIn,
              enabled: !_model.isSigningIn,
              expanded: true,
              size: DsButtonSize.lg,
              icon: Icons.login_rounded,
              onPressed: _handleSignIn,
            ),
            const SizedBox(height: DsSpacing.lg),
            RichText(
              textAlign: TextAlign.center,
              textScaler: MediaQuery.of(context).textScaler,
              text: TextSpan(
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: FFLocalizations.of(context).getText(
                      'q6t722yp' /* Do you want to register? */,
                    ),
                  ),
                  TextSpan(
                    text: FFLocalizations.of(context).getText(
                      'h1ev5ljd' /*  Register now  */,
                    ),
                    style: typography.bodyMedium.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.pushNamed(RegdreverWidget.routeName);
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            RichText(
              textAlign: TextAlign.center,
              textScaler: MediaQuery.of(context).textScaler,
              text: TextSpan(
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: FFLocalizations.of(context).getText(
                      'ix8ofow7' /* Terms of Service and Privacy P... */,
                    ),
                  ),
                  TextSpan(
                    text: FFLocalizations.of(context).getText(
                      'm5j0ga8s' /* Click here */,
                    ),
                    style: typography.bodyMedium.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await launchURL(
                          'https://toury-taxi-privacy.web.app/privacy',
                        );
                      },
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

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.colors});

  final DsColors colors;

  @override
  Widget build(BuildContext context) {
    final typography = context.dsTypography;

    return Container(
      margin: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primaryStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DsRadius.extraLarge,
        boxShadow: DsShadows.floating(),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_taxi_rounded,
              size: DsConstants.avatarXl,
              color: colors.onPrimary,
            ),
            const SizedBox(height: DsSpacing.md),
            Text(
              DsConstants.brandName,
              textAlign: TextAlign.center,
              style: typography.displaySmall.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/toury_auth_navigation.dart';
import '/core/toury_google_sign_in.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'logen_model.dart';

export 'logen_model.dart';

class LogenWidget extends StatefulWidget {
  const LogenWidget({super.key});

  static String routeName = 'logen';
  static String routePath = '/logen';

  @override
  State<LogenWidget> createState() => _LogenWidgetState();
}

class _LogenWidgetState extends State<LogenWidget>
    with TickerProviderStateMixin {
  late LogenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};
  bool _googleSignInLoading = false;

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

  Future<void> _handleEmailSignIn() async {
    GoRouter.of(context).prepareAuthEvent();

    final user = await authManager.signInWithEmail(
      context,
      _model.emailAddressTextController.text,
      _model.passwordTextController.text,
    );
    if (user == null) {
      return;
    }

    await touryFinishSignIn(context, user);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LogenModel());

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.0, 140.0),
            end: const Offset(0.0, 0.0),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.9, 1.0),
            end: const Offset(1.0, 1.0),
          ),
          TiltEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(-0.349, 0),
            end: const Offset(0, 0),
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
              resizeToAvoidBottomInset: true,
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
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: DsConstants.maxFormWidth,
                          ),
                          child: _buildLoginCard(context),
                        ),
                      ),
                    );

                    if (constraints.maxWidth < 700) {
                      return form;
                    }

                    return Row(
                      children: [
                        Expanded(flex: 4, child: form),
                        const Expanded(flex: 6, child: _BrandPanel()),
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
    final compact = TouryLayout.isCompact(context);

    return DsCard(
      elevated: true,
      padding: EdgeInsets.all(compact ? DsSpacing.lg : DsSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildLoginFields(context, compact: compact),
      ),
    ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!);
  }

  List<Widget> _buildLoginFields(
    BuildContext context, {
    required bool compact,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return [
      Center(
        child: ClipRRect(
          borderRadius: DsRadius.small,
          child: Image.asset(
            'assets/images/torytaxi.png',
            width: compact ? 120.0 : DsConstants.logoWidth,
            height: compact ? 76.0 : DsConstants.heroHeight / 2,
            fit: BoxFit.contain,
          ),
        ),
      ),
      const SizedBox(height: DsSpacing.lg),
      Text(
        'Login'.tr(),
        textAlign: TextAlign.center,
        style: typography.headlineMedium.copyWith(color: colors.textPrimary),
      ),
      const SizedBox(height: DsSpacing.xl),
      DsTextField.email(
        controller: _model.emailAddressTextController,
        focusNode: _model.emailAddressFocusNode,
        label: 'Email Address'.tr(),
      ),
      const SizedBox(height: DsSpacing.md),
      DsTextField.password(
        controller: _model.passwordTextController,
        focusNode: _model.passwordFocusNode,
        label: 'Password'.tr(),
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
      const SizedBox(height: DsSpacing.xl),
      DsButton.primary(
        label: 'Login'.tr(),
        size: DsButtonSize.lg,
        expanded: true,
        icon: Icons.login_rounded,
        onPressed: _handleEmailSignIn,
      ),
      const SizedBox(height: DsSpacing.lg),
      Row(
        children: [
          const Expanded(child: DsDivider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.sm),
            child: Text(
              'auth_google_or'.tr(),
              style: typography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: DsDivider()),
        ],
      ),
      const SizedBox(height: DsSpacing.lg),
      TouryGoogleSignInButton(
        label: 'Login with Google'.tr(),
        loading: _googleSignInLoading,
        onPressed: _handleGoogleSignIn,
      ),
      const SizedBox(height: DsSpacing.lg),
      RichText(
        textAlign: TextAlign.center,
        textScaler: MediaQuery.of(context).textScaler,
        text: TextSpan(
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          children: [
            TextSpan(text: "don't_have_account".tr()),
            TextSpan(
              text: ' ${"Sign Up here".tr()}',
              style: typography.bodyMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.pushNamed(
                    CreateAccount1ShrekWidget.routeName,
                  );
                },
            ),
          ],
        ),
      ),
    ];
  }
}

/// Brand artwork column shown beside the form on wide layouts.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primaryStrong],
          stops: const [0.0, 1.0],
          begin: const AlignmentDirectional(0.87, -1.0),
          end: const AlignmentDirectional(-0.87, 1.0),
        ),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              DsIcons.car,
              size: DsConstants.avatarXl,
              color: colors.onPrimary,
            ),
            const SizedBox(height: DsSpacing.md),
            Text(
              DsConstants.brandName,
              textAlign: TextAlign.center,
              style: typography.displaySmall.copyWith(color: colors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

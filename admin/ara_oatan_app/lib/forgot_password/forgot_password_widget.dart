import '/auth/firebase_auth/auth_util.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'forgot_password_model.dart';
export 'forgot_password_model.dart';

class ForgotPasswordWidget extends StatefulWidget {
  const ForgotPasswordWidget({super.key});

  static String routeName = 'ForgotPassword';
  static String routePath = '/forgotPassword';

  @override
  State<ForgotPasswordWidget> createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget> {
  late ForgotPasswordModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ForgotPasswordModel());

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_model.emailAddressTextController.text.isEmpty) {
      DsSnackBar.show(
        context,
        message: 'ui_text_35d76b889c'.tr(),
        tone: DsSnackTone.warning,
      );
      return;
    }
    await authManager.resetPassword(
      email: _model.emailAddressTextController.text,
      context: context,
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
              appBar: DsAppBar(
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.safePop();
                  },
                ),
                title: FFLocalizations.of(context).getText(
                  'fo18bjgj' /* Forgot Password */,
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: DsSpacing.pagePadding,
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: DsConstants.maxFormWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Desktop-only inline back affordance (app bar is hidden there).
                          if (responsiveVisibility(
                            context: context,
                            phone: false,
                            tablet: false,
                          ))
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: DsPressable(
                                onTap: () async {
                                  context.safePop();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: DsSpacing.sm,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DsIcon(DsIcons.back, size: DsIcons.sm),
                                      const SizedBox(width: DsSpacing.xs),
                                      Text(
                                        FFLocalizations.of(context).getText(
                                          'v30bz8ww' /* Back */,
                                        ),
                                        style: typography.labelLarge.copyWith(
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: DsSpacing.md),
                          DsFadeSlide(
                            child: Center(
                              child: Container(
                                width: DsConstants.avatarXl,
                                height: DsConstants.avatarXl,
                                decoration: BoxDecoration(
                                  color: colors.primarySoft,
                                  shape: BoxShape.circle,
                                  boxShadow: DsShadows.soft(
                                    dark: context.dsIsDark,
                                  ),
                                ),
                                child: Icon(
                                  Icons.lock_reset_rounded,
                                  size: DsIcons.xl,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: DsSpacing.md),
                          DsFadeSlide(
                            delay: DsDurations.instant,
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'fo18bjgj' /* Forgot Password */,
                              ),
                              textAlign: TextAlign.center,
                              style: typography.headlineMedium.copyWith(
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
                                'nd3w4jly' /* We will send you an email with... */,
                              ),
                              textAlign: TextAlign.center,
                              style: typography.bodyMedium.copyWith(
                                color: colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: DsSpacing.md),
                          DsFadeSlide(
                            delay: DsDurations.fast,
                            child: DsCard(
                              elevated: true,
                              padding: const EdgeInsets.all(DsSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DsTextField.email(
                                    controller:
                                        _model.emailAddressTextController,
                                    focusNode: _model.emailAddressFocusNode,
                                    label: FFLocalizations.of(context).getText(
                                      'vd25vt38' /* Your email address... */,
                                    ),
                                    hint: FFLocalizations.of(context).getText(
                                      '1x3j3nfg' /* Enter your email... */,
                                    ),
                                  ),
                                  const SizedBox(height: DsSpacing.md),
                                  DsButton.primary(
                                    label:
                                        FFLocalizations.of(context).getText(
                                      '6e3nyqmx' /* Send Link */,
                                    ),
                                    size: DsButtonSize.md,
                                    expanded: true,
                                    icon: Icons.send_rounded,
                                    onPressed: _sendResetLink,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: DsSpacing.md),
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

import 'package:flutter/material.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'errorpay_model.dart';

export 'errorpay_model.dart';

/// صفحة خطا في عملية الدفع ورسالة يرجى التأكد من توفر رصيد كافي في بطاقتك  او
/// المحاولة مرة اخرى
class ErrorpayWidget extends StatefulWidget {
  const ErrorpayWidget({super.key});

  static String routeName = 'ERRORPAY';
  static String routePath = '/errorpay';

  @override
  State<ErrorpayWidget> createState() => _ErrorpayWidgetState();
}

class _ErrorpayWidgetState extends State<ErrorpayWidget> {
  late ErrorpayModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ErrorpayModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _retry() {
    debugPrint('Button pressed ...');
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
                title: FFLocalizations.of(context).getText(
                  '25zdo4ux' /* فشلت عملية الدفع */,
                ),
              ),
              body: SafeArea(
                top: true,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(DsSpacing.xl),
                    child: DsScaleFade(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: DsConstants.maxFormWidth,
                        ),
                        child: DsCard(
                          elevated: true,
                          padding: const EdgeInsets.all(DsSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: DsConstants.avatarXl,
                                  height: DsConstants.avatarXl,
                                  decoration: BoxDecoration(
                                    color: colors.errorContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    size: DsIcons.xl,
                                    color: colors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(height: DsSpacing.md),
                              Text(
                                FFLocalizations.of(context).getText(
                                  'u0wt86mo' /* عذراً! */,
                                ),
                                textAlign: TextAlign.center,
                                style: typography.headlineSmall.copyWith(
                                  color: colors.error,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xxs),
                              Text(
                                FFLocalizations.of(context).getText(
                                  'nqc0mi73' /* فشلت عملية الدفع */,
                                ),
                                textAlign: TextAlign.center,
                                style: typography.titleLarge.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.sm),
                              Text(
                                FFLocalizations.of(context).getText(
                                  'gvvjgig7' /* يرجى التأكد من توفر رصيد كافي ... */,
                                ),
                                textAlign: TextAlign.center,
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xl),
                              DsButton.primary(
                                label: FFLocalizations.of(context).getText(
                                  'b45aq0r6' /* حاول مرة أخرى */,
                                ),
                                icon: Icons.refresh_rounded,
                                expanded: true,
                                size: DsButtonSize.lg,
                                onPressed: _retry,
                              ),
                            ],
                          ),
                        ),
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

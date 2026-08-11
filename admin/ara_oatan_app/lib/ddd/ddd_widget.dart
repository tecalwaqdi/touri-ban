import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'ddd_model.dart';
export 'ddd_model.dart';

/// Trip Rating and Feedback Interface
class DddWidget extends StatefulWidget {
  const DddWidget({super.key});

  static String routeName = 'ddd';
  static String routePath = '/ddd';

  @override
  State<DddWidget> createState() => _DddWidgetState();
}

class _DddWidgetState extends State<DddWidget> {
  late DddModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DddModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

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
                  'i8rrx6hq' /* Rating */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () {
                    context.safePop();
                  },
                ),
                actions: const [],
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpacing.md,
                      DsSpacing.lg,
                      DsSpacing.md,
                      DsSpacing.xxl,
                    ),
                    child: DsFadeSlide(
                      child: DsCard(
                        elevated: true,
                        bordered: false,
                        padding: const EdgeInsets.all(DsSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40.0),
                              child: Image.asset(
                                'assets/images/WhatsApp_Image_2025-06-01_at_10.47.35_PM.jpeg',
                                width: 80.0,
                                height: 80.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '1ucazbmt' /* Gregory Smith */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.titleLarge.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'zi4o4n3s' /* 652 - UKW */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ].divide(const SizedBox(height: DsSpacing.xxs)),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'qqq313e4' /* How is your trip? */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.headlineSmall.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'ohxq7rrk' /* Your feedback will help improv... */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.bodyLarge.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ].divide(const SizedBox(height: DsSpacing.xs)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: colors.warning,
                                  size: DsConstants.iconXl,
                                ),
                                Icon(
                                  Icons.star_rounded,
                                  color: colors.warning,
                                  size: DsConstants.iconXl,
                                ),
                                Icon(
                                  Icons.star_rounded,
                                  color: colors.warning,
                                  size: DsConstants.iconXl,
                                ),
                                Icon(
                                  Icons.star_rounded,
                                  color: colors.warning,
                                  size: DsConstants.iconXl,
                                ),
                                Icon(
                                  Icons.star_rounded,
                                  color: colors.disabled,
                                  size: DsConstants.iconXl,
                                ),
                              ].divide(const SizedBox(width: DsSpacing.xs)),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  hintText:
                                      FFLocalizations.of(context).getText(
                                    '6ayvu6j9' /* Additional comments... */,
                                  ),
                                  hintStyle: typography.bodyLarge.copyWith(
                                    color: colors.hint,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: colors.border,
                                      width: 1.0,
                                    ),
                                    borderRadius: DsRadius.medium,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: colors.focus,
                                      width: 1.6,
                                    ),
                                    borderRadius: DsRadius.medium,
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: colors.error,
                                      width: 1.0,
                                    ),
                                    borderRadius: DsRadius.medium,
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: colors.error,
                                      width: 1.6,
                                    ),
                                    borderRadius: DsRadius.medium,
                                  ),
                                  filled: true,
                                  fillColor: colors.surface,
                                  contentPadding:
                                      const EdgeInsets.all(DsSpacing.md),
                                ),
                                style: typography.bodyLarge.copyWith(
                                  color: colors.textPrimary,
                                ),
                                maxLines: 4,
                                minLines: 4,
                                cursorColor: colors.primary,
                                validator: _model.textControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            DsButton.primary(
                              label: FFLocalizations.of(context).getText(
                                'arhjx6bc' /* Submit Review */,
                              ),
                              expanded: true,
                              size: DsButtonSize.lg,
                              onPressed: () {
                                print('Button pressed ...');
                              },
                            ),
                          ].divide(const SizedBox(height: DsSpacing.md)),
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

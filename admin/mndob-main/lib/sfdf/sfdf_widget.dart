import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'sfdf_model.dart';
export 'sfdf_model.dart';

/// شكل لوحة سيارة فيها اربع حروف و3 ارقام
class SfdfWidget extends StatefulWidget {
  const SfdfWidget({super.key});

  static String routeName = 'sfdf';
  static String routePath = '/sfdf';

  @override
  State<SfdfWidget> createState() => _SfdfWidgetState();
}

class _SfdfWidgetState extends State<SfdfWidget> {
  late SfdfModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SfdfModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _plateCard(
    BuildContext context, {
    required String letters,
    required String numbers,
    required String country,
    DecorationImage? image,
  }) {
    final typography = context.dsTypography;

    return DsCard(
      elevated: true,
      padding: const EdgeInsets.all(DsSpacing.md),
      color: Colors.white,
      child: SizedBox(
        width: 320,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letters,
                  style: typography.headlineMedium.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Text(
                  numbers,
                  style: typography.headlineMedium.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(
              country,
              style: typography.bodyMedium.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

          return DsScreenScaffold(
            scaffoldKey: scaffoldKey,
            appBar: DsAppBar(
              automaticallyImplyLeading: true,
              title: FFLocalizations.of(context).getText(
                '593eu5p0' /* Page Title */,
              ),
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: DsSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        'z834kcif' /* لوحة السيارة */,
                      ),
                      style: typography.headlineSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xl),
                    _plateCard(
                      context,
                      letters: FFLocalizations.of(context).getText(
                        '0iuaqnxp' /* ب ي س */,
                      ),
                      numbers: FFLocalizations.of(context).getText(
                        '2sglbb8x' /* ٤٥٧٨ */,
                      ),
                      country: FFLocalizations.of(context).getText(
                        'fzfkcvym' /* المملكة العربية السعودية */,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    _plateCard(
                      context,
                      letters: FFLocalizations.of(context).getText(
                        '73yjq098' /* ع ط ر */,
                      ),
                      numbers: FFLocalizations.of(context).getText(
                        '7fn1gvg8' /* ١٢٣٤ */,
                      ),
                      country: FFLocalizations.of(context).getText(
                        'zhofj9ie' /* المملكة العربية السعودية */,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    DsCard(
                      elevated: true,
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      child: Container(
                        width: 320,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: DsRadius.large,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: Image.asset(
                              'assets/images/uuuuuuuuuu.png',
                            ).image,
                          ),
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
}

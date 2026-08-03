import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'demoooooo_model.dart';
export 'demoooooo_model.dart';

/// Tip Selection for Gregory Smith
class DemooooooWidget extends StatefulWidget {
  const DemooooooWidget({super.key});

  static String routeName = 'demoooooo';
  static String routePath = '/demoooooo';

  @override
  State<DemooooooWidget> createState() => _DemooooooWidgetState();
}

class _DemooooooWidgetState extends State<DemooooooWidget> {
  late DemooooooModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DemooooooModel());

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
                  '0jnlrniq' /* Tips */,
                ),
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () {
                    print('IconButton pressed ...');
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0, 0, DsSpacing.xs, 0),
                    child: DsIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DsSpacing.md,
                      DsSpacing.xxl,
                      DsSpacing.md,
                      DsSpacing.lg,
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
                              borderRadius: BorderRadius.circular(60.0),
                              child: Image.asset(
                                'assets/images/WhatsApp_Image_2025-06-01_at_10.47.35_PM.jpeg',
                                width: 120.0,
                                height: 120.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'gb8nvhhy' /* Gregory Smith */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.headlineSmall.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '28097fui' /* 652 - UKW */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ].divide(const SizedBox(height: DsSpacing.xs)),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'wrurdbhl' /* Wow! A 5 star !
Wanna add tip ... */
                                    ,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.headlineSmall.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _TipOption(
                                      label:
                                          FFLocalizations.of(context).getText(
                                        'iayyywkp' /* $1 */,
                                      ),
                                      selected: false,
                                    ),
                                    _TipOption(
                                      label:
                                          FFLocalizations.of(context).getText(
                                        '474ltqsi' /* $2 */,
                                      ),
                                      selected: true,
                                    ),
                                    _TipOption(
                                      label:
                                          FFLocalizations.of(context).getText(
                                        'c2fjamhr' /* $5 */,
                                      ),
                                      selected: false,
                                    ),
                                  ].divide(const SizedBox(width: DsSpacing.md)),
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '5s1vfj6y' /* Choose other amount */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.bodyLarge.copyWith(
                                    color: colors.error,
                                  ),
                                ),
                                DsButton.primary(
                                  label: FFLocalizations.of(context).getText(
                                    'bxeo1yt4' /* Done */,
                                  ),
                                  expanded: true,
                                  size: DsButtonSize.lg,
                                  onPressed: () {
                                    print('Button pressed ...');
                                  },
                                ),
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'rr49wy80' /* Maybe next time */,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: typography.bodyLarge.copyWith(
                                    color: colors.hint,
                                  ),
                                ),
                              ].divide(const SizedBox(height: DsSpacing.xl)),
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

class _TipOption extends StatelessWidget {
  const _TipOption({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      width: 80.0,
      height: 80.0,
      decoration: BoxDecoration(
        color: selected ? colors.primary : colors.primarySoft,
        shape: BoxShape.circle,
      ),
      alignment: const AlignmentDirectional(0.0, 0.0),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xs),
        child: Text(
          label,
          style: typography.headlineSmall.copyWith(
            color: selected ? colors.onPrimary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

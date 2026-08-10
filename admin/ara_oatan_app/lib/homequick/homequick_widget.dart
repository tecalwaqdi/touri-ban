import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/index.dart';
import 'homequick_model.dart';
export 'homequick_model.dart';

class HomequickWidget extends StatefulWidget {
  const HomequickWidget({super.key});

  static String routeName = 'Homequick';
  static String routePath = '/homequick';

  @override
  State<HomequickWidget> createState() => _HomequickWidgetState();
}

class _HomequickWidgetState extends State<HomequickWidget> {
  late HomequickModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomequickModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroImageUrl = touryResolveHeroImageUrl(
      primary: context.select<FFAppState, String>((s) => s.IMGVILL),
      secondary: context.select<FFAppState, String>((s) => s.imgDolh),
    );

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
                  'x2uu2w0l' /* Choose Your Location */,
                ),
                centerTitle: false,
                automaticallyImplyLeading: false,
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () => context.safePop(),
                ),
              ),
              body: SafeArea(
                top: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DsSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText(
                                'fu17746a' /* Where would you like to start ... */,
                              ),
                              style: typography.headlineSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LocationRow(
                                  label: FFLocalizations.of(context).getText(
                                    'lvqlwcy2' /* Current Country */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    '4pjlfi4n' /* United States */,
                                  ),
                                  actionLabel:
                                      FFLocalizations.of(context).getText(
                                    '5z3z67yf' /* Change */,
                                  ),
                                  onAction: () {
                                    context.pushNamed(AldolWidget.routeName);
                                  },
                                ),
                                _LocationRow(
                                  label: FFLocalizations.of(context).getText(
                                    'sy7pwzh0' /* Current City */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    'tbxwlrxf' /* San Francisco */,
                                  ),
                                  actionLabel:
                                      FFLocalizations.of(context).getText(
                                    '4b1rzv1o' /* Change */,
                                  ),
                                  onAction: () {
                                    context.pushNamed(Citie2Widget.routeName);
                                  },
                                ),
                                _LocationRow(
                                  label: FFLocalizations.of(context).getText(
                                    '75t9rw1v' /* Current Location */,
                                  ),
                                  value: FFLocalizations.of(context).getText(
                                    'ubzpq3ur' /* 1234 Market Street, Downtown */,
                                  ),
                                  actionLabel:
                                      FFLocalizations.of(context).getText(
                                    '1b27g97u' /* Change */,
                                  ),
                                  onAction: () {
                                    context.pushNamed(ListWidget.routeName);
                                  },
                                ),
                              ].divide(const SizedBox(height: DsSpacing.md)),
                            ),
                            Container(
                              width: double.infinity,
                              height: DsConstants.heroHeight,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image:
                                      touryNetworkImageProvider(heroImageUrl),
                                ),
                                boxShadow: DsShadows.card(
                                  dark: context.dsIsDark,
                                ),
                                borderRadius: DsRadius.extraLarge,
                              ),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: colors.scrim,
                                  borderRadius: DsRadius.extraLarge,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(DsSpacing.md),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        DsIcons.location,
                                        color: colors.onPrimary,
                                        size: DsSpacing.massive,
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional
                                                .fromSTEB(
                                          DsSpacing.md,
                                          DsSpacing.xs,
                                          DsSpacing.md,
                                          0.0,
                                        ),
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            'ahldraeq' /* Map showing your current locat... */,
                                          ),
                                          textAlign: TextAlign.center,
                                          style:
                                              typography.bodyMedium.copyWith(
                                            color: colors.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _OptionCard(
                                  icon: Icons.route_rounded,
                                  title: FFLocalizations.of(context).getText(
                                    'jb1tfjnr' /* Design My Route */,
                                  ),
                                  subtitle:
                                      FFLocalizations.of(context).getText(
                                    'zkgmj11i' /* Add landmarks to customize you... */,
                                  ),
                                  highlighted: true,
                                ),
                                _OptionCard(
                                  icon: DsIcons.profile,
                                  title: FFLocalizations.of(context).getText(
                                    's2bu2d3m' /* Let the Driver Decide */,
                                  ),
                                  subtitle:
                                      FFLocalizations.of(context).getText(
                                    'ra7tf46f' /* Rely on the driver's local exp... */,
                                  ),
                                  highlighted: false,
                                ),
                              ].divide(const SizedBox(height: DsSpacing.md)),
                            ),
                          ]
                              .divide(const SizedBox(height: DsSpacing.md))
                              .addToStart(
                                  const SizedBox(height: DsSpacing.md)),
                        ),
                      ),
                      Align(
                        alignment: const AlignmentDirectional(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            DsSpacing.md,
                            DsSpacing.md,
                            DsSpacing.md,
                            DsSpacing.xxxl,
                          ),
                          child: DsButton.primary(
                            label: FFLocalizations.of(context).getText(
                              'ke9nketc' /* Next */,
                            ),
                            expanded: true,
                            size: DsButtonSize.md,
                            onPressed: () {
                              context.pushNamed(
                                DemoDWidget.routeName,
                                queryParameters: {
                                  'isSpeed': serializeParam(
                                    false,
                                    ParamType.bool,
                                  ),
                                }.withoutNulls,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onAction,
  });

  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: DsSpacing.xxs),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DsSpacing.sm),
        DsButton.outlined(
          label: actionLabel,
          size: DsButtonSize.sm,
          onPressed: onAction,
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlighted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: DsRadius.medium,
        border: Border.all(
          color: highlighted ? colors.primary : colors.border,
          width: highlighted ? 2.0 : 1.0,
        ),
        boxShadow: DsShadows.card(dark: context.dsIsDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: DsSpacing.massive,
              height: DsSpacing.massive,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: const AlignmentDirectional(0.0, 0.0),
              child: Icon(
                icon,
                color: highlighted ? colors.primary : colors.iconMuted,
                size: DsConstants.iconMd,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ].divide(const SizedBox(width: DsSpacing.md)),
        ),
      ),
    );
  }
}

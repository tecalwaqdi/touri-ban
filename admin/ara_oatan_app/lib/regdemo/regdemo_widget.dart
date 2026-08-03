import 'package:flutter/material.dart';

import '/backend/schema/enums/enums.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'regdemo_model.dart';

export 'regdemo_model.dart';

/// Create a clean and modern FlutterFlow page with the following:
///
/// - Page title: "Select Entity Type"
/// - Display three selectable cards or radio buttons for entity type:
///   1.
///
/// Government Entity
///   2. Company or Organization
///   3. Individual
///
/// - Each option should be clearly labeled and selectable (use radio buttons
/// or toggle-style cards).
/// - Only one option can be selected at a time.
/// - Add a large button at the bottom labeled "Next".
/// - Use a vertical layout with proper spacing.
/// - Style: Soft background, rounded cards, and modern typography.
///
/// Ensure the selected option is stored in a variable named
/// `selectedEntityType` for later use.
class RegdemoWidget extends StatefulWidget {
  const RegdemoWidget({super.key});

  static String routeName = 'regdemo';
  static String routePath = '/regdemo';

  @override
  State<RegdemoWidget> createState() => _RegdemoWidgetState();
}

class _RegdemoWidgetState extends State<RegdemoWidget> {
  late RegdemoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegdemoModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _select(int value) {
    _model.idselect = value;
    safeSetState(() {});
  }

  Future<void> _goNext() async {
    await Future.wait([
      Future(() async {
        if (_model.idselect == 1) {
          FFAppState().type = TypeShrek.Gov;
          safeSetState(() {});
        }
      }),
      Future(() async {
        if (_model.idselect == 2) {
          FFAppState().type = TypeShrek.Company;
          safeSetState(() {});

          context.pushNamed(CreateAccount1ShrekWidget.routeName);
        }
      }),
      Future(() async {
        if (_model.idselect == 3) {
          FFAppState().type = TypeShrek.Company;
          safeSetState(() {});
        }
      }),
    ]);
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
                title: FFLocalizations.of(context).getText(
                  'qodn6hhz' /* Register a Success Partner - S... */,
                ),
                leading: DsIconButton(
                  icon: DsIcons.back,
                  onPressed: () async {
                    context.pop();
                  },
                ),
              ),
              body: SafeArea(
                top: true,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          DsSpacing.md,
                          DsSpacing.lg,
                          DsSpacing.md,
                          DsSpacing.md,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: DsConstants.maxContentWidth,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'fsxw45xd' /* Choose the type of entity you ... */,
                                  ),
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: DsSpacing.lg),
                                DsFadeSlide(
                                  child: _EntityOptionCard(
                                    icon: Icons.account_balance_rounded,
                                    label: FFLocalizations.of(context).getText(
                                      'ghm9sr8v' /* Government Entity */,
                                    ),
                                    selected: _model.idselect == 1,
                                    onTap: () => _select(1),
                                    onLabelTap: () {
                                      debugPrint('push');
                                      context.pushNamed(List3Widget.routeName);
                                    },
                                  ),
                                ),
                                const SizedBox(height: DsSpacing.sm),
                                DsFadeSlide(
                                  delay: DsDurations.instant,
                                  child: _EntityOptionCard(
                                    icon: Icons.corporate_fare_rounded,
                                    label: FFLocalizations.of(context).getText(
                                      'xkchshdg' /* Company or Organization */,
                                    ),
                                    selected: _model.idselect == 2,
                                    onTap: () => _select(2),
                                  ),
                                ),
                                const SizedBox(height: DsSpacing.sm),
                                DsFadeSlide(
                                  delay: DsDurations.fast,
                                  child: _EntityOptionCard(
                                    icon: DsIcons.profile,
                                    label: FFLocalizations.of(context).getText(
                                      'pbewpc3t' /* Individual */,
                                    ),
                                    selected: _model.idselect == 3,
                                    onTap: () => _select(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DsSpacing.md,
                        DsSpacing.xs,
                        DsSpacing.md,
                        DsSpacing.md,
                      ),
                      child: DsButton(
                        label: FFLocalizations.of(context).getText(
                          'kry3halw' /* Next */,
                        ),
                        variant: DsButtonVariant.primary,
                        size: DsButtonSize.lg,
                        expanded: true,
                        trailing: Icon(
                          Icons.navigate_next,
                          size: DsIcons.sm,
                          color: colors.onPrimary,
                        ),
                        onPressed: _goNext,
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

/// Toggle-style card representing one selectable entity type.
class _EntityOptionCard extends StatelessWidget {
  const _EntityOptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLabelTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    final title = Text(
      label,
      style: typography.titleMedium.copyWith(color: colors.textPrimary),
    );

    return DsCard(
      onTap: onTap,
      elevated: selected,
      color: selected ? colors.selected : null,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? colors.primary : colors.iconMuted,
            size: DsIcons.md,
          ),
          const SizedBox(width: DsSpacing.sm),
          Container(
            width: DsConstants.avatarMd,
            height: DsConstants.avatarMd,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: DsRadius.medium,
            ),
            child: Icon(icon, size: DsIcons.sm, color: colors.primary),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: onLabelTap == null
                ? title
                : DsPressable(onTap: onLabelTap, child: title),
          ),
        ],
      ),
    );
  }
}

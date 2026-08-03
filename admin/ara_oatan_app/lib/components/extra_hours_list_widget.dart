import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'extra_hours_list_model.dart';
export 'extra_hours_list_model.dart';

class ExtraHoursListWidget extends StatefulWidget {
  const ExtraHoursListWidget({super.key});

  @override
  State<ExtraHoursListWidget> createState() => _ExtraHoursListWidgetState();
}

class _ExtraHoursListWidgetState extends State<ExtraHoursListWidget> {
  late ExtraHoursListModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExtraHoursListModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DsSpacing.md, DsSpacing.sm, DsSpacing.md, DsSpacing.md),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: 181.9,
        decoration: BoxDecoration(
          color: colors.card,
          boxShadow: DsShadows.floating(dark: isDark),
          borderRadius: DsRadius.small,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              DsSpacing.xs, DsSpacing.xs, DsSpacing.sm, DsSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 4.0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: DsRadius.extraSmall,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      DsSpacing.sm, 0.0, DsSpacing.sm, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, DsSpacing.xxs, 0.0, 0.0),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'f1pdbqxu' /* 4:00pm */,
                          ),
                          style: typography.headlineSmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, DsSpacing.xxs, 0.0, 0.0),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'j7lun4ww' /* Extra hours have been added to... */,
                          ),
                          style: typography.labelMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    DsSpacing.sm, 0.0, 0.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        '7ybnefhe' /* Order Summary */,
                      ),
                      style: typography.labelSmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, DsSpacing.xxs, 0.0, DsSpacing.xxs),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                DsSpacing.xxs, DsSpacing.xxs, 0.0, 0.0),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                '355tnqg2' /* $25.40 */,
                              ),
                              style: typography.headlineSmall.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, DsSpacing.xxs, 0.0, DsSpacing.xs),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          '21ixhq6o' /* (4 items) */,
                        ),
                        style: typography.labelMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

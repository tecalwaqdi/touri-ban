import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'taim_model.dart';
export 'taim_model.dart';

/// Description for AI:
/// Create a Flutter page for scheduling a trip where the user can select a
/// trip date and time using custom dropdowns for selecting hours (12-hour
/// format) and minutes (0-59).
///
/// The page should include the following elements:
///
/// Title: Display "Schedule Your Trip" at the top.
/// Date Picker:
/// Use showDatePicker to display a calendar-style date picker where the user
/// can select a trip date.
/// Time Selection:
/// Use a DropdownButton for selecting the hour in a 12-hour format (1-12).
/// Use a DropdownButton for selecting minutes (0-59).
/// Optionally, add an AM/PM dropdown to distinguish between morning and
/// evening.
class TaimWidget extends StatefulWidget {
  const TaimWidget({super.key});

  @override
  State<TaimWidget> createState() => _TaimWidgetState();
}

class _TaimWidgetState extends State<TaimWidget> {
  late TaimModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TaimModel());

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
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: DsShadows.soft(dark: isDark),
          borderRadius: DsRadius.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      '9v0tmtoa' /* Select Time */,
                    ),
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Container(
                          height: 60.0,
                          decoration: BoxDecoration(
                            borderRadius: DsRadius.extraSmall,
                            border: Border.all(
                              color: colors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                DsSpacing.sm, DsSpacing.md, DsSpacing.sm, DsSpacing.md),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '2cbqkulx' /* Hour */,
                                  ),
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colors.textPrimary,
                                  size: 24.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 60.0,
                          decoration: BoxDecoration(
                            borderRadius: DsRadius.extraSmall,
                            border: Border.all(
                              color: colors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                DsSpacing.sm, DsSpacing.md, DsSpacing.sm, DsSpacing.md),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    'xhvwhnys' /* Minute */,
                                  ),
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colors.textPrimary,
                                  size: 24.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 60.0,
                          decoration: BoxDecoration(
                            borderRadius: DsRadius.extraSmall,
                            border: Border.all(
                              color: colors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                DsSpacing.sm, DsSpacing.md, DsSpacing.sm, DsSpacing.md),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '1n0b0iz7' /* AM/PM */,
                                  ),
                                  style: typography.bodyMedium.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colors.textPrimary,
                                  size: 24.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ].divide(DsSpacing.gapSm),
                  ),
                ].divide(DsSpacing.gapXs),
              ),
            ].divide(DsSpacing.gapXl),
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'schedulethe_trip_model.dart';

export 'schedulethe_trip_model.dart';

/// Create a Flutter page for scheduling a trip.
///
/// The page should include the following elements:
///
/// Title: Display "Schedule Your Trip" at the top.
/// Date Picker:
/// A widget that allows the user to select a trip date (using a
/// calendar-style date picker).
/// Time Picker:
/// A widget that allows the user to select the trip time (using a time
/// picker).
/// Save Button:
/// A button labeled "Save Trip" to save the selected date and time.
/// Layout:
/// Arrange the date picker and time picker vertically using a column layout.
/// Add spacing between the widgets for better clarity and usability.
/// Ensure the save button is placed below the pickers for easy access.
/// Optional Features:
///
/// Display the selected date and time in a readable format once the user
/// selects them.
/// Consider adding a confirmation message or screen after the trip is
/// scheduled.
class ScheduletheTripWidget extends StatefulWidget {
  const ScheduletheTripWidget({super.key});

  static String routeName = 'ScheduletheTrip';
  static String routePath = '/scheduletheTrip';

  @override
  State<ScheduletheTripWidget> createState() => _ScheduletheTripWidgetState();
}

class _ScheduletheTripWidgetState extends State<ScheduletheTripWidget> {
  late ScheduletheTripModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ScheduletheTripModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _confirm() async {
    if ((_model.calendarSelectedDay == null) ||
        ((_model.hoValue == null || _model.hoValue == '') ||
            (_model.miValue == null || _model.miValue == '') ||
            (_model.ftrhValue == null || _model.ftrhValue == ''))) {
      await showDialog(
        context: context,
        builder: (alertDialogContext) {
          return WebViewAware(
            child: AlertDialog(
              title: Text('ui_text_7f2f6a15cf'.tr()),
              content: Text('ui_text_9262ef60ec'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(alertDialogContext),
                  child: Text('ui_text_b0a98216a3'.tr()),
                ),
              ],
            ),
          );
        },
      );
    } else {
      FFAppState().dataSchedule = _model.calendarSelectedDay?.start;
      FFAppState().taimSchedule =
          '${_model.ftrhValue}${_model.hoValue}: ${_model.miValue} ';
      FFAppState().fulltextSchedule = valueOrDefault<String>(
        'مجدول بتاريخ ${dateTimeFormat(
          "d/M/y",
          FFAppState().dataSchedule,
          locale: FFLocalizations.of(context).languageCode,
        )}  الساعة:  ${FFAppState().taimSchedule}',
        'إختياري ، يمكنك إختيار تاريخ ووقت بدء الرحلة',
      );
      FFAppState().update(() {});

      context.pushNamed(Checkout66Widget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
                  'aauqih1n' /* Schedule the Trip */,
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.md,
                    DsSpacing.xxxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsFadeSlide(
                        child: DsCard(
                          elevated: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DsSpacing.xs,
                            vertical: DsSpacing.md,
                          ),
                          child: FlutterFlowCalendar(
                            color: colors.primary,
                            iconColor: colors.icon,
                            weekFormat: true,
                            weekStartsMonday: false,
                            initialDate: getCurrentTimestamp,
                            rowHeight: 44.75,
                            onChange: (DateTimeRange? newSelectedDate) {
                              safeSetState(() =>
                                  _model.calendarSelectedDay = newSelectedDate);
                            },
                            titleStyle: typography.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                            dayOfWeekStyle: typography.labelSmall.copyWith(
                              color: colors.textSecondary,
                            ),
                            dateStyle: typography.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                            selectedDateStyle: typography.titleSmall.copyWith(
                              color: colors.onPrimary,
                            ),
                            inactiveDateStyle: typography.bodyMedium.copyWith(
                              color: colors.hint,
                            ),
                            locale: FFLocalizations.of(context).languageCode,
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 60),
                        child: DsCard(
                          elevated: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: DsIcons.sm,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: DsSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        '0m6rs2gg' /* Select the Time */,
                                      ),
                                      style: typography.titleSmall.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DsSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TimeDropDown(
                                      controller:
                                          _model.hoValueController ??=
                                              FormFieldController<String>(null),
                                      hintText:
                                          FFLocalizations.of(context).getText(
                                        '1q75q567' /* Hour */,
                                      ),
                                      options: [
                                        FFLocalizations.of(context).getText(
                                          'txzd7ud0' /* 1 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'xpwy17eh' /* 2 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          '59v6qu8e' /* 3 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'yjyjwoh9' /* 4 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'jmmnf4gl' /* 5 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          '4qeacvin' /* 6 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'eosmry97' /* 7 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'oimc0hsy' /* 8 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          's769e4aj' /* 9 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          '0wkssu4g' /* 10 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'dsaod397' /* 11 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'k95rciu3' /* 12 */,
                                        )
                                      ],
                                      onChanged: (val) =>
                                          safeSetState(() => _model.hoValue = val),
                                    ),
                                  ),
                                  const SizedBox(width: DsSpacing.sm),
                                  Expanded(
                                    child: _TimeDropDown(
                                      controller: _model.miValueController ??=
                                          FormFieldController<String>(
                                        _model.miValue ??=
                                            FFLocalizations.of(context).getText(
                                          'ikoasx9i' /* 00 */,
                                        ),
                                      ),
                                      hintText:
                                          FFLocalizations.of(context).getText(
                                        '8pmtkzbu' /* Minute */,
                                      ),
                                      options: [
                                        FFLocalizations.of(context).getText(
                                          'pbd2uvr1' /* 00 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'lpbwk788' /* 15 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          '8j3feh3d' /* 30 */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'uh51b3yo' /* 45 */,
                                        )
                                      ],
                                      onChanged: (val) =>
                                          safeSetState(() => _model.miValue = val),
                                    ),
                                  ),
                                  const SizedBox(width: DsSpacing.sm),
                                  Expanded(
                                    child: _TimeDropDown(
                                      controller: _model.ftrhValueController ??=
                                          FormFieldController<String>(
                                        _model.ftrhValue ??=
                                            FFLocalizations.of(context).getText(
                                          '7fvoygad' /* PM */,
                                        ),
                                      ),
                                      hintText:
                                          FFLocalizations.of(context).getText(
                                        'qd7e7kdp' /* AM */,
                                      ),
                                      options: [
                                        FFLocalizations.of(context).getText(
                                          '86wk383c' /* AM */,
                                        ),
                                        FFLocalizations.of(context).getText(
                                          'c2vjf4gu' /* PM */,
                                        )
                                      ],
                                      onChanged: (val) => safeSetState(
                                          () => _model.ftrhValue = val),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 120),
                        child: Container(
                          width: double.infinity,
                          padding: DsSpacing.cardPadding,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [colors.primary, colors.primaryStrong],
                            ),
                            borderRadius: DsRadius.large,
                            boxShadow: DsShadows.primaryGlow(
                              dark: context.dsIsDark,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FFLocalizations.of(context).getText(
                                  'cqytzsi1' /* The trip time is */,
                                ),
                                style: typography.labelMedium.copyWith(
                                  color: colors.onPrimary
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: DsSpacing.xs),
                              Text(
                                _model.calendarSelectedDay == null
                                    ? '—'
                                    : dateTimeFormat(
                                        "d/M/y",
                                        _model.calendarSelectedDay!.start,
                                        locale: FFLocalizations.of(context)
                                            .languageCode,
                                      ),
                                style: typography.headlineSmall.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xl),
                      DsFadeSlide(
                        delay: const Duration(milliseconds: 180),
                        child: DsButton.primary(
                          label: FFLocalizations.of(context).getText(
                            '79mh13gj' /* Confirm */,
                          ),
                          icon: Icons.check_circle_outline_rounded,
                          size: DsButtonSize.lg,
                          expanded: true,
                          onPressed: _confirm,
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

/// Hour / minute / meridiem selector styled with Design System tokens.
class _TimeDropDown extends StatelessWidget {
  const _TimeDropDown({
    required this.controller,
    required this.options,
    required this.hintText,
    required this.onChanged,
  });

  final FormFieldController<String> controller;
  final List<String> options;
  final String hintText;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return FlutterFlowDropDown<String>(
      controller: controller,
      options: options,
      onChanged: onChanged,
      height: DsConstants.buttonHeightMd,
      textStyle: typography.titleSmall.copyWith(color: colors.textPrimary),
      hintText: hintText,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colors.iconMuted,
        size: DsIcons.md,
      ),
      fillColor: colors.surface,
      elevation: 0.0,
      borderColor: colors.border,
      borderWidth: 1.0,
      borderRadius: DsRadius.md,
      margin: const EdgeInsetsDirectional.fromSTEB(
        DsSpacing.sm,
        0.0,
        DsSpacing.xs,
        0.0,
      ),
      hidesUnderline: true,
      isOverButton: false,
      isSearchable: false,
      isMultiSelect: false,
    );
  }
}

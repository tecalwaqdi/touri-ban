import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/design_system/design_system.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'taim_model.dart';
export 'taim_model.dart';

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

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.timerController.onStartTimer();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Align(
      alignment: AlignmentDirectional.center,
      child: DsCard(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.xl,
          DsSpacing.lg,
          DsSpacing.xl,
          DsSpacing.xl,
        ),
        color: colors.surface,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(DsIcons.close, color: colors.textPrimary),
                ),
              ),
              Text(
                FFLocalizations.of(context).getText('k2zibe66'),
                style: typography.titleMedium.copyWith(
                  color: colors.primaryStrong,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DsSpacing.gapSm,
              FlutterFlowTimer(
                initialTime: getCurrentTimestamp.millisecondsSinceEpoch <
                        FFAppState().EndDate!.millisecondsSinceEpoch
                    ? functions.calculateRemainingMs(
                        getCurrentTimestamp, FFAppState().EndDate!)
                    : 0,
                getDisplayTime: (value) =>
                    StopWatchTimer.getDisplayTime(value, milliSecond: false),
                controller: _model.timerController,
                updateStateInterval: const Duration(milliseconds: 1000),
                onChanged: (value, displayTime, shouldUpdate) {
                  _model.timerMilliseconds = value;
                  _model.timerValue = displayTime;
                  if (shouldUpdate) safeSetState(() {});
                },
                textAlign: TextAlign.start,
                style: typography.headlineSmall.copyWith(
                  color: colors.primaryStrong,
                ),
              ),
              if (_model.timerMilliseconds == 0) ...[
                DsSpacing.gapSm,
                Text(
                  FFLocalizations.of(context).getText('vclm4olo'),
                  style: typography.bodyMedium.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              DsSpacing.gapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _timeColumn(
                    context,
                    label: FFLocalizations.of(context).getText('r0d4t29u'),
                    icon: Icons.timer_outlined,
                    iconColor: colors.success,
                    value: dateTimeFormat(
                      'd/M/y',
                      FFAppState().startTime,
                      locale: FFLocalizations.of(context).languageCode,
                    ),
                    valueColor: colors.success,
                  ),
                  _timeColumn(
                    context,
                    label: FFLocalizations.of(context).getText('n5kxjaax'),
                    icon: Icons.timer_off_outlined,
                    iconColor: colors.error,
                    value: dateTimeFormat(
                      'd/M/y',
                      FFAppState().EndDate,
                      locale: FFLocalizations.of(context).languageCode,
                    ),
                    valueColor: colors.error,
                  ),
                ],
              ),
              DsSpacing.gapMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _timeColumn(
                    context,
                    label: FFLocalizations.of(context).getText('ipd61kmc'),
                    icon: Icons.timer_outlined,
                    iconColor: colors.success,
                    value: dateTimeFormat(
                      'jm',
                      FFAppState().startTime,
                      locale: FFLocalizations.of(context).languageCode,
                    ),
                    valueColor: colors.success,
                  ),
                  _timeColumn(
                    context,
                    label: FFLocalizations.of(context).getText('an8ejy50'),
                    icon: Icons.timer_off_outlined,
                    iconColor: colors.error,
                    value: dateTimeFormat(
                      'jm',
                      FFAppState().EndDate,
                      locale: FFLocalizations.of(context).languageCode,
                    ),
                    valueColor: colors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeColumn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
    required Color valueColor,
  }) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        DsSpacing.gapXxs,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 13),
            DsSpacing.gapXs,
            Text(
              value,
              style: typography.bodyLarge.copyWith(
                color: valueColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

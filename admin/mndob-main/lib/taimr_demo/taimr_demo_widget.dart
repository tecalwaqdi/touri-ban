import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'taimr_demo_model.dart';
export 'taimr_demo_model.dart';

class TaimrDemoWidget extends StatefulWidget {
  const TaimrDemoWidget({super.key});

  static String routeName = 'taimrDemo';
  static String routePath = '/taimrDemo';

  @override
  State<TaimrDemoWidget> createState() => _TaimrDemoWidgetState();
}

class _TaimrDemoWidgetState extends State<TaimrDemoWidget> {
  late TaimrDemoModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TaimrDemoModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.timerController.onStartTimer();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
                'tq0c4st3' /* Page Title */,
              ),
            ),
            body: SafeArea(
              top: true,
              child: Padding(
                padding: DsSpacing.pagePadding,
                child: DsCard(
                  elevated: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Timer',
                        style: typography.titleMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
                      FlutterFlowTimer(
                        initialTime: getCurrentTimestamp.millisecondsSinceEpoch <
                                FFAppState().EndDate!.millisecondsSinceEpoch
                            ? functions.calculateRemainingMs(
                                getCurrentTimestamp, FFAppState().EndDate!)
                            : 0,
                        getDisplayTime: (value) =>
                            StopWatchTimer.getDisplayTime(value,
                                milliSecond: false),
                        controller: _model.timerController,
                        updateStateInterval: Duration(milliseconds: 1000),
                        onChanged: (value, displayTime, shouldUpdate) {
                          _model.timerMilliseconds = value;
                          _model.timerValue = displayTime;
                          if (shouldUpdate) safeSetState(() {});
                        },
                        textAlign: TextAlign.center,
                        style: typography.displaySmall.copyWith(
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xl),
                      DsButton.primary(
                        label: FFLocalizations.of(context).getText(
                          '71jjm3da' /* Button */,
                        ),
                        expanded: true,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () async {
                          _model.timerController.onStartTimer();
                        },
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

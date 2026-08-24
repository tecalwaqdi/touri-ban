import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'tfasel_orser_widget.dart' show TfaselOrserWidget;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class TfaselOrserModel extends FlutterFlowModel<TfaselOrserWidget> {
  ///  Local state fields for this page.

  LatLng? loceshn;

  bool? ok10;

  bool? isnot = false;

  ///  State fields for stateful widgets in this page.

  AudioPlayer? soundPlayer1;
  AudioPlayer? soundPlayer2;
  // State field(s) for Timer1 widget.
  final timer1InitialTimeMs = 0;
  int timer1Milliseconds = 0;
  String timer1Value = StopWatchTimer.getDisplayTime(0, milliSecond: false);
  FlutterFlowTimerController timer1Controller =
      FlutterFlowTimerController(StopWatchTimer(mode: StopWatchMode.countDown));

  AudioPlayer? soundPlayer3;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    timer1Controller.dispose();
  }
}

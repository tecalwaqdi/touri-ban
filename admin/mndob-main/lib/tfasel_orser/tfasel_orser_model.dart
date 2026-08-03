import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/components/review_screen_widget.dart';
import '/components/taim_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_timer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:map_launcher/map_launcher.dart' as $ml;
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:styled_divider/styled_divider.dart';
import 'tfasel_orser_widget.dart' show TfaselOrserWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

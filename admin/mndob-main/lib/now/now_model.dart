import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'now_widget.dart' show NowWidget;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class NowModel extends FlutterFlowModel<NowWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in Now widget.
  SettingsRecord? ngl;
  AudioPlayer? soundPlayer;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

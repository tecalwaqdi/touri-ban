import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import '/index.dart';
import 'tfasel_copy_widget.dart' show TfaselCopyWidget;
import 'package:flutter/material.dart';

class TfaselCopyModel extends FlutterFlowModel<TfaselCopyWidget> {
  ///  State fields for stateful widgets in this page.

  InstantTimer? instantDi;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantDi?.cancel();
  }
}

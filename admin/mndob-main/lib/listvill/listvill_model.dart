import '/components/villmndob_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'listvill_widget.dart' show ListvillWidget;
import 'package:flutter/material.dart';

class ListvillModel extends FlutterFlowModel<ListvillWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for villmndob component.
  late VillmndobModel villmndobModel;

  @override
  void initState(BuildContext context) {
    villmndobModel = createModel(context, () => VillmndobModel());
  }

  @override
  void dispose() {
    villmndobModel.dispose();
  }
}

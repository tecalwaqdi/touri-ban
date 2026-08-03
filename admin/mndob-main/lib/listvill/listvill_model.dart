import '/components/villmndob_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'listvill_widget.dart' show ListvillWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

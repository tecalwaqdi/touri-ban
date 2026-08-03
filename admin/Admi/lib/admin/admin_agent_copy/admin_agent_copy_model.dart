import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_agent_copy_widget.dart' show AdminAgentCopyWidget;
import 'package:flutter/material.dart';

class AdminAgentCopyModel extends FlutterFlowModel<AdminAgentCopyWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Menu2 component.
  late Menu2Model menu2Model;
  // State field(s) for Switchngl widget.
  bool? switchnglValue;
  // State field(s) for Switchgoogle widget.
  bool? switchgoogleValue;

  @override
  void initState(BuildContext context) {
    menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    menu2Model.dispose();
  }
}

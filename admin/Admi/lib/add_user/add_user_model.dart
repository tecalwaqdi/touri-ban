import '/components/add_yser_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'add_user_widget.dart' show AddUserWidget;
import 'package:flutter/material.dart';

class AddUserModel extends FlutterFlowModel<AddUserWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for addYser component.
  late AddYserModel addYserModel;

  @override
  void initState(BuildContext context) {
    addYserModel = createModel(context, () => AddYserModel());
  }

  @override
  void dispose() {
    addYserModel.dispose();
  }
}

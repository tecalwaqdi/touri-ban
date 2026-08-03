import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'driver_activation_widget.dart' show DriverActivationWidget;
import 'package:flutter/material.dart';

class DriverActivationModel extends FlutterFlowModel<DriverActivationWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for naim widget.
  FocusNode? naimFocusNode;
  TextEditingController? naimTextController;
  String? Function(BuildContext, String?)? naimTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // State field(s) for TextFieldtyp widget.
  FocusNode? textFieldtypFocusNode;
  TextEditingController? textFieldtypTextController;
  String? Function(BuildContext, String?)? textFieldtypTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    naimFocusNode?.dispose();
    naimTextController?.dispose();

    textFieldFocusNode2?.dispose();
    textController3?.dispose();

    textFieldtypFocusNode?.dispose();
    textFieldtypTextController?.dispose();
  }
}

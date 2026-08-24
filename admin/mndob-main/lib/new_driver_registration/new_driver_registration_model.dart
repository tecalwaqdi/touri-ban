import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'new_driver_registration_widget.dart' show NewDriverRegistrationWidget;
import 'package:flutter/material.dart';

class NewDriverRegistrationModel
    extends FlutterFlowModel<NewDriverRegistrationWidget> {
  ///  Local state fields for this page.

  String? rigt;

  String? midd;

  String? lift;

  String? number;

  ///  State fields for stateful widgets in this page.

  // State field(s) for identityNumber widget.
  FocusNode? identityNumberFocusNode;
  TextEditingController? identityNumberTextController;
  String? Function(BuildContext, String?)?
      identityNumberTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController5;
  String? Function(BuildContext, String?)? textController5Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode5;
  TextEditingController? textController6;
  String? Function(BuildContext, String?)? textController6Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode6;
  TextEditingController? textController7;
  String? Function(BuildContext, String?)? textController7Validator;
  // State field(s) for nameCar widget.
  FocusNode? nameCarFocusNode;
  TextEditingController? nameCarTextController;
  String? Function(BuildContext, String?)? nameCarTextControllerValidator;
  // State field(s) for SerialNumber widget.
  FocusNode? serialNumberFocusNode;
  TextEditingController? serialNumberTextController;
  String? Function(BuildContext, String?)? serialNumberTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode7;
  TextEditingController? textController10;
  String? Function(BuildContext, String?)? textController10Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode8;
  TextEditingController? textController11;
  String? Function(BuildContext, String?)? textController11Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode9;
  TextEditingController? textController12;
  String? Function(BuildContext, String?)? textController12Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode10;
  TextEditingController? textController13;
  String? Function(BuildContext, String?)? textController13Validator;
  // Stores action output result for [Backend Call - API (demo)] action in Button widget.
  ApiCallResponse? apiResultz1d;
  // Stores action output result for [Gemini - Generate Text] action in Button widget.
  String? mseg;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    identityNumberFocusNode?.dispose();
    identityNumberTextController?.dispose();

    textFieldFocusNode1?.dispose();
    textController2?.dispose();

    textFieldFocusNode2?.dispose();
    textController3?.dispose();

    textFieldFocusNode3?.dispose();
    textController4?.dispose();

    textFieldFocusNode4?.dispose();
    textController5?.dispose();

    textFieldFocusNode5?.dispose();
    textController6?.dispose();

    textFieldFocusNode6?.dispose();
    textController7?.dispose();

    nameCarFocusNode?.dispose();
    nameCarTextController?.dispose();

    serialNumberFocusNode?.dispose();
    serialNumberTextController?.dispose();

    textFieldFocusNode7?.dispose();
    textController10?.dispose();

    textFieldFocusNode8?.dispose();
    textController11?.dispose();

    textFieldFocusNode9?.dispose();
    textController12?.dispose();

    textFieldFocusNode10?.dispose();
    textController13?.dispose();
  }
}

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'add_payment_card_widget.dart' show AddPaymentCardWidget;
import 'package:flutter/material.dart';

class AddPaymentCardModel extends FlutterFlowModel<AddPaymentCardWidget> {
  ///  Local state fields for this page.

  String? naim = ' ';

  String? number = ' ';

  String? mm = ' ';

  String? yy = ' ';

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for DropDownmm widget.
  String? dropDownmmValue;
  FormFieldController<String>? dropDownmmValueController;
  // State field(s) for DropDownyy widget.
  String? dropDownyyValue;
  FormFieldController<String>? dropDownyyValueController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? textController3Validator;
  // State field(s) for CheckboxListTile widget.
  bool? checkboxListTileValue;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();
  }
}

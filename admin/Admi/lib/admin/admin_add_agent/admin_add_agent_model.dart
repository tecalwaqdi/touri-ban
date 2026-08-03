import '/flutter_flow/flutter_flow_util.dart';
import '/backend/backend.dart';
import '/index.dart';
import 'admin_add_agent_widget.dart' show AdminAddAgentWidget;
import 'package:flutter/material.dart';

class AdminAddAgentModel extends FlutterFlowModel<AdminAddAgentWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for naimfull widget.
  FocusNode? naimfullFocusNode;
  TextEditingController? naimfullTextController;
  String? Function(BuildContext, String?)? naimfullTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  // State field(s) for pass widget.
  FocusNode? passFocusNode;
  TextEditingController? passTextController;
  late bool passVisibility;
  String? Function(BuildContext, String?)? passTextControllerValidator;
  // State field(s) for cPass widget.
  FocusNode? cPassFocusNode;
  TextEditingController? cPassTextController;
  late bool cPassVisibility;
  String? Function(BuildContext, String?)? cPassTextControllerValidator;
  // State field(s) for agent commission percent.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController7;
  String? Function(BuildContext, String?)? textController7Validator;
  // State field(s) for app commission percent.
  FocusNode? appCommissionFocusNode;
  TextEditingController? appCommissionTextController;
  String? Function(BuildContext, String?)? appCommissionTextControllerValidator;
  // VAT percent for the new agent.
  TextEditingController? vatPercentTextController;
  // State field(s) for Switch widget.
  bool? switchValue;

  DateTime? agentStartDate;
  DateTime? agentEndDate;
  CountriesRecord? selectedCountry;
  List<CountriesRecord> countries = [];
  bool countriesLoading = true;
  bool isSubmitting = false;

  final formKey = GlobalKey<FormState>();

  @override
  void initState(BuildContext context) {
    passVisibility = false;
    cPassVisibility = false;
  }

  @override
  void dispose() {
    naimfullFocusNode?.dispose();
    naimfullTextController?.dispose();

    textFieldFocusNode1?.dispose();
    textController2?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    textFieldFocusNode2?.dispose();
    textController4?.dispose();

    passFocusNode?.dispose();
    passTextController?.dispose();

    cPassFocusNode?.dispose();
    cPassTextController?.dispose();

    textFieldFocusNode3?.dispose();
    textController7?.dispose();

    appCommissionFocusNode?.dispose();
    appCommissionTextController?.dispose();

    vatPercentTextController?.dispose();
  }
}

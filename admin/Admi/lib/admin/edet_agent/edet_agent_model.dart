import '/flutter_flow/flutter_flow_util.dart';
import '/backend/backend.dart';
import 'edet_agent_widget.dart' show EdetAgentWidget;
import 'package:flutter/material.dart';

class EdetAgentModel extends FlutterFlowModel<EdetAgentWidget> {
  final formKey = GlobalKey<FormState>();

  TextEditingController? nameTextController;
  FocusNode? nameFocusNode;
  TextEditingController? phoneTextController;
  FocusNode? phoneFocusNode;
  TextEditingController? emailTextController;
  TextEditingController? vatPercentTextController;
  TextEditingController? appCommissionTextController;
  FocusNode? appCommissionFocusNode;
  TextEditingController? agentCommissionTextController;
  FocusNode? agentCommissionFocusNode;

  DateTime? agentStartDate;
  DateTime? agentEndDate;
  CountriesRecord? selectedCountry;
  List<CountriesRecord> countries = [];
  bool countriesLoading = true;
  bool activeValue = true;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameTextController?.dispose();
    nameFocusNode?.dispose();
    phoneTextController?.dispose();
    phoneFocusNode?.dispose();
    emailTextController?.dispose();
    vatPercentTextController?.dispose();
    appCommissionTextController?.dispose();
    appCommissionFocusNode?.dispose();
    agentCommissionTextController?.dispose();
    agentCommissionFocusNode?.dispose();
  }
}

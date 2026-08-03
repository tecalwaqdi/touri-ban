import '/flutter_flow/flutter_flow_util.dart';
import 'edet_transport_company_widget.dart' show EdetTransportCompanyWidget;
import 'package:flutter/material.dart';

class EdetTransportCompanyModel
    extends FlutterFlowModel<EdetTransportCompanyWidget> {
  final formKey = GlobalKey<FormState>();

  TextEditingController? nameTextController;
  FocusNode? nameFocusNode;
  TextEditingController? licenseTextController;
  FocusNode? licenseFocusNode;
  TextEditingController? phoneTextController;
  FocusNode? phoneFocusNode;
  TextEditingController? emailTextController;
  FocusNode? emailFocusNode;

  bool activeValue = true;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameTextController?.dispose();
    nameFocusNode?.dispose();
    licenseTextController?.dispose();
    licenseFocusNode?.dispose();
    phoneTextController?.dispose();
    phoneFocusNode?.dispose();
    emailTextController?.dispose();
    emailFocusNode?.dispose();
  }
}

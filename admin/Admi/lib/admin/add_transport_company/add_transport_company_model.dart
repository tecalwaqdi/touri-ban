import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'add_transport_company_widget.dart' show AddTransportCompanyWidget;
import 'package:flutter/material.dart';

class AddTransportCompanyModel extends FlutterFlowModel<AddTransportCompanyWidget> {
  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;
  bool passwordVisibility = false;
  bool confirmPasswordVisibility = false;

  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;

  FocusNode? licenseFocusNode;
  TextEditingController? licenseTextController;

  FocusNode? phoneFocusNode;
  TextEditingController? phoneTextController;

  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;

  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;

  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;

  bool activeValue = true;
  List<CountriesRecord> countries = [];
  bool countriesLoading = true;
  CountriesRecord? selectedCountry;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();
    licenseFocusNode?.dispose();
    licenseTextController?.dispose();
    phoneFocusNode?.dispose();
    phoneTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }
}

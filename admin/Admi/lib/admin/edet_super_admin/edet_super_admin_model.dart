import '/flutter_flow/flutter_flow_util.dart';
import 'edet_super_admin_widget.dart' show EdetSuperAdminWidget;
import 'package:flutter/material.dart';

class EdetSuperAdminModel extends FlutterFlowModel<EdetSuperAdminWidget> {
  final formKey = GlobalKey<FormState>();

  TextEditingController? nameTextController;
  FocusNode? nameFocusNode;
  TextEditingController? phoneTextController;
  FocusNode? phoneFocusNode;
  TextEditingController? emailTextController;

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
  }
}

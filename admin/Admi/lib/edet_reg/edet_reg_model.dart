
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'edet_reg_widget.dart' show EdetRegWidget;
import 'package:flutter/material.dart';

class EdetRegModel extends FlutterFlowModel<EdetRegWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextFieldnaim widget.
  FocusNode? textFieldnaimFocusNode;
  TextEditingController? textFieldnaimTextController;
  String? Function(BuildContext, String?)? textFieldnaimTextControllerValidator;
  // State field(s) for Switch widget.
  FocusNode? textFieldDescFocusNode;
  TextEditingController? textFieldDescTextController;

  bool? switchValue;
  bool isDataUploading_uploadDataO6s = false;
  FFUploadedFile uploadedLocalFile_uploadDataO6s =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataO6s = '';
  bool recordInitialized = false;
  String? countryLabel;

  void bindCitiesRecord(CitiesRecord record) {
    if (recordInitialized) {
      return;
    }
    textFieldnaimTextController ??=
        TextEditingController(text: record.naim);
    textFieldDescTextController ??=
        TextEditingController(text: record.osf);
    switchValue ??= record.acctev;
    uploadedFileUrl_uploadDataO6s = record.img;
    recordInitialized = true;
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldnaimFocusNode?.dispose();
    textFieldnaimTextController?.dispose();
    textFieldDescFocusNode?.dispose();
    textFieldDescTextController?.dispose();
  }
}

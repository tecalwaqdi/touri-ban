import '/flutter_flow/flutter_flow_util.dart';
import 'add_reg_widget.dart' show AddRegWidget;
import 'package:flutter/material.dart';

class AddRegModel extends FlutterFlowModel<AddRegWidget> {
  FocusNode? textFieldnaimFocusNode;
  TextEditingController? textFieldnaimTextController;
  String? Function(BuildContext, String?)? textFieldnaimTextControllerValidator;

  FocusNode? textFieldDescFocusNode;
  TextEditingController? textFieldDescTextController;

  bool? switchValue;

  bool isDataUploading_uploadDataO6sc = false;
  FFUploadedFile uploadedLocalFile_uploadDataO6sc =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataO6sc = '';

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

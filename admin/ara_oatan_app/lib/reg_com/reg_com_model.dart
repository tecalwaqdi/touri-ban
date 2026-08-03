import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'reg_com_widget.dart' show RegComWidget;
import 'package:flutter/material.dart';

class RegComModel extends FlutterFlowModel<RegComWidget> {
  ///  Local state fields for this page.

  String? img;

  ///  State fields for stateful widgets in this page.

  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  // State field(s) for phone widget.
  FocusNode? phoneFocusNode;
  TextEditingController? phoneTextController;
  String? Function(BuildContext, String?)? phoneTextControllerValidator;
  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = const FFPlace();
  // State field(s) for osf widget.
  FocusNode? osfFocusNode;
  TextEditingController? osfTextController;
  String? Function(BuildContext, String?)? osfTextControllerValidator;
  bool isDataUploading_uploadDataY60 = false;
  FFUploadedFile uploadedLocalFile_uploadDataY60 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataY60 = '';

  bool isDataUploading_uploadDataPdfRks = false;
  FFUploadedFile uploadedLocalFile_uploadDataPdfRks =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataPdfRks = '';

  bool isDataUploading_uploadDataPdfSJL = false;
  FFUploadedFile uploadedLocalFile_uploadDataPdfSJL =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataPdfSJL = '';

  // State field(s) for serves widget.
  FocusNode? servesFocusNode;
  TextEditingController? servesTextController;
  String? Function(BuildContext, String?)? servesTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    phoneFocusNode?.dispose();
    phoneTextController?.dispose();

    osfFocusNode?.dispose();
    osfTextController?.dispose();

    servesFocusNode?.dispose();
    servesTextController?.dispose();
  }
}

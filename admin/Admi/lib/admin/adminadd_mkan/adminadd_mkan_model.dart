import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'adminadd_mkan_widget.dart' show AdminaddMkanWidget;
import 'package:flutter/material.dart';

class AdminaddMkanModel extends FlutterFlowModel<AdminaddMkanWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  bool isDataUploading_uploadDataCanhome = false;
  FFUploadedFile uploadedLocalFile_uploadDataCanhome =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataCanhome = '';

  bool isDataUploading_uploadDataP4b = false;
  FFUploadedFile uploadedLocalFile_uploadDataP4b =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataP4b = '';

  bool isDataUploading_uploadData8dqs = false;
  FFUploadedFile uploadedLocalFile_uploadData8dqs =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData8dqs = '';

  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = FFPlace();
  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
  // State field(s) for SwitchMosque widget.
  bool? switchMosqueValue;
  // State field(s) for SwitchRestroom widget.
  bool? switchRestroomValue;
  // State field(s) for Switchrestaurant widget.
  bool? switchrestaurantValue;
  // State field(s) for Switch widget.
  bool? switchValue;
  // State field(s) for SwitchACCTEV widget.
  bool? switchACCTEVValue;
  // State field for the star rating.
  double ratingValue = 0.0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();
  }
}

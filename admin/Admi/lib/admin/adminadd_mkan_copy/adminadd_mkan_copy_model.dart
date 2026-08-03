import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'adminadd_mkan_copy_widget.dart' show AdminaddMkanCopyWidget;
import 'package:flutter/material.dart';

class AdminaddMkanCopyModel extends FlutterFlowModel<AdminaddMkanCopyWidget> {
  ///  State fields for stateful widgets in this page.

  bool recordInitialized = false;
  bool mainImageRemoved = false;

  void bindMkanRecord(MkanRecord record) {
    if (recordInitialized) {
      return;
    }
    textController1 ??= TextEditingController(text: record.naim);
    textController2 ??= TextEditingController(text: record.osf);
    switchMosqueValue ??= record.ismsgd;
    switchRestroomValue ??= record.ishmam;
    switchrestaurantValue ??= record.isfood;
    switchValue ??= record.asAds;
    switchACCTEVValue ??= record.acctev;
    ratingValue = record.rate;
    uploadedFileUrl_uploadDataCni = record.img1;
    uploadedFileUrl_uploadData8dq = record.img2;
    if (record.location != null) {
      placePickerValue = FFPlace(
        latLng: record.location!,
        address: record.address,
      );
      googleMapsCenter = record.location;
    }
    if (record.idVill != null) {
      FFAppState().REvCITE = record.idVill;
    }
    recordInitialized = true;
  }

  bool cityLabelLoaded = false;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  bool isDataUploading_uploadDataCni = false;
  FFUploadedFile uploadedLocalFile_uploadDataCni =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataCni = '';

  bool isDataUploading_uploadData8dq = false;
  FFUploadedFile uploadedLocalFile_uploadData8dq =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData8dq = '';

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

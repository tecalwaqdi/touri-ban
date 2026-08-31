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
  bool secondImageRemoved = false;
  bool thirdImageRemoved = false;

  /// Last server img* synced into the form (detects stale-cache → server refresh).
  String _syncedImg1 = '';
  String _syncedImg2 = '';
  String _syncedImg3 = '';

  bool get _pendingMainImageEdit =>
      mainImageRemoved ||
      isDataUploading_uploadDataCni ||
      (uploadedLocalFile_uploadDataCni.bytes != null &&
          uploadedLocalFile_uploadDataCni.bytes!.isNotEmpty);

  bool get _pendingSecondImageEdit =>
      secondImageRemoved ||
      isDataUploading_uploadData8dq ||
      (uploadedLocalFile_uploadData8dq.bytes != null &&
          uploadedLocalFile_uploadData8dq.bytes!.isNotEmpty);

  bool get _pendingThirdImageEdit =>
      thirdImageRemoved ||
      isDataUploading_uploadDataImg3 ||
      (uploadedLocalFile_uploadDataImg3.bytes != null &&
          uploadedLocalFile_uploadDataImg3.bytes!.isNotEmpty);

  void bindMkanRecord(MkanRecord record) {
    if (!recordInitialized) {
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
      uploadedFileUrl_uploadDataImg3 = record.img3;
      _syncedImg1 = record.img1;
      _syncedImg2 = record.img2;
      _syncedImg3 = record.img3;
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
      if (record.idCit != null) {
        FFAppState().Revreg = record.idCit;
      }
      if (record.revDolh != null) {
        FFAppState().RevDolh = record.revDolh;
      }
      recordInitialized = true;
      return;
    }

    // Root cause fix: first StreamBuilder snapshot may be persistence-cache
    // with a stale img*. When server delivers the real document, refresh the
    // form images unless the admin has a pending local pick/upload.
    if (!_pendingMainImageEdit && record.img1 != _syncedImg1) {
      uploadedFileUrl_uploadDataCni = record.img1;
      _syncedImg1 = record.img1;
    }
    if (!_pendingSecondImageEdit && record.img2 != _syncedImg2) {
      uploadedFileUrl_uploadData8dq = record.img2;
      _syncedImg2 = record.img2;
    }
    if (!_pendingThirdImageEdit && record.img3 != _syncedImg3) {
      uploadedFileUrl_uploadDataImg3 = record.img3;
      _syncedImg3 = record.img3;
    }
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

  bool isDataUploading_uploadDataImg3 = false;
  FFUploadedFile uploadedLocalFile_uploadDataImg3 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataImg3 = '';

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

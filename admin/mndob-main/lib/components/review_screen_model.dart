import '/flutter_flow/flutter_flow_util.dart';
import 'review_screen_widget.dart' show ReviewScreenWidget;
import 'package:flutter/material.dart';

class ReviewScreenModel extends FlutterFlowModel<ReviewScreenWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for RatingBar widget.
  double? ratingBarValue;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}

import '/flutter_flow/flutter_flow_util.dart';
import 'details24_quiz_page_widget.dart' show Details24QuizPageWidget;
import 'package:flutter/material.dart';

class Details24QuizPageModel extends FlutterFlowModel<Details24QuizPageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Slider widget.
  double? sliderValue;
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

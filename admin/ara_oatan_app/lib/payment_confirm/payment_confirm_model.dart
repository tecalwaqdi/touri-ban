import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'payment_confirm_widget.dart' show PaymentConfirmWidget;
import 'package:flutter/material.dart';

class PaymentConfirmModel extends FlutterFlowModel<PaymentConfirmWidget> {
  bool isPay = false;

  ApiCallResponse? verifyResponse;
  int? conOrder;
  List<UserRecord>? mnadebList;
  int? comnadeb;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

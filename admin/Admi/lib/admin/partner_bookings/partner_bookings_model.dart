import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'partner_bookings_widget.dart' show PartnerBookingsWidget;
import 'package:flutter/material.dart';

class PartnerBookingsModel extends FlutterFlowModel<PartnerBookingsWidget> {
  late Menu2Model menu2Model;

  @override
  void initState(BuildContext context) {
    menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    menu2Model.dispose();
  }
}

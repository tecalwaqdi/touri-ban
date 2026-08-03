import '/components/not_addresses_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'list_adress_select_widget.dart' show ListAdressSelectWidget;
import 'package:flutter/material.dart';

class ListAdressSelectModel extends FlutterFlowModel<ListAdressSelectWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for not_addresses component.
  late NotAddressesModel notAddressesModel;

  @override
  void initState(BuildContext context) {
    notAddressesModel = createModel(context, () => NotAddressesModel());
  }

  @override
  void dispose() {
    notAddressesModel.dispose();
  }
}

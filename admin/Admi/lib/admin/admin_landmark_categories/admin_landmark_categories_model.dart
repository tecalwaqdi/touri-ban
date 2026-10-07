import '/components/menu2_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'admin_landmark_categories_widget.dart'
    show AdminLandmarkCategoriesWidget;
import 'package:flutter/material.dart';

class AdminLandmarkCategoriesModel
    extends FlutterFlowModel<AdminLandmarkCategoriesWidget> {
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

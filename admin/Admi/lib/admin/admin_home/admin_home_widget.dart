import '/components/admin_layout_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'admin_home_model.dart';
export 'admin_home_model.dart';

class AdminHomeWidget extends StatefulWidget {
  const AdminHomeWidget({super.key});

  static String routeName = 'AdminHome';
  static String routePath = '/adminHome';

  @override
  State<AdminHomeWidget> createState() => _AdminHomeWidgetState();
}

class _AdminHomeWidgetState extends State<AdminHomeWidget> {
  late AdminHomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminHomeModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.goNamed(Home22DashboardWidget.routeName);
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _model.menu2Model,
      updateCallback: () => safeSetState(() {}),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

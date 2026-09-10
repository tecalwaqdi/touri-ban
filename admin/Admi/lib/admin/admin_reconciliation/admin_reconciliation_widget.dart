import 'package:flutter/material.dart';

import '/components/admin_layout_widget.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Legacy exceptions scanner — redirects to primary Finance Reconciliation.
class AdminReconciliationWidget extends StatefulWidget {
  const AdminReconciliationWidget({super.key});

  static const String routeName = 'AdminReconciliation';
  static const String routePath = '/adminReconciliation';

  @override
  State<AdminReconciliationWidget> createState() =>
      _AdminReconciliationWidgetState();
}

class _AdminReconciliationWidgetState extends State<AdminReconciliationWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(AdminFinanceReconciliationWidget.routeName);
    });
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: uiTr(context, 'المطابقة'),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

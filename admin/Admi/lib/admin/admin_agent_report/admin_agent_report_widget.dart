import 'package:flutter/material.dart';

import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'admin_agent_report_model.dart';
export 'admin_agent_report_model.dart';

/// LEGACY agent money report — redirects to canonical [AdminAgentFinanceWidget].
///
/// No OrderStatusHelper.isPaid / Agent_total / FinancialEngine math here.
class AdminAgentReportWidget extends StatefulWidget {
  const AdminAgentReportWidget({
    super.key,
    required this.iduser,
  });

  final DocumentReference? iduser;

  static String routeName = 'AdminAgentReport';
  static String routePath = '/adminAgentReport';

  @override
  State<AdminAgentReportWidget> createState() => _AdminAgentReportWidgetState();
}

class _AdminAgentReportWidgetState extends State<AdminAgentReportWidget> {
  late AdminAgentReportModel _model;
  late Menu2Model _menu2Model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAgentReportModel());
    _menu2Model = createModel(context, () => Menu2Model());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(AdminAgentFinanceWidget.routeName);
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _menu2Model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () {},
      title: uiTr(context, 'تقرير الوكيل'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              uiTr(
                context,
                'تم نقل تمويل الوكلاء إلى شاشة تمويل الوكلاء (FIN V2 / FIN-9)',
              ),
            ),
            const SizedBox(height: 12),
            AdminPrimaryButton(
              label: uiTr(context, 'فتح تمويل الوكلاء'),
              onPressed: () =>
                  context.goNamed(AdminAgentFinanceWidget.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

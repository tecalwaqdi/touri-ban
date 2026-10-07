import 'package:flutter/material.dart';

import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// LEGACY finance entry — redirects to canonical [AdminFinanceReportsWidget].
///
/// Do not restore OrderStatusHelper.isPaid / FinancialEngine money math here.
class AdminReportsHubWidget extends StatefulWidget {
  const AdminReportsHubWidget({super.key});

  static String routeName = 'AdminReportsHub';
  static String routePath = '/adminReportsHub';

  @override
  State<AdminReportsHubWidget> createState() => _AdminReportsHubWidgetState();
}

class _AdminReportsHubWidgetState extends State<AdminReportsHubWidget> {
  late Menu2Model _menu2Model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(AdminFinanceReportsWidget.routeName);
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
      updateCallback: () {},
      title: uiTr(context, 'التقارير'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              uiTr(
                context,
                'تم نقل التقارير المالية إلى مركز التقارير المالي (FIN V2)',
              ),
            ),
            const SizedBox(height: 12),
            AdminPrimaryButton(
              label: uiTr(context, 'فتح التقارير المالية'),
              onPressed: () =>
                  context.goNamed(AdminFinanceReportsWidget.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

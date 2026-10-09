import 'package:flutter/material.dart';

import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/l10n/nav_translations.dart';

/// Super-admin index for the tools removed from the finance sidebar.
///
/// Does not recalculate money. Each row opens the existing screen.
class AdminFinanceControlWidget extends StatefulWidget {
  const AdminFinanceControlWidget({super.key});

  static const String routeName = 'AdminFinanceControl';
  static const String routePath = '/adminFinanceControl';

  @override
  State<AdminFinanceControlWidget> createState() =>
      _AdminFinanceControlWidgetState();
}

class _AdminFinanceControlWidgetState extends State<AdminFinanceControlWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
  }

  @override
  void dispose() {
    _menu2Model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final links = <({String route, IconData icon, String note})>[
      (
        route: AdminFinanceAdjustmentsWidget.routeName,
        icon: Icons.tune_rounded,
        note: 'التعديلات اليدوية على المبالغ',
      ),
      (
        route: AdminFinancialPeriodsWidget.routeName,
        icon: Icons.date_range_outlined,
        note: 'إقفال الفترة ومنع القيود بأثر رجعي',
      ),
      (
        route: AdminFinanceDataQualityWidget.routeName,
        icon: Icons.rule_folder_outlined,
        note: 'جودة البيانات المالية',
      ),
      (
        route: AdminFinanceAuditWidget.routeName,
        icon: Icons.manage_search_rounded,
        note: 'سجل التدقيق المالي',
      ),
      (
        route: AdminAuditLogWidget.routeName,
        icon: Icons.history_rounded,
        note: 'سجل من غيّر ماذا في اللوحة',
      ),
      (
        route: AdminFinanceReconciliationWidget.routeName,
        icon: Icons.fact_check_outlined,
        note: 'المطابقة الوحيدة المتبقية',
      ),
    ];

    return AdminLayoutWidget(
      scaffoldKey: scaffoldKey,
      menu2Model: _menu2Model,
      updateCallback: () => safeSetState(() {}),
      title: navLabel(context, AdminFinanceControlWidget.routeName),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AdminPageHeader(
            title: navLabel(context, AdminFinanceControlWidget.routeName),
            subtitle: uiTr(
              context,
              'للسوبر أدمن فقط. الصفحات القديمة ما زالت تعمل، وحساب المبالغ لم يتغير.',
            ),
          ),
          const SizedBox(height: 12),
          AdminContentCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < links.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: theme.alternate),
                  ListTile(
                    leading: Icon(links[i].icon, color: AdminUi.brandTeal),
                    title: Text(
                      navLabel(context, links[i].route),
                      style: theme.titleSmall,
                    ),
                    subtitle: Text(
                      uiTr(context, links[i].note),
                      style: theme.bodySmall.override(
                        fontFamily: theme.bodySmallFamily,
                        color: theme.secondaryText,
                        letterSpacing: 0,
                        useGoogleFonts: !theme.bodySmallIsCustom,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => context.goNamed(links[i].route),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

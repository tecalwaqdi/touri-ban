import 'package:flutter/material.dart';

import '/components/admin_layout_widget.dart';
import '/components/menu2_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Folded into Finance Home — deep-link redirect only (no duplicate UI).
class AdminFinanceChannelsWidget extends StatefulWidget {
  const AdminFinanceChannelsWidget({super.key});

  static const String routeName = 'AdminFinanceChannels';
  static const String routePath = '/adminFinanceChannels';

  @override
  State<AdminFinanceChannelsWidget> createState() =>
      _AdminFinanceChannelsWidgetState();
}

class _AdminFinanceChannelsWidgetState
    extends State<AdminFinanceChannelsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Menu2Model _menu2Model;

  @override
  void initState() {
    super.initState();
    _menu2Model = createModel(context, () => Menu2Model());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(AdminFinanceHubWidget.routeName);
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
      title: uiTr(context, 'المالية'),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

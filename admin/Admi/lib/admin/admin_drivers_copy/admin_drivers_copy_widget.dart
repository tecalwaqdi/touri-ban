import '/admin/admin_drivers/admin_drivers_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'admin_drivers_copy_model.dart';
export 'admin_drivers_copy_model.dart';

/// Legacy duplicate route — redirects to [AdminDriversWidget].
class AdminDriversCopyWidget extends StatefulWidget {
  const AdminDriversCopyWidget({super.key});

  static String routeName = 'AdminDriversCopy';
  static String routePath = '/adminDriversCopy';

  @override
  State<AdminDriversCopyWidget> createState() => _AdminDriversCopyWidgetState();
}

class _AdminDriversCopyWidgetState extends State<AdminDriversCopyWidget> {
  late AdminDriversCopyModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminDriversCopyModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(AdminDriversWidget.routeName);
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

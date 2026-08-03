import '/admin/admin_drivers/admin_drivers_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'home3_model.dart';
export 'home3_model.dart';

/// Legacy route — redirects to [AdminDriversWidget].
class Home3Widget extends StatefulWidget {
  const Home3Widget({super.key});

  static String routeName = 'home3';
  static String routePath = '/home3';

  @override
  State<Home3Widget> createState() => _Home3WidgetState();
}

class _Home3WidgetState extends State<Home3Widget> {
  late Home3Model _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Home3Model());
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

import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// Legacy route — redirects to settings.
class AdminAgentCopyWidget extends StatelessWidget {
  const AdminAgentCopyWidget({super.key});

  static String routeName = 'AdminAgentCopy';
  static String routePath = '/adminAgentCopy';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.goNamed(SettingsWidget.routeName);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

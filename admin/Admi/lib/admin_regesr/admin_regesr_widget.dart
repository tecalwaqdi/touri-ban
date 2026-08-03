import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// Public super-admin registration is disabled — redirect to login.
class AdminRegesrWidget extends StatelessWidget {
  const AdminRegesrWidget({super.key});

  static String routeName = 'adminRegesr';
  static String routePath = '/adminRegesr';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.goNamed(HomePageWidget.routeName);
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

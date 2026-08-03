import '/admin/adminvill/adminvill_widget.dart';
import 'package:flutter/material.dart';

export 'admincite_model.dart';

/// Legacy route — redirects to [AdminvillWidget] (city management).
class AdminciteWidget extends StatelessWidget {
  const AdminciteWidget({super.key});

  static String routeName = 'Admincite';
  static String routePath = '/admincite';

  @override
  Widget build(BuildContext context) => const AdminvillWidget();
}

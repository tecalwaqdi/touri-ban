import '/admin/adminadd_mkan/adminadd_mkan_widget.dart';
import 'package:flutter/material.dart';

/// Legacy route — redirects to the proper admin landmark form.
class AddPlacePage extends StatelessWidget {
  const AddPlacePage({super.key});

  static String routeName = 'AddPlace';
  static String routePath = '/addPlace';

  @override
  Widget build(BuildContext context) => const AdminaddMkanWidget();
}

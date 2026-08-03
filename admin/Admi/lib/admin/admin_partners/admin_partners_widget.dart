import '/admin/admin_m3alm/admin_m3alm_widget.dart';
import 'package:flutter/material.dart';

/// Partners-only landmarks list (`isShrek == true`).
class AdminPartnersWidget extends StatelessWidget {
  const AdminPartnersWidget({super.key});

  static String routeName = 'AdminPartners';
  static String routePath = '/adminPartners';

  @override
  Widget build(BuildContext context) {
    return const AdminM3almWidget(partnersOnly: true);
  }
}

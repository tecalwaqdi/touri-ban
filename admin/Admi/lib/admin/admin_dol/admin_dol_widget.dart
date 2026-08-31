import '/admin/admin_geo/admin_geo_adapter.dart';
import '/admin/admin_geo/admin_geo_hub_widget.dart';
import 'package:flutter/material.dart';

export 'admin_dol_model.dart';

/// Countries list — opens unified Geo Hub on the Countries tab.
class AdminDolWidget extends StatelessWidget {
  const AdminDolWidget({super.key});

  static String routeName = 'AdminDol';
  static String routePath = '/adminDol';

  @override
  Widget build(BuildContext context) {
    return const AdminGeoHubWidget(initialTab: AdminGeoTab.countries);
  }
}

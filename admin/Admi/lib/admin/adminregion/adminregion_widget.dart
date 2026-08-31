import '/admin/admin_geo/admin_geo_adapter.dart';
import '/admin/admin_geo/admin_geo_hub_widget.dart';
import 'package:flutter/material.dart';

export 'adminregion_model.dart';

/// Regions list — opens unified Geo Hub on the Regions tab.
class AdminregionWidget extends StatelessWidget {
  const AdminregionWidget({super.key});

  static String routeName = 'Adminregion';
  static String routePath = '/adminregion';

  @override
  Widget build(BuildContext context) {
    return const AdminGeoHubWidget(initialTab: AdminGeoTab.regions);
  }
}

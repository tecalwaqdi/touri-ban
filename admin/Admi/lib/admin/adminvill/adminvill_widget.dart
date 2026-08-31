import '/admin/admin_geo/admin_geo_adapter.dart';
import '/admin/admin_geo/admin_geo_hub_widget.dart';
import 'package:flutter/material.dart';

export 'adminvill_model.dart';

/// Cities list — opens unified Geo Hub on the Cities tab.
class AdminvillWidget extends StatelessWidget {
  const AdminvillWidget({super.key});

  static String routeName = 'Adminvill';
  static String routePath = '/adminvill';

  @override
  Widget build(BuildContext context) {
    return const AdminGeoHubWidget(initialTab: AdminGeoTab.cities);
  }
}

import '/design_system/design_system.dart';
import '/order/list22_task_overview_responsive/list22_task_overview_responsive_widget.dart';
import 'package:flutter/material.dart';

/// شاشة الحجوزات — تعرض بيانات الطلبات من Firestore.
class BookingsWidget extends StatelessWidget {
  const BookingsWidget({super.key});

  static String routeName = 'Bookings';
  static String routePath = '/bookings';

  @override
  Widget build(BuildContext context) {
    return const DsScreenShell(
      child: List22TaskOverviewResponsiveWidget(),
    );
  }
}

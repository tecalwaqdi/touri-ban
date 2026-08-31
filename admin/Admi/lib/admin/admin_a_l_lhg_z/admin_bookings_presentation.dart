import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';

/// Presentation-only helpers for Bookings List / Details (no business logic).
abstract final class AdminBookingsPresentation {
  AdminBookingsPresentation._();

  static String driverCellLabel(BuildContext context, String name) {
    final t = name.trim();
    if (t.isEmpty) return uiTr(context, 'لم يُعيّن بعد');
    return t;
  }

  /// Compact date line for table cells: `31/08/2026`.
  static String tableDate(DateTime? at) {
    if (at == null) return '—';
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    return '$d/$m/${at.year}';
  }

  /// Compact time line for table cells: `10:18`.
  static String tableTime(DateTime? at) {
    if (at == null) return '';
    final h = at.hour.toString().padLeft(2, '0');
    final min = at.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  static String tableDateTimeTooltip(DateTime? at) {
    if (at == null) return '—';
    return dateTimeFormat('d/M/y HH:mm:ss', at, locale: 'ar');
  }
}

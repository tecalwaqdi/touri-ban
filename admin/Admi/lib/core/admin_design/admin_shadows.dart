import 'package:flutter/material.dart';

import 'admin_colors.dart';

/// Admin UI V2 subtle elevation.
abstract final class AdminShadows {
  AdminShadows._();

  static List<BoxShadow> card(BuildContext context) {
    final dark = AdminColors.isDark(context);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.28 : 0.04),
        blurRadius: dark ? 10 : 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> modal(BuildContext context) {
    final dark = AdminColors.isDark(context);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> menu(BuildContext context) {
    final dark = AdminColors.isDark(context);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

import 'package:flutter/material.dart';

/// Design tokens — Workstream C.
/// Palette chosen for driver UX (map-first, high contrast). Not a third-party clone.
abstract final class AppColors {
  AppColors._();

  // Light
  static const primaryDark = Color(0xFF111827);
  static const primary = Color(0xFF1F2937);
  static const accent = Color(0xFF00A67E);
  static const actionBlue = Color(0xFF2563EB);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const divider = Color(0xFFE5E7EB);

  // Dark
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111827);
  static const darkElevated = Color(0xFF1F2937);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFFCBD5E1);
}

abstract final class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
}

abstract final class AppDurations {
  AppDurations._();
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
}

abstract final class AppShadows {
  AppShadows._();
  static List<BoxShadow> card({bool dark = false}) => [
        BoxShadow(
          color: dark
              ? Colors.black.withValues(alpha: 0.35)
              : AppColors.primaryDark.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

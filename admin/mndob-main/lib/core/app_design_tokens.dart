import 'package:flutter/material.dart';

import '/design_system/design_system.dart';

/// Legacy Workstream C aliases — now mirror Tory Taxi [DsColors] / tokens.
/// Prefer importing `/design_system/design_system.dart` directly in new code.
abstract final class AppColors {
  AppColors._();

  static const primaryDark = Color(0xFF154D42);
  static const primary = Color(0xFF1F6F5F);
  static const accent = Color(0xFF1F6F5F);
  static const actionBlue = Color(0xFF2F6FA8);
  static const background = Color(0xFFF7F9F8);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF121A18);
  static const textSecondary = Color(0xFF4A5854);
  static const success = Color(0xFF1F8A64);
  static const warning = Color(0xFFD4A017);
  static const danger = Color(0xFFD64550);
  static const divider = Color(0xFFE2E8E6);

  static const darkBackground = Color(0xFF0A100F);
  static const darkSurface = Color(0xFF121A18);
  static const darkElevated = Color(0xFF1F2A27);
  static const darkTextPrimary = Color(0xFFF7F9F8);
  static const darkTextSecondary = Color(0xFF9AA8A4);
}

abstract final class AppSpacing {
  AppSpacing._();
  static const xs = DsSpacing.xxs;
  static const sm = DsSpacing.xs;
  static const md = DsSpacing.md;
  static const lg = DsSpacing.lg;
  static const xl = DsSpacing.xl;
}

abstract final class AppRadius {
  AppRadius._();
  static const sm = DsRadius.xs;
  static const md = DsRadius.sm;
  static const lg = DsRadius.md;
  static const xl = DsRadius.xl;
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
}

abstract final class AppDurations {
  AppDurations._();
  static const fast = DsDurations.fast;
  static const normal = DsDurations.normal;
  static const slow = DsDurations.slow;
}

abstract final class AppShadows {
  AppShadows._();
  static List<BoxShadow> card({bool dark = false}) =>
      DsShadows.card(dark: dark);
}

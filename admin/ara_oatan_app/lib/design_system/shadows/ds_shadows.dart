import 'package:flutter/material.dart';

import '../colors/ds_color_scales.dart';

/// Unified elevation / shadow tokens.
abstract final class DsShadows {
  static const Color _tint = Color(0x1A154D42);
  static const Color _deep = Color(0x33154D42);
  static const Color _darkTint = Color(0x66000000);

  static List<BoxShadow> soft({bool dark = false}) => [
        BoxShadow(
          color: dark ? _darkTint : _tint,
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> card({bool dark = false}) => [
        BoxShadow(
          color: dark ? _darkTint : _tint,
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> floating({bool dark = false}) => [
        BoxShadow(
          color: dark ? _darkTint : _deep,
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> dialog({bool dark = false}) => [
        BoxShadow(
          color: dark ? const Color(0x80000000) : const Color(0x40154D42),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> bottomSheet({bool dark = false}) => [
        BoxShadow(
          color: dark ? const Color(0x80000000) : const Color(0x33154D42),
          blurRadius: 28,
          offset: const Offset(0, -8),
          spreadRadius: -6,
        ),
      ];

  /// Subtle brand glow for primary CTAs (classic, restrained).
  static List<BoxShadow> primaryGlow({bool dark = false}) => [
        BoxShadow(
          color: (dark ? const Color(0xFF4A9A87) : DsPrimaryScale.shade500)
              .withValues(alpha: 0.16),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
}

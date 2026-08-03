import 'package:flutter/material.dart';

/// Primary brand scale for Tory Taxi.
/// Brand anchor (500): `#1F6F5F`.
abstract final class DsPrimaryScale {
  static const Color shade50 = Color(0xFFF0F7F5);
  static const Color shade100 = Color(0xFFD9EBE6);
  static const Color shade200 = Color(0xFFB3D7CD);
  static const Color shade300 = Color(0xFF8CC3B4);
  static const Color shade400 = Color(0xFF4A9A87);
  static const Color shade500 = Color(0xFF1F6F5F);
  static const Color shade600 = Color(0xFF1A5E50);
  static const Color shade700 = Color(0xFF154D42);
  static const Color shade800 = Color(0xFF103C33);
  static const Color shade900 = Color(0xFF0A2B24);

  static const Color brand = shade500;
}

/// Neutral cool-green gray scale for surfaces and text.
abstract final class DsNeutralScale {
  static const Color shade0 = Color(0xFFFFFFFF);
  static const Color shade50 = Color(0xFFF7F9F8);
  static const Color shade100 = Color(0xFFEEF2F1);
  static const Color shade200 = Color(0xFFE2E8E6);
  static const Color shade300 = Color(0xFFC9D2CF);
  static const Color shade400 = Color(0xFF9AA8A4);
  static const Color shade500 = Color(0xFF6B7A76);
  static const Color shade600 = Color(0xFF4A5854);
  static const Color shade700 = Color(0xFF33403D);
  static const Color shade800 = Color(0xFF1F2A27);
  static const Color shade900 = Color(0xFF121A18);
  static const Color shade950 = Color(0xFF0A100F);
}

/// Semantic scales.
abstract final class DsSuccessScale {
  static const Color shade50 = Color(0xFFEDF8F3);
  static const Color shade100 = Color(0xFFD5EEE3);
  static const Color shade500 = Color(0xFF1F8A64);
  static const Color shade700 = Color(0xFF146348);
}

abstract final class DsWarningScale {
  static const Color shade50 = Color(0xFFFFF8E8);
  static const Color shade100 = Color(0xFFFEEDED);
  static const Color shade500 = Color(0xFFD4A017);
  static const Color shade700 = Color(0xFF9A7410);
}

abstract final class DsErrorScale {
  static const Color shade50 = Color(0xFFFDF0F1);
  static const Color shade100 = Color(0xFFFAD9DC);
  static const Color shade500 = Color(0xFFD64550);
  static const Color shade700 = Color(0xFFA8323B);
}

abstract final class DsInfoScale {
  static const Color shade50 = Color(0xFFEEF5FA);
  static const Color shade100 = Color(0xFFD6E7F4);
  static const Color shade500 = Color(0xFF2F6FA8);
  static const Color shade700 = Color(0xFF1F4F78);
}

import 'package:flutter/material.dart';

import '/design_system/design_system.dart';

/// ثيم تطبيق المندوب — يفوّض بالكامل إلى Design System المشترك مع تطبيق العميل.
abstract final class DriverAppTheme {
  DriverAppTheme._();

  static ThemeData light() => DsTheme.light();

  static ThemeData dark() => DsTheme.dark();
}

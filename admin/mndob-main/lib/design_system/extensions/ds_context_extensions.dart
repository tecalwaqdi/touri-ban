import 'package:flutter/material.dart';

import '../colors/ds_colors.dart';
import '../typography/ds_typography.dart';

/// Convenient access to Design System tokens from [BuildContext].
extension DsContextX on BuildContext {
  ThemeData get dsTheme => Theme.of(this);

  DsColors get dsColors => DsColors.of(this);

  DsTypography get dsTypography => DsTypography.of(this);

  TextTheme get dsText => dsTheme.textTheme;

  ColorScheme get dsColorScheme => dsTheme.colorScheme;

  bool get dsIsDark => dsTheme.brightness == Brightness.dark;

  MediaQueryData get dsMedia => MediaQuery.of(this);
}

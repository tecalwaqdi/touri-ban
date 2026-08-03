import 'package:flutter/material.dart';

import '../colors/ds_colors.dart';
import '../typography/ds_typography.dart';

/// Combined theme extension for quick access (optional).
@immutable
class DsThemeExtension extends ThemeExtension<DsThemeExtension> {
  const DsThemeExtension({
    required this.colors,
    required this.typography,
  });

  final DsColors colors;
  final DsTypography typography;

  static DsThemeExtension light = DsThemeExtension(
    colors: DsColors.light,
    typography: DsTypography.standard,
  );

  static DsThemeExtension dark = DsThemeExtension(
    colors: DsColors.dark,
    typography: DsTypography.standard,
  );

  static DsThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<DsThemeExtension>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  DsThemeExtension copyWith({
    DsColors? colors,
    DsTypography? typography,
  }) {
    return DsThemeExtension(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
    );
  }

  @override
  DsThemeExtension lerp(ThemeExtension<DsThemeExtension>? other, double t) {
    if (other is! DsThemeExtension) return this;
    return DsThemeExtension(
      colors: colors.lerp(other.colors, t),
      typography: typography.lerp(other.typography, t),
    );
  }
}

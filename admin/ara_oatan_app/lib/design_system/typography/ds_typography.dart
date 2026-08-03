import 'package:flutter/material.dart';

/// Typography system — Cairo family (already registered in pubspec).
///
/// Scale follows Material 3 roles with premium line-heights for Arabic/LTR.
@immutable
class DsTypography extends ThemeExtension<DsTypography> {
  const DsTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  static const String fontFamily = 'cairo';
  static const List<String> fontFamilyFallback = [
    'Noto Sans',
    'Roboto',
    'Arial',
  ];

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      letterSpacing: letterSpacing,
    );
  }

  static final DsTypography standard = DsTypography(
    displayLarge: _base(
      size: 40,
      weight: FontWeight.w700,
      height: 48,
      letterSpacing: -0.5,
    ),
    displayMedium: _base(
      size: 34,
      weight: FontWeight.w700,
      height: 42,
      letterSpacing: -0.4,
    ),
    displaySmall: _base(
      size: 28,
      weight: FontWeight.w700,
      height: 36,
      letterSpacing: -0.2,
    ),
    headlineLarge: _base(
      size: 24,
      weight: FontWeight.w700,
      height: 32,
    ),
    headlineMedium: _base(
      size: 22,
      weight: FontWeight.w600,
      height: 30,
    ),
    headlineSmall: _base(
      size: 20,
      weight: FontWeight.w600,
      height: 28,
    ),
    titleLarge: _base(
      size: 18,
      weight: FontWeight.w600,
      height: 26,
    ),
    titleMedium: _base(
      size: 16,
      weight: FontWeight.w600,
      height: 24,
    ),
    titleSmall: _base(
      size: 14,
      weight: FontWeight.w600,
      height: 20,
    ),
    bodyLarge: _base(
      size: 16,
      weight: FontWeight.w400,
      height: 24,
    ),
    bodyMedium: _base(
      size: 14,
      weight: FontWeight.w400,
      height: 22,
    ),
    bodySmall: _base(
      size: 12,
      weight: FontWeight.w400,
      height: 18,
    ),
    labelLarge: _base(
      size: 14,
      weight: FontWeight.w600,
      height: 20,
      letterSpacing: 0.1,
    ),
    labelMedium: _base(
      size: 12,
      weight: FontWeight.w600,
      height: 16,
      letterSpacing: 0.2,
    ),
    labelSmall: _base(
      size: 11,
      weight: FontWeight.w500,
      height: 14,
      letterSpacing: 0.3,
    ),
  );

  static DsTypography of(BuildContext context) {
    return Theme.of(context).extension<DsTypography>() ?? standard;
  }

  TextTheme toTextTheme({Color? color}) {
    TextStyle tint(TextStyle s) => color == null ? s : s.copyWith(color: color);
    return TextTheme(
      displayLarge: tint(displayLarge),
      displayMedium: tint(displayMedium),
      displaySmall: tint(displaySmall),
      headlineLarge: tint(headlineLarge),
      headlineMedium: tint(headlineMedium),
      headlineSmall: tint(headlineSmall),
      titleLarge: tint(titleLarge),
      titleMedium: tint(titleMedium),
      titleSmall: tint(titleSmall),
      bodyLarge: tint(bodyLarge),
      bodyMedium: tint(bodyMedium),
      bodySmall: tint(bodySmall),
      labelLarge: tint(labelLarge),
      labelMedium: tint(labelMedium),
      labelSmall: tint(labelSmall),
    );
  }

  @override
  DsTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
  }) {
    return DsTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  @override
  DsTypography lerp(ThemeExtension<DsTypography>? other, double t) {
    if (other is! DsTypography) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return DsTypography(
      displayLarge: l(displayLarge, other.displayLarge),
      displayMedium: l(displayMedium, other.displayMedium),
      displaySmall: l(displaySmall, other.displaySmall),
      headlineLarge: l(headlineLarge, other.headlineLarge),
      headlineMedium: l(headlineMedium, other.headlineMedium),
      headlineSmall: l(headlineSmall, other.headlineSmall),
      titleLarge: l(titleLarge, other.titleLarge),
      titleMedium: l(titleMedium, other.titleMedium),
      titleSmall: l(titleSmall, other.titleSmall),
      bodyLarge: l(bodyLarge, other.bodyLarge),
      bodyMedium: l(bodyMedium, other.bodyMedium),
      bodySmall: l(bodySmall, other.bodySmall),
      labelLarge: l(labelLarge, other.labelLarge),
      labelMedium: l(labelMedium, other.labelMedium),
      labelSmall: l(labelSmall, other.labelSmall),
    );
  }
}

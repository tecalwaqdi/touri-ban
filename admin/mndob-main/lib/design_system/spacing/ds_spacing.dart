import 'package:flutter/material.dart';

/// Unified spacing scale (4pt grid).
///
/// Never use arbitrary padding/margins — pick the nearest token.
abstract final class DsSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double giant = 56;
  static const double colossal = 64;

  // Named aliases matching the requested scale.
  static const double s4 = xxs;
  static const double s8 = xs;
  static const double s12 = sm;
  static const double s16 = md;
  static const double s20 = lg;
  static const double s24 = xl;
  static const double s28 = xxl;
  static const double s32 = xxxl;
  static const double s40 = huge;
  static const double s48 = massive;
  static const double s56 = giant;
  static const double s64 = colossal;

  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets pagePaddingHorizontal =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: xl);
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: xl, vertical: sm);
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: sm, vertical: xxs);
  static const EdgeInsets inputContentPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);

  static SizedBox get gapXxs => const SizedBox(height: xxs, width: xxs);
  static SizedBox get gapXs => const SizedBox(height: xs, width: xs);
  static SizedBox get gapSm => const SizedBox(height: sm, width: sm);
  static SizedBox get gapMd => const SizedBox(height: md, width: md);
  static SizedBox get gapLg => const SizedBox(height: lg, width: lg);
  static SizedBox get gapXl => const SizedBox(height: xl, width: xl);
  static SizedBox get gapXxl => const SizedBox(height: xxl, width: xxl);
  static SizedBox get gapXxxl => const SizedBox(height: xxxl, width: xxxl);

  static SizedBox h(double value) => SizedBox(height: value);
  static SizedBox w(double value) => SizedBox(width: value);
}

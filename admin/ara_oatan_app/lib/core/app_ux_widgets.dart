import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '/core/app_design_system.dart';
import '/core/toury_brand_widgets.dart';
import '/core/toury_image.dart';
import '/design_system/design_system.dart';

/// قياسات مرنة حسب حجم الشاشة — تمنع تجاوز الارتفاع على الجوالات الصغيرة والأجهزة اللوحية.
class TouryLayout {
  TouryLayout._();

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 700;

  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static double heroHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    if (isLandscape(context)) {
      return (h * 0.52).clamp(180.0, 360.0);
    }
    final fraction = isCompact(context) ? 0.36 : (isTablet(context) ? 0.32 : 0.44);
    return (h * fraction).clamp(200.0, 480.0);
  }

  static double countryHeroHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.26).clamp(150.0, 280.0);
  }

  static double detailHeroHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    if (isLandscape(context)) {
      return (h * 0.65).clamp(200.0, 420.0);
    }
    return (h * 0.40).clamp(220.0, 480.0);
  }

  static double panelMaxHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.58).clamp(260.0, 700.0);
  }

  /// ارتفاع بطاقة الإعلان الكاملة (صورة + نص + أزرار).
  static double landmarkAdCardHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final imageH = landmarkAdImageHeight(context);
    final titleH = landmarkTitleFontSize(context) * scale * 2.4;
    final actionsH = isCompact(context) ? 32.0 : 36.0;
    final pad = isCompact(context) ? 10.0 : 14.0;
    return imageH + titleH + actionsH + pad;
  }

  /// ارتفاع شريط بطاقات الإعلانات الأفقي (يتكيّف مع تكبير الخط).
  static double landmarkAdCarouselHeight(BuildContext context) {
    final outer = isCompact(context) ? 12.0 : 16.0;
    return landmarkAdCardHeight(context) + outer + 4.0;
  }

  /// عرض بطاقة الإعلان في الشريط الأفقي.
  static double landmarkAdCardWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (isTablet(context)) {
      return (w * 0.38).clamp(300.0, 400.0);
    }
    if (isNarrow(context)) {
      return (w * 0.86).clamp(248.0, w - 24.0);
    }
    return (w * 0.76).clamp(260.0, 340.0);
  }

  /// ارتفاع صورة بطاقة الإعلان.
  static double landmarkAdImageHeight(BuildContext context) =>
      (landmarkAdCardWidth(context) * 0.37).clamp(80.0, 112.0);

  /// عرض بطاقة المعلم في القائمة العمودية.
  static double landmarkListCardWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final maxW = contentMaxWidth(context);
    final contentW = maxW.isFinite ? maxW : w;
    final pad = pagePadding(context).horizontal;
    return (contentW - pad).clamp(280.0, 560.0);
  }

  /// حشو بطاقات المعالم.
  static EdgeInsetsDirectional landmarkCardPadding(BuildContext context) =>
      EdgeInsetsDirectional.fromSTEB(
        isNarrow(context) ? 10.0 : 12.0,
        8.0,
        isNarrow(context) ? 10.0 : 12.0,
        8.0,
      );

  /// حشو عنصر القائمة الأفقية.
  static EdgeInsetsDirectional landmarkCarouselItemPadding(BuildContext context) =>
      EdgeInsetsDirectional.fromSTEB(
        pagePadding(context).left,
        8.0,
        0.0,
        10.0,
      );

  /// حجم خط عنوان المعلم.
  static double landmarkTitleFontSize(BuildContext context) =>
      isCompact(context) ? 12.0 : (isTablet(context) ? 15.0 : 13.0);

  static double listPanelHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.42).clamp(220.0, 420.0);
  }

  static double drawerHeaderHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.16).clamp(72.0, 160.0);
  }

  static double mapPanelHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    if (isLandscape(context)) {
      return (h * 0.55).clamp(200.0, 400.0);
    }
    return (h * 0.36).clamp(240.0, 420.0);
  }

  static double cardImageHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (isTablet(context)) {
      return (w / 2.4).clamp(130.0, 220.0);
    }
    return (w * 0.48).clamp(120.0, 200.0);
  }

  static double sheetMaxHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.88).clamp(320.0, h * 0.92);
  }

  static double emptyStateImageHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.35).clamp(160.0, 400.0);
  }

  static double contentMaxWidth(BuildContext context) {
    if (isLargeScreen(context)) return 920.0;
    if (isTablet(context)) return 720.0;
    return double.infinity;
  }

  static int gridColumns(
    BuildContext context, {
    int phone = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isLargeScreen(context)) return desktop;
    if (isTablet(context)) return tablet;
    return phone;
  }

  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
        horizontal: isTablet(context)
            ? 24.0
            : (isNarrow(context) ? 12.0 : 16.0),
        vertical: isCompact(context) ? 8.0 : 12.0,
      );

  static double villageThumbSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.26).clamp(88.0, 120.0);
  }

  /// عرض بطاقة القرية في القائمة الأفقية.
  static double villageHorizontalCardWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.52).clamp(160.0, 240.0);
  }

  static double villageHorizontalCardHeight(BuildContext context) =>
      villageHorizontalCardWidth(context) * 0.53;

  static double bottomNavSafe(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + (isCompact(context) ? 2.0 : 4.0);

  static double keyboardBottomPadding(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom;

  /// حشو سفلي للتمرير فوق زر ثابت في أسفل الصفحة.
  static double scrollPaddingAboveBottomButton(BuildContext context) =>
      primaryActionBarHeight(context) + 20.0;

  /// مسافة زر الإجراء من أسفل منطقة المحتوى.
  static double bottomActionGap(BuildContext context) => 8.0;

  /// ارتفاع شريط الإجراء الرئيسي (مثل زر «التالي»).
  static double primaryActionBarHeight(BuildContext context) =>
      isCompact(context) ? 56.0 : 70.0;
  static double spinnerSize(BuildContext context) =>
      isCompact(context) ? 40.0 : 50.0;
}

/// غلاف عام لكل صفحات التطبيق — يحد العرض على الشاشات العريضة.
class TouryResponsivePage extends StatelessWidget {
  const TouryResponsivePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TouryAdaptiveScope(child: child);
  }
}

/// يحدّ عرض المحتوى على الشاشات العريضة (تابلت/سطح مكتب) مع توسيط.
class TouryAdaptiveScope extends StatelessWidget {
  const TouryAdaptiveScope({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final maxW = TouryLayout.contentMaxWidth(context);
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (TouryLayout.isTablet(context) || TouryLayout.isLargeScreen(context)) {
      content = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: TouryLayout.isLargeScreen(context) ? 24.0 : 12.0,
        ),
        child: content,
      );
    }
    if (!maxW.isFinite) {
      return content;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: content,
      ),
    );
  }
}

/// غلاف موحّد لجسم الشاشة — يمنع تجاوز الارتفاع على الشاشات الصغيرة.
class TouryResponsiveBody extends StatelessWidget {
  const TouryResponsiveBody({
    super.key,
    required this.child,
    this.safeArea = true,
    this.scroll = true,
    this.padding,
  });

  final Widget child;
  final bool safeArea;
  final bool scroll;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = child;
        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }
        if (scroll) {
          content = SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: content,
            ),
          );
        }
        if (safeArea) {
          content = SafeArea(top: true, child: content);
        }
        return content;
      },
    );
  }
}

/// شريط خطوات الحجز — يوضح للمستخدم أين هو في العملية.
class TouryBookingStepBar extends StatelessWidget {
  const TouryBookingStepBar({
    super.key,
    required this.currentStep,
    this.compact = false,
  });

  /// 1 = نوع الرحلة، 2 = الموقع، 3 = التفاصيل، 4 = الدفع
  final int currentStep;
  final bool compact;

  static const _steps = [
    ('ux_step_trip_type', Icons.route_rounded),
    ('ux_step_location', Icons.location_on_rounded),
    ('ux_step_details', Icons.list_alt_rounded),
    ('ux_step_payment', Icons.payment_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 0 : 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TouryText(
            'ux_booking_steps'.tr(),
            style: typography.labelMedium,
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12 : null,
            color: colors.textSecondary,
          ),
          SizedBox(height: compact ? 2 : 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_steps.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const SizedBox(width: 6);
                }
                final stepIndex = index ~/ 2;
                final stepNum = stepIndex + 1;
                final isActive = stepNum == currentStep;
                final isDone = stepNum < currentStep;
                return SizedBox(
                  width: 76,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: compact ? 32 : 36,
                        height: compact ? 32 : 36,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? TouryBrand.primaryGradient
                              : null,
                          color: isActive
                              ? null
                              : isDone
                                  ? TouryBrand.tealDark
                                  : colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone || isActive
                                ? (isDone
                                    ? TouryBrand.tealDark
                                    : TouryBrand.teal)
                                : colors.border,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isDone
                              ? Icons.check_rounded
                              : _steps[stepIndex].$2,
                          size: 18,
                          color: isDone || isActive
                              ? Colors.white
                              : colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 6),
                      TouryText(
                        _steps[stepIndex].$1.tr(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        fontSize: compact ? 9 : 10,
                        lineHeight: compact ? 1.1 : 1.2,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? TouryBrand.tealDark
                            : colors.textSecondary,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// بانر توجيهي يشرح للمستخدم الخطوة التالية.
class TouryHelpBanner extends StatelessWidget {
  const TouryHelpBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = TouryBannerTone.info,
    this.compact = false,
  });

  final String message;
  final IconData icon;
  final TouryBannerTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final (bg, fg, border) = switch (tone) {
      TouryBannerTone.info => (
          colors.primarySoft,
          colors.primaryStrong,
          colors.primary.withValues(alpha: 0.35),
        ),
      TouryBannerTone.success => (
          colors.successContainer,
          colors.success,
          colors.success.withValues(alpha: 0.4),
        ),
      TouryBannerTone.warning => (
          colors.warningContainer,
          DsWarningScale.shade700,
          colors.warning.withValues(alpha: 0.5),
        ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: TouryBrand.borderRadiusMd,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: compact ? 18 : 22),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: TouryText(
              message,
              style: typography.bodyMedium,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: fg,
              maxLines: compact ? 2 : 4,
              lineHeight: compact ? 1.25 : 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

enum TouryBannerTone { info, success, warning }

/// شريط علوي موحّد للشاشات الرئيسية.
class TouryMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TouryMainAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
  });

  final String title;
  final String? subtitle;
  final bool showLogo;

  static const double _logoContentHeight = 108;
  static const double _titleContentHeight = 64;

  @override
  Size get preferredSize {
  // يغطي الارتفاع الديناميكي على الشاشات الصغيرة والكبيرة
    return Size.fromHeight(showLogo ? _logoContentHeight : _titleContentHeight);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final compactHeader = screenH < 700;
    final logoW = compactHeader ? 112.0 : 128.0;
    final logoH = compactHeader ? 44.0 : 52.0;
    final height = showLogo
        ? (compactHeader ? 92.0 : _logoContentHeight)
        : (compactHeader ? 56.0 : _titleContentHeight);

    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: TouryBrand.verticalGradient,
          boxShadow: TouryBrand.cardShadow(elevated: true),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, compactHeader ? 4 : 6, 16, 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showLogo) ...[
                Center(
                  child: TouryLogo(
                    width: logoW,
                    height: logoH,
                    withBackground: true,
                  ),
                ),
                SizedBox(height: compactHeader ? 4 : 6),
              ],
              if (subtitle != null)
                TouryText(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  fontSize: compactHeader ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                  lineHeight: 1.2,
                )
              else if (title.isNotEmpty)
                TouryText(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  fontWeight: FontWeight.w700,
                  fontSize: compactHeader ? 16 : 17,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة خيار كبيرة وواضحة (نوع الرحلة، إلخ).
class TouryOptionCard extends StatelessWidget {
  const TouryOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TouryBrand.borderRadiusLg,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: selected ? TouryBrand.primaryGradient : null,
            color: selected ? null : colors.surface,
            borderRadius: TouryBrand.borderRadiusLg,
            border: Border.all(
              color: selected ? TouryBrand.tealDark : colors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? TouryBrand.cardShadow(elevated: true) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : TouryBrand.teal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? null
                      : Border.all(
                          color: TouryBrand.tealDark.withValues(alpha: 0.25),
                        ),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : TouryBrand.tealDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TouryText(
                      title,
                      style: typography.titleMedium,
                      maxLines: 2,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: selected ? Colors.white : TouryBrand.tealDark,
                    ),
                    const SizedBox(height: 4),
                    TouryText(
                      subtitle,
                      style: typography.bodySmall,
                      maxLines: 3,
                      fontSize: 12,
                      lineHeight: 1.4,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.92)
                          : colors.textSecondary,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: selected ? Colors.white : TouryBrand.teal,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حالة فارغة للقوائم.
class TouryEmptyState extends StatelessWidget {
  const TouryEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: TouryBrand.softGradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: TouryBrand.teal.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, size: 40, color: TouryBrand.tealDark),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: typography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: typography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!.tr()),
            ),
          ],
        ],
      ),
    );
  }
}

/// بطاقة خيار سيارة في قائمة الحجز.
class TouryCarOptionCard extends StatelessWidget {
  const TouryCarOptionCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.priceLabel,
    required this.minHoursLabel,
    required this.onTap,
    this.actionLabel,
    this.showArrowOnly = false,
  });

  final String title;
  final String? imageUrl;
  final String priceLabel;
  final String minHoursLabel;
  final VoidCallback onTap;
  final String? actionLabel;
  final bool showArrowOnly;

  @override
  Widget build(BuildContext context) {
    final typography = context.dsTypography;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TouryBrand.borderRadiusLg,
        child: Ink(
          decoration:
              TouryBrand.cardDecoration(context: context, elevated: true),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 78,
                decoration: BoxDecoration(
                  color: TouryBrand.tealLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: TouryBrand.teal.withValues(alpha: 0.22),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: TouryNetworkImage(
                    url: imageUrl,
                    width: 104,
                    height: 78,
                    fit: BoxFit.cover,
                    fallbackAsset: 'assets/images/car.png',
                    useBrandedFallback: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TouryText(
                      title,
                      style: typography.titleMedium,
                      maxLines: 2,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: TouryBrand.tealDark,
                      lineHeight: 1.25,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          label: priceLabel,
                          highlighted: true,
                        ),
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: minHoursLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showArrowOnly || actionLabel == null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TouryBrand.tealLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TouryBrand.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: TouryBrand.tealDark,
                  ),
                )
              else
                SizedBox(
                  width: 76,
                  child: TouryGradientButton(
                    label: actionLabel!,
                    onPressed: onTap,
                    height: 38,
                    expanded: true,
                    icon: Icons.check_rounded,
                    fontSize: 11,
                    iconSize: 14,
                    horizontalPadding: 6,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: highlighted ? TouryBrand.primaryGradient : null,
        color: highlighted ? null : TouryBrand.surface,
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? null
            : Border.all(color: TouryBrand.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted ? Colors.white : TouryBrand.tealDark,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: TouryText(
              label,
              maxLines: 1,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: highlighted ? Colors.white : TouryBrand.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// خيار قابل للنقر في شاشة الدفع (طريقة الدفع، الجدولة...).
class TouryCheckoutOptionTile extends StatelessWidget {
  const TouryCheckoutOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: TouryBrand.borderRadiusLg,
          child: Ink(
            decoration: TouryBrand.cardDecoration(
              context: context,
              elevated: selected,
              border: Border.all(
                color: selected
                    ? TouryBrand.teal
                    : TouryBrand.border.withValues(alpha: 0.7),
                width: selected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: selected ? TouryBrand.primaryGradient : null,
                    color: selected ? null : TouryBrand.tealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : TouryBrand.tealDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TouryText(
                        title,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: TouryBrand.tealDark,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      TouryText(
                        subtitle,
                        fontSize: 12,
                        color: TouryBrand.textSecondary,
                        maxLines: 2,
                        lineHeight: 1.3,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: TouryBrand.teal,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// صف في ملخص الأسعار.
class TouryPriceSummaryRow extends StatelessWidget {
  const TouryPriceSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDeduction = false,
  });

  final String label;
  final String value;
  final bool isTotal;
  final bool isDeduction;

  @override
  Widget build(BuildContext context) {
    final labelColor = isDeduction
        ? TouryBrand.error
        : isTotal
            ? TouryBrand.teal
            : TouryBrand.textSecondaryFor(context);
    // Money amounts need high contrast on dark elevated cards.
    final valueColor = isDeduction
        ? TouryBrand.error
        : isTotal
            ? TouryBrand.teal
            : TouryBrand.textPrimaryFor(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 4 : 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TouryText(
              label,
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: labelColor,
              maxLines: 3,
              lineHeight: 1.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TouryText(
              value,
              textAlign: TextAlign.end,
              fontSize: isTotal ? 17 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة ملخص الأسعار.
class TouryPriceSummaryCard extends StatelessWidget {
  const TouryPriceSummaryCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        width: double.infinity,
        decoration:
            TouryBrand.cardDecoration(context: context, elevated: true),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TouryBrand.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: TouryBrand.tealDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TouryText(
                    title,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: TouryBrand.isDark(context)
                        ? TouryBrand.teal
                        : TouryBrand.tealDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// خيار طريقة دفع في النافذة المنبثقة.
class TouryPaymentMethodOption extends StatelessWidget {
  const TouryPaymentMethodOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: DsRadius.medium,
            border: Border.all(
              color: colors.border.withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm,
            vertical: DsSpacing.sm + 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: DsSpacing.xs),
              TouryText(
                label,
                textAlign: TextAlign.center,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primaryStrong,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة ترحيب لصفحة الدخول.
class TouryWelcomeCard extends StatelessWidget {
  const TouryWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: compact ? 4 : 8),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: TouryBrand.softGradient,
        borderRadius: TouryBrand.borderRadiusLg,
        border: Border.all(color: TouryBrand.teal.withValues(alpha: 0.25)),
        boxShadow: TouryBrand.cardShadow(),
      ),
      child: Row(
        children: [
          const TouryLogo(width: 56, height: 48, withBackground: true),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TouryText(
                  'ux_welcome_login'.tr(),
                  maxLines: 2,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.primaryStrong,
                ),
                const SizedBox(height: 4),
                TouryText(
                  'ux_welcome_login_sub'.tr(),
                  maxLines: 3,
                  lineHeight: 1.45,
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صورة معلم متجاوبة — للقوائم والإعلانات.
class TouryLandmarkCardImage extends StatelessWidget {
  const TouryLandmarkCardImage({
    super.key,
    required this.img1,
    this.img2,
    this.img3,
    this.documentId,
    this.placeName,
    this.latitude,
    this.longitude,
    this.compact = false,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    ),
  });

  final String? img1;
  final String? img2;
  final String? img3;
  final String? documentId;
  final String? placeName;
  final double? latitude;
  final double? longitude;
  final bool compact;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final height = compact
        ? TouryLayout.landmarkAdImageHeight(context)
        : TouryLayout.cardImageHeight(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: TouryNetworkImage.fromPlaceImages(
        img1: img1,
        img2: img2,
        img3: img3,
        documentId: documentId,
        placeName: placeName,
        latitude: latitude,
        longitude: longitude,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        fallbackAsset: kTouryRegionFallback,
        useBrandedFallback: true,
      ),
    );
  }
}

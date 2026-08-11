import 'package:flutter/material.dart';
import '/core/app_design_system.dart';
import '/core/toury_image.dart';
import '/design_system/design_system.dart';

/// شعار الشريك «توري تاكسي» بألوانه الأصلية (فيروزي + أحمر) وخلفية شفافة.
class TouryLogo extends StatelessWidget {
  const TouryLogo({
    super.key,
    this.width = 120,
    this.height = 52,
    this.withBackground = true,
  });

  final double width;
  final double height;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final image = TouryAssetImage(
      asset: 'assets/images/torytaxi_transparent.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      fallbackAsset: 'assets/images/torytaxi.png',
    );

    if (!withBackground) return image;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: image,
    );
  }
}

/// الشعار الرسمي لرؤية السعودية 2030 — عرض أنيق وغير مزعج.
class Vision2030Mark extends StatelessWidget {
  const Vision2030Mark({
    super.key,
    this.height = 40,
    this.maxWidth = 168,
    this.opacity = 0.94,
  });

  final double height;
  final double maxWidth;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mark = Opacity(
      opacity: opacity,
      child: Image.asset(
        'assets/images/brand/vision_2030.png',
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Saudi Vision 2030',
      ),
    );

    // النص الداكن مُعدّ للخلفيات الفاتحة؛ على الوضع الداكن نضعه على سطح فاتح خفيف.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: height + 8),
      child: isDark
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.sm,
                vertical: DsSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: DsRadius.medium,
              ),
              child: mark,
            )
          : mark,
    );
  }
}

/// شعار بارز للشاشة الرئيسية.
class TouryPartnerLogoBanner extends StatelessWidget {
  const TouryPartnerLogoBanner({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TouryLogo(
        width: compact ? 128 : 148,
        height: compact ? 52 : 64,
        withBackground: true,
      ),
    );
  }
}

/// زر أساسي كلاسيكي بألوان الشعار (بدون تدرج مبالغ فيه).
class TouryGradientButton extends StatelessWidget {
  const TouryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = true,
    this.fontSize = 15,
    this.iconSize = 20,
    this.horizontalPadding = 24,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expanded;
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: TouryBrand.borderRadiusMd,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: enabled
                ? TouryBrand.teal
                : TouryBrand.teal.withValues(alpha: 0.38),
            borderRadius: TouryBrand.borderRadiusMd,
            boxShadow: enabled ? DsShadows.soft() : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: iconSize),
                    const SizedBox(width: DsSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

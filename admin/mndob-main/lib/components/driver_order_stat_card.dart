import 'package:flutter/material.dart';

import '/design_system/design_system.dart';

/// بطاقة إحصائية للطلبات — تباين واضح في الوضعين الفاتح والمظلم.
class DriverOrderStatCard extends StatelessWidget {
  const DriverOrderStatCard({
    super.key,
    required this.count,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String count;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;
    final bg = isDark
        ? Color.alphaBlend(accentColor.withValues(alpha: 0.22), colors.card)
        : Color.alphaBlend(accentColor.withValues(alpha: 0.14), colors.surface);
    final countColor = isDark ? accentColor : colors.primaryStrong;

    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.sm,
      ),
      color: bg,
      elevated: !isDark,
      child: SizedBox(
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: typography.headlineMedium.copyWith(
                color: countColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            DsSpacing.gapXs,
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.labelMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/core/driver_daily_stats_service.dart';
import '/core/driver_i18n.dart';
import '/design_system/design_system.dart';

/// بطاقة إحصائيات اليوم للمندوب.
class DriverDailyStatsCard extends StatelessWidget {
  const DriverDailyStatsCard({
    super.key,
    required this.stats,
    this.isLoading = false,
  });

  final DriverDailyStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;

    return DsCard(
      margin: const EdgeInsets.fromLTRB(
        0,
        DsSpacing.xs,
        0,
        DsSpacing.xxs,
      ),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: colors.primaryStrong,
                size: 20,
              ),
              DsSpacing.gapXs,
              Expanded(
                child: Text(
                  driverTr(context, "Today's stats"),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                  ),
                ),
            ],
          ),
          DsSpacing.gapSm,
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: driverTr(context, 'Completed trips'),
                  value: stats.tripCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: colors.success,
                ),
              ),
              DsSpacing.gapXs,
              Expanded(
                child: _StatTile(
                  label: driverTr(context, "Today's earnings"),
                  value: stats.earningsToday.toString(),
                  icon: Icons.payments_outlined,
                  color: colors.primaryStrong,
                ),
              ),
            ],
          ),
          DsSpacing.gapXs,
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: driverTr(context, 'Work hours'),
                  value: stats.hoursWorkedLabel,
                  icon: Icons.schedule_rounded,
                  color: colors.warning,
                ),
              ),
              DsSpacing.gapXs,
              Expanded(
                child: _StatTile(
                  label: driverTr(context, 'Nearby orders'),
                  value: stats.availableOrdersNearby.toString(),
                  icon: Icons.local_fire_department_outlined,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = context.dsIsDark;
    final bg = Color.alphaBlend(
      color.withValues(alpha: isDark ? 0.2 : 0.1),
      colors.card,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DsRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          DsSpacing.gapXs,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

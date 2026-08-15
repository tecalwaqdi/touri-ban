import 'package:flutter/material.dart';

import '/core/driver_i18n.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// إعدادات المظهر: نهار / ليل، مع حفظ الاختيار محلياً.
class DriverThemeModeCard extends StatelessWidget {
  const DriverThemeModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DsCard(
      padding: DsSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: colors.primaryStrong,
                  size: 22,
                ),
              ),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverTr(context, 'Appearance'),
                      style: typography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driverTr(
                        context,
                        'Choose light or dark appearance.',
                      ),
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ThemeChoice(
                  selected: !isDark,
                  icon: Icons.wb_sunny_rounded,
                  label: driverTr(context, 'Light mode'),
                  onTap: () =>
                      setDarkModeSetting(context, ThemeMode.light),
                ),
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: _ThemeChoice(
                  selected: isDark,
                  icon: Icons.nightlight_round,
                  label: driverTr(context, 'Dark mode'),
                  onTap: () =>
                      setDarkModeSetting(context, ThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final bg = selected ? colors.primary : colors.surfaceElevated;
    final fg = selected ? colors.onPrimary : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.medium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: DsRadius.medium,
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.labelLarge.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

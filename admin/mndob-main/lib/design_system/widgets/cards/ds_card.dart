import 'package:flutter/material.dart';

import '../../colors/ds_colors.dart';
import '../../radius/ds_radius.dart';
import '../../shadows/ds_shadows.dart';
import '../../spacing/ds_spacing.dart';
import '../../typography/ds_typography.dart';

/// Base surface card.
class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = DsSpacing.cardPadding,
    this.margin,
    this.elevated = false,
    this.bordered = true,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;
  final bool bordered;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.card,
        borderRadius: DsRadius.large,
        border: bordered
            ? Border.all(color: colors.border.withValues(alpha: 0.9))
            : null,
        boxShadow: elevated ? DsShadows.card(dark: isDark) : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.large,
        child: content,
      ),
    );
  }
}

class DsRideCard extends StatelessWidget {
  const DsRideCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.status,
    this.trailing,
    this.onTap,
    this.leading,
  });

  final String title;
  final String subtitle;
  final String? status;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return DsCard(
      onTap: onTap,
      elevated: true,
      child: Row(
        children: [
          leading ??
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: DsRadius.medium,
                ),
                child: Icon(Icons.directions_car_rounded, color: colors.primary),
              ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.titleMedium.copyWith(
                  color: colors.textPrimary,
                )),
                const SizedBox(height: DsSpacing.xxs),
                Text(subtitle, style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                )),
                if (status != null) ...[
                  const SizedBox(height: DsSpacing.xs),
                  Text(status!, style: typography.labelSmall.copyWith(
                    color: colors.primary,
                  )),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class DsDriverCard extends StatelessWidget {
  const DsDriverCard({
    super.key,
    required this.name,
    required this.meta,
    this.avatar,
    this.rating,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String meta;
  final Widget? avatar;
  final double? rating;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return DsCard(
      onTap: onTap,
      child: Row(
        children: [
          avatar ??
              CircleAvatar(
                backgroundColor: colors.primarySoft,
                child: Icon(Icons.person_rounded, color: colors.primary),
              ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: typography.titleMedium.copyWith(
                  color: colors.textPrimary,
                )),
                Text(meta, style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                )),
                if (rating != null)
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 16, color: colors.warning),
                      const SizedBox(width: DsSpacing.xxs),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: typography.labelMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class DsPaymentCard extends StatelessWidget {
  const DsPaymentCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return DsCard(
      onTap: onTap,
      color: selected ? colors.selected : null,
      bordered: true,
      child: Row(
        children: [
          leading ??
              Icon(Icons.credit_card_rounded, color: colors.primary),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.titleSmall.copyWith(
                  color: colors.textPrimary,
                )),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                )),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? colors.primary : colors.iconMuted,
          ),
        ],
      ),
    );
  }
}

class DsWalletCard extends StatelessWidget {
  const DsWalletCard({
    super.key,
    required this.balanceLabel,
    required this.balanceValue,
    this.action,
    this.currency,
  });

  final String balanceLabel;
  final String balanceValue;
  final String? currency;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return Container(
      width: double.infinity,
      padding: DsSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryStrong],
        ),
        borderRadius: DsRadius.extraLarge,
        boxShadow: DsShadows.primaryGlow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            balanceLabel,
            style: typography.labelMedium.copyWith(
              color: colors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            currency == null ? balanceValue : '$balanceValue $currency',
            style: typography.displaySmall.copyWith(color: colors.onPrimary),
          ),
          if (action != null) ...[
            const SizedBox(height: DsSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class DsProfileCard extends StatelessWidget {
  const DsProfileCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatar,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String subtitle;
  final Widget? avatar;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return DsCard(
      onTap: onTap,
      child: Row(
        children: [
          avatar ??
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primarySoft,
                child: Icon(Icons.person_rounded, color: colors.primary),
              ),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: typography.titleLarge.copyWith(
                  color: colors.textPrimary,
                )),
                Text(subtitle, style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                )),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded, color: colors.iconMuted),
        ],
      ),
    );
  }
}

class DsStatisticsCard extends StatelessWidget {
  const DsStatisticsCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colors.primary, size: 20),
                const SizedBox(width: DsSpacing.xs),
              ],
              Expanded(
                child: Text(label, style: typography.labelMedium.copyWith(
                  color: colors.textSecondary,
                )),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(value, style: typography.headlineSmall.copyWith(
            color: colors.textPrimary,
          )),
          if (trend != null) ...[
            const SizedBox(height: DsSpacing.xxs),
            Text(trend!, style: typography.labelSmall.copyWith(
              color: colors.success,
            )),
          ],
        ],
      ),
    );
  }
}

class DsInformationCard extends StatelessWidget {
  const DsInformationCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = DsInfoTone.info,
  });

  final String title;
  final String message;
  final IconData icon;
  final DsInfoTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final palette = switch (tone) {
      DsInfoTone.info => (colors.info, colors.infoContainer),
      DsInfoTone.success => (colors.success, colors.successContainer),
      DsInfoTone.warning => (colors.warning, colors.warningContainer),
      DsInfoTone.error => (colors.error, colors.errorContainer),
    };

    return DsCard(
      color: palette.$2,
      bordered: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.$1),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.titleSmall.copyWith(
                  color: colors.textPrimary,
                )),
                const SizedBox(height: DsSpacing.xxs),
                Text(message, style: typography.bodySmall.copyWith(
                  color: colors.textSecondary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum DsInfoTone { info, success, warning, error }

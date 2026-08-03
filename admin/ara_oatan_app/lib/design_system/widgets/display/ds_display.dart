import 'package:flutter/material.dart';

import '../../colors/ds_colors.dart';
import '../../constants/ds_constants.dart';
import '../../radius/ds_radius.dart';
import '../../spacing/ds_spacing.dart';
import '../../typography/ds_typography.dart';

class DsChip extends StatelessWidget {
  const DsChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.onDeleted,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return FilterChip(
      label: Text(
        label,
        style: typography.labelMedium.copyWith(
          color: selected ? colors.primaryStrong : colors.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      avatar: leading,
      onDeleted: onDeleted,
      backgroundColor: colors.primarySoft,
      selectedColor: colors.primaryMuted,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: DsRadius.pill),
      padding: DsSpacing.chipPadding,
    );
  }
}

class DsBadge extends StatelessWidget {
  const DsBadge({
    super.key,
    required this.child,
    this.count,
    this.show = true,
    this.color,
  });

  final Widget child;
  final int? count;
  final bool show;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    if (!show) return child;

    return Badge(
      backgroundColor: color ?? colors.error,
      isLabelVisible: count == null || count! > 0,
      label: count == null
          ? null
          : Text(count! > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}

class DsAvatar extends StatelessWidget {
  const DsAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = DsConstants.avatarMd,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final trimmed = name?.trim() ?? '';
    final initial =
        trimmed.isNotEmpty ? trimmed.substring(0, 1).toUpperCase() : '?';

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primarySoft,
      backgroundImage:
          imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? null
          : Text(
              initial,
              style: typography.titleMedium.copyWith(color: colors.primary),
            ),
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

class DsDivider extends StatelessWidget {
  const DsDivider({
    super.key,
    this.indent,
    this.endIndent,
    this.vertical = false,
  });

  final double? indent;
  final double? endIndent;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    if (vertical) {
      return VerticalDivider(
        width: 1,
        thickness: 1,
        color: colors.divider,
        indent: indent,
        endIndent: endIndent,
      );
    }
    return Divider(
      height: 1,
      thickness: 1,
      color: colors.divider,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

class DsSectionHeader extends StatelessWidget {
  const DsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.md,
        vertical: DsSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: typography.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: typography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

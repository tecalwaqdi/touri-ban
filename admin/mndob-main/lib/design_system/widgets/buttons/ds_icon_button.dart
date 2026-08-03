import 'package:flutter/material.dart';

import '../../colors/ds_colors.dart';
import '../../constants/ds_constants.dart';
import '../../radius/ds_radius.dart';

/// Unified icon button.
class DsIconButton extends StatelessWidget {
  const DsIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = DsConstants.iconMd,
    this.background,
    this.foreground,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? background;
  final Color? foreground;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final bg = background ?? (filled ? colors.primarySoft : Colors.transparent);
    final fg = foreground ?? (filled ? colors.primary : colors.icon);

    final button = Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
      child: InkWell(
        onTap: onPressed,
        borderRadius: DsRadius.medium,
        child: SizedBox(
          width: DsConstants.minTapTarget,
          height: DsConstants.minTapTarget,
          child: Icon(icon, size: size, color: fg),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Floating action button with brand styling.
class DsFab extends StatelessWidget {
  const DsFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.label,
    this.extended = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: Icon(icon),
        label: Text(label!),
      );
    }
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      child: Icon(icon),
    );
  }
}

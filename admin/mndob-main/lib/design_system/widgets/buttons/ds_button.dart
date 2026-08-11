import 'package:flutter/material.dart';

import '../../animations/ds_animations.dart';
import '../../colors/ds_colors.dart';
import '../../constants/ds_constants.dart';
import '../../radius/ds_radius.dart';
import '../../spacing/ds_spacing.dart';
import '../../typography/ds_typography.dart';

enum DsButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  danger,
  success,
}

enum DsButtonSize { sm, md, lg }

/// Unified button for Tory Taxi Design System.
class DsButton extends StatefulWidget {
  const DsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DsButtonVariant.primary,
    this.size = DsButtonSize.md,
    this.loading = false,
    this.enabled = true,
    this.expanded = false,
    this.leading,
    this.trailing,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonVariant variant;
  final DsButtonSize size;
  final bool loading;
  final bool enabled;
  final bool expanded;
  final Widget? leading;
  final Widget? trailing;
  final IconData? icon;

  factory DsButton.primary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
    bool enabled = true,
    bool expanded = false,
    IconData? icon,
    DsButtonSize size = DsButtonSize.md,
  }) =>
      DsButton(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: DsButtonVariant.primary,
        loading: loading,
        enabled: enabled,
        expanded: expanded,
        icon: icon,
        size: size,
      );

  factory DsButton.secondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
    bool enabled = true,
    bool expanded = false,
    IconData? icon,
    DsButtonSize size = DsButtonSize.md,
  }) =>
      DsButton(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: DsButtonVariant.secondary,
        loading: loading,
        enabled: enabled,
        expanded: expanded,
        icon: icon,
        size: size,
      );

  factory DsButton.outlined({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
    bool enabled = true,
    bool expanded = false,
    IconData? icon,
    DsButtonSize size = DsButtonSize.md,
  }) =>
      DsButton(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: DsButtonVariant.outlined,
        loading: loading,
        enabled: enabled,
        expanded: expanded,
        icon: icon,
        size: size,
      );

  factory DsButton.text({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
    bool enabled = true,
    IconData? icon,
    DsButtonSize size = DsButtonSize.md,
  }) =>
      DsButton(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: DsButtonVariant.text,
        loading: loading,
        enabled: enabled,
        icon: icon,
        size: size,
      );

  factory DsButton.danger({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
    bool enabled = true,
    bool expanded = false,
    IconData? icon,
    DsButtonSize size = DsButtonSize.md,
  }) =>
      DsButton(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: DsButtonVariant.danger,
        loading: loading,
        enabled: enabled,
        expanded: expanded,
        icon: icon,
        size: size,
      );

  factory DsButton.success({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
    bool enabled = true,
    bool expanded = false,
    IconData? icon,
    DsButtonSize size = DsButtonSize.md,
  }) =>
      DsButton(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: DsButtonVariant.success,
        loading: loading,
        enabled: enabled,
        expanded: expanded,
        icon: icon,
        size: size,
      );

  @override
  State<DsButton> createState() => _DsButtonState();
}

class _DsButtonState extends State<DsButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  double get _height {
    switch (widget.size) {
      case DsButtonSize.sm:
        return DsConstants.buttonHeightSm;
      case DsButtonSize.md:
        return DsConstants.buttonHeightMd;
      case DsButtonSize.lg:
        return DsConstants.buttonHeightLg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final effectiveEnabled =
        widget.enabled && !widget.loading && widget.onPressed != null;

    final palette = _palette(colors);
    final bg = !effectiveEnabled
        ? colors.disabled
        : _pressed
            ? palette.pressed
            : _hovered || _focused
                ? palette.hovered
                : palette.bg;
    final fg = !effectiveEnabled ? colors.onDisabled : palette.fg;
    final border = palette.border == null
        ? null
        : Border.all(
            color: !effectiveEnabled
                ? colors.disabled
                : palette.border!,
          );

    final child = AnimatedContainer(
      duration: DsDurations.fast,
      curve: DsCurves.standard,
      height: _height,
      padding: EdgeInsets.symmetric(
        horizontal: widget.size == DsButtonSize.sm
            ? DsSpacing.md
            : DsSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DsRadius.medium,
        border: border,
        boxShadow: widget.variant == DsButtonVariant.primary &&
                effectiveEnabled &&
                !_pressed
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.loading)
            SizedBox(
              width: DsConstants.iconSm,
              height: DsConstants.iconSm,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(fg),
              ),
            )
          else if (widget.leading != null)
            widget.leading!
          else if (widget.icon != null)
            Icon(widget.icon, size: DsConstants.iconSm, color: fg),
          if (widget.loading ||
              widget.leading != null ||
              widget.icon != null)
            const SizedBox(width: DsSpacing.xs),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography.labelLarge.copyWith(color: fg),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: DsSpacing.xs),
            widget.trailing!,
          ],
        ],
      ),
    );

    final interactive = FocusableActionDetector(
      enabled: effectiveEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: effectiveEnabled ? widget.onPressed : null,
        onTapDown:
            effectiveEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && effectiveEnabled ? 0.98 : 1,
          duration: DsDurations.fast,
          child: widget.expanded
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    return SizedBox(
                      width: maxW.isFinite ? maxW : null,
                      child: child,
                    );
                  },
                )
              : child,
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: interactive,
    );
  }

  _BtnPalette _palette(DsColors c) {
    switch (widget.variant) {
      case DsButtonVariant.primary:
        return _BtnPalette(
          bg: c.primary,
          fg: c.onPrimary,
          hovered: c.primaryStrong,
          pressed: c.primaryStrong,
        );
      case DsButtonVariant.secondary:
        return _BtnPalette(
          bg: c.primarySoft,
          fg: c.primaryStrong,
          hovered: c.primaryMuted,
          pressed: c.primaryMuted,
        );
      case DsButtonVariant.outlined:
        return _BtnPalette(
          bg: Colors.transparent,
          fg: c.primary,
          hovered: c.hover,
          pressed: c.pressed,
          border: c.primary.withValues(alpha: 0.55),
        );
      case DsButtonVariant.text:
        return _BtnPalette(
          bg: Colors.transparent,
          fg: c.primary,
          hovered: c.hover,
          pressed: c.pressed,
        );
      case DsButtonVariant.danger:
        return _BtnPalette(
          bg: c.error,
          fg: c.onError,
          hovered: Color.alphaBlend(c.overlay, c.error),
          pressed: c.error,
        );
      case DsButtonVariant.success:
        return _BtnPalette(
          bg: c.success,
          fg: c.onSuccess,
          hovered: c.success.withValues(alpha: 0.9),
          pressed: c.success,
        );
    }
  }
}

class _BtnPalette {
  const _BtnPalette({
    required this.bg,
    required this.fg,
    required this.hovered,
    required this.pressed,
    this.border,
  });

  final Color bg;
  final Color fg;
  final Color hovered;
  final Color pressed;
  final Color? border;
}

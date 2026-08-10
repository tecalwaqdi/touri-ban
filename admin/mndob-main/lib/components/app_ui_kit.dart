import 'package:flutter/material.dart';

import '/design_system/design_system.dart';

/// Legacy UI kit — now thin wrappers over Tory Taxi [Ds*] widgets.
/// Prefer using design_system directly in new screens.

enum AppButtonVariant { primary, secondary, danger }

class AppLoadingButton extends StatelessWidget {
  const AppLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return DsButton.primary(
          label: label,
          onPressed: onPressed,
          loading: loading,
          expanded: expanded,
        );
      case AppButtonVariant.secondary:
        return DsButton.outlined(
          label: label,
          onPressed: onPressed,
          loading: loading,
          expanded: expanded,
        );
      case AppButtonVariant.danger:
        return DsButton.danger(
          label: label,
          onPressed: onPressed,
          loading: loading,
          expanded: expanded,
        );
    }
  }
}

enum AppStatusTone { success, warning, danger, info, neutral }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final (Color bg, Color fg) = switch (tone) {
      AppStatusTone.success => (colors.success, colors.onPrimary),
      AppStatusTone.warning => (colors.warning, colors.textPrimary),
      AppStatusTone.danger => (colors.error, colors.onPrimary),
      AppStatusTone.info => (colors.info, colors.onPrimary),
      AppStatusTone.neutral => (colors.border, colors.textPrimary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DsRadius.pill,
      ),
      child: Text(
        label,
        style: context.dsTypography.labelSmall.copyWith(color: fg),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      title: title,
      message: message ?? '',
      icon: Icons.inbox_outlined,
      action: actionLabel == null || onAction == null
          ? null
          : DsButton.primary(
              label: actionLabel!,
              onPressed: onAction,
              expanded: true,
            ),
    );
  }
}

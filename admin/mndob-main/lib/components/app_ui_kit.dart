import 'package:flutter/material.dart';

import '/core/app_design_tokens.dart';
import '/core/driver_i18n.dart';

enum AppButtonVariant { primary, secondary, destructive }

/// Unified loading-aware button for production driver flows.
class AppLoadingButton extends StatelessWidget {
  const AppLoadingButton({
    super.key,
    required this.labelKey,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  final String labelKey;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final label = driverTr(context, labelKey);
    final canTap = enabled && !loading && onPressed != null;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (!loading)
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: canTap ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(expand ? double.infinity : 120, 52),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: canTap ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(expand ? double.infinity : 120, 52),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          ),
          child: child,
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: canTap ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(expand ? double.infinity : 120, 52),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          ),
          child: child,
        ),
    };

    return button;
  }
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.labelKey,
    this.tone = AppStatusTone.neutral,
  });

  final String labelKey;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AppStatusTone.success => (AppColors.success, Colors.white),
      AppStatusTone.warning => (AppColors.warning, AppColors.primaryDark),
      AppStatusTone.danger => (AppColors.danger, Colors.white),
      AppStatusTone.info => (AppColors.actionBlue, Colors.white),
      AppStatusTone.neutral => (AppColors.divider, AppColors.textPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: AppRadius.borderSm,
      ),
      child: Text(
        driverTr(context, labelKey),
        style: TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: colors.$2,
        ),
      ),
    );
  }
}

enum AppStatusTone { success, warning, danger, info, neutral }

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.titleKey,
    this.subtitleKey,
    this.actionLabelKey,
    this.onAction,
  });

  final String titleKey;
  final String? subtitleKey;
  final String? actionLabelKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            driverTr(context, titleKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitleKey != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              driverTr(context, subtitleKey!),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'cairo',
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (actionLabelKey != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppLoadingButton(
              labelKey: actionLabelKey!,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

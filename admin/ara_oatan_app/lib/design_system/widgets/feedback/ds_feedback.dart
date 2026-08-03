import 'package:flutter/material.dart';

import '../../colors/ds_colors.dart';
import '../../radius/ds_radius.dart';
import '../../spacing/ds_spacing.dart';
import '../../typography/ds_typography.dart';
import '../buttons/ds_button.dart';

abstract final class DsDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: DsRadius.extraLarge),
          title: Text(
            title,
            style: typography.headlineSmall.copyWith(color: colors.textPrimary),
          ),
          content: content ??
              (message == null
                  ? null
                  : Text(
                      message,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    )),
          actionsPadding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            0,
            DsSpacing.md,
            DsSpacing.md,
          ),
          actions: [
            if (cancelLabel != null)
              DsButton.text(
                label: cancelLabel,
                onPressed: () {
                  onCancel?.call();
                  Navigator.of(ctx).pop();
                },
              ),
            if (confirmLabel != null)
              DsButton.primary(
                label: confirmLabel,
                onPressed: () {
                  onConfirm?.call();
                  Navigator.of(ctx).pop(true);
                },
              ),
          ],
        );
      },
    );
  }
}

abstract final class DsBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DsSpacing.md,
              DsSpacing.sm,
              DsSpacing.md,
              DsSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: DsSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: DsRadius.pill,
                    ),
                  ),
                ),
                if (title != null) ...[
                  Text(
                    title,
                    style: typography.titleLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DsSpacing.md),
                ],
                Flexible(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

abstract final class DsSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    DsSnackTone tone = DsSnackTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = DsColors.of(context);
    final Color bg;
    switch (tone) {
      case DsSnackTone.success:
        bg = colors.success;
      case DsSnackTone.error:
        bg = colors.error;
      case DsSnackTone.warning:
        bg = colors.warning;
      case DsSnackTone.neutral:
        bg = colors.textPrimary;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: DsRadius.medium),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: colors.onPrimary,
                onPressed: onAction ?? () {},
              ),
      ),
    );
  }
}

enum DsSnackTone { neutral, success, warning, error }

class DsLoading extends StatelessWidget {
  const DsLoading({
    super.key,
    this.size = 28,
    this.message,
  });

  final double size;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: DsSpacing.md),
            Text(
              message!,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DsEmptyState extends StatelessWidget {
  const DsEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);

    return Center(
      child: Padding(
        padding: DsSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: colors.primary),
            ),
            const SizedBox(height: DsSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: typography.titleLarge.copyWith(color: colors.textPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: DsSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: DsSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class DsErrorState extends StatelessWidget {
  const DsErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      action: onRetry == null
          ? null
          : DsButton.primary(label: retryLabel, onPressed: onRetry),
    );
  }
}

class DsSuccessState extends StatelessWidget {
  const DsSuccessState({
    super.key,
    required this.title,
    this.message,
    this.action,
  });

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DsEmptyState(
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      action: action,
    );
  }
}

/// Lightweight shimmer placeholder (no external package).
class DsShimmer extends StatefulWidget {
  const DsShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<DsShimmer> createState() => _DsShimmerState();
}

class _DsShimmerState extends State<DsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? DsRadius.small,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [
                colors.primaryMuted.withValues(alpha: 0.25),
                colors.primarySoft,
                colors.primaryMuted.withValues(alpha: 0.25),
              ],
            ),
          ),
        );
      },
    );
  }
}

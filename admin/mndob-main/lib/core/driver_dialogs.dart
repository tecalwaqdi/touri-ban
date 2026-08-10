import 'package:flutter/material.dart';

import '/core/driver_i18n.dart';
import '/design_system/design_system.dart';

enum DriverMessageType { success, error, warning, info }

/// حوارات وإشعارات موحّدة لتطبيق المندوب.
abstract final class DriverDialogs {
  DriverDialogs._();

  static _Style _style(DriverMessageType type) => switch (type) {
        DriverMessageType.success => _Style(
              icon: DsIcons.success,
              color: DsSuccessScale.shade500,
              bg: DsSuccessScale.shade50,
            ),
        DriverMessageType.error => _Style(
              icon: DsIcons.error,
              color: DsErrorScale.shade500,
              bg: DsErrorScale.shade50,
            ),
        DriverMessageType.warning => _Style(
              icon: DsIcons.warning,
              color: DsWarningScale.shade700,
              bg: DsWarningScale.shade50,
            ),
        DriverMessageType.info => _Style(
              icon: DsIcons.info,
              color: DsPrimaryScale.shade700,
              bg: DsPrimaryScale.shade50,
            ),
      };

  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    DriverMessageType type = DriverMessageType.info,
    String? confirmLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: DsColors.light.scrim.withValues(alpha: 0.45),
      builder: (dialogContext) => _DriverDialogShell(
        type: type,
        title: title,
        message: message,
        actions: [
          DsButton.primary(
            label: confirmLabel ?? driverTr(context, 'OK'),
            onPressed: () => Navigator.pop(dialogContext),
            expanded: true,
          ),
        ],
      ),
    );
  }

  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    DriverMessageType type = DriverMessageType.warning,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: DsColors.light.scrim.withValues(alpha: 0.45),
      builder: (dialogContext) => _DriverDialogShell(
        type: type,
        title: title,
        message: message,
        actions: [
          Expanded(
            child: DsButton.outlined(
              label: cancelLabel ?? driverTr(context, 'Cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
              expanded: true,
            ),
          ),
          DsSpacing.gapSm,
          Expanded(
            child: destructive
                ? DsButton.danger(
                    label: confirmLabel ?? driverTr(context, 'Confirm'),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    expanded: true,
                  )
                : DsButton.primary(
                    label: confirmLabel ?? driverTr(context, 'Confirm'),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    expanded: true,
                  ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    DriverMessageType type = DriverMessageType.info,
    bool loading = false,
    int durationSeconds = 4,
  }) {
    final style = _style(type);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          DsSpacing.md,
          0,
          DsSpacing.md,
          DsSpacing.lg,
        ),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: loading
            ? const Duration(days: 1)
            : Duration(seconds: durationSeconds),
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm,
            vertical: DsSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: DsRadius.medium,
            boxShadow: DsShadows.card(),
          ),
          child: Row(
            children: [
              if (loading)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: DsSpacing.sm),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: DsSpacing.sm),
                  child: Icon(style.icon, color: Colors.white, size: DsIcons.md),
                ),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: DsTypography.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showLocationError(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    return showAlert(
      context,
      title: driverTr(context, 'Location'),
      message: message,
      type: DriverMessageType.warning,
      confirmLabel: onRetry != null
          ? driverTr(context, 'Retry')
          : driverTr(context, 'OK'),
    ).then((_) {
      if (onRetry != null) onRetry();
    });
  }
}

class _Style {
  const _Style({
    required this.icon,
    required this.color,
    required this.bg,
  });
  final IconData icon;
  final Color color;
  final Color bg;
}

class _DriverDialogShell extends StatelessWidget {
  const _DriverDialogShell({
    required this.type,
    required this.title,
    required this.message,
    required this.actions,
  });

  final DriverMessageType type;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    final typography = context.dsTypography;
    final style = DriverDialogs._style(type);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: DsRadius.large),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.lg,
            DsSpacing.xl,
            DsSpacing.lg,
            DsSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: style.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 30),
              ),
              DsSpacing.gapSm,
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              DsSpacing.gapXs,
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              DsSpacing.gapLg,
              // Bound width so DsButton(expanded: true) / Expanded children
              // never get infinite horizontal constraints (broken dialog +
              // sticky modal scrim).
              SizedBox(
                width: double.infinity,
                child: actions.length == 1
                    ? actions.first
                    : Row(children: actions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

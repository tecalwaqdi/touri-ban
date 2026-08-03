import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/core/app_design_system.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_location_service.dart';
import '/design_system/design_system.dart';

/// أنواع الرسائل المنبثقة.
enum TouryMessageType {
  success,
  error,
  warning,
  info,
}

/// نظام موحّد للرسائل المنبثقة — حوارات، تأكيدات، وإشعارات سفلية.
abstract final class TouryDialogs {
  static _Style _style(TouryMessageType type) => switch (type) {
        TouryMessageType.success => _Style(
              icon: DsIcons.success,
              color: DsSuccessScale.shade500,
              bg: DsSuccessScale.shade50,
            ),
        TouryMessageType.error => _Style(
              icon: DsIcons.error,
              color: DsErrorScale.shade500,
              bg: DsErrorScale.shade50,
            ),
        TouryMessageType.warning => _Style(
              icon: DsIcons.warning,
              color: DsWarningScale.shade700,
              bg: DsWarningScale.shade50,
            ),
        TouryMessageType.info => _Style(
              icon: DsIcons.info,
              color: DsPrimaryScale.shade700,
              bg: DsPrimaryScale.shade50,
            ),
      };

  /// رسالة تنبيه بزر واحد.
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    TouryMessageType type = TouryMessageType.info,
    String? confirmLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => WebViewAware(
        child: _TouryDialogShell(
          type: type,
          title: title,
          message: message,
          actions: [
            _TouryDialogButton(
              label: confirmLabel ?? 'dialog_ok'.tr(),
              filled: true,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  /// حوار تأكيد بزرّين — يُرجع true عند الموافقة.
  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    TouryMessageType type = TouryMessageType.warning,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => WebViewAware(
        child: _TouryDialogShell(
          type: type,
          title: title,
          message: message,
          actions: [
            _TouryDialogButton(
              label: cancelLabel ?? 'dialog_cancel'.tr(),
              filled: false,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            _TouryDialogButton(
              label: confirmLabel ?? 'dialog_confirm'.tr(),
              filled: true,
              destructive: destructive,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// إشعار سفلي منبثق.
  static void showSnackBar(
    BuildContext context,
    String message, {
    TouryMessageType type = TouryMessageType.info,
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
            boxShadow: TouryBrand.cardShadow(elevated: true),
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
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: DsTypography.fontFamily,
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) =>
      showSnackBar(context, message, type: TouryMessageType.success);

  static void showError(BuildContext context, String message) =>
      showSnackBar(context, message, type: TouryMessageType.error);

  static void showWarning(BuildContext context, String message) =>
      showSnackBar(context, message, type: TouryMessageType.warning);

  /// رسائل شائعة جاهزة — لا تستخدم رسالة GPS العامة إلا عند فشل الخدمة/الصلاحية فعلاً.
  /// Returns `true` إذا اختار المستخدم «اختيار يدوي».
  static Future<bool> showLocationError(
    BuildContext context, {
    String? message,
    TouryLocationFailure? failure,
    bool offerManualChoice = true,
  }) async {
    final resolvedMessage = message ??
        (failure != null
            ? TouryLocationService.messageForFailure(failure)
            : 'dialog_location_error'.tr());
    final style = _style(TouryMessageType.error);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => WebViewAware(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: DsRadius.large,
          ),
          title: Row(
            children: [
              Icon(style.icon, color: style.color),
              const SizedBox(width: DsSpacing.xs),
              Expanded(
                child: Text(
                  'dialog_error_title'.tr(),
                  style: const TextStyle(
                    fontFamily: DsTypography.fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            resolvedMessage,
            style: const TextStyle(
              fontFamily: DsTypography.fontFamily,
              fontSize: 14,
            ),
          ),
          actions: [
            if (offerManualChoice)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'manual'),
                child: Text('choose_manually'.tr()),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'ok'),
              child: Text('dialog_ok'.tr()),
            ),
          ],
        ),
      ),
    );
    return result == 'manual';
  }

  static Future<void> showCountryMismatch(BuildContext context) =>
      showAlert(
        context,
        title: 'dialog_country_mismatch_title'.tr(),
        message: 'dialog_country_mismatch_msg'.tr(),
        type: TouryMessageType.error,
      );

  static Future<void> showOutsideCoverage(BuildContext context) =>
      showAlert(
        context,
        title: 'dialog_outside_coverage_title'.tr(),
        message: 'dialog_outside_coverage_msg'.tr(),
        type: TouryMessageType.warning,
      );

  static Future<bool> confirmChangeCountry(BuildContext context) =>
      showConfirm(
        context,
        title: 'dialog_change_country_title'.tr(),
        message: 'dialog_change_country_msg'.tr(),
        type: TouryMessageType.warning,
        confirmLabel: 'dialog_yes'.tr(),
        cancelLabel: 'dialog_no'.tr(),
      );

  static Future<bool> confirmChangeCity(BuildContext context) =>
      showConfirm(
        context,
        title: 'dialog_change_city_title'.tr(),
        message: 'dialog_change_city_msg'.tr(),
        type: TouryMessageType.warning,
        confirmLabel: 'dialog_yes'.tr(),
        cancelLabel: 'dialog_no'.tr(),
      );

  static Future<bool> confirmUpdateLocation(BuildContext context) =>
      showConfirm(
        context,
        title: 'dialog_update_location_title'.tr(),
        message: 'dialog_update_location_msg'.tr(),
        type: TouryMessageType.warning,
        confirmLabel: 'dialog_yes'.tr(),
        cancelLabel: 'dialog_no'.tr(),
      );

  static Future<void> showSelectAllOptions(BuildContext context) =>
      showAlert(
        context,
        title: 'dialog_error_title'.tr(),
        message: 'dialog_select_all_options'.tr(),
        type: TouryMessageType.error,
      );
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

class _TouryDialogShell extends StatelessWidget {
  const _TouryDialogShell({
    required this.type,
    required this.title,
    required this.message,
    required this.actions,
  });

  final TouryMessageType type;
  final String title;
  final String message;
  final List<_TouryDialogButton> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DsColors>();
    final style = TouryDialogs._style(type);
    final surface = colors?.surface ?? TouryBrand.surfaceCard;
    final textPrimary = colors?.textPrimary ?? TouryBrand.textPrimary;
    final textSecondary = colors?.textSecondary ?? TouryBrand.textSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: DsSpacing.xxl),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: DsDurations.slow,
        curve: DsCurves.bounceOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: DsRadius.large,
            boxShadow: TouryBrand.cardShadow(elevated: true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: DsSpacing.xl),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: style.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: DsIcons.xl),
              ),
              const SizedBox(height: DsSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DsTypography.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DsTypography.fontFamily,
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: DsSpacing.xl),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DsSpacing.md,
                  0,
                  DsSpacing.md,
                  DsSpacing.md,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: DsSpacing.xs),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TouryDialogButton extends StatelessWidget {
  const _TouryDialogButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DsColors>();
    final primary = colors?.primary ?? DsPrimaryScale.brand;
    final onPrimary = colors?.onPrimary ?? Colors.white;
    final textPrimary = colors?.textPrimary ?? TouryBrand.textPrimary;
    final borderColor = colors?.border ?? TouryBrand.border;
    final error = colors?.error ?? DsErrorScale.shade500;

    final bg = destructive
        ? error
        : filled
            ? null
            : Colors.transparent;
    final gradient = destructive || !filled
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, DsPrimaryScale.shade700],
          );
    final fg = filled ? onPrimary : textPrimary;
    final border = filled
        ? null
        : Border.all(color: borderColor, width: 1.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: DsRadius.medium,
        child: Ink(
          height: DsConstants.buttonHeightMd,
          decoration: BoxDecoration(
            color: bg,
            gradient: gradient,
            borderRadius: DsRadius.medium,
            border: border,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DsTypography.fontFamily,
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

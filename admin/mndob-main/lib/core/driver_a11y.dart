import 'package:flutter/material.dart';

import '/core/driver_i18n.dart';

/// Shared a11y helpers for driver production surfaces.
abstract final class DriverA11y {
  DriverA11y._();

  static const double minTouchTarget = 48;

  static Widget iconButton({
    required BuildContext context,
    required String labelKey,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final label = driverTr(context, labelKey);
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: minTouchTarget,
          height: minTouchTarget,
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
            tooltip: label,
            constraints: const BoxConstraints(
              minWidth: minTouchTarget,
              minHeight: minTouchTarget,
            ),
          ),
        ),
      ),
    );
  }

  /// Keep phone / plate visually LTR even in Arabic UI.
  static Widget ltrText(String text, {TextStyle? style}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(text, style: style, textAlign: TextAlign.left),
    );
  }
}

/// Wraps content so text scale up to 1.5 does not hard-break layouts.
class DriverScaledSafeArea extends StatelessWidget {
  const DriverScaledSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final clamped = media.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.5,
    );
    return MediaQuery(
      data: media.copyWith(textScaler: clamped),
      child: SafeArea(child: child),
    );
  }
}

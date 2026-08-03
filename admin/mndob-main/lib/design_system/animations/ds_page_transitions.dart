import 'package:flutter/material.dart';

import 'ds_animations.dart';

/// Page-route transitions for future navigation redesigns.
abstract final class DsPageTransitions {
  static PageRouteBuilder<T> fade<T>({
    required Widget page,
    Duration duration = DsDurations.page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: DsDurations.fast,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: DsCurves.emphasized,
          ),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> slideUp<T>({
    required Widget page,
    Duration duration = DsDurations.page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: DsCurves.emphasized,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  static PageRouteBuilder<T> slideHorizontal<T>({
    required Widget page,
    bool fromEnd = true,
    Duration duration = DsDurations.page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: DsCurves.emphasized,
        );
        return SlideTransition(
          position: Tween(
            begin: Offset(fromEnd ? 0.08 : -0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

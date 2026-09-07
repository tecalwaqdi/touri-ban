import 'package:flutter/material.dart';

/// Marks descendants as living inside the persistent Admin shell (PERF-P3F).
class AdminShellScope extends InheritedWidget {
  const AdminShellScope({super.key, required super.child});

  static bool isInside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AdminShellScope>() != null;

  @override
  bool updateShouldNotify(covariant AdminShellScope oldWidget) => false;
}

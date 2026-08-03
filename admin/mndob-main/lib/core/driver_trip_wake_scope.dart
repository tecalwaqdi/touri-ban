import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// يمنع إطفاء شاشة الجهاز أثناء الرحلة النشطة (وليس منع التنقل).
class DriverTripWakeScope extends StatefulWidget {
  const DriverTripWakeScope({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<DriverTripWakeScope> createState() => _DriverTripWakeScopeState();
}

class _DriverTripWakeScopeState extends State<DriverTripWakeScope> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant DriverTripWakeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  Future<void> _sync() async {
    if (widget.enabled) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

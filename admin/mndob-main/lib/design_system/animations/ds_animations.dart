import 'package:flutter/material.dart';

/// Motion tokens — durations, curves, and reusable transitions.
abstract final class DsDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration emphasis = Duration(milliseconds: 480);
  static const Duration page = Duration(milliseconds: 320);
}

abstract final class DsCurves {
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve decelerate = Curves.decelerate;
  static const Curve bounceOut = Curves.easeOutBack;
  static const Curve sharp = Curves.easeInOut;
}

/// Fade + slide entrance for list items / cards.
class DsFadeSlide extends StatelessWidget {
  const DsFadeSlide({
    super.key,
    required this.child,
    this.offset = const Offset(0, 0.04),
    this.duration = DsDurations.normal,
    this.curve = DsCurves.emphasized,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Offset offset;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: curve,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              offset.dx * 24 * (1 - value),
              offset.dy * 24 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class DsScaleFade extends StatelessWidget {
  const DsScaleFade({
    super.key,
    required this.child,
    this.beginScale = 0.96,
    this.duration = DsDurations.normal,
    this.curve = DsCurves.emphasized,
  });

  final Widget child;
  final double beginScale;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final scale = beginScale + (1 - beginScale) * value;
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}

/// Soft press scale for interactive surfaces.
class DsPressable extends StatefulWidget {
  const DsPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scale = 0.98,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;

  @override
  State<DsPressable> createState() => _DsPressableState();
}

class _DsPressableState extends State<DsPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: DsDurations.fast,
        curve: DsCurves.standard,
        child: widget.child,
      ),
    );
  }
}

class DsAnimatedSwitcher extends StatelessWidget {
  const DsAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: DsCurves.emphasized,
      switchOutCurve: DsCurves.sharp,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

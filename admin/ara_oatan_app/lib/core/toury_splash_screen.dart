import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/core/toury_brand_widgets.dart';
import '/design_system/design_system.dart';

/// شاشة افتتاحية موحّدة — تُعرض أثناء تهيئة التطبيق وانتظار auth.
class TourySplashScreen extends StatefulWidget {
  const TourySplashScreen({super.key});

  @override
  State<TourySplashScreen> createState() => _TourySplashScreenState();
}

class _TourySplashScreenState extends State<TourySplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: DsCurves.decelerate),
    );
    _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: DsCurves.emphasized),
      ),
    );
    _loaderFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logoWidth = (shortest * 0.52).clamp(160.0, 210.0);
    final logoHeight = logoWidth * (90 / 210);
    final titleSize = (shortest * 0.055).clamp(20.0, 26.0);
    final taglineSize = (shortest * 0.035).clamp(12.0, 14.5);

    return Material(
      color: DsPrimaryScale.shade700,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DsPrimaryScale.shade500,
              DsPrimaryScale.shade700,
              DsPrimaryScale.shade900,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _DecorativeOrb(
              top: -72,
              right: -48,
              size: 220,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            _DecorativeOrb(
              bottom: -96,
              left: -64,
              size: 260,
              color: DsPrimaryScale.shade300.withValues(alpha: 0.18),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TouryLogo(
                            width: logoWidth,
                            height: logoHeight,
                            withBackground: true,
                          ),
                          const SizedBox(height: DsSpacing.md),
                          Text(
                            'app_title'.tr(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: DsTypography.fontFamily,
                              color: Colors.white.withValues(alpha: 0.96),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: DsSpacing.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              'splash_tagline'.tr(),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: DsTypography.fontFamily,
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: taglineSize,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: DsSpacing.xxl),
                          FadeTransition(
                            opacity: _loaderFade,
                            child: SizedBox(
                              width: DsIcons.xl,
                              height: DsIcons.xl,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final double size;
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

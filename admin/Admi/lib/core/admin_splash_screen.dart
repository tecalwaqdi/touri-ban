import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';

/// Unified startup splash — logo, title, and tourism tagline.
class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _shade500 = Color(0xFF1F6F5F);
  static const _shade700 = Color(0xFF154D42);
  static const _shade900 = Color(0xFF0C2E28);
  static const _shade300 = Color(0xFF4A9A87);

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
      curve: const Interval(0.0, 0.65, curve: Curves.decelerate),
    );
    _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
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
    final l10n = FFLocalizations.of(context);

    return Material(
      color: _shade700,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_shade500, _shade700, _shade900],
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
              color: _shade300.withValues(alpha: 0.18),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/__2025-07-09_133622.png',
                              width: logoWidth,
                              height: logoHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.getText('adm_splash_title'),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              color: Colors.white.withValues(alpha: 0.96),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              l10n.getText('adm_splash_tagline'),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: taglineSize,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          FadeTransition(
                            opacity: _loaderFade,
                            child: SizedBox(
                              width: 28,
                              height: 28,
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

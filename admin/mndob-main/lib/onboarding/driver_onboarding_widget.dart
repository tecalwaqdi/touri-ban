import 'package:flutter/material.dart';

import '/core/driver_bootstrap.dart';
import '/core/driver_ux_widgets.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Shown once on first install before Login.
///
/// Rules (Phase 4):
/// - Does NOT create Firebase Auth / Anonymous / Draft.
/// - Persists [DriverBootstrap.markOnboardingDone] only.
/// - Skip / Next / Back / Get started all work without a session.
/// - After finish, AuthGate re-bootstraps → Login when unauthenticated.
class DriverOnboardingWidget extends StatefulWidget {
  const DriverOnboardingWidget({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<DriverOnboardingWidget> createState() => _DriverOnboardingWidgetState();
}

class _DriverOnboardingWidgetState extends State<DriverOnboardingWidget> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <(String, String, IconData)>[
    (
      'Welcome to Touri Driver',
      'Accept trips, navigate, and earn in your city.',
      Icons.local_taxi_outlined,
    ),
    (
      'Go Online when ready',
      'Turn on GPS, go online, and receive nearby requests.',
      Icons.wifi_tethering,
    ),
    (
      'Complete your profile',
      'Register once. Admin reviews your account before trips.',
      Icons.verified_user_outlined,
    ),
  ];

  Future<void> _finish() async {
    await DriverBootstrap.markOnboardingDone();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreenShell(
      child: Builder(
        builder: (context) {
          final colors = context.dsColors;
          final typography = context.dsTypography;

          return Scaffold(
            backgroundColor: colors.scaffold,
            body: SafeArea(
              child: DriverFormWidth(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DsSpacing.md,
                        DsSpacing.xs,
                        DsSpacing.md,
                        0,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: FlutterFlowLanguageSelector(
                              width: 140,
                              backgroundColor: colors.surface,
                              borderColor: colors.border,
                              dropdownIconColor: colors.primary,
                              borderRadius: DsRadius.md,
                              textStyle: typography.bodySmall.copyWith(
                                color: colors.primary,
                              ),
                              hideFlags: true,
                              flagSize: 24,
                              flagTextGap: 8,
                              currentLanguage:
                                  FFLocalizations.of(context).languageCode,
                              languages: FFLocalizations.languages(),
                              onChanged: (lang) =>
                                  setAppLanguage(context, lang),
                            ),
                          ),
                          DsButton.text(
                            label: driverTr(context, 'Skip'),
                            onPressed: _finish,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) {
                          final p = _pages[i];
                          return Padding(
                            padding: DsSpacing.pagePadding,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: colors.primarySoft,
                                      shape: BoxShape.circle,
                                      boxShadow: DsShadows.soft(),
                                    ),
                                    child: Icon(
                                      p.$3,
                                      size: 56,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: DsSpacing.xxl),
                                  Text(
                                    driverTr(context, p.$1),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.headlineSmall.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: DsSpacing.sm),
                                  Text(
                                    driverTr(context, p.$2),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: DsDurations.fast,
                          width: i == _page ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: DsRadius.pill,
                            color: i == _page
                                ? colors.primary
                                : colors.primaryMuted,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DsSpacing.lg,
                        DsSpacing.md,
                        DsSpacing.lg,
                        DsSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          if (_page > 0) ...[
                            Expanded(
                              child: DsButton.outlined(
                                label: driverTr(context, 'Back'),
                                size: DsButtonSize.lg,
                                expanded: true,
                                onPressed: () async {
                                  await _controller.previousPage(
                                    duration: DsDurations.page,
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: DsSpacing.sm),
                          ],
                          Expanded(
                            child: DsButton.primary(
                              label: _page < _pages.length - 1
                                  ? driverTr(context, 'Next')
                                  : driverTr(context, 'Get started'),
                              size: DsButtonSize.lg,
                              expanded: true,
                              onPressed: () async {
                                if (_page < _pages.length - 1) {
                                  await _controller.nextPage(
                                    duration: DsDurations.page,
                                    curve: Curves.easeOut,
                                  );
                                } else {
                                  await _finish();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

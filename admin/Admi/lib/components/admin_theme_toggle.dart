import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact light/dark appearance control for the admin shell.
class AdminThemeToggle extends StatelessWidget {
  const AdminThemeToggle({
    super.key,
    this.compact = false,
    this.onTealChrome = false,
  });

  /// Icon-only control (app bar / sidebar footer).
  final bool compact;

  /// Use white icons/labels for teal sidebar or app bar chrome.
  final bool onTealChrome;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  void _toggle(BuildContext context) {
    final next = _isDark(context) ? ThemeMode.light : ThemeMode.dark;
    setDarkModeSetting(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final icon = dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
    final label = dark
        ? appTr(context, 'adm_theme_light')
        : appTr(context, 'adm_theme_dark');
    final fg = onTealChrome
        ? Colors.white
        : FlutterFlowTheme.of(context).primaryText;

    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: () => _toggle(context),
        icon: Icon(icon, color: fg),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggle(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.swap_horiz_rounded,
                color: fg.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full settings card: segmented light / dark switcher.
class AdminThemeModeCard extends StatelessWidget {
  const AdminThemeModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          appTr(context, 'adm_theme_title'),
          style: theme.titleSmall.override(
            fontFamily: theme.titleSmallFamily,
            fontWeight: FontWeight.w700,
            useGoogleFonts: !theme.titleSmallIsCustom,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          appTr(context, 'adm_theme_subtitle'),
          style: theme.bodySmall.override(
            fontFamily: theme.bodySmallFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.bodySmallIsCustom,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ThemeModeChoice(
                selected: !isDark,
                icon: Icons.light_mode_rounded,
                label: appTr(context, 'adm_theme_light'),
                onTap: () => setDarkModeSetting(context, ThemeMode.light),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ThemeModeChoice(
                selected: isDark,
                icon: Icons.dark_mode_rounded,
                label: appTr(context, 'adm_theme_dark'),
                onTap: () => setDarkModeSetting(context, ThemeMode.dark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeModeChoice extends StatelessWidget {
  const _ThemeModeChoice({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? theme.primary
        : theme.primaryBackground;
    final fg = selected
        ? (isDark ? const Color(0xFF0F1414) : Colors.white)
        : theme.primaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.primary
                  : theme.alternate.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

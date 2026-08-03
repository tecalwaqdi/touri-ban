import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/backend/admin_reports_country_scope.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Shared visual language for the admin panel (teal / sage identity).
class AdminUi {
  AdminUi._();

  static const Color brandTeal = Color(0xFF1F7372);
  static const Color brandMint = Color(0xFF39D2C0);
  static const Color brandSage = Color(0xFF9AB5B0);
  static const Color brandSageDark = Color(0xFF7A9A95);

  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;

  /// Use table/grid layouts only when there is enough horizontal space.
  static const double tableLayoutMinWidth = 900.0;

  static bool useTableLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tableLayoutMinWidth;

  static bool useStackedHeader(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 520;

  static double adminTableMinWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tableLayoutMinWidth ? width - 48 : 780;
  }

  static int responsiveColumnCount(
    BuildContext context, {
    int wide = 3,
    int medium = 2,
    int narrow = 1,
    double mediumBreakpoint = 700,
    double wideBreakpoint = 1100,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideBreakpoint) return wide;
    if (width >= mediumBreakpoint) return medium;
    return narrow;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top > 0 ? 8.0 : 12.0;
    return EdgeInsets.fromLTRB(
      w < 600 ? 12 : 20,
      top,
      w < 600 ? 12 : 20,
      20,
    );
  }

  static const double sectionGap = 14.0;
  static const double fieldGap = 12.0;

  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? accent,
    bool elevated = true,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return BoxDecoration(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: accent?.withValues(alpha: 0.25) ?? theme.alternate.withValues(alpha: 0.8),
        width: 1,
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: brandTeal.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration sidebarGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brandTeal,
          Color(0xFF185E5D),
        ],
      ),
    );
  }

  static BoxDecoration sidebarHeaderDecoration() {
    return BoxDecoration(
      color: brandSage.withValues(alpha: 0.35),
      border: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: theme.alternate),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: theme.primary, size: 22)
          : null,
      filled: true,
      fillColor: theme.secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: theme.error),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: theme.error, width: 1.5),
      ),
      labelStyle: theme.labelMedium.override(
        fontFamily: theme.labelMediumFamily,
        color: theme.secondaryText,
        useGoogleFonts: !theme.labelMediumIsCustom,
      ),
    );
  }

  static ThemeData buildLightTheme() {
    const primary = brandTeal;
    const secondary = brandMint;
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: false,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF4F7F8),
      fontFamily: 'cairo',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
        error: Color(0xFFFF5963),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      primaryColor: brandMint,
      scaffoldBackgroundColor: const Color(0xFF1D2428),
      fontFamily: 'cairo',
    );
  }
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final stacked = AdminUi.useStackedHeader(context) && trailing != null;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (compact ? theme.titleLarge : theme.headlineSmall).override(
            fontFamily: compact
                ? theme.titleLargeFamily
                : theme.headlineSmallFamily,
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
            useGoogleFonts: compact
                ? !theme.titleLargeIsCustom
                : !theme.headlineSmallIsCustom,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.bodyMediumIsCustom,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 12 : 16),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: trailing!,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
    );
  }
}

class AdminMenuTile extends StatelessWidget {
  const AdminMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Directionality.of(context) == ui.TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminStatCard extends StatefulWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.icon,
    this.future,
    this.count,
    this.accentColor,
    this.onTap,
    this.animateCount = true,
  }) : assert(future != null || count != null,
            'Provide either future or count');

  final String title;
  final IconData icon;
  final Future<int>? future;
  final int? count;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool animateCount;

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = widget.accentColor ?? theme.primary;

    final content = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        decoration: AdminUi.cardDecoration(context, accent: accent).copyWith(
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AdminUi.brandTeal.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: widget.count != null
              ? _StatRow(
                  title: widget.title,
                  icon: widget.icon,
                  count: widget.count!,
                  accent: accent,
                  animateCount: widget.animateCount,
                  showChevron: widget.onTap != null,
                )
              : FutureBuilder<int>(
                  future: widget.future,
                  builder: (context, snapshot) {
                    return _StatRow(
                      title: widget.title,
                      icon: widget.icon,
                      count: snapshot.data,
                      accent: accent,
                      animateCount: widget.animateCount,
                      showChevron: widget.onTap != null,
                    );
                  },
                ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (highlighted) {
          setState(() => _pressed = highlighted);
        },
        borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: accent.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.title,
    required this.icon,
    required this.count,
    required this.accent,
    this.animateCount = true,
    this.showChevron = false,
  });

  final String title;
  final IconData icon;
  final int? count;
  final Color accent;
  final bool animateCount;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.labelMedium.override(
                  fontFamily: theme.labelMediumFamily,
                  color: theme.secondaryText,
                  useGoogleFonts: !theme.labelMediumIsCustom,
                ),
              ),
              const SizedBox(height: 4),
              if (count == null)
                SpinKitThreeBounce(color: accent, size: 14)
              else if (animateCount)
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: count),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      value.toString(),
                      style: theme.headlineSmall.override(
                        fontFamily: theme.headlineSmallFamily,
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                        useGoogleFonts: !theme.headlineSmallIsCustom,
                      ),
                    );
                  },
                )
              else
                Text(
                  count.toString(),
                  style: theme.headlineSmall.override(
                    fontFamily: theme.headlineSmallFamily,
                    color: theme.primaryText,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.headlineSmallIsCustom,
                  ),
                ),
            ],
          ),
        ),
        if (showChevron)
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: accent.withValues(alpha: 0.55),
          ),
      ],
    );
  }
}

class AdminLoginCard extends StatelessWidget {
  const AdminLoginCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: AdminUi.cardDecoration(context).copyWith(
        boxShadow: [
          BoxShadow(
            color: AdminUi.brandTeal.withValues(alpha: 0.1),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: theme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لوحة التحكم',
                    style: theme.headlineSmall.override(
                      fontFamily: theme.headlineSmallFamily,
                      color: theme.primaryText,
                      fontWeight: FontWeight.w700,
                      useGoogleFonts: !theme.headlineSmallIsCustom,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

/// Scrollable body for forms — prevents bottom overflow on small screens / keyboards.
class AdminSafeScrollBody extends StatelessWidget {
  const AdminSafeScrollBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.safeTop = true,
    this.safeBottom = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final base = padding.resolve(Directionality.of(context));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          base.left,
          base.top,
          base.right,
          base.bottom + bottomInset,
        ),
        child: child,
      ),
    );
  }
}

/// Standard scrollable page body with optional header and actions.
class AdminPageBody extends StatelessWidget {
  const AdminPageBody({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.usePadding = true,
    this.scrollable = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? actions;
  final bool usePadding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final basePadding =
        usePadding ? AdminUi.pagePadding(context) : EdgeInsets.zero;
    final resolved = basePadding.resolve(Directionality.of(context));
    final scrollPadding = EdgeInsets.fromLTRB(
      resolved.left,
      resolved.top,
      resolved.right,
      resolved.bottom + bottomInset,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          AdminPageHeader(
            title: title!,
            subtitle: subtitle,
            trailing: actions,
            compact: MediaQuery.sizeOf(context).width < 600,
          )
        else if (actions != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: actions,
            ),
          ),
        child,
        const SizedBox(height: 8),
      ],
    );

    if (!scrollable) {
      return Padding(
        padding: scrollPadding,
        child: content,
      );
    }

    return SingleChildScrollView(
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: scrollPadding,
      child: content,
    );
  }
}

/// Card container for lists, tables, and forms.
class AdminContentCard extends StatelessWidget {
  AdminContentCard({
    super.key,
    required this.child,
    this.padding,
    this.title,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminUi.sectionGap),
      child: Container(
        width: double.infinity,
        decoration: AdminUi.cardDecoration(context),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.titleMedium.override(
                    fontFamily: theme.titleMediumFamily,
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.0,
                    useGoogleFonts: !theme.titleMediumIsCustom,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary action button for admin forms.
class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? theme.primary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    color: outlined ? theme.primary : Colors.white,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
              ),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.primary,
          side: BorderSide(color: theme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminUi.radiusSm),
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        ),
      ),
      child: child,
    );
  }
}

/// Consistent text field for admin forms.
class AdminTextField extends StatelessWidget {
  const AdminTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
    this.onToggleVisibility,
    this.visibilityVisible,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleVisibility;
  final bool? visibilityVisible;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      decoration: AdminUi.inputDecoration(
        context,
        label: label,
        hint: hint,
        prefixIcon: icon,
      ).copyWith(
        suffixIcon: onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  visibilityVisible == true
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}

/// Styled list row for admin data tables.
class AdminListTile extends StatelessWidget {
  const AdminListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.alternate.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                        useGoogleFonts: !theme.bodyMediumIsCustom,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: theme.secondaryText,
                          useGoogleFonts: !theme.labelSmallIsCustom,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows active reports country filter (super-admin).
class AdminReportsCountryBanner extends StatelessWidget {
  const AdminReportsCountryBanner({super.key, this.onClear});

  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (!AdminReportsCountryScope.isActive) {
      return const SizedBox.shrink();
    }

    final theme = FlutterFlowTheme.of(context);
    final label = AdminReportsCountryScope.countryLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AdminUi.sectionGap),
      child: Material(
        color: AdminUi.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_rounded,
                  color: AdminUi.brandTeal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'عرض بيانات: $label فقط',
                  style: theme.labelLarge.override(
                    fontFamily: theme.labelLargeFamily,
                    color: AdminUi.brandTeal,
                    fontWeight: FontWeight.w600,
                    useGoogleFonts: !theme.labelLargeIsCustom,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear ??
                    () {
                      AdminReportsCountryScope.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(uiTr(context, 'تم إلغاء فلترة الدولة')),
                        ),
                      );
                    },
                child: Text(uiTr(context, 'إلغاء الفلتر')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/core/admin_design/admin_design.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Sidebar section label (Overview / Operations / …).
class AdminMenuSectionHeader extends StatelessWidget {
  const AdminMenuSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontFamily: 'cairo',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Search + optional filter chips bar for list pages.
class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.trailing,
    this.chips = const [],
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final resolvedHint = hint ?? appTr(context, 'ent_search');
    return AdminContentCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: AdminUi.inputDecoration(
                    context,
                    label: resolvedHint,
                    prefixIcon: Icons.search_rounded,
                  ).copyWith(
                    labelText: null,
                    hintText: resolvedHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),
          ],
        ],
      ),
    );
  }
}

/// Filter chip matching admin brand.
class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FilterChip(
      selectedColor: AdminUi.brandTeal,
      checkmarkColor: Colors.white,
      backgroundColor: theme.secondaryBackground,
      side: BorderSide(
        color: selected
            ? AdminUi.brandTeal
            : theme.alternate.withValues(alpha: 0.8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminUi.radiusSm),
      ),
      label: Text(
        label,
        style: theme.labelMedium.override(
          fontFamily: theme.labelMediumFamily,
          color: selected ? Colors.white : theme.primaryText,
          fontWeight: FontWeight.w600,
          useGoogleFonts: !theme.labelMediumIsCustom,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Empty / zero-state for tables and lists.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 20 : 32,
        horizontal: compact ? 12 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              color: AdminUi.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AdminUi.brandTeal, size: compact ? 22 : 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            softWrap: true,
            textAlign: TextAlign.center,
            style: theme.titleMedium.override(
              fontFamily: theme.titleMediumFamily,
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              useGoogleFonts: !theme.titleMediumIsCustom,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              softWrap: true,
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: theme.secondaryText,
                fontSize: 13,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Consistent error panel with retry — never shows stack traces.
class AdminErrorState extends StatelessWidget {
  const AdminErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
    this.compact = false,
    this.retryLabel,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final vPad = compact ? 24.0 : 40.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 36 : 44,
            color: AdminUi.brandTeal.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.titleMedium.override(
              fontFamily: theme.titleMediumFamily,
              fontWeight: FontWeight.w700,
              useGoogleFonts: !theme.titleMediumIsCustom,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(retryLabel ?? uiTr(context, 'إعادة المحاولة')),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section title inside cards / detail panels.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.titleSmall.override(
                    fontFamily: theme.titleSmallFamily,
                    fontWeight: FontWeight.w700,
                    useGoogleFonts: !theme.titleSmallIsCustom,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      color: theme.secondaryText,
                      useGoogleFonts: !theme.bodySmallIsCustom,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Debounced search field with clear button and optional loading indicator.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    this.helperText,
    this.initialValue = '',
    this.debounceTag = 'admin_search',
    this.debounceMs = AdminUi.searchDebounceMs,
    this.loading = false,
    required this.onChanged,
    this.onSubmitted,
  });

  final String hint;
  final String? helperText;
  final String initialValue;
  final String debounceTag;
  final int debounceMs;
  final bool loading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant AdminSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    EasyDebounce.cancel(widget.debounceTag);
    _controller.dispose();
    super.dispose();
  }

  void _emit(String value) {
    EasyDebounce.debounce(
      widget.debounceTag,
      Duration(milliseconds: widget.debounceMs),
      () => widget.onChanged(value),
    );
  }

  void _clear() {
    _controller.clear();
    EasyDebounce.cancel(widget.debounceTag);
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    Widget? suffix;
    if (widget.loading) {
      suffix = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (hasText) {
      suffix = IconButton(
        icon: const Icon(Icons.close_rounded, size: 18),
        onPressed: _clear,
        tooltip: uiTr(context, 'مسح'),
      );
    }

    return TextField(
      controller: _controller,
      onChanged: (v) {
        setState(() {});
        _emit(v);
      },
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: AdminUi.compactSearchDecoration(
        context,
        hint: widget.hint,
        helperText: widget.helperText,
        suffixIcon: suffix,
      ),
    );
  }
}

/// Loading placeholder for page bodies.
class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final text = label ?? appTr(context, 'ent_loading');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AdminUi.brandTeal,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              text,
              style: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirm dialog with brand styling.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final theme = FlutterFlowTheme.of(context);
  final confirm = confirmLabel ?? appTr(context, 'ent_confirm');
  final cancel = cancelLabel ?? appTr(context, 'ent_cancel');
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusMd),
        ),
        title: Text(
          title,
          style: theme.titleLarge.override(
            fontFamily: theme.titleLargeFamily,
            fontWeight: FontWeight.w700,
            useGoogleFonts: !theme.titleLargeIsCustom,
          ),
        ),
        content: Text(
          message,
          style: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            color: theme.secondaryText,
            useGoogleFonts: !theme.bodyMediumIsCustom,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? theme.error : AdminUi.brandTeal,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(confirm),
          ),
        ],
      );
    },
  );
  return result == true;
}

/// Column definition for [AdminDataTable].
class AdminTableColumn {
  const AdminTableColumn({
    required this.label,
    this.flex = 1,
    this.minWidth = 100,
  });

  final String label;
  final int flex;
  final double minWidth;
}

/// Responsive data table: horizontal scroll on narrow screens.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyTitle,
    this.emptyMessage,
    this.minWidth,
  });

  final List<AdminTableColumn> columns;
  final List<List<Widget>> rows;
  final String? emptyTitle;
  final String? emptyMessage;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (rows.isEmpty) {
      return AdminContentCard(
        child: AdminEmptyState(
          title: emptyTitle ?? appTr(context, 'ent_no_data'),
          message: emptyMessage,
        ),
      );
    }

    final tableMin =
        minWidth ?? AdminUi.adminTableMinWidth(context).clamp(640.0, 1600.0);

    return AdminContentCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          // Bounded width required so Expanded columns don't collapse/overlap.
          width: tableMin,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? theme.alternate.withValues(alpha: 0.55)
                      : const Color(0xFFF9FAFB),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AdminUi.radiusMd),
                  ),
                  border: Border(
                    bottom: BorderSide(color: theme.alternate),
                  ),
                ),
                child: Row(
                  children: [
                    for (final col in columns)
                      Expanded(
                        flex: col.flex,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Text(
                            col.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.labelMedium.override(
                              fontFamily: theme.labelMediumFamily,
                              color: theme.secondaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              useGoogleFonts: !theme.labelMediumIsCustom,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < rows.length; i++)
                Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: i.isOdd
                        ? theme.primaryBackground.withValues(alpha: 0.55)
                        : theme.secondaryBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.alternate.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var c = 0; c < columns.length; c++)
                        Expanded(
                          flex: columns[c].flex,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: DefaultTextStyle(
                              style: theme.bodyMedium.override(
                                fontFamily: theme.bodyMediumFamily,
                                color: theme.primaryText,
                                fontSize: 13,
                                useGoogleFonts: !theme.bodyMediumIsCustom,
                              ),
                              child: c < rows[i].length
                                  ? rows[i][c]
                                  : const SizedBox.shrink(),
                            ),
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
  }
}

/// Status badge (pending / approved / active …).
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.label,
    this.tone = AdminBadgeTone.neutral,
  });

  final String label;
  final AdminBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AdminBadgeTone.success => (
          bg: const Color(0xFFEAF7F1),
          fg: const Color(0xFF16845B),
        ),
      AdminBadgeTone.warning => (
          bg: const Color(0xFFFFF7E8),
          fg: const Color(0xFFB7791F),
        ),
      AdminBadgeTone.danger => (
          bg: const Color(0xFFFDEEEF),
          fg: const Color(0xFFC94A55),
        ),
      AdminBadgeTone.info => (
          bg: const Color(0xFFEDF5FD),
          fg: const Color(0xFF3478C8),
        ),
      AdminBadgeTone.neutral => (
          bg: const Color(0xFFF0F2F4),
          fg: const Color(0xFF667085),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.fg,
          fontFamily: 'cairo',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum AdminBadgeTone { success, warning, danger, info, neutral }

/// Compact KPI strip used on finance / dashboard headers (string values OK).
class AdminKpiStrip extends StatelessWidget {
  const AdminKpiStrip({super.key, required this.items});

  final List<({String label, String value, IconData icon, Color? color})> items;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final count = AdminUi.responsiveColumnCount(
      context,
      wide: items.length.clamp(1, 4),
      medium: 2,
      narrow: 1,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width.clamp(140.0, constraints.maxWidth),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 90, maxHeight: 110),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(AdminUi.radiusSm),
                    border: Border.all(color: AdminColors.borderOf(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (item.color ?? AdminUi.brandTeal)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color ?? AdminUi.brandTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.labelMedium.override(
                                fontFamily: theme.labelMediumFamily,
                                color: theme.secondaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                useGoogleFonts: !theme.labelMediumIsCustom,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleLarge.override(
                                fontFamily: theme.titleLargeFamily,
                                color: theme.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                useGoogleFonts: !theme.titleLargeIsCustom,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Compact period segmented control + optional refresh (UI V2.1).
class AdminPeriodSegmented<T> extends StatelessWidget {
  const AdminPeriodSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.onRefresh,
    this.refreshTooltip,
  });

  final List<T> values;
  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  final VoidCallback? onRefresh;
  final String? refreshTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.alternate.withValues(alpha: 0.45)
            : const Color(0xFFF0F2F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final v in values)
                  Material(
                    color: selected == v
                        ? AdminUi.brandTeal
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => onChanged(v),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Text(
                          labels[v] ?? '$v',
                          style: theme.labelMedium.override(
                            fontFamily: theme.labelMediumFamily,
                            color: selected == v
                                ? Colors.white
                                : theme.primaryText,
                            fontWeight: selected == v
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 12.5,
                            useGoogleFonts: !theme.labelMediumIsCustom,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              tooltip: refreshTooltip ?? uiTr(context, 'تحديث'),
              onPressed: onRefresh,
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(Icons.refresh_rounded, color: AdminUi.brandTeal),
            ),
        ],
      ),
    );
  }
}

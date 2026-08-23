import 'package:flutter/material.dart';

import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Sidebar section label (Overview / Operations / …).
class AdminMenuSectionHeader extends StatelessWidget {
  const AdminMenuSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontFamily: 'cairo',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
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
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AdminUi.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AdminUi.brandTeal, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            softWrap: true,
            textAlign: TextAlign.center,
            style: theme.titleMedium.override(
              fontFamily: theme.titleMediumFamily,
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
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
                useGoogleFonts: !theme.bodyMediumIsCustom,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 18),
            action!,
          ],
        ],
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
              backgroundColor:
                  destructive ? theme.error : AdminUi.brandTeal,
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
                  color: AdminUi.brandTeal.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.18
                        : 0.06,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AdminUi.radiusMd),
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
                              color: AdminUi.brandTeal,
                              fontWeight: FontWeight.w700,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: i.isOdd
                        ? theme.primaryBackground.withValues(alpha: 0.55)
                        : theme.secondaryBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.alternate.withValues(alpha: 0.4),
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
          bg: const Color(0xFFE8F7F0),
          fg: const Color(0xFF0F7A4A),
        ),
      AdminBadgeTone.warning => (
          bg: const Color(0xFFFFF6E5),
          fg: const Color(0xFFB06A00),
        ),
      AdminBadgeTone.danger => (
          bg: const Color(0xFFFFEBEE),
          fg: const Color(0xFFC62828),
        ),
      AdminBadgeTone.info => (
          bg: AdminUi.brandTeal.withValues(alpha: 0.12),
          fg: AdminUi.brandTeal,
        ),
      AdminBadgeTone.neutral => (
          bg: const Color(0xFFF0F2F4),
          fg: const Color(0xFF5A6570),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.fg,
          fontFamily: 'cairo',
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
                  constraints: const BoxConstraints(minHeight: 96),
                  padding: const EdgeInsets.all(16),
                  decoration: AdminUi.cardDecoration(
                    context,
                    accent: item.color ?? AdminUi.brandTeal,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (item.color ?? AdminUi.brandTeal)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color ?? AdminUi.brandTeal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
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

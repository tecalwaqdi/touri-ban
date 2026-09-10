import 'package:flutter/material.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import '/backend/admin_ops_filters.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Operations Hub KPI strip — Total / Active / Completed / Cancelled.
///
/// Counts must share the same scope/filters as the bookings table.
class AdminBookingsSummaryStrip extends StatelessWidget {
  const AdminBookingsSummaryStrip({
    super.key,
    required this.counts,
    this.isLoading = false,
    this.selectedLifecycle = AdminOrderLifecycleFilter.all,
    this.onLifecycleSelected,
  });

  final AdminBookingsSummaryCounts counts;
  final bool isLoading;
  final AdminOrderLifecycleFilter selectedLifecycle;
  final ValueChanged<AdminOrderLifecycleFilter>? onLifecycleSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Semantics(
      identifier: 'qa-bookings-ops-kpis',
      label:
          'total:${counts.total ?? '-'} active:${counts.active ?? '-'} completed:${counts.completed ?? '-'} cancelled:${counts.cancelled ?? '-'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
        ),
        child: isLoading
            ? Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Container(
                      height: 28,
                      margin: EdgeInsetsDirectional.only(end: i == 3 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: theme.alternate.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(
                      context,
                      uiTr(context, 'الإجمالي'),
                      '${counts.total ?? '—'}',
                      theme.secondaryText,
                      lifecycle: AdminOrderLifecycleFilter.all,
                    ),
                    _chip(
                      context,
                      uiTr(context, 'الحالية'),
                      '${counts.active ?? '—'}',
                      const Color(0xFFE65100),
                      lifecycle: AdminOrderLifecycleFilter.active,
                    ),
                    _chip(
                      context,
                      uiTr(context, 'المكتملة'),
                      '${counts.completed ?? '—'}',
                      theme.success,
                      lifecycle: AdminOrderLifecycleFilter.completed,
                    ),
                    _chip(
                      context,
                      uiTr(context, 'الملغية'),
                      '${counts.cancelled ?? '—'}',
                      theme.error,
                      lifecycle: AdminOrderLifecycleFilter.cancelled,
                    ),
                    if (counts.results > 0)
                      _chip(
                        context,
                        uiTr(context, 'النتائج'),
                        counts.results.toString(),
                        AdminUi.brandTeal,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    String value,
    Color accent, {
    AdminOrderLifecycleFilter? lifecycle,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final selected =
        lifecycle != null && selectedLifecycle == lifecycle;
    final child = Container(
      margin: const EdgeInsetsDirectional.only(end: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: selected ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: selected ? 0.55 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: accent,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.labelLarge.override(
              fontFamily: theme.labelLargeFamily,
              fontWeight: FontWeight.w800,
              color: accent,
              useGoogleFonts: !theme.labelLargeIsCustom,
            ),
          ),
        ],
      ),
    );
    if (lifecycle == null || onLifecycleSelected == null) return child;
    return InkWell(
      onTap: () => onLifecycleSelected!(lifecycle),
      borderRadius: BorderRadius.circular(8),
      child: child,
    );
  }
}

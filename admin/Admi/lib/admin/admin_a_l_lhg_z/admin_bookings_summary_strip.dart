import 'package:flutter/material.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import '/backend/admin_ops_filters.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact horizontal summary strip for the bookings page.
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
      ),
      child: isLoading
          ? Row(
              children: List.generate(
                5,
                (i) => Expanded(
                  child: Container(
                    height: 28,
                    margin: EdgeInsetsDirectional.only(end: i == 4 ? 0 : 8),
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
                    uiTr(context, 'النتائج'),
                    counts.results.toString(),
                    AdminUi.brandTeal,
                  ),
                  if (counts.total != null)
                    _chip(
                      context,
                      uiTr(context, 'الإجمالي'),
                      counts.total!.toString(),
                      theme.secondaryText,
                    ),
                  if (counts.active != null)
                    _chip(
                      context,
                      uiTr(context, 'الحالية'),
                      counts.active!.toString(),
                      const Color(0xFFE65100),
                      lifecycle: AdminOrderLifecycleFilter.active,
                    ),
                  if (counts.completed != null)
                    _chip(
                      context,
                      uiTr(context, 'المكتملة'),
                      counts.completed!.toString(),
                      theme.success,
                      lifecycle: AdminOrderLifecycleFilter.completed,
                    ),
                  if (counts.cancelled != null)
                    _chip(
                      context,
                      uiTr(context, 'الملغية'),
                      counts.cancelled!.toString(),
                      theme.error,
                      lifecycle: AdminOrderLifecycleFilter.cancelled,
                    ),
                  if (counts.expired != null)
                    _chip(
                      context,
                      uiTr(context, 'المنتهية'),
                      counts.expired!.toString(),
                      theme.secondaryText,
                      lifecycle: AdminOrderLifecycleFilter.expired,
                    ),
                ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: selected ? 0.55 : 0.2),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
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
      onTap: () {
        if (selectedLifecycle == lifecycle) {
          onLifecycleSelected!(AdminOrderLifecycleFilter.all);
        } else {
          onLifecycleSelected!(lifecycle);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }
}

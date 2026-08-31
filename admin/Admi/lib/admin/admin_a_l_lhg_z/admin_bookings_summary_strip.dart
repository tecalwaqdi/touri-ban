import 'package:flutter/material.dart';

import '/admin/admin_a_l_lhg_z/admin_bookings_query.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact horizontal summary strip for the bookings page.
class AdminBookingsSummaryStrip extends StatelessWidget {
  const AdminBookingsSummaryStrip({
    super.key,
    required this.counts,
    this.isLoading = false,
  });

  final AdminBookingsSummaryCounts counts;
  final bool isLoading;

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
                    ),
                  if (counts.completed != null)
                    _chip(
                      context,
                      uiTr(context, 'المكتملة'),
                      counts.completed!.toString(),
                      theme.success,
                    ),
                  if (counts.cancelled != null)
                    _chip(
                      context,
                      uiTr(context, 'الملغية'),
                      counts.cancelled!.toString(),
                      theme.error,
                    ),
                  if (counts.expired != null)
                    _chip(
                      context,
                      uiTr(context, 'المنتهية'),
                      counts.expired!.toString(),
                      theme.secondaryText,
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
    Color accent,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
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
  }
}

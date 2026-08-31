import 'package:flutter/material.dart';

import '/backend/driver_admin_stats_loader.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Compact summary strip for Drivers (uses existing aggregate loader).
class AdminDriversSummaryStrip extends StatelessWidget {
  const AdminDriversSummaryStrip({
    super.key,
    required this.stats,
    this.loading = false,
    this.error = false,
    this.onRetry,
    this.onlineHint,
    this.availableHint,
    this.busyHint,
  });

  final DriverAdminStats stats;
  final bool loading;
  final bool error;
  final VoidCallback? onRetry;

  /// Optional page-derived operational hints (not full-collection scans).
  final int? onlineHint;
  final int? availableHint;
  final int? busyHint;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (error) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(uiTr(context, 'تعذر تحميل الإحصائيات'))),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(uiTr(context, 'إعادة')),
              ),
          ],
        ),
      );
    }

    final chips = <(String, String, Color)>[
      (uiTr(context, 'إجمالي المناديب'), '${stats.total}', AdminUi.brandTeal),
      (
        uiTr(context, 'بانتظار المراجعة'),
        '${stats.pendingReview}',
        Colors.blue.shade700
      ),
      (uiTr(context, 'معتمدون'), '${stats.approved}', Colors.green.shade700),
      if (onlineHint != null)
        (uiTr(context, 'متصلون الآن'), '$onlineHint', const Color(0xFF00897B)),
      if (availableHint != null)
        (uiTr(context, 'متاحون'), '$availableHint', Colors.green.shade600),
      if (busyHint != null)
        (uiTr(context, 'مشغولون'), '$busyHint', Colors.deepOrange.shade700),
      (uiTr(context, 'موقوفون'), '${stats.suspended + stats.deactivated}',
          Colors.brown.shade700),
    ];

    return Semantics(
      identifier: 'qa-driver-counters',
      container: true,
      label:
          'total:${stats.total} pending:${stats.pendingReview} approved:${stats.approved} '
          'activated:${stats.activated} deactivated:${stats.deactivated} '
          'suspended:${stats.suspended}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate.withValues(alpha: 0.7)),
        ),
        child: loading
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
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  for (final chip in chips)
                    _chip(context, chip.$1, chip.$2, chip.$3),
                ],
              ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value, Color color) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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
              color: color,
              useGoogleFonts: !theme.labelLargeIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

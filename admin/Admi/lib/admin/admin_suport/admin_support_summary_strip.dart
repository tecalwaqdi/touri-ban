import 'package:flutter/material.dart';

import '/admin/admin_suport/admin_support_stats_loader.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminSupportSummaryStrip extends StatelessWidget {
  const AdminSupportSummaryStrip({
    super.key,
    required this.stats,
    this.loading = false,
    this.error = false,
    this.onRetry,
  });

  final AdminSupportStats stats;
  final bool loading;
  final bool error;
  final VoidCallback? onRetry;

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
                  onPressed: onRetry, child: Text(uiTr(context, 'إعادة'))),
          ],
        ),
      );
    }

    final chips = <(String, String, Color)>[
      (
        uiTr(context, 'مفتوحة'),
        '${stats.totalOpenish}',
        Colors.deepOrange.shade700,
      ),
      (uiTr(context, 'جديدة'), '${stats.newTickets}', Colors.blue.shade700),
      (
        uiTr(context, 'قيد المعالجة'),
        '${stats.inProgress}',
        const Color(0xFF00897B),
      ),
      (
        uiTr(context, 'بانتظار العميل'),
        '${stats.waitingUser}',
        Colors.amber.shade800,
      ),
      (uiTr(context, 'تم الحل'), '${stats.resolved}', Colors.green.shade700),
      (uiTr(context, 'مغلقة'), '${stats.closed}', Colors.brown.shade700),
    ];

    return Container(
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
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _chip(context, chips[i].$1, chips[i].$2, chips[i].$3),
                  ],
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              color: color,
              fontWeight: FontWeight.w800,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.labelSmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '/backend/driver_admin_stats_loader.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Aggregate counter strip for the drivers admin page (not page `.length`).
class AdminDriverCountersStrip extends StatelessWidget {
  const AdminDriverCountersStrip({
    super.key,
    required this.stats,
    this.loading = false,
    this.error = false,
    this.onRetry,
  });

  final DriverAdminStats stats;
  final bool loading;
  final bool error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (loading) {
      return Semantics(
        identifier: 'qa-driver-counters',
        container: true,
        label: 'loading:true',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(minHeight: 3),
        ),
      );
    }
    if (error) {
      return AdminContentCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text(uiTr(context, 'تعذر تحميل عدادات المناديب'))),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(uiTr(context, 'إعادة'))),
          ],
        ),
      );
    }

    final tiles = <(String, int, Color)>[
      (uiTr(context, 'الإجمالي'), stats.total, AdminUi.brandTeal),
      (uiTr(context, 'V2'), stats.v2Total, Colors.indigo.shade700),
      (uiTr(context, 'Legacy'), stats.legacyTotal, theme.secondaryText),
      (uiTr(context, 'معتمدون'), stats.approved, Colors.green.shade700),
      (uiTr(context, 'مفعّلون'), stats.activated, Colors.green.shade700),
      (uiTr(context, 'غير مفعّلين'), stats.deactivated, Colors.orange.shade800),
      (uiTr(context, 'تحت المراجعة'), stats.pendingReview, Colors.blue.shade700),
      (uiTr(context, 'مرفوضون'), stats.rejected, theme.error),
      (
        uiTr(context, 'يحتاجون استكمال'),
        stats.needsChanges,
        Colors.deepOrange.shade700
      ),
      (uiTr(context, 'موقوفون'), stats.suspended, Colors.brown.shade700),
      (
        uiTr(context, 'حالة غير محددة'),
        stats.unknownLegacy,
        theme.secondaryText
      ),
      (
        uiTr(context, 'وثائق مكتملة'),
        stats.docsComplete,
        Colors.green.shade700
      ),
      (
        uiTr(context, 'وثائق ناقصة'),
        stats.docsMissing,
        Colors.orange.shade800
      ),
      (
        uiTr(context, 'وثائق تحتاج إعادة رفع'),
        stats.docsNeedsReupload,
        Colors.deepOrange.shade700
      ),
      (
        uiTr(context, 'وثائق غير معروفة (Legacy)'),
        stats.docsUnknownLegacy,
        theme.secondaryText
      ),
    ];

    return Semantics(
      identifier: 'qa-driver-counters',
      container: true,
      label:
          'total:${stats.total} v2:${stats.v2Total} legacy:${stats.legacyTotal} '
          'activated:${stats.activated} deactivated:${stats.deactivated} '
          'pending:${stats.pendingReview} rejected:${stats.rejected} '
          'needsChanges:${stats.needsChanges} unknown:${stats.unknownLegacy} '
          'docsComplete:${stats.docsComplete} docsMissing:${stats.docsMissing} '
          'docsNeedsReupload:${stats.docsNeedsReupload} '
          'docsUnknownLegacy:${stats.docsUnknownLegacy}',
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stats.scopedNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              uiTr(context, stats.scopedNote),
              softWrap: true,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in tiles)
              _CounterChip(label: t.$1, value: t.$2, color: t.$3),
          ],
        ),
        if (!stats.reviewBucketsBalance ||
            !stats.v2LegacyBalance ||
            !stats.docsBucketsBalance)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              uiTr(
                context,
                'Note: V2+Legacy, review+legacy, and docs buckets should equal total',
              ),
              softWrap: true,
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
      ],
    ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.titleMedium.override(
              fontFamily: theme.titleMediumFamily,
              fontWeight: FontWeight.w800,
              color: color,
              useGoogleFonts: !theme.titleMediumIsCustom,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            softWrap: true,
            style: theme.labelSmall.override(
              fontFamily: theme.labelSmallFamily,
              color: theme.secondaryText,
              useGoogleFonts: !theme.labelSmallIsCustom,
            ),
          ),
        ],
      ),
    );
  }
}

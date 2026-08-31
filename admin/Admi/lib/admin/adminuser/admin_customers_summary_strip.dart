import 'package:flutter/material.dart';

import '/admin/adminuser/admin_customers_stats_loader.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminCustomersSummaryStrip extends StatelessWidget {
  const AdminCustomersSummaryStrip({
    super.key,
    required this.stats,
    this.loading = false,
    this.error = false,
    this.onRetry,
    this.pageLiveTripHint,
  });

  final AdminCustomerStats stats;
  final bool loading;
  final bool error;
  final VoidCallback? onRetry;
  final int? pageLiveTripHint;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (error) {
      return _shell(
        theme,
        Row(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 16, color: theme.secondaryText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                uiTr(context, 'تعذر تحميل الإحصائيات'),
                style: theme.bodySmall,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(uiTr(context, 'إعادة')),
              ),
          ],
        ),
      );
    }

    final live = pageLiveTripHint ?? stats.withLiveTripHint;
    final items = <(String, String)>[
      (uiTr(context, 'إجمالي المستخدمين'), '${stats.total}'),
      (uiTr(context, 'نشطون'), '${stats.active}'),
      (uiTr(context, 'موقوفون'), '${stats.suspended}'),
      (uiTr(context, 'رحلة حالية'), '$live'),
    ];

    return _shell(
      theme,
      loading
          ? Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Container(
                    height: 22,
                    margin: EdgeInsetsDirectional.only(end: i == 3 ? 0 : 10),
                    decoration: BoxDecoration(
                      color: theme.alternate.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            )
          : Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: theme.alternate.withValues(alpha: 0.7),
                    ),
                  _metric(context, items[i].$1, items[i].$2),
                ],
              ],
            ),
    );
  }

  Widget _shell(FlutterFlowTheme theme, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.55)),
      ),
      child: child,
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: Row(
        children: [
          Text(
            value,
            style: theme.titleSmall.override(
              fontFamily: theme.titleSmallFamily,
              fontWeight: FontWeight.w700,
              color: AdminUi.brandTeal,
              useGoogleFonts: !theme.titleSmallIsCustom,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

import 'package:flutter/material.dart';

import '/components/admin_firestore_list.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Firestore cursor pagination controls for bookings (real pages, not client slices).
class AdminBookingsPaginationBar extends StatelessWidget {
  const AdminBookingsPaginationBar({
    super.key,
    required this.state,
    required this.pageSize,
    required this.visibleCount,
  });

  final AdminFirestoreListMeta state;
  final int pageSize;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final fetched = state.totalFetched;
    final total = state.totalAvailable;
    final approxPage = fetched == 0 ? 1 : ((fetched - 1) ~/ pageSize) + 1;
    final totalPages = total == null || total <= 0
        ? null
        : ((total - 1) ~/ pageSize) + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == null
                  ? '$visibleCount ${uiTr(context, 'حجزًا معروضة')}'
                      '${state.hasMore ? '+' : ''} · '
                      '${uiTr(context, 'صفحة')} ~$approxPage'
                  : '$total ${uiTr(context, 'حجزًا')} · '
                      '$visibleCount ${uiTr(context, 'معروضة')}'
                      '${totalPages != null ? ' · ${uiTr(context, 'صفحة')} $approxPage / $totalPages' : ''}',
              style: theme.labelSmall.override(
                fontFamily: theme.labelSmallFamily,
                color: theme.secondaryText,
                useGoogleFonts: !theme.labelSmallIsCustom,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: state.isLoading || state.isLoadingMore
                ? null
                : () => state.refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(uiTr(context, 'تحديث')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminUi.brandTeal,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: (!state.hasMore || state.isLoadingMore)
                ? null
                : () => state.loadMore(),
            icon: state.isLoadingMore
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.navigate_next_rounded, size: 18),
            label: Text(uiTr(context, 'التالي')),
            style: FilledButton.styleFrom(
              foregroundColor: AdminUi.brandTeal,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

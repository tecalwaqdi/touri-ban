import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Cache-first, limited Firestore list for picker sheets (no live subscription).
class AdminCacheRecordList<T> extends StatefulWidget {
  const AdminCacheRecordList({
    super.key,
    required this.query,
    required this.recordBuilder,
    this.queryBuilder,
    this.limit = kAdminPickerLimit,
    required this.itemBuilder,
    this.emptyMessage = 'لا توجد نتائج',
    this.searchHint = 'بحث...',
    this.filter,
  });

  final Query query;
  final RecordBuilder<T> recordBuilder;
  final Query Function(Query)? queryBuilder;
  final int limit;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final String searchHint;
  final bool Function(T item, String query)? filter;

  @override
  State<AdminCacheRecordList<T>> createState() =>
      _AdminCacheRecordListState<T>();
}

class _AdminCacheRecordListState<T> extends State<AdminCacheRecordList<T>> {
  List<T> _items = [];
  bool _loading = true;
  bool _hasError = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final items = await queryListCacheFirst<T>(
        widget.query,
        widget.recordBuilder,
        queryBuilder: widget.queryBuilder,
        limit: widget.limit,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  List<T> get _visible {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _items;
    final filter = widget.filter;
    if (filter != null) {
      return _items.where((item) => filter(item, q)).toList();
    }
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminUi.radiusSm),
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: _loading && _items.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : _hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تعذر تحميل القائمة',
                              textAlign: TextAlign.center,
                              style: theme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(appTr(context, 'adm_retry')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          widget.emptyMessage,
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          widget.itemBuilder(context, _visible[index]),
                    ),
        ),
      ],
    );
  }
}

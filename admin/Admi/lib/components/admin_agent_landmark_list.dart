import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/admin_country_landmark_filter.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_firestore_list.dart';

/// Country-agent landmark list: fast first page + capped background merge.
class AdminAgentLandmarkList extends StatefulWidget {
  const AdminAgentLandmarkList({
    super.key,
    required this.partnersOnly,
    required this.builder,
    this.pageSize = kAdminPageSize,
    this.loading,
  });

  final bool partnersOnly;
  final int pageSize;
  final Widget Function(
    BuildContext context,
    List<MkanRecord> visibleItems,
    AdminFirestoreListMeta<MkanRecord> state,
  ) builder;
  final Widget? loading;

  @override
  State<AdminAgentLandmarkList> createState() => _AdminAgentLandmarkListState();
}

class _AdminAgentLandmarkListState extends State<AdminAgentLandmarkList> {
  List<MkanRecord> _allItems = [];
  int _visibleCount = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _backgroundLoadRunning = false;

  bool get _hasMore => _visibleCount < _allItems.length;

  late final void Function() _externalRefreshListener;
  late final void Function(String docId) _externalRemoveListener;

  @override
  void initState() {
    super.initState();
    _externalRefreshListener = () {
      if (mounted) unawaited(_lightRefresh());
    };
    _externalRemoveListener = (docId) {
      if (!mounted) return;
      setState(() {
        _allItems.removeWhere((m) => m.reference.id == docId);
        if (_visibleCount > _allItems.length) {
          _visibleCount = _allItems.length;
        }
      });
    };
    AdminListRefresh.register(AdminListScope.landmarks, _externalRefreshListener);
    AdminListRefresh.registerRemove(
      AdminListScope.landmarks,
      _externalRemoveListener,
    );
    _bootstrap();
  }

  @override
  void dispose() {
    AdminListRefresh.unregister(AdminListScope.landmarks, _externalRefreshListener);
    AdminListRefresh.unregisterRemove(
      AdminListScope.landmarks,
      _externalRemoveListener,
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdminAgentLandmarkList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnersOnly != widget.partnersOnly) {
      _reload(forceRefresh: true);
    }
  }

  Future<void> _bootstrap() async {
    final cached = AdminCountryLandmarkFilter.cachedItems(
      partnersOnly: widget.partnersOnly,
    );
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _allItems = cached;
        _visibleCount = _initialVisible(cached.length);
        _loading = false;
      });
      return;
    }

    await _loadQuickFirstPage();
    _scheduleBackgroundMerge();
  }

  int _initialVisible(int total) =>
      total <= widget.pageSize ? total : widget.pageSize;

  Future<void> _loadQuickFirstPage() async {
    try {
      final items = await queryListCacheFirst<MkanRecord>(
        MkanRecord.collection,
        MkanRecord.fromSnapshot,
        queryBuilder: (collection) {
          var q = collection as Query<Map<String, dynamic>>;
          if (widget.partnersOnly) {
            q = q.where('isShrek', isEqualTo: true);
          }
          return AdminCountryScope.applyLandmarkCountryFilter(q)
              .orderBy(FieldPath.documentId);
        },
        limit: widget.pageSize,
      );

      final filtered = AdminCountryScope.filterLandmarks(items);
      if (!mounted || filtered.isEmpty) return;

      setState(() {
        _allItems = filtered;
        _visibleCount = _initialVisible(filtered.length);
        _loading = false;
      });
    } catch (_) {}
  }

  void _scheduleBackgroundMerge() {
    if (_backgroundLoadRunning) return;
    _backgroundLoadRunning = true;
    Future<void>.delayed(const Duration(milliseconds: 120), () async {
      try {
        await _reload(forceRefresh: true, silent: true);
      } finally {
        _backgroundLoadRunning = false;
      }
    });
  }

  Future<void> _reload({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (!silent && _allItems.isEmpty) {
      setState(() {
        _loading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final items = await AdminCountryLandmarkFilter.loadAll(
        partnersOnly: widget.partnersOnly,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _allItems = items;
        if (_visibleCount == 0 || forceRefresh) {
          _visibleCount = _initialVisible(items.length);
        } else if (_visibleCount > items.length) {
          _visibleCount = items.length;
        }
        _loading = false;
        _loadingMore = false;
        _hasError = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_allItems.isNotEmpty) {
        if (!silent) {
          setState(() {
            _loading = false;
            _hasError = true;
            _errorMessage = 'تعذر تحديث قائمة المعالم';
          });
        }
        return;
      }
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'تعذر تحميل المعالم. تحقق من الاتصال وحاول مرة أخرى.';
      });
    }
  }

  Future<void> _lightRefresh() async {
    if (_backgroundLoadRunning) return;
    try {
      final items = await queryListCacheFirst<MkanRecord>(
        MkanRecord.collection,
        MkanRecord.fromSnapshot,
        queryBuilder: (collection) {
          var q = collection as Query<Map<String, dynamic>>;
          if (widget.partnersOnly) {
            q = q.where('isShrek', isEqualTo: true);
          }
          return AdminCountryScope.applyLandmarkCountryFilter(q)
              .orderBy(FieldPath.documentId);
        },
        limit: widget.pageSize,
      );
      final filtered = AdminCountryScope.filterLandmarks(items);
      if (!mounted) return;
      setState(() {
        _allItems = filtered;
        _visibleCount = _initialVisible(filtered.length);
        _loading = false;
        _loadingMore = false;
        _hasError = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted || _allItems.isNotEmpty) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'تعذر تحديث قائمة المعالم';
      });
    }
  }

  Future<void> refresh() => _reload(forceRefresh: true);

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() {
      _visibleCount =
          (_visibleCount + widget.pageSize).clamp(0, _allItems.length);
      _loadingMore = false;
    });
  }

  AdminFirestoreListMeta<MkanRecord> _meta() =>
      AdminFirestoreListMeta<MkanRecord>(
        isLoading: _loading,
        isLoadingMore: _loadingMore,
        hasMore: _hasMore,
        fromCache: false,
        hasError: _hasError,
        errorMessage: _errorMessage,
        refresh: refresh,
        loadMore: loadMore,
        totalFetched: _visibleCount,
        totalAvailable: _allItems.length,
      );

  @override
  Widget build(BuildContext context) {
    if (_loading && _allItems.isEmpty) {
      return widget.loading ??
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
    }

    if (_hasError && _allItems.isEmpty) {
      return AdminListErrorState(
        message: _errorMessage ?? 'تعذر تحميل البيانات',
        onRetry: refresh,
      );
    }

    final visible = _allItems.take(_visibleCount).toList(growable: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasError && _allItems.isNotEmpty)
          AdminListErrorBanner(
            message: _errorMessage ?? 'تعذر تحديث البيانات',
            onRetry: refresh,
          ),
        widget.builder(context, visible, _meta()),
      ],
    );
  }
}

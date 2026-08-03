import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_firestore_cache.dart';

/// تحميل معالم القرية على دفعات — أسرع في الفتح الأول.
class TouryMkanPaginationController extends ChangeNotifier {
  TouryMkanPaginationController({this.pageSize = 12});

  final int pageSize;

  DocumentReference? _villageRef;
  DocumentSnapshot? _lastDoc;
  final List<MkanRecord> items = <MkanRecord>[];

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  Object? lastError;
  bool _disposed = false;

  String? get villagePath => _villageRef?.path;

  void _notifySafe() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// يربط القرية — يعرض الكاش فوراً إن وُجد.
  void bindVillage(DocumentReference? villageRef) {
    if (villageRef == null) return;
    if (_villageRef?.path == villageRef.path && items.isNotEmpty) {
      return;
    }

    _villageRef = villageRef;
    lastError = null;

    final cached = TouryFirestoreCache.peekMkanFirstPage(villageRef);
    if (cached != null && cached.isNotEmpty) {
      items
        ..clear()
        ..addAll(cached);
      _lastDoc = null;
      hasMore = cached.length >= pageSize;
      isLoading = false;
      isLoadingMore = false;
      _notifySafe();
      unawaited(_refreshInitialFromNetwork(villageRef));
      return;
    }

    items.clear();
    _lastDoc = null;
    hasMore = true;
    isLoading = true;
    isLoadingMore = false;
    _notifySafe();
    unawaited(loadInitial());
  }

  Future<void> loadInitial() async {
    if (_disposed) return;
    final village = _villageRef;
    if (village == null) return;

    if (items.isNotEmpty) {
      unawaited(_refreshInitialFromNetwork(village));
      return;
    }

    isLoading = true;
    lastError = null;
    _notifySafe();

    try {
      await _fetchAndApplyFirstPage(village);
    } catch (e, st) {
      lastError = e;
      debugPrint('TouryMkanPagination.loadInitial: $e\n$st');
    } finally {
      if (!_disposed) {
        isLoading = false;
        _notifySafe();
      }
    }
  }

  Future<void> _refreshInitialFromNetwork(DocumentReference village) async {
    if (_disposed) return;
    try {
      await _fetchAndApplyFirstPage(village);
      if (_disposed) return;
      _notifySafe();
    } catch (e, st) {
      debugPrint('TouryMkanPagination.refresh: $e\n$st');
    }
  }

  Future<void> _fetchAndApplyFirstPage(DocumentReference village) async {
    final snap = await _pageQuery(village).limit(pageSize).get(
          const GetOptions(source: Source.serverAndCache),
        );
    if (_disposed || _villageRef?.path != village.path) return;

    items
      ..clear()
      ..addAll(snap.docs.map(MkanRecord.fromSnapshot));
    _lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
    hasMore = snap.docs.length >= pageSize;
    if (items.isNotEmpty) {
      TouryFirestoreCache.storeMkanFirstPage(village, items);
    }
  }

  Query _pageQuery(DocumentReference villageRef) {
    return MkanRecord.collection
        .where('acctev', isEqualTo: true)
        .where('id_vill', isEqualTo: villageRef)
        .orderBy('naim');
  }

  Future<void> loadMore() async {
    if (_disposed) return;
    final village = _villageRef;
    if (village == null || !hasMore || isLoadingMore || isLoading) return;
    isLoadingMore = true;
    lastError = null;
    _notifySafe();

    try {
      var query = _pageQuery(village).limit(pageSize);
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snap = await query.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (_disposed) return;
      if (snap.docs.isEmpty) {
        hasMore = false;
      } else {
        items.addAll(snap.docs.map(MkanRecord.fromSnapshot));
        _lastDoc = snap.docs.last;
        hasMore = snap.docs.length >= pageSize;
      }
    } catch (e, st) {
      lastError = e;
      debugPrint('TouryMkanPagination.loadMore: $e\n$st');
    } finally {
      if (!_disposed) {
        isLoadingMore = false;
        _notifySafe();
      }
    }
  }

  Future<void> ensureLoadedForSearch({int maxExtraPages = 2}) async {
    var pages = 0;
    while (hasMore && !isLoading && !isLoadingMore && pages < maxExtraPages) {
      await loadMore();
      pages++;
    }
  }

  Future<void> ensureAllLoaded() async {
    await ensureLoadedForSearch(maxExtraPages: 8);
  }

  @override
  void dispose() {
    _disposed = true;
    items.clear();
    super.dispose();
  }
}

/// زر/صف «تحميل المزيد» أسفل القائمة.
class TouryLoadMoreTile extends StatelessWidget {
  const TouryLoadMoreTile({
    super.key,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    this.itemCount,
    this.loadedCount,
  });

  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final int? itemCount;
  final int? loadedCount;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      if (loadedCount != null && loadedCount! > 0) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'landmarks_loaded_count'
                  .tr(namedArgs: {'count': '$loadedCount'}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                itemCount != null
                    ? 'load_more_landmarks_count'.tr(namedArgs: {
                        'loaded': '$loadedCount',
                        'total': '$itemCount',
                      })
                    : 'load_more_landmarks'.tr(),
              ),
            ),
    );
  }
}

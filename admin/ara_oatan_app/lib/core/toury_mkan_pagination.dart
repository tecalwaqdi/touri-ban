import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/toury_firestore_cache.dart';

/// حجم صفحة المعالم موحّد بين Prefetch والكاش والـ Pagination.
const int kTouryMkanPageSize = 24;

/// جلسة معالم لكل قرية — تبقى في الذاكرة عند التنقل بين الشاشات.
class TouryMkanPaginationHub {
  TouryMkanPaginationHub._();

  static final Map<String, TouryMkanPaginationController> _byVillage =
      <String, TouryMkanPaginationController>{};
  static const int _maxSessions = 8;

  static TouryMkanPaginationController acquire(DocumentReference villageRef) {
    final key = villageRef.path;
    final existing = _byVillage.remove(key);
    if (existing != null) {
      _byVillage[key] = existing; // LRU touch
      existing.bindVillage(villageRef);
      return existing;
    }
    final created = TouryMkanPaginationController(pageSize: kTouryMkanPageSize);
    created.bindVillage(villageRef);
    _byVillage[key] = created;
    while (_byVillage.length > _maxSessions) {
      final oldestKey = _byVillage.keys.first;
      final old = _byVillage.remove(oldestKey);
      old?.dispose();
    }
    return created;
  }

  static bool owns(TouryMkanPaginationController controller) {
    return _byVillage.values.any((c) => identical(c, controller));
  }

  @visibleForTesting
  static void clearForTests() {
    for (final c in _byVillage.values) {
      c.dispose();
    }
    _byVillage.clear();
  }
}

/// تحميل معالم القرية على دفعات — كاش فوري + تحديث خلفي عند الحاجة فقط.
class TouryMkanPaginationController extends ChangeNotifier {
  TouryMkanPaginationController({this.pageSize = kTouryMkanPageSize});

  final int pageSize;

  DocumentReference? _villageRef;
  DocumentSnapshot? _lastDoc;
  final List<MkanRecord> items = <MkanRecord>[];

  bool isLoading = false;
  bool isLoadingMore = false;
  bool isRefreshing = false;
  bool hasMore = true;
  Object? lastError;
  bool _disposed = false;
  int _bindGeneration = 0;

  String? get villagePath => _villageRef?.path;

  void _notifySafe() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _sameItemIds(List<MkanRecord> a, List<MkanRecord> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].reference.path != b[i].reference.path) return false;
    }
    return true;
  }

  /// يربط القرية — يعرض الكاش/الجلسة فوراً دون Loading إن وُجدت بيانات.
  void bindVillage(DocumentReference? villageRef) {
    if (villageRef == null) return;

    // نفس القرية وبيانات معروضة مسبقاً — لا إعادة جلب.
    if (_villageRef?.path == villageRef.path && items.isNotEmpty) {
      isLoading = false;
      return;
    }

    _bindGeneration++;
    final generation = _bindGeneration;
    _villageRef = villageRef;
    lastError = null;

    final cached = TouryFirestoreCache.peekMkanPage(villageRef);
    if (cached != null && cached.items.isNotEmpty) {
      items
        ..clear()
        ..addAll(cached.items);
      _lastDoc = cached.lastDoc;
      hasMore = cached.hasMore;
      isLoading = false;
      isLoadingMore = false;
      _notifySafe();

      if (cached.needsBackgroundRefresh) {
        unawaited(
          _refreshInitialFromNetwork(
            villageRef,
            generation: generation,
            silent: true,
          ),
        );
      }
      return;
    }

    items.clear();
    _lastDoc = null;
    hasMore = true;
    isLoading = true;
    isLoadingMore = false;
    _notifySafe();
    unawaited(loadInitial(generation: generation));
  }

  Future<void> loadInitial({int? generation}) async {
    if (_disposed) return;
    final village = _villageRef;
    if (village == null) return;
    final gen = generation ?? _bindGeneration;

    if (items.isNotEmpty) {
      unawaited(
        _refreshInitialFromNetwork(
          village,
          generation: gen,
          silent: true,
        ),
      );
      return;
    }

    isLoading = true;
    lastError = null;
    _notifySafe();

    try {
      // 1) كاش Firestore المحلي أولاً — يظهر فوراً إن وُجد.
      final paintedFromDisk = await _tryApplyFromFirestoreDiskCache(
        village,
        generation: gen,
      );
      if (_disposed || gen != _bindGeneration) return;
      if (paintedFromDisk) {
        isLoading = false;
        _notifySafe();
      }

      // 2) شبكة / serverAndCache لإكمال أو تحديث الصفحة.
      await _fetchAndApplyFirstPage(
        village,
        generation: gen,
        preferServer: true,
      );
    } catch (e, st) {
      if (gen == _bindGeneration) {
        lastError = e;
      }
      debugPrint('TouryMkanPagination.loadInitial: $e\n$st');
    } finally {
      if (!_disposed && gen == _bindGeneration) {
        isLoading = false;
        _notifySafe();
      }
    }
  }

  Future<bool> _tryApplyFromFirestoreDiskCache(
    DocumentReference village, {
    required int generation,
  }) async {
    try {
      final snap = await _pageQuery(village).limit(pageSize).get(
            const GetOptions(source: Source.cache),
          );
      if (_disposed || generation != _bindGeneration) return false;
      if (_villageRef?.path != village.path) return false;
      if (snap.docs.isEmpty) return false;

      final page = TouryMkanCachedPage(
        items: snap.docs.map(MkanRecord.fromSnapshot).toList(),
        lastDoc: snap.docs.last,
        hasMore: snap.docs.length >= pageSize,
        fetchedAt: DateTime.now(),
      );
      items
        ..clear()
        ..addAll(page.items);
      _lastDoc = page.lastDoc;
      hasMore = page.hasMore;
      TouryFirestoreCache.storeMkanPage(village, page);
      return true;
    } catch (_) {
      // لا يوجد كاش قرص — نكمل من الشبكة.
      return false;
    }
  }

  Future<void> _refreshInitialFromNetwork(
    DocumentReference village, {
    required int generation,
    bool silent = true,
  }) async {
    if (_disposed || generation != _bindGeneration) return;
    if (isRefreshing) return;
    isRefreshing = true;
    try {
      await _fetchAndApplyFirstPage(
        village,
        generation: generation,
        preferServer: true,
        replaceOnlyIfChanged: silent,
      );
      if (_disposed || generation != _bindGeneration) return;
      if (!silent || items.isNotEmpty) {
        _notifySafe();
      }
    } catch (e, st) {
      debugPrint('TouryMkanPagination.refresh: $e\n$st');
    } finally {
      isRefreshing = false;
    }
  }

  Future<void> _fetchAndApplyFirstPage(
    DocumentReference village, {
    required int generation,
    bool preferServer = true,
    bool replaceOnlyIfChanged = false,
  }) async {
    final snap = await _pageQuery(village).limit(pageSize).get(
          GetOptions(
            source: preferServer ? Source.serverAndCache : Source.serverAndCache,
          ),
        );
    if (_disposed || generation != _bindGeneration) return;
    if (_villageRef?.path != village.path) return;

    final nextItems = snap.docs.map(MkanRecord.fromSnapshot).toList();
    final nextLast = snap.docs.isEmpty ? null : snap.docs.last;
    final nextHasMore = snap.docs.length >= pageSize;

    if (replaceOnlyIfChanged && _sameItemIds(items, nextItems)) {
      _lastDoc = nextLast ?? _lastDoc;
      hasMore = nextHasMore;
      if (nextItems.isNotEmpty) {
        TouryFirestoreCache.storeMkanPage(
          village,
          TouryMkanCachedPage(
            items: nextItems,
            lastDoc: nextLast,
            hasMore: nextHasMore,
            fetchedAt: DateTime.now(),
          ),
        );
      }
      return;
    }

    items
      ..clear()
      ..addAll(nextItems);
    _lastDoc = nextLast;
    hasMore = nextHasMore;
    if (items.isNotEmpty) {
      TouryFirestoreCache.storeMkanPage(
        village,
        TouryMkanCachedPage(
          items: List<MkanRecord>.from(items),
          lastDoc: _lastDoc,
          hasMore: hasMore,
          fetchedAt: DateTime.now(),
        ),
      );
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
    final generation = _bindGeneration;
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
      if (_disposed || generation != _bindGeneration) return;
      if (snap.docs.isEmpty) {
        hasMore = false;
      } else {
        final incoming = snap.docs.map(MkanRecord.fromSnapshot).toList();
        final existing = items.map((e) => e.reference.path).toSet();
        for (final row in incoming) {
          if (existing.add(row.reference.path)) {
            items.add(row);
          }
        }
        _lastDoc = snap.docs.last;
        hasMore = snap.docs.length >= pageSize;
      }
    } catch (e, st) {
      lastError = e;
      debugPrint('TouryMkanPagination.loadMore: $e\n$st');
    } finally {
      if (!_disposed && generation == _bindGeneration) {
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

  /// إعادة جلب صريحة (زر إعادة المحاولة) — تُفرّغ الكاش الناعم لهذه القرية.
  Future<void> forceReload() async {
    final village = _villageRef;
    if (village == null) return;
    TouryFirestoreCache.invalidateMkanPage(village);
    items.clear();
    _lastDoc = null;
    hasMore = true;
    isLoading = true;
    lastError = null;
    _bindGeneration++;
    final generation = _bindGeneration;
    _notifySafe();
    await loadInitial(generation: generation);
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

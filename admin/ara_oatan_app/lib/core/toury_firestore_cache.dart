import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/app_state.dart';
import '/backend/backend.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_vehicle_catalog.dart';
import '/flutter_flow/flutter_flow_util.dart';

class _CacheEntry<T> {
  _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// صفحة معالم محفوظة مع مؤشر Firestore لاستكمال التصفح بدون تكرار.
class TouryMkanCachedPage {
  TouryMkanCachedPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.fetchedAt,
  });

  final List<MkanRecord> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  final DateTime fetchedAt;

  bool get needsBackgroundRefresh =>
      DateTime.now().difference(fetchedAt) >=
      TouryFirestoreCache.mkanSoftRefreshAfter;

  TouryMkanCachedPage copyWithItems() => TouryMkanCachedPage(
        items: List<MkanRecord>.from(items),
        lastDoc: lastDoc,
        hasMore: hasMore,
        fetchedAt: fetchedAt,
      );
}

/// Shared in-memory caches and broadcast streams for hot Firestore reads.
class TouryFirestoreCache {
  TouryFirestoreCache._();

  static final _streamCache = <String, Stream<dynamic>>{};
  static final _onceCache = <String, _CacheEntry<dynamic>>{};
  static final _countCache = <String, _CacheEntry<int>>{};
  static final _streamLastValue = <String, dynamic>{};

  static const _docTtl = Duration(minutes: 5);
  /// المعالم شبه ثابتة — كاش أطول يقلل إعادة الجلب عند التنقل.
  static const _mkanTtl = Duration(minutes: 15);
  /// بعد هذه المدة نحدّث في الخلفية دون إظهار Loading.
  static const mkanSoftRefreshAfter = Duration(minutes: 2);
  static const _staticTtl = Duration(minutes: 15);
  static const _countTtl = Duration(minutes: 5);
  static const _chatCountTtl = Duration(minutes: 2);

  static Stream<T> _staleWhileRevalidate<T>(
    String onceKey,
    Stream<T> live, {
    Duration ttl = _docTtl,
  }) {
    final cached = _onceCache[onceKey];
    if (cached != null && !cached.isExpired) {
      return Stream.multi((controller) {
        controller.add(cached.value as T);
        final sub = live.listen(
          (value) {
            _onceCache[onceKey] =
                _CacheEntry<dynamic>(value, DateTime.now().add(ttl));
            controller.add(value);
          },
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: false,
        );
        controller.onCancel = sub.cancel;
      });
    }
    return live.map((value) {
      _onceCache[onceKey] = _CacheEntry<dynamic>(value, DateTime.now().add(ttl));
      return value;
    });
  }

  static Stream<List<SettingsRecord>> settingsStream({
    Query Function(Query)? queryBuilder,
    int limit = -1,
    bool singleRecord = false,
  }) {
    const key = 'settings:id=1';
    const onceKey = 'settings-once:id=1';
    return _broadcastStream(key, () {
      final live = querySettingsRecord(
        queryBuilder: queryBuilder ??
            (settingsRecord) => settingsRecord.where('id', isEqualTo: 1),
        limit: limit,
        singleRecord: singleRecord,
      );
      return _staleWhileRevalidate<List<SettingsRecord>>(
        onceKey,
        live,
        ttl: _staticTtl,
      );
    }).cast<List<SettingsRecord>>();
  }

  static Future<List<SettingsRecord>> settingsOnce({
    Query Function(Query)? queryBuilder,
    int limit = -1,
    bool singleRecord = false,
  }) {
    return once(
      'settings-once:id=1:$singleRecord',
      () => querySettingsRecordOnce(
        queryBuilder: queryBuilder ??
            (settingsRecord) => settingsRecord.where('id', isEqualTo: 1),
        limit: limit,
        singleRecord: singleRecord,
      ),
      ttl: _docTtl,
    );
  }

  static const _mkanListLimit = 48;
  static const _mkanPageSize = 24;
  static const _typeCarLimit = 120;

  static int get mkanPageSize => _mkanPageSize;

  static Stream<List<MkanRecord>> mkanStream({
    required String cacheKey,
    Query Function(Query)? queryBuilder,
    int limit = _mkanListLimit,
    bool singleRecord = false,
  }) {
    final streamKey = 'mkan:$cacheKey';
    final onceKey = 'mkan-once:$cacheKey';
    return _broadcastStream(streamKey, () {
      final live = queryMkanRecord(
        queryBuilder: queryBuilder,
        limit: limit,
        singleRecord: singleRecord,
      );
      return _staleWhileRevalidate<List<MkanRecord>>(onceKey, live, ttl: _mkanTtl);
    }).cast<List<MkanRecord>>();
  }

  static Stream<List<VillagesRecord>> villagesStream({
    required String cacheKey,
    Query Function(Query)? queryBuilder,
    int limit = 200,
    bool singleRecord = false,
  }) {
    final streamKey = 'villages:$cacheKey';
    final onceKey = 'villages-once:$cacheKey';
    return _broadcastStream(streamKey, () {
      final live = queryVillagesRecord(
        queryBuilder: queryBuilder,
        limit: limit,
        singleRecord: singleRecord,
      );
      return _staleWhileRevalidate<List<VillagesRecord>>(
        onceKey,
        live,
        ttl: _staticTtl,
      );
    }).cast<List<VillagesRecord>>();
  }

  static Stream<List<TypeCarRecord>> typeCarStream({
    Query Function(Query)? queryBuilder,
    int limit = _typeCarLimit,
  }) {
    const streamKey = 'typecar:active-v3:all';
    const onceKey = 'typecar-once:active-v3:all';
    return _broadcastStream(streamKey, () {
      final live = queryTypeCarRecord(
        queryBuilder: queryBuilder,
        limit: limit,
      ).map(_filterActiveTypeCars);
      return _staleWhileRevalidate<List<TypeCarRecord>>(
        onceKey,
        live,
        ttl: _staticTtl,
      );
    }).cast<List<TypeCarRecord>>();
  }

  static List<TypeCarRecord> _filterActiveTypeCars(List<TypeCarRecord> cars) {
    final countryRef = FFAppState().dolh;
    final iso = TouryCountryRegistry.normalizeIso(countryRef?.id);
    final filtered = cars.where((car) {
      if (!car.isAvailableForListing) return false;
      if (countryRef == null && (iso == null || iso.isEmpty)) return true;
      return car.matchesCountry(
        countryRef: countryRef,
        iso2: iso,
      );
    }).toList();
    return tourySortTypeCars(filtered);
  }

  static void invalidateTypeCar() {
    _streamCache.remove('typecar:active-v3:all');
    _onceCache.remove('typecar-once:active-v3:all');
    _streamLastValue.remove('typecar:active-v3:all');
    _streamCache.removeWhere((key, _) => key.startsWith('typecar:'));
    _onceCache.removeWhere((key, _) => key.startsWith('typecar-once:'));
    _streamLastValue.removeWhere((key, _) => key.startsWith('typecar:'));
  }

  /// آخر قائمة سيارات محفوظة — لعرض فوري عند إعادة فتح الشاشة.
  static List<TypeCarRecord>? peekTypeCars() {
    final cached = _onceCache['typecar-once:active-v3:all'];
    if (cached != null && !cached.isExpired) {
      return List<TypeCarRecord>.from(cached.value as List<TypeCarRecord>);
    }
    final last = _streamLastValue['typecar:active-v3:all'];
    if (last is List<TypeCarRecord>) {
      return List<TypeCarRecord>.from(last);
    }
    return null;
  }

  static Stream<List<OrderRecord>> userOrdersStream(
    DocumentReference? userRef, {
    int limit = 80,
  }) {
    if (userRef == null) {
      return Stream.value(const <OrderRecord>[]);
    }
    final streamKey = 'orders:user:${userRef.path}';
    final onceKey = 'orders-once:user:${userRef.path}';
    return _broadcastStream(streamKey, () {
      final live = queryOrderRecord(
        queryBuilder: (orderRecord) => orderRecord
            .where('USER', isEqualTo: userRef)
            .orderBy('data_order', descending: true),
        limit: limit,
      );
      return _staleWhileRevalidate<List<OrderRecord>>(onceKey, live);
    }).cast<List<OrderRecord>>();
  }

  static Stream<List<CitiesRecord>> citiesStream({
    required String cacheKey,
    Query Function(Query)? queryBuilder,
    int limit = -1,
    bool singleRecord = false,
  }) {
    final streamKey = 'cities:$cacheKey';
    final onceKey = 'cities-once:$cacheKey';
    return _broadcastStream(streamKey, () {
      final live = queryCitiesRecord(
        queryBuilder: queryBuilder,
        limit: limit,
        singleRecord: singleRecord,
      );
      return _staleWhileRevalidate<List<CitiesRecord>>(
        onceKey,
        live,
        ttl: _staticTtl,
      );
    }).cast<List<CitiesRecord>>();
  }

  static Stream<List<CountriesRecord>> countriesStream({
    required String cacheKey,
    Query Function(Query)? queryBuilder,
    int limit = -1,
    bool singleRecord = false,
  }) {
    final streamKey = 'countries:$cacheKey';
    final onceKey = 'countries-once:$cacheKey';
    return _broadcastStream(streamKey, () {
      final live = queryCountriesRecord(
        queryBuilder: queryBuilder,
        limit: limit,
        singleRecord: singleRecord,
      );
      return _staleWhileRevalidate<List<CountriesRecord>>(
        onceKey,
        live,
        ttl: _staticTtl,
      );
    }).cast<List<CountriesRecord>>();
  }

  /// إعدادات إضافية (مثل سجل id != 1 في الدفع).
  static Future<SettingsRecord?> settingsRecordOnce({
    Query Function(Query)? queryBuilder,
    bool singleRecord = true,
  }) async {
    final key = 'settings-custom:${queryBuilder.hashCode}:$singleRecord';
    final rows = await once(
      key,
      () => querySettingsRecordOnce(
        queryBuilder: queryBuilder,
        singleRecord: singleRecord,
      ),
      ttl: _docTtl,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  static void warmup() {
    // تأخير بسيط حتى تظهر الواجهة أولاً ثم التحميل في الخلفية.
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      unawaited(settingsOnce().catchError((_) => <SettingsRecord>[]));
      unawaited(_warmTypeCarsOnce());
    });
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      unawaited(_warmVillagesOnce());
      unawaited(_warmCitiesOnce());
    });
    Future<void>.delayed(const Duration(milliseconds: 3200), () {
      unawaited(_warmCountriesOnce());
    });
  }

  static Future<void> _warmTypeCarsOnce() async {
    await once(
      'typecar-once:active-v3:all',
      () async => _filterActiveTypeCars(
        await queryTypeCarRecordOnce(limit: _typeCarLimit),
      ),
      ttl: _staticTtl,
    ).catchError((_) => <TypeCarRecord>[]);
  }

  static Future<void> _warmCitiesOnce() async {
    await once(
      'cities-once:saudi-warm',
      () => queryCitiesRecordOnce(
        queryBuilder: (q) => q.where('saudi', isEqualTo: true),
        limit: 60,
      ),
      ttl: _staticTtl,
    ).catchError((_) => <CitiesRecord>[]);
  }

  static Future<void> _warmVillagesOnce() async {
    await once(
      'villages-once:active',
      () => queryVillagesRecordOnce(
        queryBuilder: (q) => q.where('acctev', isEqualTo: true),
        limit: 120,
      ),
      ttl: _staticTtl,
    ).catchError((_) => <VillagesRecord>[]);
  }

  static Future<void> _warmCountriesOnce() async {
    await once(
      'countries-once:saudi:true',
      () => queryCountriesRecordOnce(
        queryBuilder: (q) => q.where('saudi', isEqualTo: true),
        singleRecord: true,
      ),
      ttl: _staticTtl,
    ).catchError((_) => <CountriesRecord>[]);
  }

  /// يحمّل أول صفحة معالم فقط — أسرع من جلب مئات المستندات دفعة واحدة.
  static void warmMkanForVillage(DocumentReference villageRef) {
    prefetchMkanFirstPage(villageRef);
  }

  static String _mkanPageOnceKey(DocumentReference ref) =>
      'mkan-page-once:${ref.path}';

  static void prefetchMkanFirstPage(DocumentReference villageRef) {
    final onceKey = _mkanPageOnceKey(villageRef);
    unawaited(
      once(
        onceKey,
        () => _fetchMkanPageBundle(villageRef, pageSize: _mkanPageSize),
        ttl: _mkanTtl,
      ).catchError(
        (_) => TouryMkanCachedPage(
          items: const <MkanRecord>[],
          lastDoc: null,
          hasMore: false,
          fetchedAt: DateTime.now(),
        ),
      ),
    );
  }

  static TouryMkanCachedPage? peekMkanPage(DocumentReference villageRef) {
    final cached = _onceCache[_mkanPageOnceKey(villageRef)];
    if (cached == null || cached.isExpired) return null;
    final value = cached.value;
    if (value is TouryMkanCachedPage) {
      return value.copyWithItems();
    }
    if (value is List<MkanRecord>) {
      // توافق مع إدخالات قديمة في الكاش.
      return TouryMkanCachedPage(
        items: List<MkanRecord>.from(value),
        lastDoc: null,
        hasMore: value.length >= _mkanPageSize,
        fetchedAt: cached.expiresAt.subtract(_mkanTtl),
      );
    }
    return null;
  }

  static List<MkanRecord>? peekMkanFirstPage(DocumentReference villageRef) {
    return peekMkanPage(villageRef)?.items;
  }

  /// يحفظ صفحة المعالم الأولى مع مؤشر التصفح.
  static void storeMkanPage(
    DocumentReference villageRef,
    TouryMkanCachedPage page,
  ) {
    if (page.items.isEmpty) return;
    _onceCache[_mkanPageOnceKey(villageRef)] = _CacheEntry<dynamic>(
      page,
      DateTime.now().add(_mkanTtl),
    );
  }

  /// يحفظ صفحة المعالم الأولى في الكاش بعد جلبها من pagination.
  static void storeMkanFirstPage(
    DocumentReference villageRef,
    List<MkanRecord> items,
  ) {
    if (items.isEmpty) return;
    storeMkanPage(
      villageRef,
      TouryMkanCachedPage(
        items: List<MkanRecord>.from(items),
        lastDoc: null,
        hasMore: items.length >= _mkanPageSize,
        fetchedAt: DateTime.now(),
      ),
    );
  }

  static void invalidateMkanPage(DocumentReference villageRef) {
    _onceCache.remove(_mkanPageOnceKey(villageRef));
  }

  static Future<TouryMkanCachedPage> _fetchMkanPageBundle(
    DocumentReference villageRef, {
    int pageSize = _mkanPageSize,
    DocumentSnapshot? startAfter,
  }) async {
    var query = MkanRecord.collection
        .where('acctev', isEqualTo: true)
        .where('id_vill', isEqualTo: villageRef)
        .orderBy('naim')
        .limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap =
        await query.get(const GetOptions(source: Source.serverAndCache));
    return TouryMkanCachedPage(
      items: snap.docs.map(MkanRecord.fromSnapshot).toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= pageSize,
      fetchedAt: DateTime.now(),
    );
  }

  static Future<List<MkanRecord>> _fetchMkanPage(
    DocumentReference villageRef, {
    int pageSize = _mkanPageSize,
    DocumentSnapshot? startAfter,
  }) async {
    final page = await _fetchMkanPageBundle(
      villageRef,
      pageSize: pageSize,
      startAfter: startAfter,
    );
    return page.items;
  }

  static Future<VillagesRecord> villageDocumentOnce(DocumentReference ref) {
    return once(
      'village-doc:${ref.path}',
      () => VillagesRecord.getDocumentOnce(ref),
      ttl: _staticTtl,
    );
  }

  static Future<VillagesRecord?> villageByNameOnce(String name) {
    final key = 'village-by-name:$name';
    return once(
      key,
      () async {
        final rows = await queryVillagesRecordOnce(
          queryBuilder: (q) => q.where('naim', isEqualTo: name),
          singleRecord: true,
        );
        return rows.isNotEmpty ? rows.first : null;
      },
      ttl: _staticTtl,
    );
  }

  static Future<CountriesRecord?> countryByNameOnce(String name) {
    final key = 'country-by-name:$name';
    return once(
      key,
      () async {
        final rows = await queryCountriesRecordOnce(
          queryBuilder: (q) => q.where('naim', isEqualTo: name),
          singleRecord: true,
        );
        return rows.isNotEmpty ? rows.first : null;
      },
      ttl: _staticTtl,
    );
  }

  static Future<int> chatTodayCount({
    required DocumentReference? currentUserRef,
  }) {
    final dayKey = DateTime.now().toIso8601String().substring(0, 10);
    final userKey = currentUserRef?.path ?? 'guest';
    return count(
      'chat-today:$dayKey:$userKey',
      () => queryChatRecordCount(
        queryBuilder: (chatRecord) => chatRecord.where(
          'participants',
          arrayContains: currentUserRef,
        ),
      ),
      ttl: _chatCountTtl,
    );
  }

  static Future<T> once<T>(
    String key,
    Future<T> Function() fetch, {
    Duration ttl = _docTtl,
  }) async {
    final cached = _onceCache[key];
    if (cached != null && !cached.isExpired) {
      return cached.value as T;
    }
    final value = await fetch();
    _onceCache[key] = _CacheEntry<dynamic>(value, DateTime.now().add(ttl));
    return value;
  }

  static Future<CitiesRecord> cityOnce(DocumentReference ref) {
    return once('city:${ref.path}', () => CitiesRecord.getDocumentOnce(ref));
  }

  static Future<CountriesRecord> countryOnce(DocumentReference ref) {
    return once(
      'country:${ref.path}',
      () => CountriesRecord.getDocumentOnce(ref),
    );
  }

  static Future<int> mkanCount({
    required String cacheKey,
    Query Function(Query)? queryBuilder,
    int limit = -1,
  }) {
    return count(
      'mkan-count:$cacheKey',
      () => queryMkanRecordCount(
        queryBuilder: queryBuilder,
        limit: limit,
      ),
      ttl: _countTtl,
    );
  }

  static Future<int> count(
    String key,
    Future<int> Function() fetch, {
    Duration ttl = _countTtl,
  }) async {
    final cached = _countCache[key];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }
    final value = await fetch();
    _countCache[key] = _CacheEntry<int>(value, DateTime.now().add(ttl));
    return value;
  }

  static void invalidateDocument(String path) {
    _onceCache.removeWhere((key, _) => key.contains(path));
    _countCache.clear();
  }

  /// يُستدعى عند تحديث صورة في Firestore لإجبار إعادة الجلب.
  static void invalidateImageDocument(String path) {
    invalidateDocument(path);
  }

  static void clear() {
    _streamCache.clear();
    _onceCache.clear();
    _countCache.clear();
    _streamLastValue.clear();
  }

  /// Drop cached user-orders stream so Retry starts a fresh listen.
  static void invalidateUserOrders(DocumentReference? userRef) {
    if (userRef == null) return;
    final streamKey = 'orders:user:${userRef.path}';
    final onceKey = 'orders-once:user:${userRef.path}';
    _streamCache.remove(streamKey);
    _streamLastValue.remove(streamKey);
    _onceCache.remove(onceKey);
  }

  static Stream<T> _broadcastStream<T>(String key, Stream<T> Function() create) {
    if (!_streamCache.containsKey(key)) {
      final raw = create().asBroadcastStream(
        onListen: (sub) {},
        onCancel: (sub) {},
      );
      // On terminal error, drop cache so the next listen recreates the stream.
      raw.listen(
        (value) => _streamLastValue[key] = value,
        onError: (_) {
          _streamCache.remove(key);
          _streamLastValue.remove(key);
        },
        cancelOnError: false,
      );
      _streamCache[key] = raw;
    }
    return _streamWithReplay<T>(key, _streamCache[key]!.cast<T>());
  }

  /// يعيد آخر قيمة فوراً — يحل تعليق StreamBuilder عند العودة للشاشة.
  static Stream<T> _streamWithReplay<T>(String key, Stream<T> source) async* {
    final last = _streamLastValue[key];
    if (last != null) {
      yield last as T;
    }
    yield* source;
  }
}

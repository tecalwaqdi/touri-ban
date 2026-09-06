import 'dart:collection';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_perf_trace.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/core/admin_currency.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_order_query.dart';
import '/core/finance/finance_reconciliation_read_model.dart';
import '/core/finance/financial_trip_semantics.dart';

/// PERF-P3 — shared Finance **source** reads (coalescing + short session cache).
///
/// Accounting formulas stay in frozen F1/F2/B1 models — this class only loads
/// and reuses Firestore candidate sets / settlement maps.
class AdminFinanceRepository {
  AdminFinanceRepository._();
  static final AdminFinanceRepository instance = AdminFinanceRepository._();

  /// Short-lived finance source TTL (session / route reuse).
  static const Duration sourceTtl = Duration(seconds: 45);

  /// Presentation label TTL (country/driver/agent display only).
  static const Duration labelTtl = Duration(minutes: 10);

  static const int maxSourceEntries = 24;
  static const int maxLabelEntries = 200;

  final LinkedHashMap<String, _CacheEntry<Object?>> _sourceCache =
      LinkedHashMap<String, _CacheEntry<Object?>>();
  final Map<String, Future<Object?>> _inFlight = <String, Future<Object?>>{};

  final LinkedHashMap<String, _CacheEntry<String>> _labelCache =
      LinkedHashMap<String, _CacheEntry<String>>();

  /// Last B1 result keyed by source identity (orders+settlements fingerprint).
  String? _b1MemoKey;
  FinanceReconciliationResult? _b1MemoResult;

  // ---------------------------------------------------------------------------
  // Session / invalidation
  // ---------------------------------------------------------------------------

  void clearSession() {
    _sourceCache.clear();
    _inFlight.clear();
    _labelCache.clear();
    _b1MemoKey = null;
    _b1MemoResult = null;
    AdminPerfTrace.financeRepoInvalidate(reason: 'session_clear');
  }

  void invalidateAllFinanceSource() {
    _sourceCache.removeWhere((k, _) => k.startsWith('src:'));
    _b1MemoKey = null;
    _b1MemoResult = null;
    AdminPerfTrace.financeRepoInvalidate(reason: 'finance_source');
  }

  void invalidateSettlements() {
    _sourceCache.removeWhere(
      (k, _) => k.contains('|settlements_maps|') || k.contains('|hub_bundle|'),
    );
    // B1 depends on settlements maps.
    _b1MemoKey = null;
    _b1MemoResult = null;
    AdminPerfTrace.financeRepoInvalidate(reason: 'settlements');
  }

  void invalidatePeriod({
    required AdminDatePreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
  }) {
    final range = AdminDateRangeResolver.resolve(
      preset: preset,
      customStart: customStart,
      customEnd: customEnd,
    );
    final needle = _rangeToken(range);
    _sourceCache.removeWhere((k, _) => k.contains(needle));
    _b1MemoKey = null;
    _b1MemoResult = null;
    AdminPerfTrace.financeRepoInvalidate(reason: 'period');
  }

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------

  String _sessionPart() {
    final uid = currentUserUid.isEmpty ? 'anon' : currentUserUid;
    final role = AdminRoleService.isAccountant
        ? 'acct'
        : (AdminRoleService.isCountryAgent ? 'agent' : 'admin');
    final scope = AdminRoleService.usesCountryFinanceScope
        ? (AdminRoleService.scopedCountryRef ??
                AdminCountryScope.activeCountryRef)
            ?.path
        : 'global';
    return '$uid|$role|${scope ?? 'none'}';
  }

  String _rangeToken(AdminDateRange? range) {
    if (range == null) return 'all';
    return '${range.startInclusive.millisecondsSinceEpoch}_'
        '${range.endExclusive.millisecondsSinceEpoch}';
  }

  String sourceKey({
    required String kind,
    required AdminDateRange? range,
    DocumentReference? country,
    DocumentReference? driverRef,
  }) {
    return 'src:$_sessionPart()|$kind|${_rangeToken(range)}|'
        '${country?.path ?? '-'}|${driverRef?.path ?? '-'}';
  }

  // ---------------------------------------------------------------------------
  // Coalescing + cache core
  // ---------------------------------------------------------------------------

  Future<T> _coalesce<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() loader,
    bool cacheSuccess = true,
  }) async {
    final cached = _sourceCache[key];
    if (cached != null && !cached.isExpired(ttl) && cached.value is T) {
      // LRU touch
      _sourceCache.remove(key);
      _sourceCache[key] = cached;
      AdminPerfTrace.financeRepoCacheHit(kind: key.split('|').length > 2 ? key.split('|')[2] : 'src');
      return cached.value as T;
    }

    final pending = _inFlight[key];
    if (pending != null) {
      AdminPerfTrace.financeRepoInFlightJoin(kind: 'src');
      return await pending as T;
    }

    AdminPerfTrace.financeRepoCacheMiss(kind: 'src');
    final fut = () async {
      try {
        final value = await loader();
        if (cacheSuccess) {
          _putSource(key, value);
        }
        return value;
      } catch (e) {
        // Do not sticky-cache failures.
        _sourceCache.remove(key);
        rethrow;
      } finally {
        _inFlight.remove(key);
      }
    }();
    _inFlight[key] = fut;
    return await fut;
  }

  void _putSource(String key, Object? value) {
    _sourceCache.remove(key);
    _sourceCache[key] = _CacheEntry(value, DateTime.now());
    while (_sourceCache.length > maxSourceEntries) {
      _sourceCache.remove(_sourceCache.keys.first);
    }
  }

  // ---------------------------------------------------------------------------
  // PERF-P4A — modern first page (critical path; not full-period summary)
  // ---------------------------------------------------------------------------

  DocumentReference? _resolveCountry(DocumentReference? countryRef) {
    if (AdminRoleService.usesCountryFinanceScope) {
      return AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
    }
    return countryRef;
  }

  AdminDateRange? _resolveRange({
    required AdminDatePreset datePreset,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return AdminDateRangeResolver.resolve(
      preset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
    );
  }

  /// Coalesced modern completed page — sole critical-path order query for Hub.
  Future<FinanceOrderPage> loadModernFirstPage({
    required AdminDatePreset datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    bool forceRefresh = false,
  }) async {
    final range = _resolveRange(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
    );
    final country = _resolveCountry(countryRef);
    final key = sourceKey(
      kind: 'modern_page',
      range: range,
      country: country,
      driverRef: driverRef,
    );
    if (forceRefresh) {
      _sourceCache.remove(key);
      _inFlight.remove(key);
    }
    return _coalesce<FinanceOrderPage>(
      key: key,
      ttl: sourceTtl,
      loader: () async {
        try {
          AdminPerfTrace.financeRepoQueryEnd(kind: 'modern_page_start', docs: 0);
          return await FinanceOrderQuery.fetchModernPage(
            range: range,
            country: country,
            driverRef: driverRef,
            limit: FinanceOrderQuery.tablePageSize,
          );
        } on FirebaseException catch (e) {
          throw StateError('finance_query_unavailable:${e.code}');
        }
      },
    );
  }

  /// Hub/Agent first useful rows — does not await summary or settlements maps.
  Future<List<AccountantTripRow>> loadHubFirstPage({
    AdminDatePreset datePreset = AdminDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    String currency = 'SAR',
    bool forceRefresh = false,
  }) async {
    final scope = AccountantFinanceLoaderScope.scopeForCurrentUser(
      countryOverride: countryRef,
    );
    final sym = AdminCurrency.symbolByCode[currency] ?? currency;
    final page = await loadModernFirstPage(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
      countryRef: countryRef,
      driverRef: driverRef,
      forceRefresh: forceRefresh,
    );
    return _tripsFromOrders(page.orders, scope: scope, symbol: sym);
  }

  // ---------------------------------------------------------------------------
  // Completed order source (modern+legacy) — summary scan; seeds from first page
  // ---------------------------------------------------------------------------

  Future<FinanceOrderScanResult> loadCompletedScan({
    required AdminDatePreset datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    void Function(List<OrderRecord> firstOrders, int docsRead)? onFirstPage,
    bool forceRefresh = false,
  }) async {
    final range = _resolveRange(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
    );
    final country = _resolveCountry(countryRef);
    final key = sourceKey(
      kind: 'completed_scan',
      range: range,
      country: country,
      driverRef: driverRef,
    );
    if (forceRefresh) {
      _sourceCache.remove(key);
      _inFlight.remove(key);
    }

    void signalFirst(FinanceOrderScanResult scan) {
      if (onFirstPage == null) return;
      final first = scan.orders.take(FinanceOrderQuery.tablePageSize).toList();
      onFirstPage(first, first.length);
    }

    final existing = _sourceCache[key];
    if (!forceRefresh &&
        existing != null &&
        !existing.isExpired(sourceTtl) &&
        existing.value is FinanceOrderScanResult) {
      final scan = existing.value as FinanceOrderScanResult;
      AdminPerfTrace.financeRepoCacheHit(kind: 'completed_scan');
      signalFirst(scan);
      return scan;
    }

    // During live load, prefer chunk callback for earliest rows; also signal
    // after completion so in-flight joiners still get first-page data.
    var chunkSignaled = false;
    final scan = await _coalesce<FinanceOrderScanResult>(
      key: key,
      ttl: sourceTtl,
      loader: () async {
        try {
          // PERF-P4A: reuse coalesced modern first page (no duplicate query).
          final firstPage = await loadModernFirstPage(
            datePreset: datePreset,
            customStart: customStart,
            customEnd: customEnd,
            countryRef: countryRef,
            driverRef: driverRef,
            forceRefresh: forceRefresh,
          );
          if (onFirstPage != null) {
            chunkSignaled = true;
            onFirstPage(firstPage.orders, firstPage.docsRead);
          }
          return await FinanceOrderQuery.scanCompletedCandidates(
            range: range,
            country: country,
            driverRef: driverRef,
            seedModernOrders: firstPage.orders,
            modernStartAfter: firstPage.lastDocument,
            seedDocsRead: firstPage.docsRead,
            // Already signaled via loadModernFirstPage above.
            onFirstModernChunk: null,
          );
        } on FirebaseException catch (e) {
          throw StateError('finance_query_unavailable:${e.code}');
        }
      },
    );
    if (!chunkSignaled) signalFirst(scan);
    return scan;
  }

  Future<List<Map<String, dynamic>>> loadSettlementsMaps({
    bool forceRefresh = false,
  }) {
    // Settlements maps are not date-scoped in loader today — key by session only.
    final range = AdminDateRangeResolver.resolve(preset: AdminDatePreset.thisYear);
    final country = _resolveCountry(null);
    final key = sourceKey(
      kind: 'settlements_maps',
      range: range,
      country: AdminRoleService.usesCountryFinanceScope ? country : null,
    );
    if (forceRefresh) {
      _sourceCache.remove(key);
      _inFlight.remove(key);
    }
    return _coalesce<List<Map<String, dynamic>>>(
      key: key,
      ttl: sourceTtl,
      loader: () => _fetchSettlementsMaps(
        AdminRoleService.usesCountryFinanceScope ? country : null,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchSettlementsMaps(
    DocumentReference? country,
  ) async {
    try {
      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('financial_settlements');
      if (AdminRoleService.usesCountryFinanceScope && country != null) {
        q = q.where('countryId', isEqualTo: country.path);
      }
      q = q.orderBy('createdAt', descending: true);
      final out = <Map<String, dynamic>>[];
      DocumentSnapshot? last;
      const cap = 200;
      while (out.length < cap) {
        var page = q.limit(FinanceOrderQuery.tablePageSize);
        if (last != null) page = page.startAfterDocument(last);
        final snap = await page.get();
        AdminPerfTrace.financeDocsRead(snap.docs.length, source: 'settlements_maps');
        AdminPerfTrace.financeRepoQueryEnd(kind: 'settlements_maps', docs: snap.docs.length);
        if (snap.docs.isEmpty) break;
        for (final d in snap.docs) {
          out.add(<String, dynamic>{'id': d.id, ...d.data()});
        }
        last = snap.docs.last;
        if (snap.docs.length < FinanceOrderQuery.tablePageSize) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  int countOpenSettlementsFromMaps(List<Map<String, dynamic>> maps) {
    var open = 0;
    for (final map in maps) {
      final st = (map['status'] ?? '').toString().toLowerCase();
      final outstanding = (map['outstandingMinor'] as num?)?.toInt() ?? 0;
      if (st == 'settled' || st == 'voided') continue;
      if (outstanding > 0 ||
          st == 'draft' ||
          st == 'locked' ||
          st == 'partially_paid' ||
          st == 'open' ||
          st == 'pending') {
        open++;
      }
    }
    return open;
  }

  // ---------------------------------------------------------------------------
  // Hub / Agent / Reports bundle (F1 aggregate outside cache of formulas)
  // ---------------------------------------------------------------------------

  Future<AccountantFinanceViewBundle> loadHubBundle({
    AdminDatePreset datePreset = AdminDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    String currency = 'SAR',
    String periodLabel = '',
    void Function(List<AccountantTripRow> firstRows, int docsRead)? onFirstPage,
    bool forceRefresh = false,
  }) async {
    final scope = AccountantFinanceLoaderScope.scopeForCurrentUser(
      countryOverride: countryRef,
    );
    final sym = AdminCurrency.symbolByCode[currency] ?? currency;

    // PERF-P4A: settlements maps independent of completed scan — run together.
    final settlementsFuture = loadSettlementsMaps(forceRefresh: forceRefresh);
    final scanFuture = loadCompletedScan(
      datePreset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
      countryRef: countryRef,
      driverRef: driverRef,
      forceRefresh: forceRefresh,
      onFirstPage: (orders, docs) {
        if (onFirstPage == null) return;
        final rows = _tripsFromOrders(orders, scope: scope, symbol: sym);
        onFirstPage(rows, docs);
      },
    );
    final settled = await Future.wait<Object>([scanFuture, settlementsFuture]);
    final scan = settled[0] as FinanceOrderScanResult;
    final maps = settled[1] as List<Map<String, dynamic>>;

    final orders = scan.orders;
    final model = AccountantFinanceReadModel.aggregate(
      orders: orders,
      scope: scope,
      currency: currency,
    );
    final trips = _tripsFromOrders(orders, scope: scope, symbol: sym);
    var fixturesSkippedForTable = 0;
    for (final o in orders) {
      if (FinancialTripSemantics.isFinanceQaFixture(o) ||
          AdminQaFixture.isFixtureOrder(o)) {
        fixturesSkippedForTable++;
      }
    }

    final openSettlements = countOpenSettlementsFromMaps(maps);

    final alerts = <String>[];
    final incomplete = model.completedTripsWithPartialFinancialData +
        model.completedTripsWithUnresolvedFinancialData;
    if (incomplete > 0) {
      alerts.add('$incomplete رحلات مكتملة تحتاج استكمال بيانات مالية');
    }
    if (model.unattributedAgentCompleted > 0) {
      alerts.add(
        '${model.unattributedAgentCompleted} رحلات بدون إسناد وكيل تاريخي موثوق',
      );
    }
    if (openSettlements > 0) {
      alerts.add('$openSettlements تسويات بها مبلغ متبقٍ / غير مسددة');
    }

    return AccountantFinanceViewBundle(
      model: model,
      trips: trips,
      alerts: alerts,
      currency: currency,
      periodLabel: periodLabel.isEmpty ? datePreset.name : periodLabel,
      docsScanned: scan.docsRead,
      truncated: scan.truncated || orders.length >= FinanceOrderQuery.scanCap,
      openSettlementsRemaining: openSettlements,
      fixturesExcludedFromTable: fixturesSkippedForTable,
    );
  }

  /// PERF-P4A: first-page B1 with settlement membership (no full-year scan).
  Future<FinanceReconciliationResult> loadReconciliationFirstPage({
    AdminDatePreset datePreset = AdminDatePreset.thisYear,
    bool forceRefresh = false,
  }) async {
    final scope = AccountantFinanceLoaderScope.scopeForCurrentUser();
    final pageFuture = loadModernFirstPage(
      datePreset: datePreset,
      forceRefresh: forceRefresh,
    );
    final settlementsFuture = loadSettlementsMaps(forceRefresh: forceRefresh);
    final page = await pageFuture;
    final settlements = await settlementsFuture;
    return _b1BuildMemoized(
      orders: page.orders,
      settlements: settlements,
      scope: scope,
      currency: 'SAR',
      allowMemo: false,
    );
  }

  Future<FinanceReconciliationResult> loadReconciliation({
    AdminDatePreset datePreset = AdminDatePreset.thisYear,
    void Function(FinanceReconciliationResult partial)? onFirstPage,
    bool forceRefresh = false,
  }) async {
    final scope = AccountantFinanceLoaderScope.scopeForCurrentUser();
    final settlementsFuture =
        loadSettlementsMaps(forceRefresh: forceRefresh);

    // PERF-P4A: first rows need settlement evidence — never classify with [].
    if (onFirstPage != null) {
      // ignore: unawaited_futures
      Future.wait<Object>([
        loadModernFirstPage(
          datePreset: datePreset,
          forceRefresh: forceRefresh,
        ),
        settlementsFuture,
      ]).then((parts) {
        final page = parts[0] as FinanceOrderPage;
        final settlements = parts[1] as List<Map<String, dynamic>>;
        onFirstPage(
          _b1BuildMemoized(
            orders: page.orders,
            settlements: settlements,
            scope: scope,
            currency: 'SAR',
            allowMemo: false,
          ),
        );
      });
    }

    final scanFuture = loadCompletedScan(
      datePreset: datePreset,
      forceRefresh: forceRefresh,
    );
    final settled = await Future.wait<Object>([scanFuture, settlementsFuture]);
    final orders = settled[0] as FinanceOrderScanResult;
    final settlements = settled[1] as List<Map<String, dynamic>>;
    return _b1BuildMemoized(
      orders: orders.orders,
      settlements: settlements,
      scope: scope,
      currency: 'SAR',
      allowMemo: true,
    );
  }

  FinanceReconciliationResult _b1BuildMemoized({
    required List<OrderRecord> orders,
    required List<Map<String, dynamic>> settlements,
    required AccountantFinanceScope scope,
    required String currency,
    required bool allowMemo,
  }) {
    final orderFp = orders.map((o) => o.reference.path).join(',');
    final setFp = settlements.map((m) => '${m['id']}').join(',');
    final key =
        'b1|${scope.includeAllCountries}|${scope.countryPaths.join(",")}|'
        '$currency|${orderFp.hashCode}|${setFp.hashCode}|${orders.length}|'
        '${settlements.length}';
    if (allowMemo && _b1MemoKey == key && _b1MemoResult != null) {
      AdminPerfTrace.financeRepoCacheHit(kind: 'b1_memo');
      return _b1MemoResult!;
    }
    final sw = Stopwatch()..start();
    final result = FinanceReconciliationReadModel.buildReconciliation(
      orders: orders,
      scope: scope,
      currency: currency,
      settlements: settlements,
    );
    sw.stop();
    AdminPerfTrace.financeClassificationMs(sw.elapsedMilliseconds);
    if (allowMemo) {
      _b1MemoKey = key;
      _b1MemoResult = result;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Display labels (presentation only)
  // ---------------------------------------------------------------------------

  String cachedLabel(String key, String Function() resolve) {
    final hit = _labelCache[key];
    if (hit != null && !hit.isExpired(labelTtl)) {
      _labelCache.remove(key);
      _labelCache[key] = hit;
      return hit.value;
    }
    final v = resolve();
    _labelCache.remove(key);
    _labelCache[key] = _CacheEntry(v, DateTime.now());
    while (_labelCache.length > maxLabelEntries) {
      _labelCache.remove(_labelCache.keys.first);
    }
    return v;
  }

  // ---------------------------------------------------------------------------
  // Trip rows helper (same as loader)
  // ---------------------------------------------------------------------------

  static List<AccountantTripRow> _tripsFromOrders(
    List<OrderRecord> orders, {
    required AccountantFinanceScope scope,
    required String symbol,
  }) {
    final trips = <AccountantTripRow>[];
    for (final o in orders) {
      if (FinancialTripSemantics.isFinanceQaFixture(o) ||
          AdminQaFixture.isFixtureOrder(o)) {
        continue;
      }
      if (!scope.allowsCountry(o.revDolh?.path)) continue;
      if (AdminRoleService.usesCountryFinanceScope) {
        if (AdminCountryScope.filterOrders([o]).isEmpty) continue;
      }
      final row = AccountantTripRow.fromOrder(o, symbol: symbol);
      if (!row.operationallyCompleted) continue;
      trips.add(row);
    }
    trips.sort((a, b) {
      final ad = a.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return trips;
  }
}

class _CacheEntry<T> {
  _CacheEntry(this.value, this.storedAt);
  final T value;
  final DateTime storedAt;
  bool isExpired(Duration ttl) =>
      DateTime.now().difference(storedAt) > ttl;
}

/// Scope helper extracted so repository does not circular-import loader API.
abstract final class AccountantFinanceLoaderScope {
  static AccountantFinanceScope scopeForCurrentUser({
    DocumentReference? countryOverride,
  }) {
    if (AdminRoleService.usesCountryFinanceScope) {
      final ref = AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
      final path = ref?.path;
      if (path == null || path.isEmpty) {
        return const AccountantFinanceScope(
          includeAllCountries: false,
          countryPaths: [],
        );
      }
      return AccountantFinanceScope(
        includeAllCountries: false,
        countryPaths: [path],
      );
    }
    if (countryOverride != null) {
      return AccountantFinanceScope(
        includeAllCountries: false,
        countryPaths: [countryOverride.path],
      );
    }
    return const AccountantFinanceScope(includeAllCountries: true);
  }
}

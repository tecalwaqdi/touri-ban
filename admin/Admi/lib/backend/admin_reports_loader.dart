import 'dart:async';

import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/backend/dashboard_stats_loader.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/finance/financial_engine.dart';

/// Country-scoped admin report for super-admin dashboard.
class AdminReportsSummary {
  const AdminReportsSummary({
    required this.landmarks,
    required this.partners,
    required this.regions,
    required this.cities,
    required this.appUsers,
    required this.agents,
    required this.representatives,
    required this.transportCompanies,
    required this.activeBookings,
    required this.totalBookings,
    required this.paidBookings,
    required this.totalSales,
    required this.supportTickets,
    required this.agentRows,
    required this.countryLabel,
    required this.loadedAt,
    this.loadComplete = true,
  });

  final int landmarks;
  final int partners;
  final int regions;
  final int cities;
  final int appUsers;
  final int agents;
  final int representatives;
  final int transportCompanies;
  final int activeBookings;
  final int totalBookings;
  final int paidBookings;
  final double totalSales;
  final int supportTickets;
  final List<AdminReportAgentRow> agentRows;
  final String countryLabel;
  final DateTime loadedAt;
  final bool loadComplete;

  static AdminReportsSummary empty({
    String countryLabel = 'جميع الدول',
    bool loadComplete = false,
  }) =>
      AdminReportsSummary(
        landmarks: 0,
        partners: 0,
        regions: 0,
        cities: 0,
        appUsers: 0,
        agents: 0,
        representatives: 0,
        transportCompanies: 0,
        activeBookings: 0,
        totalBookings: 0,
        paidBookings: 0,
        totalSales: 0,
        supportTickets: 0,
        agentRows: const [],
        countryLabel: countryLabel,
        loadedAt: DateTime.now(),
        loadComplete: loadComplete,
      );

  AdminReportsSummary copyWith({
    int? landmarks,
    int? partners,
    int? regions,
    int? cities,
    int? appUsers,
    int? agents,
    int? representatives,
    int? transportCompanies,
    int? activeBookings,
    int? totalBookings,
    int? paidBookings,
    double? totalSales,
    int? supportTickets,
    List<AdminReportAgentRow>? agentRows,
    String? countryLabel,
    DateTime? loadedAt,
    bool? loadComplete,
  }) {
    return AdminReportsSummary(
      landmarks: landmarks ?? this.landmarks,
      partners: partners ?? this.partners,
      regions: regions ?? this.regions,
      cities: cities ?? this.cities,
      appUsers: appUsers ?? this.appUsers,
      agents: agents ?? this.agents,
      representatives: representatives ?? this.representatives,
      transportCompanies: transportCompanies ?? this.transportCompanies,
      activeBookings: activeBookings ?? this.activeBookings,
      totalBookings: totalBookings ?? this.totalBookings,
      paidBookings: paidBookings ?? this.paidBookings,
      totalSales: totalSales ?? this.totalSales,
      supportTickets: supportTickets ?? this.supportTickets,
      agentRows: agentRows ?? this.agentRows,
      countryLabel: countryLabel ?? this.countryLabel,
      loadedAt: loadedAt ?? this.loadedAt,
      loadComplete: loadComplete ?? this.loadComplete,
    );
  }
}

class AdminReportAgentRow {
  const AdminReportAgentRow({
    required this.agent,
    required this.bookings,
    required this.sales,
  });

  final UserRecord agent;
  final int bookings;
  final double sales;
}

const _summaryTtl = Duration(minutes: 5);
const _countTimeout = Duration(seconds: 6);

final Map<String, _CachedSummary> _summaryCache = {};
final Map<String, int> _generationsByKey = {};

class _CachedSummary {
  _CachedSummary(this.summary, this.at);

  final AdminReportsSummary summary;
  final DateTime at;

  bool get isFresh => DateTime.now().difference(at) < _summaryTtl;
}

String _cacheKey(DocumentReference? countryRef, String countryLabel) =>
    countryRef?.path ?? 'all:$countryLabel';

/// Returns cached summary when available (even slightly stale) for instant UI.
AdminReportsSummary? peekAdminReportsSummary({
  DocumentReference? countryRef,
  String countryLabel = 'جميع الدول',
}) {
  final entry = _summaryCache[_cacheKey(countryRef, countryLabel)];
  return entry?.summary;
}

Future<int> _countQuery(Future<int> Function() load) async {
  try {
    return await load().timeout(_countTimeout);
  } catch (_) {
    return 0;
  }
}

({int paid, int active, double sales, int totalBookings, Map<String, int> bookingsByCountry, Map<String, double> salesByCountry})
    _orderStats(List<OrderRecord> orders) {
  var paid = 0;
  var active = 0;
  var sales = 0.0;
  final bookingsByCountry = <String, int>{};
  final salesByCountry = <String, double>{};

  for (final order in orders) {
    if (order.allnow) active++;
    final f = FinancialEngine.orderFinancials(order);
    if (f.isPaid) {
      paid++;
      sales += f.totalSales;
    }
    final countryPath = order.revDolh?.path;
    if (countryPath != null) {
      bookingsByCountry[countryPath] =
          (bookingsByCountry[countryPath] ?? 0) + 1;
      if (f.isPaid) {
        salesByCountry[countryPath] =
            (salesByCountry[countryPath] ?? 0) + f.totalSales;
      }
    }
  }

  return (
    paid: paid,
    active: active,
    sales: sales,
    totalBookings: orders.length,
    bookingsByCountry: bookingsByCountry,
    salesByCountry: salesByCountry,
  );
}

List<AdminReportAgentRow> _agentRows(
  List<UserRecord> agents,
  Map<String, int> bookingsByCountry,
  Map<String, double> salesByCountry,
) {
  return agents
      .map(
        (agent) => AdminReportAgentRow(
          agent: agent,
          bookings: bookingsByCountry[agent.revDlohAgent?.path ?? ''] ?? 0,
          sales: salesByCountry[agent.revDlohAgent?.path ?? ''] ?? 0,
        ),
      )
      .toList(growable: false);
}

Future<List<OrderRecord>> _loadAllOrders(DocumentReference? countryRef) async {
  final results = <OrderRecord>[];
  DocumentSnapshot? last;

  while (true) {
    final batch = AdminCountryScope.filterOrders(
      await queryOrderRecordOnce(
        queryBuilder: (q) {
          var query = AdminCountryScope.applyOrderQuery(q)
              .orderBy('data_order', descending: true);
          if (countryRef != null) {
            query = query.where('Rev_dolh', isEqualTo: countryRef);
          }
          if (last != null) {
            query = query.startAfterDocument(last);
          }
          return query;
        },
        limit: kAdminPageSize,
      ),
    );
    if (batch.isEmpty) break;
    results.addAll(batch);
    last = await batch.last.reference.get();
    if (batch.length < kAdminPageSize) break;
    if (results.length >= kAdminMaxPages * kAdminPageSize) break;
  }
  return results;
}

Future<({List<UserRecord> agents, List<OrderRecord> orders})> _loadCoreData(
  DocumentReference? countryRef,
) async {
  final agents = await queryUserRecordOnce(
    queryBuilder: (q) {
      var query = q.where('Isagent', isEqualTo: true);
      if (countryRef != null) {
        query = query.where('Rev_dloh_agent', isEqualTo: countryRef);
      }
      return query.orderBy(FieldPath.documentId);
    },
    limit: 100,
  );

  List<OrderRecord> orders;
  orders = await _loadAllOrders(countryRef);

  return (agents: agents, orders: orders);
}

AdminReportsSummary _partialFromCore({
  required DocumentReference? countryRef,
  required String countryLabel,
  required List<UserRecord> agents,
  required List<OrderRecord> orders,
}) {
  final stats = _orderStats(orders);
  return AdminReportsSummary(
    landmarks: 0,
    partners: 0,
    regions: 0,
    cities: 0,
    appUsers: 0,
    agents: agents.length,
    representatives: 0,
    transportCompanies: 0,
    activeBookings: 0,
    totalBookings: stats.totalBookings,
    paidBookings: stats.paid,
    totalSales: stats.sales,
    supportTickets: 0,
    agentRows: _agentRows(
      agents,
      stats.bookingsByCountry,
      stats.salesByCountry,
    ),
    countryLabel: countryLabel,
    loadedAt: DateTime.now(),
    loadComplete: false,
  );
}

Future<AdminReportsSummary> _loadCounts({
  required DocumentReference? countryRef,
  required AdminReportsSummary partial,
  void Function(AdminReportsSummary summary)? onProgress,
}) async {
  final counts = <String, int>{};

  AdminReportsSummary merge() => partial.copyWith(
        landmarks: counts['landmarks'] ?? partial.landmarks,
        partners: counts['partners'] ?? partial.partners,
        regions: counts['regions'] ?? partial.regions,
        cities: counts['cities'] ?? partial.cities,
        appUsers: counts['appUsers'] ?? partial.appUsers,
        agents: counts['agents'] ?? partial.agents,
        representatives: counts['representatives'] ?? partial.representatives,
        transportCompanies:
            counts['transportCompanies'] ?? partial.transportCompanies,
        activeBookings: counts['activeBookings'] ?? partial.activeBookings,
        totalBookings: counts['totalBookings'] ?? partial.totalBookings,
        paidBookings: counts['paidBookings'] ?? partial.paidBookings,
        totalSales: counts['totalSales'] != null
            ? (counts['totalSales'] as num).toDouble()
            : partial.totalSales,
        supportTickets: counts['supportTickets'] ?? partial.supportTickets,
        loadedAt: DateTime.now(),
      );

  Future<void> applyCount(String key, Future<int> Function() load) async {
    counts[key] = await _countQuery(load);
    onProgress?.call(merge());
  }

  if (countryRef == null) {
    await _countInBatches([
      () => applyCount('landmarks', () => queryMkanRecordCount()),
      () => applyCount(
        'partners',
        () => queryMkanRecordCount(
          queryBuilder: (q) =>
              (q as Query<Map<String, dynamic>>).where('isShrek', isEqualTo: true),
        ),
      ),
      () => applyCount('regions', () => queryCitiesRecordCount()),
      () => applyCount('cities', () => queryVillagesRecordCount()),
      () => applyCount('appUsers', queryAppUserCount),
      () => applyCount(
        'activeBookings',
        () => queryOrderRecordCount(
          queryBuilder: (q) => q.where('ALLNOW', isEqualTo: true),
        ),
      ),
      () => applyCount(
        'agents',
        () => queryUserRecordCount(
          queryBuilder: (q) => q.where('Isagent', isEqualTo: true),
        ),
      ),
      () => applyCount(
        'representatives',
        () => queryUserRecordCount(
          queryBuilder: (q) => q.where('ismndob', isEqualTo: true),
        ),
      ),
      () => applyCount('transportCompanies', () => queryTransportCompanyRecordCount()),
      () => applyCount('supportTickets', () => querySupportRecordCount()),
    ]);
  } else {
    await _countInBatches([
      () => applyCount(
        'landmarks',
        () => queryMkanRecordCount(
          queryBuilder: (collection) {
            var q = collection as Query<Map<String, dynamic>>;
            return q.where('Rev_dolh', isEqualTo: countryRef);
          },
        ),
      ),
      () => applyCount(
        'partners',
        () => queryMkanRecordCount(
          queryBuilder: (collection) {
            var q = collection as Query<Map<String, dynamic>>;
            return q
                .where('Rev_dolh', isEqualTo: countryRef)
                .where('isShrek', isEqualTo: true);
          },
        ),
      ),
      () => applyCount(
        'regions',
        () => queryCitiesRecordCount(
          queryBuilder: (q) => q.where('dolh', isEqualTo: countryRef),
        ),
      ),
      () => applyCount(
        'cities',
        () => queryVillagesRecordCount(
          queryBuilder: (q) => q.where('dolh', isEqualTo: countryRef),
        ),
      ),
      () => applyCount(
        'appUsers',
        () => queryScopedAppUserCount(countryRef),
      ),
      () => applyCount(
        'agents',
        () => queryUserRecordCount(
          queryBuilder: (q) => q
              .where('Isagent', isEqualTo: true)
              .where('Rev_dloh_agent', isEqualTo: countryRef),
        ),
      ),
      () => applyCount(
        'activeBookings',
        () => queryOrderRecordCount(
          queryBuilder: (q) => q
              .where('ALLNOW', isEqualTo: true)
              .where('Rev_dolh', isEqualTo: countryRef),
        ),
      ),
      () => applyCount(
        'representatives',
        () => queryUserRecordCount(
          queryBuilder: (q) => q
              .where('ismndob', isEqualTo: true)
              .where('Rev_dolh', isEqualTo: countryRef),
        ),
      ),
      () => applyCount(
        'transportCompanies',
        () => queryTransportCompanyRecordCount(
          queryBuilder: (q) => q.where('Rev_dolh', isEqualTo: countryRef),
        ),
      ),
      () => applyCount(
        'supportTickets',
        () => querySupportRecordCount(
          queryBuilder: (q) => q.where('Rev_dolh', isEqualTo: countryRef),
        ),
      ),
    ]);
  }

  return merge().copyWith(loadComplete: true, loadedAt: DateTime.now());
}

Future<void> _countInBatches(List<Future<void> Function()> tasks) async {
  const batchSize = 3;
  for (var i = 0; i < tasks.length; i += batchSize) {
    final end = i + batchSize > tasks.length ? tasks.length : i + batchSize;
    await Future.wait(tasks.sublist(i, end).map((task) => task()));
  }
}

int _nextGeneration(String key) =>
    _generationsByKey[key] = (_generationsByKey[key] ?? 0) + 1;

bool _isCurrentGeneration(String key, int generation) =>
    _generationsByKey[key] == generation;

/// Fast path: returns cached summary if fresh.
Future<AdminReportsSummary> loadAdminReportsSummary({
  DocumentReference? countryRef,
  String countryLabel = 'جميع الدول',
}) async {
  final key = _cacheKey(countryRef, countryLabel);
  final cached = _summaryCache[key];
  if (cached != null && cached.isFresh && cached.summary.loadComplete) {
    return cached.summary;
  }

  final generation = _nextGeneration(key);
  final core = await _loadCoreData(countryRef);
  if (!_isCurrentGeneration(key, generation)) {
    return cached?.summary ??
        AdminReportsSummary.empty(countryLabel: countryLabel);
  }

  final partial = _partialFromCore(
    countryRef: countryRef,
    countryLabel: countryLabel,
    agents: core.agents,
    orders: core.orders,
  );

  final full = await _loadCounts(countryRef: countryRef, partial: partial);
  if (!_isCurrentGeneration(key, generation)) {
    return cached?.summary ?? partial;
  }

  _summaryCache[key] = _CachedSummary(full, DateTime.now());
  return full;
}

/// Two-phase load: [onPartial] fires quickly, [onComplete] when counts finish.
Future<void> loadAdminReportsSummaryProgressive({
  DocumentReference? countryRef,
  String countryLabel = 'جميع الدول',
  required void Function(AdminReportsSummary summary) onPartial,
  required void Function(AdminReportsSummary summary) onComplete,
}) async {
  final key = _cacheKey(countryRef, countryLabel);
  final cached = _summaryCache[key];

  if (cached != null && cached.isFresh && cached.summary.loadComplete) {
    onPartial(cached.summary);
    onComplete(cached.summary);
    return;
  }

  final generation = _nextGeneration(key);

  if (cached != null && cached.isFresh && !cached.summary.loadComplete) {
    onPartial(cached.summary);
  } else if (cached != null && !cached.isFresh) {
    onPartial(cached.summary);
  }

  try {
    final core = await _loadCoreData(countryRef);
    if (!_isCurrentGeneration(key, generation)) return;

    final partial = _partialFromCore(
      countryRef: countryRef,
      countryLabel: countryLabel,
      agents: core.agents,
      orders: core.orders,
    );
    _summaryCache[key] = _CachedSummary(partial, DateTime.now());
    onPartial(partial);

    final full = await _loadCounts(
      countryRef: countryRef,
      partial: partial,
      onProgress: (progress) {
        if (!_isCurrentGeneration(key, generation)) return;
        _summaryCache[key] = _CachedSummary(progress, DateTime.now());
        onPartial(progress);
      },
    );
    if (!_isCurrentGeneration(key, generation)) return;

    _summaryCache[key] = _CachedSummary(full, DateTime.now());
    onComplete(full);
  } catch (_) {
    if (!_isCurrentGeneration(key, generation)) return;
    final fallback = cached?.summary ??
        AdminReportsSummary.empty(countryLabel: countryLabel);
    onPartial(fallback);
    onComplete(fallback.copyWith(loadComplete: true));
  }
}

/// Warm reports cache in background for super-admin.
void scheduleAdminReportsWarmup() {
  // Disabled — background warmup competed with the reports screen and caused
  // cancelled loads / empty UI on mobile.
}

/// Clears cached report summaries (e.g. on logout).
void clearAdminReportsSummaryCache() {
  _summaryCache.clear();
  _generationsByKey.clear();
}

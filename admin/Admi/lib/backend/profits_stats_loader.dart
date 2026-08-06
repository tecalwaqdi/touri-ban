import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/finance/financial_engine.dart';

/// Time window for profits dashboard filters.
enum ProfitsPeriod {
  today,
  week,
  month,
  year,
  all,
}

extension ProfitsPeriodLabel on ProfitsPeriod {
  String get arabicLabel => switch (this) {
        ProfitsPeriod.today => 'اليوم',
        ProfitsPeriod.week => '7 أيام',
        ProfitsPeriod.month => 'هذا الشهر',
        ProfitsPeriod.year => 'هذه السنة',
        ProfitsPeriod.all => 'الكل',
      };
}

/// One bar in the monthly revenue chart.
class ProfitsMonthlyPoint {
  const ProfitsMonthlyPoint({
    required this.month,
    required this.label,
    required this.sales,
    required this.appProfit,
    required this.orderCount,
  });

  final DateTime month;
  final String label;
  final double sales;
  final double appProfit;
  final int orderCount;
}

/// Recent order row for the transactions list.
class ProfitsOrderRow {
  const ProfitsOrderRow({required this.order});

  final OrderRecord order;
}

/// Aggregated profits metrics from Firestore orders.
class ProfitsSummary {
  const ProfitsSummary({
    required this.totalSales,
    required this.appProfit,
    required this.vat,
    required this.repCommission,
    required this.deliveryFees,
    required this.orderCount,
    required this.paidCount,
    required this.pendingCount,
    required this.canceledCount,
    required this.monthlyTrend,
    required this.recentOrders,
    required this.period,
    required this.loadedAt,
  });

  final double totalSales;
  final double appProfit;
  final double vat;
  final double repCommission;
  final double deliveryFees;
  final int orderCount;
  final int paidCount;
  final int pendingCount;
  final int canceledCount;
  final List<ProfitsMonthlyPoint> monthlyTrend;
  final List<ProfitsOrderRow> recentOrders;
  final ProfitsPeriod period;
  final DateTime loadedAt;

  double get platformFees => appProfit + vat;

  double get partnerPayouts => repCommission + deliveryFees;

  bool get isExpired =>
      DateTime.now().difference(loadedAt) > const Duration(minutes: 3);
}

DateTime? _periodStart(ProfitsPeriod period) {
  final now = DateTime.now();
  return switch (period) {
    ProfitsPeriod.today => DateTime(now.year, now.month, now.day),
    ProfitsPeriod.week => now.subtract(const Duration(days: 7)),
    ProfitsPeriod.month => DateTime(now.year, now.month, 1),
    ProfitsPeriod.year => DateTime(now.year, 1, 1),
    ProfitsPeriod.all => null,
  };
}

String _monthLabel(DateTime month) {
  const labels = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return labels[month.month - 1];
}

List<ProfitsMonthlyPoint> _buildMonthlyTrend(List<OrderRecord> orders) {
  final now = DateTime.now();
  final months = List.generate(6, (i) {
    final m = DateTime(now.year, now.month - (5 - i), 1);
    return DateTime(m.year, m.month, 1);
  });

  return months.map((monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    var sales = 0.0;
    var appProfit = 0.0;
    var count = 0;

    for (final order in orders) {
      if (!OrderStatusHelper.countsTowardRevenue(order)) continue;
      final date = order.dataOrder;
      if (date == null) continue;
      if (!date.isBefore(monthEnd) || date.isBefore(monthStart)) continue;
      count++;
      final f = FinancialEngine.orderFinancials(order);
      sales += f.totalSales;
      appProfit += f.appProfit;
    }

    return ProfitsMonthlyPoint(
      month: monthStart,
      label: _monthLabel(monthStart),
      sales: sales,
      appProfit: appProfit,
      orderCount: count,
    );
  }).toList();
}

Future<List<OrderRecord>> _loadOrdersPage({
  DateTime? start,
  int maxDocs = 300,
}) async {
  final results = <OrderRecord>[];
  DocumentSnapshot? last;
  final pageLimit = kAdminPageSize;

  while (results.length < maxDocs) {
    var query = AdminCountryScope.applyOrderQuery(OrderRecord.collection)
        .orderBy('data_order', descending: true);
    if (start != null) {
      query = query.where('data_order', isGreaterThanOrEqualTo: start);
    }
    if (last != null) {
      query = query.startAfterDocument(last);
    }

    final snap = await getQuerySnapshotFast(query.limit(pageLimit));
    if (snap.docs.isEmpty) break;

    final batch = AdminCountryScope.filterOrders(
      mapQuerySnapshot(snap, OrderRecord.fromSnapshot),
    );
    if (batch.isEmpty) break;
    results.addAll(batch);
    last = snap.docs.last;
    if (snap.docs.length < pageLimit) break;
  }

  if (results.length > maxDocs) {
    return results.sublist(0, maxDocs);
  }
  return results;
}

/// Loads profits via server aggregation with paginated client fallback.
Future<ProfitsSummary> loadProfitsStats({
  ProfitsPeriod period = ProfitsPeriod.month,
}) async {
  final start = _periodStart(period);
  final countryRef = AdminCountryScope.activeCountryRef;

  try {
    final remote = await CloudFunctionsClient.aggregateFinancialSummary(
      countryPath: countryRef?.path,
      periodStart: start,
    );
    // Remote totals are authoritative — only fetch a slim sample for charts/rows.
    final sample = await _loadOrdersPage(start: start, maxDocs: 80);
    final totals = FinancialEngine.aggregate(sample);

    return ProfitsSummary(
      totalSales: (remote['totalSales'] as num?)?.toDouble() ?? totals.totalSales,
      appProfit: (remote['appProfit'] as num?)?.toDouble() ?? totals.appProfit,
      vat: (remote['vat'] as num?)?.toDouble() ?? totals.vat,
      repCommission:
          (remote['repCommission'] as num?)?.toDouble() ?? totals.repCommission,
      deliveryFees:
          (remote['deliveryFees'] as num?)?.toDouble() ?? totals.deliveryFees,
      orderCount: (remote['orderCount'] as int?) ?? totals.activeOrderCount,
      paidCount: (remote['paidCount'] as int?) ?? totals.paidCount,
      pendingCount: (remote['pendingCount'] as int?) ?? totals.pendingCount,
      canceledCount: (remote['canceledCount'] as int?) ?? totals.canceledCount,
      monthlyTrend: _buildMonthlyTrend(sample),
      recentOrders: sample
          .where(OrderStatusHelper.countsTowardRevenue)
          .take(12)
          .map((o) => ProfitsOrderRow(order: o))
          .toList(),
      period: period,
      loadedAt: DateTime.now(),
    );
  } catch (_) {
    final orders = await _loadOrdersPage(start: start, maxDocs: 400);
    final totals = FinancialEngine.aggregate(orders);

    return ProfitsSummary(
      totalSales: totals.totalSales,
      appProfit: totals.appProfit,
      vat: totals.vat,
      repCommission: totals.repCommission,
      deliveryFees: totals.deliveryFees,
      orderCount: totals.activeOrderCount,
      paidCount: totals.paidCount,
      pendingCount: totals.pendingCount,
      canceledCount: totals.canceledCount,
      monthlyTrend: _buildMonthlyTrend(orders),
      recentOrders: orders
          .where(OrderStatusHelper.countsTowardRevenue)
          .take(12)
          .map((o) => ProfitsOrderRow(order: o))
          .toList(),
      period: period,
      loadedAt: DateTime.now(),
    );
  }
}

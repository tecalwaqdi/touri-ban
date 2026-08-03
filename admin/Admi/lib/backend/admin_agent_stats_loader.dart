import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/core/finance/financial_engine.dart';

/// Booking metrics for an agent's country scope (from Firestore `order`).
class AgentReportStats {
  const AgentReportStats({
    required this.totalBookings,
    required this.activeBookings,
    required this.paidBookings,
    required this.completionRate,
    required this.totalSales,
    required this.commissionEarned,
    required this.recentOrders,
  });

  final int totalBookings;
  final int activeBookings;
  final int paidBookings;
  final double completionRate;
  final double totalSales;
  final double commissionEarned;
  final List<OrderRecord> recentOrders;

  static const empty = AgentReportStats(
    totalBookings: 0,
    activeBookings: 0,
    paidBookings: 0,
    completionRate: 0,
    totalSales: 0,
    commissionEarned: 0,
    recentOrders: [],
  );
}

String orderDisplayTitle(OrderRecord order) {
  if (order.cartext.isNotEmpty) return order.cartext;
  if (order.villText.isNotEmpty) return order.villText;
  if (order.iDorder.isNotEmpty) return order.iDorder;
  if (order.naimUserText.isNotEmpty) return order.naimUserText;
  return 'حجز';
}

Future<List<OrderRecord>> _loadAgentOrders(DocumentReference countryRef) async {
  final results = <OrderRecord>[];
  DocumentSnapshot? last;

  while (true) {
    final batch = await queryOrderRecordOnce(
      queryBuilder: (q) {
        var query = AdminCountryScope.applyOrderQuery(q)
            .where('Rev_dolh', isEqualTo: countryRef)
            .orderBy('data_order', descending: true);
        if (last != null) query = query.startAfterDocument(last);
        return query;
      },
      limit: kAdminPageSize,
    );
    if (batch.isEmpty) break;
    results.addAll(batch);
    last = await batch.last.reference.get();
    if (batch.length < kAdminPageSize) break;
    if (results.length >= kAdminMaxPages * kAdminPageSize) break;
  }
  return results;
}

/// Loads agent performance from orders in the agent's country (`Rev_dolh`).
Future<AgentReportStats> loadAgentReportStats(UserRecord agent) async {
  final countryRef = agent.revDlohAgent;
  if (countryRef == null) {
    return AgentReportStats.empty;
  }

  final orders = await _loadAgentOrders(countryRef);
  final totals = FinancialEngine.aggregate(orders);

  var activeBookings = 0;
  for (final order in orders) {
    if (order.allnow) activeBookings++;
  }

  final decided = totals.paidCount + totals.canceledCount;
  final completionRate =
      decided == 0 ? 0.0 : (totals.paidCount / decided) * 100.0;

  final commissionPercent = agent.agentTotal;
  final commissionEarned = commissionPercent > 0
      ? FinancialEngine.calculateProfit(orders) * commissionPercent / 100.0
      : 0.0;

  return AgentReportStats(
    totalBookings: orders.length,
    activeBookings: activeBookings,
    paidBookings: totals.paidCount,
    completionRate: completionRate,
    totalSales: totals.totalSales,
    commissionEarned: commissionEarned,
    recentOrders: orders.take(10).toList(),
  );
}

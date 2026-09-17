import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/core/finance/financial_engine.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/financial_accounting_engine.dart';

/// Booking metrics for an agent's country scope (from Firestore `order`).
///
/// Money fields use [FinancialAccountingEngine] persisted majors / FIN-9
/// agent snapshots — never a live commission rate inventing historical fees.
class AgentReportStats {
  const AgentReportStats({
    required this.totalBookings,
    required this.activeBookings,
    required this.paidBookings,
    required this.completionRate,
    required this.totalSales,
    required this.commissionEarned,
    required this.recentOrders,
    this.salesAvailable = true,
    this.commissionAvailable = true,
  });

  final int totalBookings;
  final int activeBookings;
  final int paidBookings;
  final double completionRate;
  final double totalSales;
  final double commissionEarned;
  final List<OrderRecord> recentOrders;

  /// False when no paid trip had a provable customer/gross amount.
  final bool salesAvailable;

  /// False when agent share could not be proven from snapshots / platform fee.
  final bool commissionAvailable;

  static const empty = AgentReportStats(
    totalBookings: 0,
    activeBookings: 0,
    paidBookings: 0,
    completionRate: 0,
    totalSales: 0,
    commissionEarned: 0,
    recentOrders: [],
    salesAvailable: true,
    commissionAvailable: true,
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
  var activeBookings = 0;
  var paidBookings = 0;
  var canceled = 0;
  var sales = 0.0;
  var salesHits = 0;
  var commission = 0.0;
  var commissionHits = 0;
  final agentId = agent.reference.id;
  final agentRate = agent.agentTotal;

  for (final order in orders) {
    if (order.allnow) activeBookings++;
    if (OrderStatusHelper.isCanceled(order)) {
      canceled++;
      continue;
    }
    if (!OrderStatusHelper.isPaid(order)) continue;
    paidBookings++;

    final snap = FinancialOrderAdapter.fromOrder(order);
    final line = FinancialAccountingEngine.analyze(snap);
    final paidMajor = line.customerPaid?.majorUnits ?? line.grossBase?.majorUnits;
    if (paidMajor != null) {
      sales += paidMajor;
      salesHits++;
    }

    // Prefer FIN-9 snapshotted agent amount when this agent owns the snapshot.
    if (line.agentId == agentId &&
        line.hasProvableAgentSnapshot &&
        line.agentAmount != null) {
      commission += line.agentAmount!.majorUnits;
      commissionHits++;
      continue;
    }

    // Fallback: Agent_total % of persisted platform fee (not of gross).
    final platform = line.platformFee?.majorUnits;
    if (platform != null && agentRate > 0) {
      commission += platform * agentRate / 100.0;
      commissionHits++;
    }
  }

  final decided = paidBookings + canceled;
  final completionRate =
      decided == 0 ? 0.0 : (paidBookings / decided) * 100.0;

  return AgentReportStats(
    totalBookings: orders.length,
    activeBookings: activeBookings,
    paidBookings: paidBookings,
    completionRate: completionRate,
    totalSales: sales,
    commissionEarned: commission,
    recentOrders: orders.take(10).toList(),
    salesAvailable: paidBookings == 0 || salesHits > 0,
    commissionAvailable: paidBookings == 0 || commissionHits > 0,
  );
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/schema/order_record.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/finance/finance_runtime_gate.dart';
import '/core/finance/financial_engine.dart';

/// Aggregated finance snapshot for the Enterprise Finance Hub.
class FinanceHubSnapshot {
  const FinanceHubSnapshot({
    required this.revenue,
    required this.appProfit,
    required this.commissions,
    required this.pendingSettlements,
    required this.paidOrders,
    required this.pendingOrders,
    required this.canceledOrders,
    required this.driverBalances,
    required this.companyBalances,
    required this.agentBalances,
    required this.ledger,
    required this.periodLabel,
    this.isApproximate = false,
  });

  final double revenue;
  final double appProfit;
  final double commissions;
  final double pendingSettlements;
  final int paidOrders;
  final int pendingOrders;
  final int canceledOrders;
  final Map<String, double> driverBalances;
  final Map<String, double> companyBalances;
  final Map<String, double> agentBalances;
  final List<FinanceLedgerEntry> ledger;
  final String periodLabel;

  /// True when KPIs came from a client sample fallback (not CF aggregates).
  final bool isApproximate;
}

class FinanceLedgerEntry {
  const FinanceLedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.partyLabel,
    required this.createdAt,
    required this.orderPath,
    required this.note,
  });

  final String id;
  final String type;
  final double amount;
  final String partyLabel;
  final DateTime? createdAt;
  final String orderPath;
  final String note;
}

/// Builds finance hub views from server aggregates + real wallet/ledger docs.
abstract final class FinanceLedgerService {
  FinanceLedgerService._();

  static Future<FinanceHubSnapshot> load({
    required DateTime from,
    required DateTime to,
    String periodLabel = '',
  }) async {
    Map<String, dynamic>? remote;
    try {
      remote = await CloudFunctionsClient.aggregateFinancialSummary(
        countryPath: AdminCountryScope.activeCountryRef?.path,
        periodStart: from,
      );
    } catch (_) {
      remote = null;
    }

    final driverBal = await _loadWalletBalances();
    final ledger = await _loadTransactionLedger();

    if (remote != null) {
      FinanceRuntimeGate.setAuthoritativeBackendData(true);
      return FinanceHubSnapshot(
        revenue: (remote['totalSales'] as num?)?.toDouble() ?? 0,
        appProfit: (remote['appProfit'] as num?)?.toDouble() ?? 0,
        commissions: (remote['repCommission'] as num?)?.toDouble() ?? 0,
        pendingSettlements:
            (remote['pendingSettlements'] as num?)?.toDouble() ?? 0,
        // Cloud Functions may return doubles (e.g. 67.5); never cast with `as int`.
        paidOrders: (remote['paidCount'] as num?)?.round() ?? 0,
        pendingOrders: (remote['pendingCount'] as num?)?.round() ?? 0,
        canceledOrders: (remote['canceledCount'] as num?)?.round() ?? 0,
        driverBalances: driverBal,
        companyBalances: const {},
        agentBalances: const {},
        ledger: ledger,
        periodLabel: periodLabel,
        isApproximate: false,
      );
    }

    // Fallback: limited client sample — marked approximate in UI.
    FinanceRuntimeGate.setAuthoritativeBackendData(false);
    return _loadApproximateFromOrders(
      from: from,
      to: to,
      periodLabel: periodLabel,
      driverBalances: driverBal,
      ledger: ledger,
    );
  }

  static Future<Map<String, double>> _loadWalletBalances() async {
    final out = <String, double>{};
    try {
      final snap =
          await FirebaseFirestore.instance.collection('wallets').limit(200).get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final bal = (d['currentBalance'] as num?)?.toDouble() ?? 0;
        final uid = (d['userRef'] is DocumentReference)
            ? (d['userRef'] as DocumentReference).id
            : (d['driverId'] ?? doc.id).toString();
        out[uid] = bal;
      }
    } catch (_) {}
    return out;
  }

  static Future<List<FinanceLedgerEntry>> _loadTransactionLedger() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(80)
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        final uid = (d['userRef'] is DocumentReference)
            ? (d['userRef'] as DocumentReference).id
            : (d['driverId'] ?? '—').toString();
        DateTime? at;
        final created = d['createdAt'];
        if (created is Timestamp) at = created.toDate();
        return FinanceLedgerEntry(
          id: doc.id,
          type: (d['type'] ?? 'tx').toString(),
          amount: (d['amount'] as num?)?.toDouble() ?? 0,
          partyLabel: uid,
          createdAt: at,
          orderPath: (d['orderRef'] is DocumentReference)
              ? (d['orderRef'] as DocumentReference).path
              : '',
          note: (d['notes'] ?? d['description_code'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<FinanceHubSnapshot> _loadApproximateFromOrders({
    required DateTime from,
    required DateTime to,
    required String periodLabel,
    required Map<String, double> driverBalances,
    required List<FinanceLedgerEntry> ledger,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await FirebaseFirestore.instance
          .collection('order')
          .orderBy('data_order', descending: true)
          .limit(120)
          .get();
    } catch (_) {
      snap = await FirebaseFirestore.instance.collection('order').limit(80).get();
    }

    final country = AdminCountryScope.activeCountryRef;
    final orders = snap.docs
        .map((d) => OrderRecord.fromSnapshot(d))
        .where((o) {
          final t = o.dataOrder;
          if (t == null) return true;
          return !t.isBefore(from) && !t.isAfter(to);
        })
        .where((o) {
          if (country == null) return true;
          if (!AdminRoleService.isCountryAgent &&
              !AdminCountryScope.hasActiveCountryScope) {
            return true;
          }
          final rev = o.snapshotData['Rev_dolh'];
          if (rev is DocumentReference) return rev.path == country.path;
          return true;
        })
        .toList();

    double revenue = 0;
    double appProfit = 0;
    double commissions = 0;
    double pending = 0;
    var paid = 0;
    var pendingCount = 0;
    var canceled = 0;
    final fallbackLedger = <FinanceLedgerEntry>[...ledger];

    for (final order in orders) {
      final econ = FinancialEngine.orderFinancials(order);
      if (OrderStatusHelper.isCanceled(order)) {
        canceled++;
        continue;
      }
      if (OrderStatusHelper.isPaid(order)) {
        paid++;
        revenue += econ.totalSales;
        appProfit += econ.appProfit;
        commissions += econ.repCommission;
        if (fallbackLedger.length < 80) {
          fallbackLedger.add(
            FinanceLedgerEntry(
              id: order.reference.id,
              type: 'revenue',
              amount: econ.totalSales,
              partyLabel: order.mndobUser?.id ?? order.reference.id,
              createdAt: order.dataOrder,
              orderPath: order.reference.path,
              note: 'ent_ledger_revenue',
            ),
          );
        }
      } else if (OrderStatusHelper.isPending(order)) {
        pendingCount++;
        pending += econ.totalSales > 0
            ? econ.totalSales
            : order.total.toDouble();
      }
    }

    return FinanceHubSnapshot(
      revenue: revenue,
      appProfit: appProfit,
      commissions: commissions,
      pendingSettlements: pending,
      paidOrders: paid,
      pendingOrders: pendingCount,
      canceledOrders: canceled,
      driverBalances: driverBalances,
      companyBalances: const {},
      agentBalances: const {},
      ledger: fallbackLedger,
      periodLabel: periodLabel,
      isApproximate: true,
    );
  }
}

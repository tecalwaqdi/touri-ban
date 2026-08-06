import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/schema/order_record.dart';
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

/// Builds ledger-style finance views from existing order economics.
abstract final class FinanceLedgerService {
  FinanceLedgerService._();

  static Future<FinanceHubSnapshot> load({
    required DateTime from,
    required DateTime to,
    String periodLabel = '',
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
    final driverBal = <String, double>{};
    final companyBal = <String, double>{};
    final agentBal = <String, double>{};
    final ledger = <FinanceLedgerEntry>[];

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
        final driverKey = order.mndobUser?.id ??
            (order.snapshotData['mndob_user'] is DocumentReference
                ? (order.snapshotData['mndob_user'] as DocumentReference).id
                : 'unknown');
        driverBal[driverKey] =
            (driverBal[driverKey] ?? 0) + econ.repCommission;

        final companyPath =
            (order.snapshotData['transport_company'] as DocumentReference?)
                    ?.path ??
                '';
        if (companyPath.isNotEmpty) {
          companyBal[companyPath] =
              (companyBal[companyPath] ?? 0) + (econ.repCommission * 0.1);
        }

        final agentPath =
            (order.snapshotData['Rev_dloh_agent'] as DocumentReference?)
                    ?.path ??
                (order.snapshotData['agent_ref'] as DocumentReference?)?.path ??
                '';
        if (agentPath.isNotEmpty) {
          agentBal[agentPath] =
              (agentBal[agentPath] ?? 0) + (econ.appProfit * 0.05);
        }

        ledger.add(
          FinanceLedgerEntry(
            id: order.reference.id,
            type: 'revenue',
            amount: econ.totalSales,
            partyLabel: driverKey,
            createdAt: order.dataOrder,
            orderPath: order.reference.path,
            note: 'ent_ledger_revenue',
          ),
        );
        ledger.add(
          FinanceLedgerEntry(
            id: '${order.reference.id}_comm',
            type: 'commission',
            amount: econ.repCommission,
            partyLabel: driverKey,
            createdAt: order.dataOrder,
            orderPath: order.reference.path,
            note: 'ent_ledger_commission',
          ),
        );
      } else if (OrderStatusHelper.isPending(order)) {
        pendingCount++;
        pending += econ.totalSales > 0
            ? econ.totalSales
            : order.total.toDouble();
        ledger.add(
          FinanceLedgerEntry(
            id: '${order.reference.id}_pending',
            type: 'pending',
            amount: order.total.toDouble(),
            partyLabel: order.reference.id,
            createdAt: order.dataOrder,
            orderPath: order.reference.path,
            note: 'ent_ledger_pending',
          ),
        );
      }
    }

    await _ensureInvoices(orders);

    return FinanceHubSnapshot(
      revenue: revenue,
      appProfit: appProfit,
      commissions: commissions,
      pendingSettlements: pending,
      paidOrders: paid,
      pendingOrders: pendingCount,
      canceledOrders: canceled,
      driverBalances: driverBal,
      companyBalances: companyBal,
      agentBalances: agentBal,
      ledger: ledger,
      periodLabel: periodLabel,
    );
  }

  static Future<void> _ensureInvoices(List<OrderRecord> orders) async {
    final batch = FirebaseFirestore.instance.batch();
    var writes = 0;
    for (final order in orders) {
      if (!OrderStatusHelper.isPaid(order)) continue;
      final invRef = FirebaseFirestore.instance
          .collection('finance_invoices')
          .doc(order.reference.id);
      try {
        final existing = await invRef.get();
        if (existing.exists) continue;
        final econ = FinancialEngine.orderFinancials(order);
        batch.set(invRef, {
          'order_ref': order.reference,
          'amount': econ.totalSales,
          'app_profit': econ.appProfit,
          'commission': econ.repCommission,
          'currency': order.snapshotData['currency'] ?? 'SAR',
          'status': 'issued',
          'created_at': FieldValue.serverTimestamp(),
          'period': order.dataOrder?.toIso8601String() ?? '',
          if (AdminCountryScope.activeCountryRef != null)
            'Rev_dolh': AdminCountryScope.activeCountryRef,
        });
        writes++;
        if (writes >= 40) break;
      } catch (_) {}
    }
    if (writes > 0) {
      try {
        await batch.commit();
      } catch (_) {}
    }
  }
}

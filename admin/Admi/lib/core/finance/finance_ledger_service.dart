import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/financial_accounting_loader.dart';
import '/core/admin_currency.dart';
import '/core/finance/admin_money_presentation.dart';
import '/core/finance/finance_runtime_gate.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/money_amount.dart';

/// Aggregated finance snapshot for the Enterprise Finance Hub (V2 only).
class FinanceHubSnapshot {
  const FinanceHubSnapshot({
    required this.primaryCurrency,
    required this.collectedTripValue,
    required this.platformFees,
    required this.recordedVat,
    required this.driverNet,
    required this.settlementEligibleDue,
    required this.companyOwesDrivers,
    required this.completedAndCollected,
    required this.completedButNotCollected,
    required this.cancelledOrExpired,
    required this.pendingPayment,
    required this.totalsSource,
    required this.periodLabel,
    required this.driverBalances,
    required this.ledger,
    this.isApproximate = false,
  });

  final String primaryCurrency;

  /// Realized collected trip value (V2 customerPaidAll — collected only).
  final MoneyAmount collectedTripValue;

  /// Realized platform fees on collected trips.
  final MoneyAmount platformFees;

  /// Recorded VAT on collected trips.
  final MoneyAmount recordedVat;

  /// Driver net on collected trips.
  final MoneyAmount driverNet;

  /// Settlement-eligible cash position (drivers owe company).
  final MoneyAmount settlementEligibleDue;

  /// Company owes drivers (cash + online entitlements owed).
  final MoneyAmount companyOwesDrivers;

  final int completedAndCollected;
  final int completedButNotCollected;
  final int cancelledOrExpired;
  final int pendingPayment;

  /// `server_v2` | `client_full`
  final String totalsSource;
  final String periodLabel;
  final Map<String, double> driverBalances;
  final List<FinanceLedgerEntry> ledger;

  /// True when KPIs came from client full-scan fallback.
  final bool isApproximate;

  String get currencySymbol =>
      AdminCurrency.symbolByCode[primaryCurrency] ?? primaryCurrency;
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

/// Builds Finance Hub views from canonical Financial Accounting V2 only.
///
/// Does not call legacy `aggregateFinancialSummary` / [FinancialEngine].
abstract final class FinanceLedgerService {
  FinanceLedgerService._();

  static Future<FinanceHubSnapshot> load({
    required AdminDatePreset datePreset,
    String periodLabel = '',
  }) async {
    final filter = FinancialReportFilter(datePreset: datePreset);
    final result = await FinancialAccountingLoader.load(filter);

    final byCurrency = result.byCurrency;
    final primary = _pickPrimaryCurrency(byCurrency);
    final t = byCurrency[primary] ?? FinancialCurrencyTotals(currency: primary);

    final eligibleDue = t.cashDriversOweCompany;
    final owesDrivers = MoneyAmount(
      currency: primary,
      minorUnits: t.cashCompanyOwesDrivers.minorUnits +
          t.onlineCompanyOwesDrivers.minorUnits,
    );

    final approximate = result.totalsSource == 'client_full';
    FinanceRuntimeGate.setAuthoritativeBackendData(!approximate);

    final driverBal = await _loadWalletBalances();
    final ledger = await _loadTransactionLedger();

    return FinanceHubSnapshot(
      primaryCurrency: primary,
      collectedTripValue: t.customerPaidAll,
      platformFees: t.platformFeeAll,
      recordedVat: t.recordedVatAll,
      driverNet: t.driverEntitlementAll,
      settlementEligibleDue: eligibleDue,
      companyOwesDrivers: owesDrivers,
      completedAndCollected: t.completedAndCollected,
      completedButNotCollected: t.completedButNotCollected,
      cancelledOrExpired: t.cancelledOrExpired,
      pendingPayment: t.pendingPayment,
      totalsSource: result.totalsSource,
      periodLabel: periodLabel,
      driverBalances: driverBal,
      ledger: ledger,
      isApproximate: approximate,
    );
  }

  static String _pickPrimaryCurrency(
    Map<String, FinancialCurrencyTotals> byCurrency,
  ) {
    if (byCurrency.isEmpty) return 'SAR';
    if (byCurrency.containsKey('SAR')) return 'SAR';
    final entries = byCurrency.entries.toList()
      ..sort(
        (a, b) => b.value.customerPaidAll.minorUnits
            .compareTo(a.value.customerPaidAll.minorUnits),
      );
    return entries.first.key;
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
}

/// Shared Hub money label helper (presentation only).
String financeHubMoneyLabel(MoneyAmount? m, String symbol) =>
    AdminOrderMoneyDisplay.formatMoneyAmount(m, symbolOverride: symbol);

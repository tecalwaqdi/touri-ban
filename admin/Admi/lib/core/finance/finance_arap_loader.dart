import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_ops_filters.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_country_scope.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/finance_control_facade.dart';
import '/core/finance/finance_unsettled_exposure.dart';
import '/core/finance/financial_amount_resolution.dart';

/// Canonical AR/AP exposure buckets — never wallet balances.
enum FinanceArapSide {
  companyReceivable,
  driverPayable,
}

/// Settlement lifecycle statuses required on AR/AP screen.
enum FinanceSettlementLifecycle {
  unsettled,
  draft,
  locked,
  partiallyPaid,
  settled,
}

extension FinanceSettlementLifecycleX on FinanceSettlementLifecycle {
  String get code => switch (this) {
        FinanceSettlementLifecycle.unsettled => 'UNSETTLED',
        FinanceSettlementLifecycle.draft => 'DRAFT',
        FinanceSettlementLifecycle.locked => 'LOCKED',
        FinanceSettlementLifecycle.partiallyPaid => 'PARTIALLY_PAID',
        FinanceSettlementLifecycle.settled => 'SETTLED',
      };

  String get labelAr => switch (this) {
        FinanceSettlementLifecycle.unsettled => 'غير مسوّاة',
        FinanceSettlementLifecycle.draft => 'مسودة',
        FinanceSettlementLifecycle.locked => 'مقفلة',
        FinanceSettlementLifecycle.partiallyPaid => 'مدفوعة جزئيًا',
        FinanceSettlementLifecycle.settled => 'مسوّاة',
      };
}

class FinanceSettlementOutstandingRow {
  const FinanceSettlementOutstandingRow({
    required this.settlementId,
    required this.status,
    required this.side,
    required this.currency,
    required this.driverId,
    required this.outstandingMinor,
    required this.paidConfirmedMinor,
    required this.netMinor,
    required this.directionRaw,
  });

  final String settlementId;
  final FinanceSettlementLifecycle status;
  final FinanceArapSide side;
  final String currency;
  final String driverId;
  final int? outstandingMinor;
  final int? paidConfirmedMinor;
  final int? netMinor;
  final String directionRaw;
}

class FinanceArapSnapshot {
  const FinanceArapSnapshot({
    required this.tripCompanyReceivables,
    required this.tripDriverPayables,
    required this.settlementRows,
    required this.settlementsByStatus,
    required this.fixturesExcludedTrips,
    required this.fixturesExcludedSettlements,
  });

  final List<AccountantTripRow> tripCompanyReceivables;
  final List<AccountantTripRow> tripDriverPayables;
  final List<FinanceSettlementOutstandingRow> settlementRows;
  final Map<FinanceSettlementLifecycle, int> settlementsByStatus;
  final int fixturesExcludedTrips;
  final int fixturesExcludedSettlements;

  List<FinanceSettlementOutstandingRow> get companyReceivableSettlements =>
      settlementRows
          .where((r) => r.side == FinanceArapSide.companyReceivable)
          .toList(growable: false);

  List<FinanceSettlementOutstandingRow> get driverPayableSettlements =>
      settlementRows
          .where((r) => r.side == FinanceArapSide.driverPayable)
          .toList(growable: false);
}

/// Loads trip-level unsettled + settlement-level outstanding via FIN V2 facade.
abstract final class FinanceArapLoader {
  FinanceArapLoader._();

  static Future<FinanceArapSnapshot> load({
    AdminDatePreset datePreset = AdminDatePreset.last30Days,
  }) async {
    final trips = await FinanceControlFacade.loadTripLedgerPage(
      datePreset: datePreset,
      forceRefresh: true,
    );
    var tripFixtures = 0;
    final usable = <AccountantTripRow>[];
    for (final t in trips) {
      if (AdminQaFixture.isFixtureId(t.orderId)) {
        tripFixtures++;
        continue;
      }
      usable.add(t);
    }

    final companyRx = FinanceUnsettledExposure.companyReceivables(usable);
    final driverPy = FinanceUnsettledExposure.driverPayables(usable);

    final settlementPack = await _loadSettlements();
    return FinanceArapSnapshot(
      tripCompanyReceivables: companyRx,
      tripDriverPayables: driverPy,
      settlementRows: settlementPack.rows,
      settlementsByStatus: settlementPack.byStatus,
      fixturesExcludedTrips: tripFixtures,
      fixturesExcludedSettlements: settlementPack.fixturesExcluded,
    );
  }

  static Future<
      ({
        List<FinanceSettlementOutstandingRow> rows,
        Map<FinanceSettlementLifecycle, int> byStatus,
        int fixturesExcluded,
      })> _loadSettlements() async {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('financial_settlements');
    final country = AdminRoleService.usesCountryFinanceScope
        ? (AdminRoleService.scopedCountryRef ??
            AdminCountryScope.activeCountryRef)
        : AdminCountryScope.activeCountryRef;
    if (AdminRoleService.usesCountryFinanceScope && country == null) {
      return (
        rows: <FinanceSettlementOutstandingRow>[],
        byStatus: {
          for (final s in FinanceSettlementLifecycle.values) s: 0,
        },
        fixturesExcluded: 0,
      );
    }
    if (country != null) {
      q = q.where('countryId', isEqualTo: country.path);
    }
    final snap = await q.limit(400).get();
    final rows = <FinanceSettlementOutstandingRow>[];
    final byStatus = {
      for (final s in FinanceSettlementLifecycle.values) s: 0,
    };
    var fixtures = 0;
    for (final doc in snap.docs) {
      final d = doc.data();
      if (AdminQaFixture.isFinanceQaSettlement(d, settlementId: doc.id)) {
        fixtures++;
        continue;
      }
      final status = _lifecycleOf(d);
      byStatus[status] = (byStatus[status] ?? 0) + 1;
      // Settled listed for completeness but outstanding section filters later.
      final side = _sideOf(d);
      rows.add(
        FinanceSettlementOutstandingRow(
          settlementId: doc.id,
          status: status,
          side: side,
          currency: '${d['currency'] ?? ''}'.trim().isEmpty
              ? '—'
              : '${d['currency']}'.trim().toUpperCase(),
          driverId: '${d['driverId'] ?? d['mndobId'] ?? ''}',
          outstandingMinor: (d['outstandingMinor'] as num?)?.toInt(),
          paidConfirmedMinor: (d['paidConfirmedMinor'] as num?)?.toInt(),
          netMinor: (d['netMinor'] as num?)?.toInt() ??
              (d['netAmountMinor'] as num?)?.toInt(),
          directionRaw: '${d['direction'] ?? d['settlementDirection'] ?? ''}',
        ),
      );
    }
    return (rows: rows, byStatus: byStatus, fixturesExcluded: fixtures);
  }

  static FinanceSettlementLifecycle _lifecycleOf(Map<String, dynamic> d) {
    final st = '${d['status'] ?? ''}'.trim().toLowerCase();
    switch (st) {
      case 'settled':
      case 'complete':
      case 'completed':
        return FinanceSettlementLifecycle.settled;
      case 'partially_paid':
      case 'partial':
        return FinanceSettlementLifecycle.partiallyPaid;
      case 'locked':
        return FinanceSettlementLifecycle.locked;
      case 'draft':
      case 'open':
      case 'pending':
        return FinanceSettlementLifecycle.draft;
      default:
        final outstanding = (d['outstandingMinor'] as num?)?.toInt();
        if (outstanding != null && outstanding > 0) {
          return FinanceSettlementLifecycle.unsettled;
        }
        return FinanceSettlementLifecycle.unsettled;
    }
  }

  static FinanceArapSide _sideOf(Map<String, dynamic> d) {
    final dir =
        '${d['direction'] ?? d['settlementDirection'] ?? ''}'.toUpperCase();
    if (dir.contains('COMPANY_PAYS') ||
        dir.contains('PAYABLE') ||
        dir.contains('DRIVER_RECEIVES')) {
      return FinanceArapSide.driverPayable;
    }
    if (dir.contains('DRIVER_PAYS') ||
        dir.contains('RECEIVABLE') ||
        dir.contains('COMPANY_RECEIVES')) {
      return FinanceArapSide.companyReceivable;
    }
    final net = (d['netMinor'] as num?)?.toInt() ??
        (d['netAmountMinor'] as num?)?.toInt();
    // Convention: net > 0 DRIVER_PAYS_COMPANY → company receivable.
    if (net != null && net < 0) return FinanceArapSide.driverPayable;
    return FinanceArapSide.companyReceivable;
  }
}

/// Trip unsettled filters: COMPLETE + collected/paid + not locked-settlement claimed.
abstract final class FinanceUnsettledExposurePolicy {
  FinanceUnsettledExposurePolicy._();

  static bool isClaimedInLockedSettlement(AccountantTripRow row) {
    final st = row.settlementStatusLabel;
    // Locked / settled Arabic labels from ledger membership.
    return st.contains('مسوّى') ||
        st.contains('مقفلة') ||
        st.toLowerCase().contains('locked') ||
        st.toLowerCase().contains('settled');
  }

  static bool isCompleteFinancial(AccountantTripRow row) =>
      row.dataQuality == FinancialDataQuality.complete;
}

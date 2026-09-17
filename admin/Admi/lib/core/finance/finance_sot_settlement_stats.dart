import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/core/admin_qa_fixture.dart';

/// Result of a settlement KPI rollup from [financial_settlements].
///
/// When [available] is false, money counters must be treated as unknown — never
/// displayed as authoritative zeros (missing ≠ 0).
class FinanceSotSettlementStatsResult {
  const FinanceSotSettlementStatsResult({
    required this.available,
    required this.settled,
    required this.pending,
    required this.outstandingMinor,
    required this.paidConfirmedMinor,
    required this.fixturesExcluded,
    required this.docsRead,
    this.unavailableReason,
  });

  const FinanceSotSettlementStatsResult.unavailable({
    String reason = 'unavailable',
  }) : this(
          available: false,
          settled: 0,
          pending: 0,
          outstandingMinor: 0,
          paidConfirmedMinor: 0,
          fixturesExcluded: 0,
          docsRead: 0,
          unavailableReason: reason,
        );

  final bool available;
  final int settled;
  final int pending;

  /// Sum of settlement `outstandingMinor` (expected − confirmed payments).
  final int outstandingMinor;

  /// Sum of settlement `paidConfirmedMinor` (confirmed valid payments).
  final int paidConfirmedMinor;

  final int fixturesExcluded;
  final int docsRead;
  final String? unavailableReason;
}

/// Canonical settlement KPI counters from [financial_settlements] (SoT).
///
/// Country-scoped when the session uses country finance scope or has an active
/// country filter. QA/demo fixtures are excluded from normal KPIs.
abstract final class FinanceSotSettlementStats {
  FinanceSotSettlementStats._();

  static DocumentReference? effectiveCountryRef({
    DocumentReference? countryOverride,
  }) {
    if (countryOverride != null) return countryOverride;
    if (AdminRoleService.usesCountryFinanceScope) {
      return AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
    }
    return AdminCountryScope.activeCountryRef;
  }

  /// True when settlement docs must be limited to a single country.
  static bool get requiresCountryScope =>
      AdminRoleService.usesCountryFinanceScope;

  /// Settlement KPI rollup from [financial_settlements].
  ///
  /// [available] is false when the load fails or country scope is required but
  /// missing — callers must treat money fields as unavailable, not zero.
  static Future<FinanceSotSettlementStatsResult> load({
    DocumentReference? countryOverride,
    int limit = 500,
  }) async {
    try {
      final country = effectiveCountryRef(countryOverride: countryOverride);
      if (requiresCountryScope && country == null) {
        return FinanceSotSettlementStatsResult.unavailable(
          reason: 'country_scope_required',
        );
      }

      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('financial_settlements');
      if (country != null) {
        // Prefer document path equality (matches AdminFinanceRepository).
        q = q.where('countryId', isEqualTo: country.path);
      }
      q = q.limit(limit);
      final snap = await q.get();

      var settled = 0;
      var pending = 0;
      var outstanding = 0;
      var paidConfirmed = 0;
      var fixturesExcluded = 0;

      for (final doc in snap.docs) {
        final d = doc.data();
        if (AdminQaFixture.isFinanceQaSettlement(d, settlementId: doc.id)) {
          fixturesExcluded++;
          continue;
        }
        // Defense-in-depth if query could not apply countryId.
        if (country != null) {
          final cid = '${d['countryId'] ?? ''}'.trim();
          if (cid.isNotEmpty &&
              cid != country.path &&
              cid != country.id &&
              !cid.endsWith('/${country.id}')) {
            continue;
          }
        }
        final st = (d['status'] ?? '').toString().toLowerCase();
        if (st == 'settled') settled++;
        if (st == 'draft' ||
            st == 'locked' ||
            st == 'partially_paid' ||
            st == 'open' ||
            st == 'pending') {
          pending++;
        }
        final docOutstanding = (d['outstandingMinor'] as num?)?.toInt();
        final docPaid = (d['paidConfirmedMinor'] as num?)?.toInt();
        // Missing fields stay out of the sum (do not coerce null → 0 addend
        // beyond Firestore absences that mean "no confirmed payment yet").
        if (docOutstanding != null) outstanding += docOutstanding;
        if (docPaid != null) paidConfirmed += docPaid;
      }

      return FinanceSotSettlementStatsResult(
        available: true,
        settled: settled,
        pending: pending,
        outstandingMinor: outstanding,
        paidConfirmedMinor: paidConfirmed,
        fixturesExcluded: fixturesExcluded,
        docsRead: snap.docs.length,
      );
    } catch (_) {
      return FinanceSotSettlementStatsResult.unavailable(
        reason: 'load_failed',
      );
    }
  }

  /// Count of open / remaining settlements (fixture-excluded).
  static int countOpen(List<Map<String, dynamic>> maps) {
    var open = 0;
    for (final map in maps) {
      final id = (map['id'] ?? '').toString();
      if (AdminQaFixture.isFinanceQaSettlement(map, settlementId: id)) {
        continue;
      }
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
}

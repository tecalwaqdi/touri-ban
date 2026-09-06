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
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_trip_semantics.dart';

/// Loads orders (scoped) and builds [AccountantFinanceViewBundle] via F1 only.
///
/// PERF-P2A: completed-candidate server queries + first-page callback.
/// Summary always uses full eligible population (never visible page only).
abstract final class AccountantFinanceLoader {
  AccountantFinanceLoader._();

  /// Retained for report/tests — hard scan ceiling (completed-only).
  static const int scanCap = FinanceOrderQuery.scanCap;

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

  static Future<AccountantFinanceViewBundle> load({
    AdminDatePreset datePreset = AdminDatePreset.thisMonth,
    DateTime? customStart,
    DateTime? customEnd,
    DocumentReference? countryRef,
    DocumentReference? driverRef,
    String currency = 'SAR',
    String periodLabel = '',
    void Function(List<AccountantTripRow> firstRows, int docsRead)? onFirstPage,
  }) async {
    final range = AdminDateRangeResolver.resolve(
      preset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
    );

    DocumentReference? effectiveCountry;
    if (AdminRoleService.usesCountryFinanceScope) {
      effectiveCountry = AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
    } else {
      effectiveCountry = countryRef;
    }

    final scope = scopeForCurrentUser(countryOverride: effectiveCountry);
    final sym = AdminCurrency.symbolByCode[currency] ?? currency;

    // FIRST USEFUL ROWS — modern completed page only (does not define totals).
    try {
      final firstPage = await FinanceOrderQuery.fetchModernPage(
        range: range,
        country: effectiveCountry,
        driverRef: driverRef,
        limit: FinanceOrderQuery.tablePageSize,
      );
      final firstRows = _tripsFromOrders(
        firstPage.orders,
        scope: scope,
        symbol: sym,
      );
      onFirstPage?.call(firstRows, firstPage.docsRead);
    } on FirebaseException catch (e) {
      // Controlled surface — no silent 100k fallback.
      throw StateError(
        'finance_query_unavailable:${e.code}',
      );
    }

    // FULL PERIOD SUMMARY — chunked completed candidates (modern + legacy).
    final scan = await FinanceOrderQuery.scanCompletedCandidates(
      range: range,
      country: effectiveCountry,
      driverRef: driverRef,
    );
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

    final openSettlements = await _countOpenSettlements(effectiveCountry);

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
      truncated: scan.truncated || orders.length >= scanCap,
      openSettlementsRemaining: openSettlements,
      fixturesExcludedFromTable: fixturesSkippedForTable,
    );
  }

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

  static Future<int> _countOpenSettlements(DocumentReference? country) async {
    try {
      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('financial_settlements');
      if (AdminRoleService.usesCountryFinanceScope && country != null) {
        q = q.where('countryId', isEqualTo: country.path);
      }
      q = q.orderBy('createdAt', descending: true);
      DocumentSnapshot<Map<String, dynamic>>? last;
      var open = 0;
      var seen = 0;
      const cap = 500;
      while (seen < cap) {
        Query<Map<String, dynamic>> page = q.limit(50);
        if (last != null) {
          page = page.startAfterDocument(last);
        }
        final snap = await page.get();
        AdminPerfTrace.financeDocsRead(
          snap.docs.length,
          source: 'settlements_open',
        );
        if (snap.docs.isEmpty) break;
        for (final doc in snap.docs) {
          seen++;
          final map = doc.data();
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
        last = snap.docs.last;
        if (snap.docs.length < 50) break;
      }
      return open;
    } catch (_) {
      return 0;
    }
  }

  /// Broad completed-trip scan for B1 reconciliation workspace (scoped).
  static Future<List<OrderRecord>> loadOrdersForCurrentScope({
    AdminDatePreset datePreset = AdminDatePreset.thisYear,
    void Function(List<OrderRecord> firstPage, int docsRead)? onFirstPage,
  }) async {
    DocumentReference? country;
    if (usesCountryFinanceScopeSafe()) {
      country = AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
    }
    final range = AdminDateRangeResolver.resolve(preset: datePreset);

    try {
      final first = await FinanceOrderQuery.fetchModernPage(
        range: range,
        country: country,
        limit: FinanceOrderQuery.tablePageSize,
      );
      onFirstPage?.call(first.orders, first.docsRead);
    } on FirebaseException catch (e) {
      throw StateError('finance_query_unavailable:${e.code}');
    }

    final scan = await FinanceOrderQuery.scanCompletedCandidates(
      range: range,
      country: country,
    );
    return scan.orders;
  }

  static bool usesCountryFinanceScopeSafe() =>
      AdminRoleService.usesCountryFinanceScope;

  /// Settlement docs as maps for B1 association (read-only, paginated chunks).
  static Future<List<Map<String, dynamic>>> loadSettlementsMaps() async {
    try {
      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('financial_settlements');
      if (AdminRoleService.usesCountryFinanceScope) {
        final country = AdminRoleService.scopedCountryRef ??
            AdminCountryScope.activeCountryRef;
        if (country != null) {
          q = q.where('countryId', isEqualTo: country.path);
        }
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
}

/// Filter helpers for the money-movement table (presentation only).
abstract final class AccountantTripFilters {
  static List<AccountantTripRow> apply(
    List<AccountantTripRow> rows, {
    String? paymentMethod,
    String? collectionStatus,
    String? settlementStatus,
    FinancialDataQuality? quality,
    String? search,
  }) {
    return rows.where((r) {
      if (AdminQaFixture.isFixtureId(r.orderId) ||
          FinancialTripSemantics.isFinanceQaFixture(r.order)) {
        return false;
      }
      if (paymentMethod != null &&
          paymentMethod.isNotEmpty &&
          r.paymentMethodLabel != paymentMethod) {
        return false;
      }
      if (collectionStatus != null &&
          collectionStatus.isNotEmpty &&
          r.collectionStatusLabel != collectionStatus) {
        return false;
      }
      if (settlementStatus != null &&
          settlementStatus.isNotEmpty &&
          r.settlementStatusLabel != settlementStatus) {
        return false;
      }
      if (quality != null && r.dataQuality != quality) return false;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final hay =
            '${r.orderId} ${r.driverLabel} ${r.agentLabel} ${r.countryLabel}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}

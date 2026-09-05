import '/backend/admin_country_scope.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/core/admin_currency.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/accountant_finance_view_model.dart';
import '/core/finance/financial_amount_resolution.dart';

/// Loads orders (scoped) and builds [AccountantFinanceViewBundle] via F1 only.
///
/// Country Agent: Firestore query constrained to scoped country — no global
/// load then UI filter.
abstract final class AccountantFinanceLoader {
  AccountantFinanceLoader._();

  static const int scanCap = 100000;

  static AccountantFinanceScope scopeForCurrentUser({
    DocumentReference? countryOverride,
  }) {
    if (AdminRoleService.isCountryAgent) {
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
  }) async {
    final range = AdminDateRangeResolver.resolve(
      preset: datePreset,
      customStart: customStart,
      customEnd: customEnd,
    );

    DocumentReference? effectiveCountry;
    if (AdminRoleService.isCountryAgent) {
      effectiveCountry = AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
    } else {
      effectiveCountry = countryRef ?? AdminCountryScope.activeCountryRef;
    }

    final orders = await _scanOrders(
      range: range,
      country: effectiveCountry,
      driverRef: driverRef,
    );

    final scope = scopeForCurrentUser(countryOverride: effectiveCountry);
    final model = AccountantFinanceReadModel.aggregate(
      orders: orders,
      scope: scope,
      currency: currency,
    );

    final sym = AdminCurrency.symbolByCode[currency] ?? currency;
    final trips = <AccountantTripRow>[];
    for (final o in orders) {
      if (!scope.allowsCountry(o.revDolh?.path)) continue;
      if (AdminRoleService.isCountryAgent) {
        if (AdminCountryScope.filterOrders([o]).isEmpty) continue;
      }
      final row = AccountantTripRow.fromOrder(o, symbol: sym);
      if (!row.operationallyCompleted) continue;
      trips.add(row);
    }
    trips.sort((a, b) {
      final ad = a.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

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
      docsScanned: orders.length,
      truncated: orders.length >= scanCap,
      openSettlementsRemaining: openSettlements,
    );
  }

  static Future<List<OrderRecord>> _scanOrders({
    required AdminDateRange? range,
    required DocumentReference? country,
    DocumentReference? driverRef,
  }) async {
    final results = <OrderRecord>[];
    DocumentSnapshot? last;

    while (results.length < scanCap) {
      Query q = OrderRecord.collection.orderBy('data_order', descending: true);
      if (driverRef != null) {
        q = OrderRecord.collection
            .where('mndob_user', isEqualTo: driverRef)
            .orderBy('data_order', descending: true);
      } else if (country != null) {
        q = OrderRecord.collection
            .where('Rev_dolh', isEqualTo: country)
            .orderBy('data_order', descending: true);
      }
      if (range != null && driverRef == null) {
        q = q
            .where('data_order', isGreaterThanOrEqualTo: range.startTimestamp)
            .where('data_order', isLessThan: range.endTimestamp);
      }
      if (last != null) q = q.startAfterDocument(last);
      final snap = await q.limit(kAdminPageSizeLarge).get();
      if (snap.docs.isEmpty) break;
      for (final doc in snap.docs) {
        final order = OrderRecord.fromSnapshot(doc);
        if (range != null && driverRef != null) {
          final d = order.dataOrder;
          if (d == null) continue;
          if (d.isBefore(range.startInclusive) ||
              !d.isBefore(range.endExclusive)) {
            continue;
          }
        }
        if (country != null && order.revDolh?.path != country.path) continue;
        if (AdminRoleService.isCountryAgent) {
          if (AdminCountryScope.filterOrders([order]).isEmpty) continue;
        }
        results.add(order);
      }
      last = snap.docs.last;
      if (snap.docs.length < kAdminPageSizeLarge) break;
    }
    return results;
  }

  static Future<int> _countOpenSettlements(DocumentReference? country) async {
    try {
      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('financial_settlements');
      if (AdminRoleService.isCountryAgent && country != null) {
        q = q.where('countryId', isEqualTo: country.path);
      }
      final snap = await q.limit(500).get();
      var open = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final st = (d['status'] ?? '').toString().toLowerCase();
        final outstanding = (d['outstandingMinor'] as num?)?.toInt() ?? 0;
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
    } catch (_) {
      return 0;
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
            '${r.orderId} ${r.driverLabel} ${r.agentLabel}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}

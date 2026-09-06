
import '/backend/admin_country_scope.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_perf_trace.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/core/admin_qa_fixture.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/core/toury_system_status_codes.dart';

/// PERF-P2A — scoped, completed-candidate order queries (read-only).
///
/// ROW DELIVERY: cursor pages of modern `status_code` completions.
/// SUMMARY SCAN: chunked modern + narrow legacy candidates, then frozen
/// [FinancialTripSemantics.isOperationallyCompleted] (never page-only totals).
abstract final class FinanceOrderQuery {
  FinanceOrderQuery._();

  /// First useful table page (UI density).
  static const int tablePageSize = 40;

  /// Chunk size for background summary scans.
  static const int scanChunkSize = kAdminPageSizeLarge;

  /// Hard safety cap (same as P0) — completed-only scans rarely approach this.
  static const int scanCap = 100000;

  static const List<String> modernCompletedCodes = [
    TourySystemStatusCodes.completed,
    TourySystemStatusCodes.legacyTripCompleted,
  ];

  /// Narrow legacy `halh` equality candidates (Arabic / English complete).
  /// Client still requires empty `status_code` + frozen completion helper.
  static const List<String> legacyHalhEquals = [
    'مكتمل',
    'completed',
  ];

  static DocumentReference? effectiveCountry({
    DocumentReference? countryOverride,
  }) {
    if (AdminRoleService.usesCountryFinanceScope) {
      return AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
    }
    return countryOverride;
  }

  /// MODERN COMPLETED QUERY — server filters status_code + date + country.
  static Query buildModernCompletedQuery({
    required AdminDateRange? range,
    DocumentReference? country,
    DocumentReference? driverRef,
  }) {
    Query q = OrderRecord.collection
        .where('status_code', whereIn: modernCompletedCodes)
        .orderBy('data_order', descending: true);

    if (driverRef != null) {
      q = OrderRecord.collection
          .where('mndob_user', isEqualTo: driverRef)
          .where('status_code', whereIn: modernCompletedCodes)
          .orderBy('data_order', descending: true);
    } else if (country != null) {
      q = OrderRecord.collection
          .where('Rev_dolh', isEqualTo: country)
          .where('status_code', whereIn: modernCompletedCodes)
          .orderBy('data_order', descending: true);
    }

    if (range != null && driverRef == null) {
      q = q
          .where('data_order', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('data_order', isLessThan: range.endTimestamp);
    }
    return q;
  }

  /// LEGACY CANDIDATE QUERY — equality on `halh` (+ date/country when possible).
  static Query buildLegacyHalhQuery({
    required String halhValue,
    required AdminDateRange? range,
    DocumentReference? country,
  }) {
    Query q = OrderRecord.collection
        .where('halh', isEqualTo: halhValue)
        .orderBy('data_order', descending: true);
    if (country != null) {
      q = OrderRecord.collection
          .where('Rev_dolh', isEqualTo: country)
          .where('halh', isEqualTo: halhValue)
          .orderBy('data_order', descending: true);
    }
    if (range != null) {
      q = q
          .where('data_order', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('data_order', isLessThan: range.endTimestamp);
    }
    return q;
  }

  static Future<FinanceOrderPage> fetchModernPage({
    required AdminDateRange? range,
    DocumentReference? country,
    DocumentReference? driverRef,
    DocumentSnapshot? startAfter,
    int limit = tablePageSize,
  }) async {
    try {
      var q = buildModernCompletedQuery(
        range: range,
        country: country,
        driverRef: driverRef,
      );
      if (startAfter != null) q = q.startAfterDocument(startAfter);
      final snap = await q.limit(limit).get();
      AdminPerfTrace.financeDocsRead(snap.docs.length, source: 'modern_page');
      final orders = <OrderRecord>[];
      for (final doc in snap.docs) {
        final order = OrderRecord.fromSnapshot(doc);
        if (!_passesScope(order, country: country, driverRef: driverRef, range: range)) {
          continue;
        }
        if (!_isCanonicalCompletedNonQa(order)) continue;
        orders.add(order);
      }
      return FinanceOrderPage(
        orders: orders,
        lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
        hasMore: snap.docs.length >= limit,
        docsRead: snap.docs.length,
        source: FinanceOrderPageSource.modern,
      );
    } on FirebaseException catch (e) {
      AdminPerfTrace.financeQueryError(e.code, source: 'modern_page');
      rethrow;
    }
  }

  /// Chunked scan of modern + legacy candidates for **summary** (not UI page).
  ///
  /// PERF-P3: [onFirstModernChunk] fires after the first modern page so callers
  /// do not need a separate [fetchModernPage] (eliminates duplicate modern query).
  ///
  /// PERF-P4A: [seedModernOrders] + [modernStartAfter] let the repository reuse
  /// a coalesced [fetchModernPage] without re-querying the first page.
  static Future<FinanceOrderScanResult> scanCompletedCandidates({
    required AdminDateRange? range,
    DocumentReference? country,
    DocumentReference? driverRef,
    void Function(List<OrderRecord> firstOrders, int docsRead)?
        onFirstModernChunk,
    List<OrderRecord>? seedModernOrders,
    DocumentSnapshot? modernStartAfter,
    int seedDocsRead = 0,
  }) async {
    final byPath = <String, OrderRecord>{};
    var docsRead = seedDocsRead;
    var truncated = false;
    var firstModernSignaled = false;

    if (seedModernOrders != null && seedModernOrders.isNotEmpty) {
      for (final order in seedModernOrders) {
        byPath[order.reference.path] = order;
      }
      firstModernSignaled = true;
      onFirstModernChunk?.call(
        seedModernOrders.take(tablePageSize).toList(),
        seedDocsRead > 0 ? seedDocsRead : seedModernOrders.length,
      );
    }

    Future<void> ingestPage(
      Query base, {
      required bool isModern,
      DocumentSnapshot? startAfter,
    }) async {
      DocumentSnapshot? last = startAfter;
      while (byPath.length < scanCap) {
        var q = base;
        if (last != null) q = q.startAfterDocument(last);
        QuerySnapshot snap;
        try {
          snap = await q.limit(scanChunkSize).get();
        } on FirebaseException catch (e) {
          AdminPerfTrace.financeQueryError(e.code, source: 'scan_chunk');
          rethrow;
        }
        docsRead += snap.docs.length;
        AdminPerfTrace.financeDocsRead(snap.docs.length, source: 'scan_chunk');
        if (snap.docs.isEmpty) break;
        final pageAccepted = <OrderRecord>[];
        for (final doc in snap.docs) {
          final order = OrderRecord.fromSnapshot(doc);
          if (!_passesScope(
            order,
            country: country,
            driverRef: driverRef,
            range: range,
          )) {
            continue;
          }
          if (!_isCanonicalCompletedNonQa(order)) continue;
          byPath[order.reference.path] = order;
          pageAccepted.add(order);
          if (byPath.length >= scanCap) {
            truncated = true;
            break;
          }
        }
        if (isModern && !firstModernSignaled && onFirstModernChunk != null) {
          firstModernSignaled = true;
          final first = pageAccepted.take(tablePageSize).toList();
          onFirstModernChunk(first, snap.docs.length);
        }
        last = snap.docs.last;
        if (snap.docs.length < scanChunkSize) break;
      }
    }

    await ingestPage(
      buildModernCompletedQuery(
        range: range,
        country: country,
        driverRef: driverRef,
      ),
      isModern: true,
      startAfter: modernStartAfter,
    );

    // Legacy path: only when not driver-filtered (driver+halh indexes may be absent).
    if (driverRef == null) {
      for (final halh in legacyHalhEquals) {
        if (byPath.length >= scanCap) {
          truncated = true;
          break;
        }
        await ingestPage(
          buildLegacyHalhQuery(
            halhValue: halh,
            range: range,
            country: country,
          ),
          isModern: false,
        );
      }
    }

    final orders = byPath.values.toList()
      ..sort((a, b) {
        final ad = a.dataOrder ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.dataOrder ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    return FinanceOrderScanResult(
      orders: orders,
      docsRead: docsRead,
      truncated: truncated,
    );
  }

  static bool _isCanonicalCompletedNonQa(OrderRecord order) {
    if (FinancialTripSemantics.isFinanceQaFixture(order) ||
        AdminQaFixture.isFixtureOrder(order)) {
      return false;
    }
    // Legacy candidates must have empty status_code before Arabic fallback.
    final code = (order.snapshotData['status_code'] ?? '').toString().trim();
    if (code.isEmpty) {
      // Only accept via frozen helper (Arabic / completed halh).
      return FinancialTripSemantics.isOperationallyCompleted(order);
    }
    // Modern path already constrained; still run helper for safety.
    return FinancialTripSemantics.isOperationallyCompleted(order);
  }

  static bool _passesScope(
    OrderRecord order, {
    required DocumentReference? country,
    required DocumentReference? driverRef,
    required AdminDateRange? range,
  }) {
    if (driverRef != null) {
      if (order.mndobUser?.path != driverRef.path) return false;
      if (range != null) {
        final d = order.dataOrder;
        if (d == null) return false;
        if (d.isBefore(range.startInclusive) || !d.isBefore(range.endExclusive)) {
          return false;
        }
      }
    }
    if (country != null && order.revDolh?.path != country.path) return false;
    if (AdminRoleService.usesCountryFinanceScope) {
      if (AdminCountryScope.filterOrders([order]).isEmpty) return false;
    }
    return true;
  }
}

enum FinanceOrderPageSource { modern, legacy, mixed }

class FinanceOrderPage {
  const FinanceOrderPage({
    required this.orders,
    required this.lastDocument,
    required this.hasMore,
    required this.docsRead,
    required this.source,
  });

  final List<OrderRecord> orders;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int docsRead;
  final FinanceOrderPageSource source;
}

class FinanceOrderScanResult {
  const FinanceOrderScanResult({
    required this.orders,
    required this.docsRead,
    required this.truncated,
  });

  final List<OrderRecord> orders;
  final int docsRead;
  final bool truncated;
}

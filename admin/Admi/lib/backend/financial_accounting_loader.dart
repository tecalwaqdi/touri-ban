
import '/backend/admin_country_scope.dart';
import '/backend/admin_ops_filters.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/core/cloud_functions/cloud_functions_client.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/money_amount.dart';
import '/core/finance/settlement_preview.dart';

/// Filters for Financial Accounting V2 reporting (read-only).
class FinancialReportFilter {
  const FinancialReportFilter({
    this.datePreset = AdminDatePreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.countryRef,
    this.driverRef,
    this.channel,
    this.lifecycle,
    this.payment,
    this.confidence,
    this.currency,
  });

  final AdminDatePreset datePreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final DocumentReference? countryRef;
  final DocumentReference? driverRef;
  final FinancialPaymentChannel? channel;
  final FinancialLifecycle? lifecycle;
  final FinancialPaymentState? payment;
  final FinancialConfidence? confidence;
  final String? currency;

  AdminDateRange? get dateRange => AdminDateRangeResolver.resolve(
        preset: datePreset,
        customStart: customStart,
        customEnd: customEnd,
      );

  String get signature => [
        datePreset.name,
        customStart?.toUtc().toIso8601String() ?? '',
        customEnd?.toUtc().toIso8601String() ?? '',
        countryRef?.path ?? '',
        driverRef?.path ?? '',
        channel?.name ?? '',
        lifecycle?.name ?? '',
        payment?.name ?? '',
        confidence?.name ?? '',
        currency ?? '',
      ].join('|');
}

class FinancialReportRow {
  const FinancialReportRow({
    required this.order,
    required this.line,
  });

  final OrderRecord order;
  final FinancialOrderLine line;
}

class FinancialQualityStats {
  const FinancialQualityStats({
    this.totalLines = 0,
    this.high = 0,
    this.derived = 0,
    this.incomplete = 0,
    this.reconciled = 0,
    this.reconciliationDifference = 0,
    this.unsupportedCurrency = 0,
    this.missingPaymentStatus = 0,
    this.missingLifecycle = 0,
    this.missingDriver = 0,
  });

  final int totalLines;
  final int high;
  final int derived;
  final int incomplete;
  final int reconciled;
  final int reconciliationDifference;
  final int unsupportedCurrency;
  final int missingPaymentStatus;
  final int missingLifecycle;
  final int missingDriver;
}

class FinancialReportResult {
  const FinancialReportResult({
    required this.byCurrency,
    required this.quality,
    required this.tableRows,
    required this.loadedAt,
    required this.docsScanned,
    required this.filterSignature,
    required this.totalsSource,
    this.truncated = false,
    this.tablePage = 0,
    this.tablePageSize = 50,
    this.allMatchingLines = const [],
  });

  /// Full-dataset currency totals (Cards).
  final Map<String, FinancialCurrencyTotals> byCurrency;
  final FinancialQualityStats quality;

  /// Paginated table rows only.
  final List<FinancialReportRow> tableRows;
  final DateTime loadedAt;
  final int docsScanned;
  final String filterSignature;
  final String totalsSource;
  final bool truncated;
  final int tablePage;
  final int tablePageSize;

  /// Optional full matching lines (driver preview / client full scan).
  final List<FinancialOrderLine> allMatchingLines;

  int get incompleteCount => quality.incomplete;
}

/// Loads financial totals (full dataset) + paginated table.
///
/// Cards NEVER use a 500-row sample. Prefer CF `aggregateFinancialAccountingV2`.
abstract final class FinancialAccountingLoader {
  FinancialAccountingLoader._();

  /// Safety ceiling for client full-scan fallback only.
  static const int clientFullScanCap = 100000;
  static const int tablePageSize = 50;

  static DocumentReference? _effectiveCountry(FinancialReportFilter f) {
    if (AdminRoleService.isCountryAgent) {
      return AdminRoleService.scopedCountryRef ??
          AdminCountryScope.activeCountryRef;
    }
    return f.countryRef ?? AdminCountryScope.activeCountryRef;
  }

  static bool _matchesLine(FinancialOrderLine line, FinancialReportFilter f) {
    if (f.channel != null && line.channel != f.channel) return false;
    if (f.lifecycle != null && line.lifecycle != f.lifecycle) return false;
    if (f.payment != null && line.payment != f.payment) return false;
    if (f.confidence != null && line.confidence != f.confidence) return false;
    if (f.currency != null &&
        f.currency!.isNotEmpty &&
        line.currency != CurrencyMoneyPolicy.normalizeCode(f.currency)) {
      return false;
    }
    return true;
  }

  /// Full load: totals via CF (or client full scan) + first table page.
  static Future<FinancialReportResult> load(
    FinancialReportFilter filter, {
    int tablePage = 0,
  }) async {
    final range = filter.dateRange;
    final country = _effectiveCountry(filter);
    final scopedFilter = FinancialReportFilter(
      datePreset: filter.datePreset,
      customStart: filter.customStart,
      customEnd: filter.customEnd,
      countryRef: country,
      driverRef: filter.driverRef,
      channel: filter.channel,
      lifecycle: filter.lifecycle,
      payment: filter.payment,
      confidence: filter.confidence,
      currency: filter.currency,
    );

    Map<String, FinancialCurrencyTotals>? byCurrency;
    FinancialQualityStats quality = const FinancialQualityStats();
    var docsScanned = 0;
    var totalsSource = 'client_full';
    var truncated = false;
    var allLines = <FinancialOrderLine>[];

    // Driver-scoped: prefer full client scan (small set) so statement lines exist.
    if (filter.driverRef != null) {
      final scanned = await _clientFullScan(scopedFilter);
      byCurrency = scanned.byCurrency;
      quality = scanned.quality;
      docsScanned = scanned.docsScanned;
      truncated = scanned.truncated;
      allLines = scanned.lines;
      totalsSource = 'client_full';
    } else {
      try {
        final remote =
            await CloudFunctionsClient.aggregateFinancialAccountingV2(
          countryPath: country?.path,
          periodStart: range?.startInclusive,
          periodEnd: range?.endExclusive,
          driverId: filter.driverRef?.id,
          channel: filter.channel?.name,
          lifecycle: filter.lifecycle?.name,
          payment: filter.payment?.name,
          confidence: filter.confidence?.name,
          currency: filter.currency,
        );
        byCurrency = _parseRemoteTotals(remote);
        quality = _parseQuality(remote);
        docsScanned = (remote['quality'] is Map)
            ? ((remote['quality'] as Map)['docsScanned'] as num?)?.toInt() ?? 0
            : 0;
        totalsSource = (remote['source'] as String?) ?? 'server_v2';
      } catch (_) {
        final scanned = await _clientFullScan(scopedFilter);
        byCurrency = scanned.byCurrency;
        quality = scanned.quality;
        docsScanned = scanned.docsScanned;
        truncated = scanned.truncated;
        allLines = scanned.lines;
        totalsSource = 'client_full';
      }
    }

    // Table page — always paginated server-side (not used for cards).
    final table = await _loadTablePage(
      scopedFilter,
      page: tablePage,
      pageSize: tablePageSize,
    );

    return FinancialReportResult(
      byCurrency: byCurrency,
      quality: quality,
      tableRows: table,
      loadedAt: DateTime.now().toUtc(),
      docsScanned: docsScanned,
      filterSignature: scopedFilter.signature,
      totalsSource: totalsSource,
      truncated: truncated,
      tablePage: tablePage,
      tablePageSize: tablePageSize,
      allMatchingLines: allLines,
    );
  }

  /// Driver settlement preview — full lines for that driver (read-only).
  static Future<SettlementPreview> loadSettlementPreview({
    required DocumentReference driverRef,
    required String currency,
    FinancialReportFilter? filter,
  }) async {
    final base = filter ?? const FinancialReportFilter(datePreset: AdminDatePreset.all);
    final f = FinancialReportFilter(
      datePreset: base.datePreset,
      customStart: base.customStart,
      customEnd: base.customEnd,
      countryRef: _effectiveCountry(base),
      driverRef: driverRef,
      channel: base.channel,
      lifecycle: base.lifecycle,
      payment: base.payment,
      confidence: base.confidence,
      currency: currency,
    );

    try {
      final remote = await CloudFunctionsClient.aggregateFinancialAccountingV2(
        countryPath: f.countryRef?.path,
        periodStart: f.dateRange?.startInclusive,
        periodEnd: f.dateRange?.endExclusive,
        driverId: driverRef.id,
        currency: currency,
        mode: 'settlement_preview',
      );
      final preview = remote['settlementPreview'];
      if (preview is Map) {
        // Still rebuild from local full scan for line detail when needed.
      }
    } catch (_) {}

    final scanned = await _clientFullScan(f);
    return SettlementPreview.build(
      driverId: driverRef.id,
      currency: currency,
      lines: scanned.lines,
      from: f.dateRange?.startInclusive,
      to: f.dateRange?.endExclusive,
      countryPath: f.countryRef?.path,
    );
  }

  static Future<List<FinancialReportRow>> _loadTablePage(
    FinancialReportFilter filter, {
    required int page,
    required int pageSize,
  }) async {
    final range = filter.dateRange;
    final country = filter.countryRef;
    Query q = OrderRecord.collection.orderBy('data_order', descending: true);
    if (filter.driverRef != null) {
      q = OrderRecord.collection
          .where('mndob_user', isEqualTo: filter.driverRef)
          .orderBy('data_order', descending: true);
    } else if (country != null) {
      q = OrderRecord.collection
          .where('Rev_dolh', isEqualTo: country)
          .orderBy('data_order', descending: true);
    }
    if (range != null && filter.driverRef == null) {
      q = q
          .where('data_order', isGreaterThanOrEqualTo: range.startTimestamp)
          .where('data_order', isLessThan: range.endTimestamp);
    }

    // Over-fetch then filter client-side for channel/lifecycle/etc.
    final need = (page + 1) * pageSize;
    final collected = <FinancialReportRow>[];
    DocumentSnapshot? last;
    var guard = 0;
    while (collected.length < need && guard < 40) {
      guard++;
      var pageQ = q.limit(kAdminPageSizeLarge);
      if (last != null) pageQ = pageQ.startAfterDocument(last);
      final snap = await pageQ.get();
      if (snap.docs.isEmpty) break;
      for (final doc in snap.docs) {
        final order = OrderRecord.fromSnapshot(doc);
        if (range != null && filter.driverRef != null) {
          final d = order.dataOrder;
          if (d == null) continue;
          if (d.isBefore(range.startInclusive) || !d.isBefore(range.endExclusive)) {
            continue;
          }
        }
        if (AdminRoleService.isCountryAgent) {
          final ok = AdminCountryScope.filterOrders([order]);
          if (ok.isEmpty) continue;
        }
        final line = FinancialOrderAdapter.analyzeOrder(order);
        if (!_matchesLine(line, filter)) continue;
        collected.add(FinancialReportRow(order: order, line: line));
      }
      last = snap.docs.last;
      if (snap.docs.length < kAdminPageSizeLarge) break;
    }

    final start = page * pageSize;
    if (start >= collected.length) return const [];
    final end =
        (start + pageSize > collected.length) ? collected.length : start + pageSize;
    return collected.sublist(start, end);
  }

  static Future<
      ({
        Map<String, FinancialCurrencyTotals> byCurrency,
        FinancialQualityStats quality,
        int docsScanned,
        bool truncated,
        List<FinancialOrderLine> lines,
      })> _clientFullScan(FinancialReportFilter filter) async {
    final range = filter.dateRange;
    final country = filter.countryRef;
    final results = <OrderRecord>[];
    DocumentSnapshot? last;
    var truncated = false;

    while (results.length < clientFullScanCap) {
      Query q = OrderRecord.collection.orderBy('data_order', descending: true);
      if (filter.driverRef != null) {
        q = OrderRecord.collection
            .where('mndob_user', isEqualTo: filter.driverRef)
            .orderBy('data_order', descending: true);
      } else if (country != null) {
        q = OrderRecord.collection
            .where('Rev_dolh', isEqualTo: country)
            .orderBy('data_order', descending: true);
      }
      if (range != null && filter.driverRef == null) {
        q = q
            .where('data_order', isGreaterThanOrEqualTo: range.startTimestamp)
            .where('data_order', isLessThan: range.endTimestamp);
      }
      if (last != null) q = q.startAfterDocument(last);
      final snap = await q.limit(kAdminPageSizeLarge).get();
      if (snap.docs.isEmpty) break;
      for (final doc in snap.docs) {
        final order = OrderRecord.fromSnapshot(doc);
        if (range != null && filter.driverRef != null) {
          final d = order.dataOrder;
          if (d == null) continue;
          if (d.isBefore(range.startInclusive) || !d.isBefore(range.endExclusive)) {
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
    if (results.length >= clientFullScanCap) truncated = true;

    final lines = <FinancialOrderLine>[];
    var missingPay = 0, missingLife = 0, missingDriver = 0, unsupported = 0;
    var reconciled = 0, reconDiff = 0;
    for (final order in results) {
      final data = order.snapshotData;
      if (data['payment_status'] == null) missingPay++;
      if (data['status_code'] == null) missingLife++;
      if (order.mndobUser == null) missingDriver++;
      final line = FinancialOrderAdapter.analyzeOrder(order);
      if (!line.currencySupported) unsupported++;
      if (line.reconStatus == FinancialReconStatus.reconciled) reconciled++;
      if (line.reconStatus == FinancialReconStatus.difference) reconDiff++;
      if (!_matchesLine(line, filter)) continue;
      lines.add(line);
    }

    return (
      byCurrency: FinancialAccountingEngine.aggregateByCurrency(lines),
      quality: FinancialQualityStats(
        totalLines: lines.length,
        high: lines.where((l) => l.confidence == FinancialConfidence.high).length,
        derived:
            lines.where((l) => l.confidence == FinancialConfidence.derived).length,
        incomplete: lines
            .where((l) => l.confidence == FinancialConfidence.incomplete)
            .length,
        reconciled: reconciled,
        reconciliationDifference: reconDiff,
        unsupportedCurrency: unsupported,
        missingPaymentStatus: missingPay,
        missingLifecycle: missingLife,
        missingDriver: missingDriver,
      ),
      docsScanned: results.length,
      truncated: truncated,
      lines: lines,
    );
  }

  static Map<String, FinancialCurrencyTotals> _parseRemoteTotals(
    Map<String, dynamic> remote,
  ) {
    final raw = remote['byCurrency'];
    if (raw is! Map) return {};
    final out = <String, FinancialCurrencyTotals>{};
    raw.forEach((key, value) {
      if (value is! Map) return;
      final code = key.toString();
      final t = FinancialCurrencyTotals(currency: code);
      int i(String k) => (value[k] as num?)?.toInt() ?? 0;
      MoneyAmount m(String k) =>
          MoneyAmount(currency: code, minorUnits: i(k));

      t.cashCollectedTrips = i('cashCollectedTrips');
      t.onlinePaidTrips = i('onlinePaidTrips');
      t.incompleteLines = i('incompleteLines');
      t.highCount = i('highCount');
      t.derivedCount = i('derivedCount');
      t.cashCustomerCollected = m('cashCustomerCollectedMinor');
      t.cashHeldByDrivers = m('cashHeldByDriversMinor');
      t.cashDriverEntitlements = m('cashDriverEntitlementsMinor');
      t.cashPlatformFees = m('cashPlatformFeesMinor');
      t.cashRecordedVat = m('cashRecordedVatMinor');
      t.cashDiscounts = m('cashDiscountsMinor');
      t.cashDriversOweCompany = m('cashDriversOweCompanyMinor');
      t.cashCompanyOwesDrivers = m('cashCompanyOwesDriversMinor');
      t.cashUnreconciled = m('cashUnreconciledMinor');
      t.onlineCustomerPaid = m('onlineCustomerPaidMinor');
      t.onlineHeldByCompany = m('onlineHeldByCompanyMinor');
      t.onlineDriverEntitlements = m('onlineDriverEntitlementsMinor');
      t.onlinePlatformFees = m('onlinePlatformFeesMinor');
      t.onlineRecordedVat = m('onlineRecordedVatMinor');
      t.onlineDiscounts = m('onlineDiscountsMinor');
      t.onlineRemainingPosition = m('onlineRemainingPositionMinor');
      t.onlineCompanyOwesDrivers = m('onlineCompanyOwesDriversMinor');
      t.grossBaseFare = m('grossBaseFareMinor');
      t.customerPaidAll = m('customerPaidAllMinor');
      t.platformFeeAll = m('platformFeeAllMinor');
      t.recordedVatAll = m('recordedVatAllMinor');
      t.driverEntitlementAll = m('driverEntitlementAllMinor');
      t.recordedDiscountsAll = m('recordedDiscountsAllMinor');
      t.completedAndCollected = i('completedAndCollected');
      t.paidButNotCompleted = i('paidButNotCompleted');
      t.completedButNotCollected = i('completedButNotCollected');
      t.pendingPayment = i('pendingPayment');
      t.cancelledOrExpired = i('cancelledOrExpired');
      out[code] = t;
    });
    return out;
  }

  static FinancialQualityStats _parseQuality(Map<String, dynamic> remote) {
    final q = remote['quality'];
    if (q is! Map) return const FinancialQualityStats();
    int i(String k) => (q[k] as num?)?.toInt() ?? 0;
    return FinancialQualityStats(
      totalLines: i('totalLines'),
      high: i('high'),
      derived: i('derived'),
      incomplete: i('incomplete'),
      reconciled: i('reconciled'),
      reconciliationDifference: i('reconciliationDifference'),
      unsupportedCurrency: i('unsupportedCurrency'),
      missingPaymentStatus: i('missingPaymentStatus'),
      missingLifecycle: i('missingLifecycle'),
      missingDriver: i('missingDriver'),
    );
  }
}

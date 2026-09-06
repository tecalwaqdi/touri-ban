import '/backend/schema/order_record.dart';
import '/core/finance/accountant_finance_read_model.dart';
import '/core/finance/finance_reconciliation_qa.dart';
import '/core/finance/financial_accounting_engine.dart';
import '/core/finance/financial_amount_resolution.dart';
import '/core/finance/financial_order_adapter.dart';
import '/core/finance/financial_trip_semantics.dart';
import '/core/finance/money_amount.dart';

// ---------------------------------------------------------------------------
// Status axes (independent — never collapse)
// ---------------------------------------------------------------------------

enum RecOperationalStatus { completed, notCompleted }

enum RecFinancialSnapshotStatus { complete, partial, unresolved }

enum RecPaymentMethod { cash, online, unknown }

enum RecCollectionStatus { collected, uncollected, notApplicable, unknown }

enum RecAgentStatus { complete, none, ambiguous, missing, unresolved }

enum RecSettlementStatus {
  unsettled,
  partial,
  settled,
  notRequired,
  unknown,
}

enum RecReconciliationStatus {
  reconciled,
  needsReview,
  blockedByMissingData,
}

enum RecSettlementEligibility {
  eligible,
  notYetEligible,
  blockedByData,
  notApplicable,
}

/// Stable accountant-facing issue codes (labels later).
abstract final class RecIssueCode {
  RecIssueCode._();

  static const missingGross = 'MISSING_GROSS';
  static const missingDriverNet = 'MISSING_DRIVER_NET';
  static const missingAgentHistory = 'MISSING_AGENT_HISTORY';
  static const cashNotCollected = 'CASH_NOT_COLLECTED';
  static const noSettlement = 'NO_SETTLEMENT';
  static const settlementPartial = 'SETTLEMENT_PARTIAL';
  static const settlementMismatch = 'SETTLEMENT_MISMATCH';
  static const ambiguousAgent = 'AMBIGUOUS_AGENT';
  static const unallocatedPayment = 'UNALLOCATED_PAYMENT';
  static const financialSnapshotMismatch = 'FINANCIAL_SNAPSHOT_MISMATCH';
  static const agentAmountMismatch = 'AGENT_AMOUNT_MISMATCH';
  static const unresolvedAgent = 'UNRESOLVED_AGENT';
  static const unresolvedFinancial = 'UNRESOLVED_FINANCIAL';
  static const partialFinancial = 'PARTIAL_FINANCIAL';
}

/// Business-state vs data-quality classification for an issue.
enum RecIssueKind { businessState, dataQuality }

class RecIssue {
  const RecIssue({
    required this.code,
    required this.kind,
    this.detail,
  });

  final String code;
  final RecIssueKind kind;
  final String? detail;
}

class RecSettlementLink {
  const RecSettlementLink({
    required this.settlementId,
    this.direction,
    this.dueMinor,
    this.paidMinor,
    this.remainingMinor,
    this.status,
  });

  final String settlementId;
  final String? direction;
  final int? dueMinor;
  final int? paidMinor;
  final int? remainingMinor;
  final String? status;
}

class RecSourceEvidence {
  const RecSourceEvidence({
    this.operationalField,
    this.financialFields = const [],
    this.collectionField,
    this.agentSnapshotFields = const [],
    this.settlementSource,
  });

  final String? operationalField;
  final List<String> financialFields;
  final String? collectionField;
  final List<String> agentSnapshotFields;
  final String? settlementSource;
}

class FinanceReconciliationRecord {
  const FinanceReconciliationRecord({
    required this.orderId,
    required this.displayReference,
    required this.countryPath,
    required this.driverId,
    required this.completedAt,
    required this.paymentMethod,
    required this.operationalStatus,
    required this.financialSnapshotStatus,
    required this.collectionStatus,
    required this.agentStatus,
    required this.settlementStatus,
    required this.reconciliationStatus,
    required this.settlementEligibility,
    this.gross,
    this.customerTotal,
    this.platformFee,
    this.vat,
    this.driverNet,
    this.agentAmount,
    this.companyReceivable,
    this.companyPayable,
    this.driverReceivable,
    this.driverPayable,
    this.settlementDue,
    this.settlementPaid,
    this.settlementRemaining,
    this.settlementLinks = const [],
    this.dataQualityIssues = const [],
    this.businessStateIssues = const [],
    required this.sourceEvidence,
    this.currency,
  });

  final String orderId;
  final String displayReference;
  final String? countryPath;
  final String? driverId;
  final DateTime? completedAt;
  final RecPaymentMethod paymentMethod;

  final RecOperationalStatus operationalStatus;
  final RecFinancialSnapshotStatus financialSnapshotStatus;
  final RecCollectionStatus collectionStatus;
  final RecAgentStatus agentStatus;
  final RecSettlementStatus settlementStatus;
  final RecReconciliationStatus reconciliationStatus;
  final RecSettlementEligibility settlementEligibility;

  final MoneyAmount? gross;
  final MoneyAmount? customerTotal;
  final MoneyAmount? platformFee;
  final MoneyAmount? vat;
  final MoneyAmount? driverNet;
  final MoneyAmount? agentAmount;

  final MoneyAmount? companyReceivable;
  final MoneyAmount? companyPayable;
  final MoneyAmount? driverReceivable;
  final MoneyAmount? driverPayable;

  final MoneyAmount? settlementDue;
  final MoneyAmount? settlementPaid;
  final MoneyAmount? settlementRemaining;

  final List<RecSettlementLink> settlementLinks;
  final List<RecIssue> dataQualityIssues;
  final List<RecIssue> businessStateIssues;
  final RecSourceEvidence sourceEvidence;
  final String? currency;

  List<RecIssue> get allIssues => [...dataQualityIssues, ...businessStateIssues];
}

class FinanceReconciliationSummary {
  const FinanceReconciliationSummary({
    required this.completedTrips,
    required this.financialComplete,
    required this.financialPartial,
    required this.financialUnresolved,
    required this.reconciled,
    required this.needsReview,
    required this.blockedByMissingData,
    required this.cashCollected,
    required this.cashUncollected,
    required this.settled,
    required this.unsettled,
    required this.agentComplete,
    required this.agentMissing,
    required this.agentNone,
    required this.agentAmbiguous,
    required this.agentUnresolved,
    required this.qaFixturesExcluded,
    required this.moneyOmittedIncompleteCount,
    required this.currency,
    this.completedGross,
    this.companyReceivableTotal,
    this.companyPayableTotal,
    this.driverReceivableTotal,
    this.driverPayableTotal,
  });

  final int completedTrips;
  final int financialComplete;
  final int financialPartial;
  final int financialUnresolved;
  final int reconciled;
  final int needsReview;
  final int blockedByMissingData;
  final int cashCollected;
  final int cashUncollected;
  final int settled;
  final int unsettled;
  final int agentComplete;
  final int agentMissing;
  final int agentNone;
  final int agentAmbiguous;
  final int agentUnresolved;
  final int qaFixturesExcluded;
  final int moneyOmittedIncompleteCount;
  final String currency;

  /// Only COMPLETE financial snapshots contribute.
  final MoneyAmount? completedGross;
  final MoneyAmount? companyReceivableTotal;
  final MoneyAmount? companyPayableTotal;
  final MoneyAmount? driverReceivableTotal;
  final MoneyAmount? driverPayableTotal;
}

class UnallocatedCompanyPaymentView {
  const UnallocatedCompanyPaymentView({
    required this.id,
    this.amountMinor,
    this.currency,
    this.externalRef,
    this.note,
  });

  final String id;
  final int? amountMinor;
  final String? currency;
  final String? externalRef;
  final String? note;
}

class FinanceReconciliationResult {
  const FinanceReconciliationResult({
    required this.records,
    required this.summary,
    required this.exceptions,
    required this.unallocatedPayments,
    this.diagnosticsExcluded = const [],
  });

  final List<FinanceReconciliationRecord> records;
  final FinanceReconciliationSummary summary;
  final List<FinanceReconciliationRecord> exceptions;
  final List<UnallocatedCompanyPaymentView> unallocatedPayments;

  /// QA / golden rows excluded from normal counts (diagnostics only).
  final List<FinanceReconciliationRecord> diagnosticsExcluded;
}

/// Canonical F3-B1 read-only reconciliation model.
///
/// Pure transformation: Firestore loading is out of scope.
abstract final class FinanceReconciliationReadModel {
  FinanceReconciliationReadModel._();

  /// Canonical percent-of-platform-fee agent share (matches C2 Functions).
  static int? computeAgentAmountMinor(
    int? platformFeeMinor,
    num? ratePercent,
  ) {
    if (platformFeeMinor == null || ratePercent == null) return null;
    if (ratePercent <= 0) return null;
    return (platformFeeMinor * ratePercent / 100).round();
  }

  static FinanceReconciliationResult buildReconciliation({
    required Iterable<OrderRecord> orders,
    required AccountantFinanceScope scope,
    required String currency,
    Iterable<Map<String, dynamic>> settlements = const [],
    Iterable<Map<String, dynamic>> settlementPayments = const [],
    Iterable<Map<String, dynamic>> unallocatedPayments = const [],
  }) {
    final code = CurrencyMoneyPolicy.normalizeCode(currency);
    final settlementIndex = _indexSettlements(settlements);

    final records = <FinanceReconciliationRecord>[];
    final diagnostics = <FinanceReconciliationRecord>[];
    var qaExcluded = 0;

    for (final order in orders) {
      final data = Map<String, dynamic>.from(order.snapshotData);

      if (FinanceReconciliationQa.isReconciliationQaOrder(order)) {
        qaExcluded++;
        final diag = _classifyOne(
          order: order,
          data: data,
          currencyCode: code,
          settlementIndex: settlementIndex,
          forceInclude: true,
        );
        if (diag != null) diagnostics.add(diag);
        continue;
      }

      final snap = FinancialOrderAdapter.fromOrder(order);
      if (!scope.allowsCountry(snap.countryPath)) continue;
      if (!scope.allowsDriver(snap.driverId)) continue;

      final lineCurrency = CurrencyMoneyPolicy.normalizeCode(
        (snap.currency ?? '').isNotEmpty ? snap.currency : code,
      );
      // Scope first; currency filter only for money aggregation later.
      final rec = _classifyOne(
        order: order,
        data: data,
        currencyCode: code,
        settlementIndex: settlementIndex,
        forceInclude: false,
      );
      if (rec == null) continue;

      // Country/driver already applied. Include all operational statuses for
      // completeness of input set? Spec: every *included* trip — we include
      // completed + not completed that passed scope (for test 5).
      if (lineCurrency != code &&
          rec.operationalStatus == RecOperationalStatus.completed) {
        // Still count in completed with unresolved currency? Prefer skip money
        // but keep record when operational completed in other currency only if
        // scope wants all — F1 skips other currencies. Match F1: skip.
        continue;
      }
      records.add(rec);
    }

    final summary = _summarize(records, code, qaExcluded);
    final exceptions = records
        .where((r) =>
            r.reconciliationStatus != RecReconciliationStatus.reconciled)
        .toList();

    final unalloc = <UnallocatedCompanyPaymentView>[];
    for (final p in unallocatedPayments) {
      final id = '${p['id'] ?? p['paymentId'] ?? ''}'.trim();
      if (id.isEmpty) continue;
      if (FinanceReconciliationQa.isReconciliationQaFixture(p, orderId: id)) {
        continue;
      }
      unalloc.add(UnallocatedCompanyPaymentView(
        id: id,
        amountMinor: (p['amountMinor'] as num?)?.toInt() ??
            (p['amount_minor'] as num?)?.toInt(),
        currency: (p['currency'] ?? '').toString().trim().isEmpty
            ? null
            : (p['currency'] as String),
        externalRef: (p['externalRef'] ?? p['external_ref'] ?? '').toString(),
        note: 'UNALLOCATED — not auto-matched to trips/settlements',
      ));
    }

    // [settlementPayments] accepted for API stability — never heuristically
    // matched to trips (legacy company_payments remain UNALLOCATED).
    final _ = settlementPayments;

    return FinanceReconciliationResult(
      records: records,
      summary: summary,
      exceptions: exceptions,
      unallocatedPayments: unalloc,
      diagnosticsExcluded: diagnostics,
    );
  }

  // -------------------------------------------------------------------------
  // Classification
  // -------------------------------------------------------------------------

  static FinanceReconciliationRecord? _classifyOne({
    required OrderRecord order,
    required Map<String, dynamic> data,
    required String currencyCode,
    required Map<String, List<_SettlementDoc>> settlementIndex,
    required bool forceInclude,
  }) {
    final snap = FinancialOrderAdapter.fromOrder(order);
    final line = FinancialAccountingEngine.analyze(snap);
    final resolution = FinancialAmountResolution.fromLine(line);
    final orderId = order.reference.id;

    final opCompleted =
        FinancialTripSemantics.isOperationallyCompletedSnapshot(snap);
    final operational = opCompleted
        ? RecOperationalStatus.completed
        : RecOperationalStatus.notCompleted;

    if (!forceInclude &&
        !opCompleted &&
        operational == RecOperationalStatus.notCompleted) {
      // Still emit not-completed when caller wants matrix coverage — include
      // all scoped orders so test 5 can assert notCompleted.
    }

    // COMPLETE = preferred stored components present (missing ≠ 0).
    // Formula mismatches are separate issues — do not downgrade to PARTIAL
    // when all required snapshot fields exist (F3-B1 §D / §U).
    final financial = _financialSnapshotStatus(snap, resolution);

    final paymentMethod = switch (line.channel) {
      FinancialPaymentChannel.cash => RecPaymentMethod.cash,
      FinancialPaymentChannel.online => RecPaymentMethod.online,
      FinancialPaymentChannel.unknown => RecPaymentMethod.unknown,
    };

    final collection = _collectionStatus(
      order: order,
      snap: snap,
      method: paymentMethod,
    );

    final agent = _agentStatus(snap);
    final links = settlementIndex[orderId] ?? const <_SettlementDoc>[];
    final settlement = _settlementStatus(
      links: links,
      operational: operational,
      financial: financial,
      method: paymentMethod,
    );

    final dataIssues = <RecIssue>[];
    final bizIssues = <RecIssue>[];

    if (!snap.hasTotalMndob2) {
      dataIssues.add(const RecIssue(
        code: RecIssueCode.missingGross,
        kind: RecIssueKind.dataQuality,
      ));
    }
    if (!snap.hasTotalMndob) {
      dataIssues.add(const RecIssue(
        code: RecIssueCode.missingDriverNet,
        kind: RecIssueKind.dataQuality,
      ));
    }
    // Prefer stored-field presence over engine derivation for issue codes.
    if (resolution.missingFields.contains('gross') && snap.hasTotalMndob2) {
      // already covered
    }
    if (financial == RecFinancialSnapshotStatus.partial) {
      dataIssues.add(const RecIssue(
        code: RecIssueCode.partialFinancial,
        kind: RecIssueKind.dataQuality,
      ));
    }
    if (financial == RecFinancialSnapshotStatus.unresolved) {
      dataIssues.add(const RecIssue(
        code: RecIssueCode.unresolvedFinancial,
        kind: RecIssueKind.dataQuality,
      ));
    }

    // Formula check when all components present (do not overwrite).
    if (resolution.gross != null &&
        resolution.companyCommission != null &&
        resolution.vat != null &&
        resolution.driverNet != null) {
      final expected = resolution.gross!.minorUnits -
          resolution.companyCommission!.minorUnits -
          resolution.vat!.minorUnits;
      if ((expected - resolution.driverNet!.minorUnits).abs() >
          FinancialAccountingEngine.matchToleranceMinor) {
        dataIssues.add(RecIssue(
          code: RecIssueCode.financialSnapshotMismatch,
          kind: RecIssueKind.dataQuality,
          detail:
              'expected_driver_net_minor=$expected actual=${resolution.driverNet!.minorUnits}',
        ));
      }
    }

    if (agent == RecAgentStatus.missing) {
      dataIssues.add(const RecIssue(
        code: RecIssueCode.missingAgentHistory,
        kind: RecIssueKind.dataQuality,
      ));
    } else if (agent == RecAgentStatus.ambiguous) {
      dataIssues.add(const RecIssue(
        code: RecIssueCode.ambiguousAgent,
        kind: RecIssueKind.dataQuality,
      ));
    } else if (agent == RecAgentStatus.unresolved) {
      dataIssues.add(const RecIssue(
        code: RecIssueCode.unresolvedAgent,
        kind: RecIssueKind.dataQuality,
      ));
    }

    // Agent share validation — historical fields only.
    final rateType = (snap.agentRateType ?? '').trim().toLowerCase();
    if (rateType == 'percent_of_platform_fee' &&
        snap.agentRate != null &&
        snap.agentAmountMinor != null &&
        resolution.companyCommission != null) {
      final expected = computeAgentAmountMinor(
        resolution.companyCommission!.minorUnits,
        snap.agentRate,
      );
      if (expected != null &&
          (expected - snap.agentAmountMinor!).abs() >
              FinancialAccountingEngine.matchToleranceMinor) {
        dataIssues.add(RecIssue(
          code: RecIssueCode.agentAmountMismatch,
          kind: RecIssueKind.dataQuality,
          detail: 'expected=$expected actual=${snap.agentAmountMinor}',
        ));
      }
    }

    if (paymentMethod == RecPaymentMethod.cash &&
        collection == RecCollectionStatus.uncollected &&
        operational == RecOperationalStatus.completed) {
      bizIssues.add(const RecIssue(
        code: RecIssueCode.cashNotCollected,
        kind: RecIssueKind.businessState,
      ));
    }

    final eligibility = _settlementEligibility(
      operational: operational,
      financial: financial,
      collection: collection,
      method: paymentMethod,
      settlement: settlement,
      lineEligible: line.settlementEligible,
      hasMismatch: dataIssues.any(
        (i) => i.code == RecIssueCode.financialSnapshotMismatch,
      ),
    );

    if (eligibility == RecSettlementEligibility.eligible &&
        settlement == RecSettlementStatus.unsettled) {
      bizIssues.add(const RecIssue(
        code: RecIssueCode.noSettlement,
        kind: RecIssueKind.businessState,
      ));
    }
    if (settlement == RecSettlementStatus.partial) {
      bizIssues.add(const RecIssue(
        code: RecIssueCode.settlementPartial,
        kind: RecIssueKind.businessState,
      ));
    }

    MoneyAmount? settleDue;
    MoneyAmount? settlePaid;
    MoneyAmount? settleRem;
    final linkViews = <RecSettlementLink>[];
    for (final s in links) {
      linkViews.add(RecSettlementLink(
        settlementId: s.id,
        direction: s.direction,
        dueMinor: s.dueMinor,
        paidMinor: s.paidMinor,
        remainingMinor: s.remainingMinor,
        status: s.status,
      ));
      if (s.dueMinor != null &&
          s.paidMinor != null &&
          s.remainingMinor != null) {
        final expectedRem = s.dueMinor! - s.paidMinor!;
        if ((expectedRem - s.remainingMinor!).abs() >
            FinancialAccountingEngine.matchToleranceMinor) {
          dataIssues.add(RecIssue(
            code: RecIssueCode.settlementMismatch,
            kind: RecIssueKind.dataQuality,
            detail:
                'settlement=${s.id} expected_remaining=$expectedRem actual=${s.remainingMinor}',
          ));
        }
      }
      settleDue ??= s.dueMinor != null
          ? MoneyAmount(currency: currencyCode, minorUnits: s.dueMinor!)
          : null;
      settlePaid ??= s.paidMinor != null
          ? MoneyAmount(currency: currencyCode, minorUnits: s.paidMinor!)
          : null;
      settleRem ??= s.remainingMinor != null
          ? MoneyAmount(currency: currencyCode, minorUnits: s.remainingMinor!)
          : null;
    }

    final obligations = _obligations(
      method: paymentMethod,
      collection: collection,
      financial: financial,
      resolution: resolution,
      line: line,
      currencyCode: currencyCode,
    );

    final recon = _reconciliationStatus(
      operational: operational,
      financial: financial,
      agent: agent,
      collection: collection,
      method: paymentMethod,
      dataIssues: dataIssues,
      bizIssues: bizIssues,
    );

    final display = _displayReference(order, data);
    final evidence = RecSourceEvidence(
      operationalField: (data['status_code'] ?? '').toString().trim().isEmpty
          ? 'legacy_halh_fallback'
          : 'status_code',
      financialFields: [
        if (snap.hasTotalMndob2) 'total_mndob2',
        if (snap.hasTotalApp) 'total_app',
        if (snap.hasTotalVat) 'total_vat',
        if (snap.hasTotalMndob) 'total_mndob',
        if (snap.hasTotal) 'total',
      ],
      collectionField: paymentMethod == RecPaymentMethod.online
          ? 'n/a_online'
          : (FinancialTripSemantics.isCashCollected(order)
              ? 'payment_status|cash_collection_status'
              : 'payment_status|cash_collection_status'),
      agentSnapshotFields: [
        if ((snap.agentAttributionStatus ?? '').isNotEmpty)
          'agent_attribution_status',
        if ((snap.agentId ?? '').isNotEmpty) 'agent_id',
        if (snap.agentRate != null) 'agent_rate',
        if ((snap.agentRateType ?? '').isNotEmpty) 'agent_rate_type',
        if (snap.agentAmountMinor != null) 'agent_amount_minor',
      ],
      settlementSource:
          links.isEmpty ? 'none' : 'financial_settlements:${links.length}',
    );

    final MoneyAmount? gross =
        snap.hasTotalMndob2 ? resolution.gross : null;
    final MoneyAmount? platformFee =
        snap.hasTotalApp ? resolution.companyCommission : null;
    final MoneyAmount? vat = snap.hasTotalVat ? resolution.vat : null;
    final MoneyAmount? driverNet =
        snap.hasTotalMndob ? resolution.driverNet : null;
    final MoneyAmount? customerTotal =
        snap.hasTotal ? line.customerPaid : null;

    return FinanceReconciliationRecord(
      orderId: orderId,
      displayReference: display,
      countryPath: snap.countryPath,
      driverId: snap.driverId,
      completedAt: snap.orderedAt,
      paymentMethod: paymentMethod,
      operationalStatus: operational,
      financialSnapshotStatus: financial,
      collectionStatus: collection,
      agentStatus: agent,
      settlementStatus: settlement,
      reconciliationStatus: recon,
      settlementEligibility: eligibility,
      gross: gross,
      customerTotal: customerTotal,
      platformFee: platformFee,
      vat: vat,
      driverNet: driverNet,
      agentAmount: line.agentAmount,
      companyReceivable: obligations.companyReceivable,
      companyPayable: obligations.companyPayable,
      driverReceivable: obligations.driverReceivable,
      driverPayable: obligations.driverPayable,
      settlementDue: settleDue,
      settlementPaid: settlePaid,
      settlementRemaining: settleRem,
      settlementLinks: linkViews,
      dataQualityIssues: dataIssues,
      businessStateIssues: bizIssues,
      sourceEvidence: evidence,
      currency: currencyCode,
    );
  }

  static RecFinancialSnapshotStatus _financialSnapshotStatus(
    FinancialOrderSnapshot snap,
    FinancialAmountResolution resolution,
  ) {
    final preferredComplete = snap.hasTotalMndob2 &&
        snap.hasTotalApp &&
        snap.hasTotalVat &&
        snap.hasTotalMndob;
    if (preferredComplete) {
      return RecFinancialSnapshotStatus.complete;
    }
    return switch (resolution.quality) {
      FinancialDataQuality.complete => RecFinancialSnapshotStatus.complete,
      FinancialDataQuality.partial => RecFinancialSnapshotStatus.partial,
      FinancialDataQuality.unresolved => RecFinancialSnapshotStatus.unresolved,
    };
  }

  static RecCollectionStatus _collectionStatus({
    required OrderRecord order,
    required FinancialOrderSnapshot snap,
    required RecPaymentMethod method,
  }) {
    if (method == RecPaymentMethod.online) {
      return RecCollectionStatus.notApplicable;
    }
    if (method == RecPaymentMethod.unknown) {
      if (FinancialTripSemantics.isCashCollected(order) ||
          FinancialTripSemantics.isCashCollectedSnapshot(snap)) {
        return RecCollectionStatus.collected;
      }
      return RecCollectionStatus.unknown;
    }
    // CASH
    if (FinancialTripSemantics.isCashCollected(order) ||
        FinancialTripSemantics.isCashCollectedSnapshot(snap)) {
      return RecCollectionStatus.collected;
    }
    return RecCollectionStatus.uncollected;
  }

  static RecAgentStatus _agentStatus(FinancialOrderSnapshot o) {
    final status = (o.agentAttributionStatus ?? '').trim().toLowerCase();
    final id = (o.agentId ?? '').trim();
    final hasAmount = o.agentAmountMinor != null;
    final hasRate = o.agentRate != null;

    if (status == 'none') return RecAgentStatus.none;
    if (status == 'ambiguous') return RecAgentStatus.ambiguous;
    if (status == 'rate_missing' || status == 'platform_missing') {
      return RecAgentStatus.unresolved;
    }
    if (status == 'attributed' || status == 'snapshot') {
      if (id.isNotEmpty && hasAmount) return RecAgentStatus.complete;
      return RecAgentStatus.unresolved;
    }

    if (status.isEmpty && id.isEmpty && !hasAmount && !hasRate) {
      return RecAgentStatus.missing;
    }
    if (id.isNotEmpty && hasAmount) return RecAgentStatus.complete;
    if (id.isNotEmpty || hasAmount || hasRate) {
      return RecAgentStatus.unresolved;
    }
    return RecAgentStatus.missing;
  }

  static RecSettlementStatus _settlementStatus({
    required List<_SettlementDoc> links,
    required RecOperationalStatus operational,
    required RecFinancialSnapshotStatus financial,
    required RecPaymentMethod method,
  }) {
    if (links.isEmpty) {
      if (operational != RecOperationalStatus.completed) {
        return RecSettlementStatus.notRequired;
      }
      return RecSettlementStatus.unsettled;
    }

    var anySettled = false;
    var anyPartial = false;
    var anyOpen = false;
    for (final s in links) {
      final st = (s.status ?? '').toLowerCase();
      if (st == 'settled' || st == 'complete' || st == 'completed') {
        anySettled = true;
        continue;
      }
      if (st == 'partially_paid' || st == 'partial') {
        anyPartial = true;
        continue;
      }
      if (s.dueMinor != null &&
          s.paidMinor != null &&
          s.paidMinor! > 0 &&
          s.remainingMinor != null &&
          s.remainingMinor! > 0) {
        anyPartial = true;
        continue;
      }
      anyOpen = true;
    }
    if (anySettled && !anyPartial && !anyOpen) {
      return RecSettlementStatus.settled;
    }
    if (anyPartial || (anySettled && anyOpen)) {
      return RecSettlementStatus.partial;
    }
    if (anyOpen) return RecSettlementStatus.unsettled;
    return RecSettlementStatus.unknown;
  }

  static RecSettlementEligibility _settlementEligibility({
    required RecOperationalStatus operational,
    required RecFinancialSnapshotStatus financial,
    required RecCollectionStatus collection,
    required RecPaymentMethod method,
    required RecSettlementStatus settlement,
    required bool lineEligible,
    required bool hasMismatch,
  }) {
    if (operational != RecOperationalStatus.completed) {
      return RecSettlementEligibility.notApplicable;
    }
    if (settlement == RecSettlementStatus.settled) {
      return RecSettlementEligibility.notApplicable;
    }
    if (financial != RecFinancialSnapshotStatus.complete || hasMismatch) {
      return RecSettlementEligibility.blockedByData;
    }
    if (method == RecPaymentMethod.cash &&
        collection != RecCollectionStatus.collected) {
      return RecSettlementEligibility.notYetEligible;
    }
    if (method == RecPaymentMethod.online &&
        collection == RecCollectionStatus.unknown) {
      return RecSettlementEligibility.notYetEligible;
    }
    // Prefer frozen engine eligibility when available.
    if (lineEligible) return RecSettlementEligibility.eligible;
    if (method == RecPaymentMethod.cash &&
        collection == RecCollectionStatus.collected &&
        financial == RecFinancialSnapshotStatus.complete) {
      return RecSettlementEligibility.eligible;
    }
    if (method == RecPaymentMethod.online &&
        financial == RecFinancialSnapshotStatus.complete) {
      // Online: company holds funds; settlement of driver may be eligible when paid.
      return RecSettlementEligibility.eligible;
    }
    return RecSettlementEligibility.notYetEligible;
  }

  static ({
    MoneyAmount? companyReceivable,
    MoneyAmount? companyPayable,
    MoneyAmount? driverReceivable,
    MoneyAmount? driverPayable,
  }) _obligations({
    required RecPaymentMethod method,
    required RecCollectionStatus collection,
    required RecFinancialSnapshotStatus financial,
    required FinancialAmountResolution resolution,
    required FinancialOrderLine line,
    required String currencyCode,
  }) {
    MoneyAmount? companyReceivable;
    MoneyAmount? companyPayable;
    MoneyAmount? driverReceivable;
    MoneyAmount? driverPayable;

    if (financial != RecFinancialSnapshotStatus.complete) {
      return (
        companyReceivable: null,
        companyPayable: null,
        driverReceivable: null,
        driverPayable: null,
      );
    }

    final commission = resolution.companyCommission;
    final vat = resolution.vat;
    final driverNet = resolution.driverNet;
    final companyShare = (commission != null && vat != null)
        ? MoneyAmount(
            currency: currencyCode,
            minorUnits: commission.minorUnits + vat.minorUnits,
          )
        : line.signedCashPosition;

    if (method == RecPaymentMethod.cash) {
      // Customer → Driver. After collection, Driver may owe Company.
      if (collection == RecCollectionStatus.collected) {
        companyReceivable = companyShare;
        driverPayable = companyShare;
      }
      // Uncollected: obligations unresolved until collection.
    } else if (method == RecPaymentMethod.online) {
      // Company holds funds; may owe Driver.
      companyPayable = driverNet;
      driverReceivable = driverNet;
    }

    return (
      companyReceivable: companyReceivable,
      companyPayable: companyPayable,
      driverReceivable: driverReceivable,
      driverPayable: driverPayable,
    );
  }

  /// Deterministic reconciliation rollup.
  ///
  /// RECONCILED — operational completed + financial COMPLETE + agent COMPLETE|NONE
  ///   + no data-quality mismatch issues + cash collected (or online N/A)
  ///   + settlement not mismatched.
  /// BLOCKED_BY_MISSING_DATA — financial PARTIAL/UNRESOLVED or agent MISSING/UNRESOLVED.
  /// NEEDS_REVIEW — otherwise (business gaps, ambiguous agent, formula mismatch, etc.).
  static RecReconciliationStatus _reconciliationStatus({
    required RecOperationalStatus operational,
    required RecFinancialSnapshotStatus financial,
    required RecAgentStatus agent,
    required RecCollectionStatus collection,
    required RecPaymentMethod method,
    required List<RecIssue> dataIssues,
    required List<RecIssue> bizIssues,
  }) {
    if (operational != RecOperationalStatus.completed) {
      return RecReconciliationStatus.blockedByMissingData;
    }

    if (financial == RecFinancialSnapshotStatus.partial ||
        financial == RecFinancialSnapshotStatus.unresolved ||
        agent == RecAgentStatus.missing ||
        agent == RecAgentStatus.unresolved) {
      return RecReconciliationStatus.blockedByMissingData;
    }

    final hasHardDataIssue = dataIssues.any((i) =>
        i.code == RecIssueCode.financialSnapshotMismatch ||
        i.code == RecIssueCode.agentAmountMismatch ||
        i.code == RecIssueCode.settlementMismatch ||
        i.code == RecIssueCode.ambiguousAgent);

    if (hasHardDataIssue || agent == RecAgentStatus.ambiguous) {
      return RecReconciliationStatus.needsReview;
    }

    if (method == RecPaymentMethod.cash &&
        collection == RecCollectionStatus.uncollected) {
      return RecReconciliationStatus.needsReview;
    }

    if (bizIssues.any((i) =>
        i.code == RecIssueCode.settlementPartial ||
        i.code == RecIssueCode.noSettlement)) {
      // Eligible but unsettled → review, not reconciled.
      if (bizIssues.any((i) => i.code == RecIssueCode.noSettlement) ||
          bizIssues.any((i) => i.code == RecIssueCode.settlementPartial)) {
        return RecReconciliationStatus.needsReview;
      }
    }

    if (agent == RecAgentStatus.complete || agent == RecAgentStatus.none) {
      if (method == RecPaymentMethod.online ||
          collection == RecCollectionStatus.collected ||
          collection == RecCollectionStatus.notApplicable) {
        // Settled or not-yet-required without NO_SETTLEMENT issue.
        final unsettledEligible =
            bizIssues.any((i) => i.code == RecIssueCode.noSettlement);
        if (unsettledEligible) {
          return RecReconciliationStatus.needsReview;
        }
        return RecReconciliationStatus.reconciled;
      }
    }

    return RecReconciliationStatus.needsReview;
  }

  static String _displayReference(
    OrderRecord order,
    Map<String, dynamic> data,
  ) {
    for (final key in [
      'display_reference',
      'displayReference',
      'order_ref',
      'cash_ref',
      'booking_ref',
    ]) {
      final v = '${data[key] ?? ''}'.trim();
      if (v.isNotEmpty) return v;
    }
    final id = order.reference.id;
    if (id.length >= 8) {
      return 'CASH-${id.substring(0, 8).toUpperCase()}';
    }
    return id;
  }

  static Map<String, List<_SettlementDoc>> _indexSettlements(
    Iterable<Map<String, dynamic>> settlements,
  ) {
    final out = <String, List<_SettlementDoc>>{};
    for (final raw in settlements) {
      final id = '${raw['id'] ?? raw['settlementId'] ?? ''}'.trim();
      if (id.isEmpty) continue;
      if (FinanceReconciliationQa.isReconciliationQaSettlement(
        raw,
        settlementId: id,
      )) {
        continue;
      }
      final due = (raw['dueMinor'] as num?)?.toInt() ??
          (raw['totalDueMinor'] as num?)?.toInt();
      final paid = (raw['paidMinor'] as num?)?.toInt() ??
          (raw['totalPaidMinor'] as num?)?.toInt();
      var remaining = (raw['remainingMinor'] as num?)?.toInt() ??
          (raw['outstandingMinor'] as num?)?.toInt();
      if (remaining == null && due != null && paid != null) {
        remaining = due - paid;
      }
      final doc = _SettlementDoc(
        id: id,
        direction: (raw['direction'] ?? '').toString().trim().isEmpty
            ? null
            : (raw['direction'] as String),
        dueMinor: due,
        paidMinor: paid,
        remainingMinor: remaining,
        status: (raw['status'] ?? '').toString(),
      );
      for (final key in ['eligibleOrderIds', 'orderIds', 'lineOrderIds']) {
        final list = raw[key];
        if (list is! List) continue;
        for (final oidRaw in list) {
          final oid = '$oidRaw'.trim();
          if (oid.isEmpty) continue;
          out.putIfAbsent(oid, () => []).add(doc);
        }
      }
    }
    return out;
  }

  static FinanceReconciliationSummary _summarize(
    List<FinanceReconciliationRecord> records,
    String code,
    int qaExcluded,
  ) {
    var completed = 0;
    var finComplete = 0;
    var finPartial = 0;
    var finUnresolved = 0;
    var reconciled = 0;
    var needsReview = 0;
    var blocked = 0;
    var cashCollected = 0;
    var cashUncollected = 0;
    var settled = 0;
    var unsettled = 0;
    var agentComplete = 0;
    var agentMissing = 0;
    var agentNone = 0;
    var agentAmbiguous = 0;
    var agentUnresolved = 0;
    var omitted = 0;

    var gross = 0;
    var companyRecv = 0;
    var companyPay = 0;
    var driverRecv = 0;
    var driverPay = 0;
    var hasGross = false;
    var hasCr = false;
    var hasCp = false;
    var hasDr = false;
    var hasDp = false;

    for (final r in records) {
      if (r.operationalStatus != RecOperationalStatus.completed) continue;
      completed++;

      switch (r.financialSnapshotStatus) {
        case RecFinancialSnapshotStatus.complete:
          finComplete++;
          break;
        case RecFinancialSnapshotStatus.partial:
          finPartial++;
          omitted++;
          break;
        case RecFinancialSnapshotStatus.unresolved:
          finUnresolved++;
          omitted++;
          break;
      }

      switch (r.reconciliationStatus) {
        case RecReconciliationStatus.reconciled:
          reconciled++;
          break;
        case RecReconciliationStatus.needsReview:
          needsReview++;
          break;
        case RecReconciliationStatus.blockedByMissingData:
          blocked++;
          break;
      }

      if (r.paymentMethod == RecPaymentMethod.cash) {
        if (r.collectionStatus == RecCollectionStatus.collected) {
          cashCollected++;
        } else if (r.collectionStatus == RecCollectionStatus.uncollected) {
          cashUncollected++;
        }
      }

      if (r.settlementStatus == RecSettlementStatus.settled) {
        settled++;
      } else if (r.settlementStatus == RecSettlementStatus.unsettled ||
          r.settlementStatus == RecSettlementStatus.partial) {
        unsettled++;
      }

      switch (r.agentStatus) {
        case RecAgentStatus.complete:
          agentComplete++;
          break;
        case RecAgentStatus.missing:
          agentMissing++;
          break;
        case RecAgentStatus.none:
          agentNone++;
          break;
        case RecAgentStatus.ambiguous:
          agentAmbiguous++;
          break;
        case RecAgentStatus.unresolved:
          agentUnresolved++;
          break;
      }

      if (r.financialSnapshotStatus == RecFinancialSnapshotStatus.complete) {
        if (r.gross != null) {
          gross += r.gross!.minorUnits;
          hasGross = true;
        }
        if (r.companyReceivable != null) {
          companyRecv += r.companyReceivable!.minorUnits;
          hasCr = true;
        }
        if (r.companyPayable != null) {
          companyPay += r.companyPayable!.minorUnits;
          hasCp = true;
        }
        if (r.driverReceivable != null) {
          driverRecv += r.driverReceivable!.minorUnits;
          hasDr = true;
        }
        if (r.driverPayable != null) {
          driverPay += r.driverPayable!.minorUnits;
          hasDp = true;
        }
      }
    }

    MoneyAmount? m(bool has, int minor) =>
        has ? MoneyAmount(currency: code, minorUnits: minor) : null;

    return FinanceReconciliationSummary(
      completedTrips: completed,
      financialComplete: finComplete,
      financialPartial: finPartial,
      financialUnresolved: finUnresolved,
      reconciled: reconciled,
      needsReview: needsReview,
      blockedByMissingData: blocked,
      cashCollected: cashCollected,
      cashUncollected: cashUncollected,
      settled: settled,
      unsettled: unsettled,
      agentComplete: agentComplete,
      agentMissing: agentMissing,
      agentNone: agentNone,
      agentAmbiguous: agentAmbiguous,
      agentUnresolved: agentUnresolved,
      qaFixturesExcluded: qaExcluded,
      moneyOmittedIncompleteCount: omitted,
      currency: code,
      completedGross: m(hasGross, gross),
      companyReceivableTotal: m(hasCr, companyRecv),
      companyPayableTotal: m(hasCp, companyPay),
      driverReceivableTotal: m(hasDr, driverRecv),
      driverPayableTotal: m(hasDp, driverPay),
    );
  }
}

class _SettlementDoc {
  const _SettlementDoc({
    required this.id,
    this.direction,
    this.dueMinor,
    this.paidMinor,
    this.remainingMinor,
    this.status,
  });

  final String id;
  final String? direction;
  final int? dueMinor;
  final int? paidMinor;
  final int? remainingMinor;
  final String? status;
}

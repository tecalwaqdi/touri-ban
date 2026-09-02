import '/core/finance/money_amount.dart';
import '/core/toury_system_status_codes.dart';

/// Financial data quality for a single order line.
enum FinancialConfidence {
  high,
  derived,
  incomplete,
}

/// Reconciliation outcome for a collected line.
enum FinancialReconStatus {
  notApplicable,
  reconciled,
  difference,
  unsupported,
}

/// Admin reporting payment channel.
enum FinancialPaymentChannel {
  cash,
  online,
  unknown,
}

/// Normalized trip lifecycle for finance (not ops UI).
enum FinancialLifecycle {
  completed,
  cancelled,
  expired,
  pendingPayment,
  active,
  unknown,
}

/// Normalized payment for finance.
enum FinancialPaymentState {
  paid,
  cashCollected,
  captured,
  pendingCash,
  unpaid,
  processing,
  failed,
  refunded,
  unknown,
}

/// Collection / revenue bucket (never mixed into one "Revenue" number).
enum FinancialCollectionBucket {
  completedAndCollected,
  paidButNotCompleted,
  completedButNotCollected,
  pendingPayment,
  cancelledOrExpired,
  other,
}

/// Input snapshot — historical order fields only (no live country rates).
class FinancialOrderSnapshot {
  const FinancialOrderSnapshot({
    required this.orderId,
    this.currency,
    this.paymentMethodRaw,
    this.statusCode,
    this.paymentStatus,
    this.halhOrder,
    this.halh,
    this.allnow = false,
    this.total,
    this.totalApp,
    this.totalVat,
    this.totalMndob,
    this.totalMndob2,
    this.ksm,
    this.hasTotal = false,
    this.hasTotalApp = false,
    this.hasTotalVat = false,
    this.hasTotalMndob = false,
    this.hasTotalMndob2 = false,
    this.hasKsm = false,
    this.driverId,
    this.countryPath,
    this.orderedAt,
  });

  final String orderId;
  final String? currency;
  final String? paymentMethodRaw;
  final String? statusCode;
  final String? paymentStatus;
  final String? halhOrder;
  final String? halh;
  final bool allnow;
  final num? total;
  final num? totalApp;
  final num? totalVat;
  final num? totalMndob;
  final num? totalMndob2;
  final num? ksm;
  final bool hasTotal;
  final bool hasTotalApp;
  final bool hasTotalVat;
  final bool hasTotalMndob;
  final bool hasTotalMndob2;
  final bool hasKsm;
  final String? driverId;
  final String? countryPath;
  final DateTime? orderedAt;
}

/// Per-order accounting line for Admin reporting (read-only).
class FinancialOrderLine {
  const FinancialOrderLine({
    required this.orderId,
    required this.currency,
    required this.channel,
    required this.lifecycle,
    required this.payment,
    required this.bucket,
    required this.confidence,
    required this.currencySupported,
    this.customerPaid,
    this.grossBase,
    this.platformFee,
    this.recordedVat,
    this.recordedDiscount,
    this.driverNet,
    this.cashHeldByDriver,
    this.signedCashPosition,
    this.onlineHeldByCompany,
    this.onlineRemainingPosition,
    this.reconciliationDifference,
    this.reconStatus = FinancialReconStatus.notApplicable,
    this.settlementEligible = false,
    this.exclusionReason,
    this.notes = const [],
  });

  final String orderId;
  final String currency;
  final FinancialPaymentChannel channel;
  final FinancialLifecycle lifecycle;
  final FinancialPaymentState payment;
  final FinancialCollectionBucket bucket;
  final FinancialConfidence confidence;
  final bool currencySupported;

  final MoneyAmount? customerPaid;
  final MoneyAmount? grossBase;
  final MoneyAmount? platformFee;
  final MoneyAmount? recordedVat;
  final MoneyAmount? recordedDiscount;
  final MoneyAmount? driverNet;

  /// Cash: money held by driver after collection.
  final MoneyAmount? cashHeldByDriver;

  /// Cash: held − entitlement (>0 driver owes company).
  final MoneyAmount? signedCashPosition;

  /// Online: money held by company/gateway.
  final MoneyAmount? onlineHeldByCompany;

  /// Online: held − driver entitlement (>0 company retains).
  final MoneyAmount? onlineRemainingPosition;

  /// Platform+VAT−discount vs position difference.
  final MoneyAmount? reconciliationDifference;
  final FinancialReconStatus reconStatus;
  final bool settlementEligible;
  final String? exclusionReason;

  final List<String> notes;

  bool get isFinanciallyPaid =>
      payment == FinancialPaymentState.paid ||
      payment == FinancialPaymentState.cashCollected ||
      payment == FinancialPaymentState.captured;

  bool get isFinanciallyCompleted =>
      lifecycle == FinancialLifecycle.completed;

  bool get qualifiesCollectedCash =>
      channel == FinancialPaymentChannel.cash &&
      isFinanciallyCompleted &&
      isFinanciallyPaid &&
      confidence != FinancialConfidence.incomplete &&
      currencySupported;

  bool get qualifiesCollectedOnline =>
      channel == FinancialPaymentChannel.online &&
      isFinanciallyCompleted &&
      isFinanciallyPaid &&
      confidence != FinancialConfidence.incomplete &&
      currencySupported;
}

/// Currency-grouped reporting totals.
class FinancialCurrencyTotals {
  FinancialCurrencyTotals({required this.currency})
      : cashCustomerCollected = MoneyAmount.zero(currency),
        cashHeldByDrivers = MoneyAmount.zero(currency),
        cashDriverEntitlements = MoneyAmount.zero(currency),
        cashPlatformFees = MoneyAmount.zero(currency),
        cashRecordedVat = MoneyAmount.zero(currency),
        cashDiscounts = MoneyAmount.zero(currency),
        cashDriversOweCompany = MoneyAmount.zero(currency),
        cashCompanyOwesDrivers = MoneyAmount.zero(currency),
        cashUnreconciled = MoneyAmount.zero(currency),
        onlineCustomerPaid = MoneyAmount.zero(currency),
        onlineHeldByCompany = MoneyAmount.zero(currency),
        onlineDriverEntitlements = MoneyAmount.zero(currency),
        onlinePlatformFees = MoneyAmount.zero(currency),
        onlineRecordedVat = MoneyAmount.zero(currency),
        onlineDiscounts = MoneyAmount.zero(currency),
        onlineRemainingPosition = MoneyAmount.zero(currency),
        onlineCompanyOwesDrivers = MoneyAmount.zero(currency),
        grossBaseFare = MoneyAmount.zero(currency),
        customerPaidAll = MoneyAmount.zero(currency),
        platformFeeAll = MoneyAmount.zero(currency),
        recordedVatAll = MoneyAmount.zero(currency),
        driverEntitlementAll = MoneyAmount.zero(currency),
        recordedDiscountsAll = MoneyAmount.zero(currency),
        completedAndCollectedMinor = MoneyAmount.zero(currency),
        completedButNotCollectedMinor = MoneyAmount.zero(currency),
        cancelledOrExpiredMinor = MoneyAmount.zero(currency),
        incompleteMinor = MoneyAmount.zero(currency),
        expectedPlatformAfterCollection = MoneyAmount.zero(currency),
        expectedDriverNetAfterCollection = MoneyAmount.zero(currency),
        cashCompletedPendingMinor = MoneyAmount.zero(currency),
        onlineCompletedPendingMinor = MoneyAmount.zero(currency);

  final String currency;

  int cashCollectedTrips = 0;
  int onlinePaidTrips = 0;
  int incompleteLines = 0;
  int highCount = 0;
  int derivedCount = 0;

  MoneyAmount cashCustomerCollected;
  MoneyAmount cashHeldByDrivers;
  MoneyAmount cashDriverEntitlements;
  MoneyAmount cashPlatformFees;
  MoneyAmount cashRecordedVat;
  MoneyAmount cashDiscounts;
  MoneyAmount cashDriversOweCompany;
  MoneyAmount cashCompanyOwesDrivers;
  MoneyAmount cashUnreconciled;

  MoneyAmount onlineCustomerPaid;
  MoneyAmount onlineHeldByCompany;
  MoneyAmount onlineDriverEntitlements;
  MoneyAmount onlinePlatformFees;
  MoneyAmount onlineRecordedVat;
  MoneyAmount onlineDiscounts;
  MoneyAmount onlineRemainingPosition;
  MoneyAmount onlineCompanyOwesDrivers;

  MoneyAmount grossBaseFare;
  MoneyAmount customerPaidAll;
  MoneyAmount platformFeeAll;
  MoneyAmount recordedVatAll;
  MoneyAmount driverEntitlementAll;
  MoneyAmount recordedDiscountsAll;

  int completedAndCollected = 0;
  int paidButNotCompleted = 0;
  int completedButNotCollected = 0;
  int pendingPayment = 0;
  int cancelledOrExpired = 0;

  /// Bucket face values (customer paid where applicable).
  MoneyAmount completedAndCollectedMinor;
  MoneyAmount completedButNotCollectedMinor;
  MoneyAmount cancelledOrExpiredMinor;
  MoneyAmount incompleteMinor;

  /// Theoretical commission/entitlement after collection (not realized).
  MoneyAmount expectedPlatformAfterCollection;
  MoneyAmount expectedDriverNetAfterCollection;

  int cashCompletedPending = 0;
  int onlineCompletedPending = 0;
  MoneyAmount cashCompletedPendingMinor;
  MoneyAmount onlineCompletedPendingMinor;

  int lifecycleCompleted = 0;
  int lifecycleCancelled = 0;
  int lifecycleExpired = 0;
}

/// Financial Accounting Engine V2 — Admin reporting only (no writes).
abstract final class FinancialAccountingEngine {
  FinancialAccountingEngine._();

  static const int matchToleranceMinor = 1;

  // ---------------------------------------------------------------------------
  // Normalization
  // ---------------------------------------------------------------------------

  static FinancialLifecycle normalizedLifecycleStatus(
    FinancialOrderSnapshot o,
  ) {
    final code = (o.statusCode ?? '').trim().toLowerCase();
    if (code.isNotEmpty) {
      if (code == TourySystemStatusCodes.completed ||
          code == TourySystemStatusCodes.legacyTripCompleted) {
        return FinancialLifecycle.completed;
      }
      if (code.startsWith('cancelled') ||
          code.startsWith('canceled') ||
          code == TourySystemStatusCodes.legacyCancelled ||
          code == TourySystemStatusCodes.legacyCanceled) {
        return FinancialLifecycle.cancelled;
      }
      if (code == TourySystemStatusCodes.expired || code == 'expired') {
        return FinancialLifecycle.expired;
      }
      if (code == 'payment_pending' ||
          code == TourySystemStatusCodes.unpaid ||
          code.contains('payment')) {
        return FinancialLifecycle.pendingPayment;
      }
      if (code.contains('progress') ||
          code.contains('accepted') ||
          code.contains('arrived') ||
          code.contains('driver') ||
          code == TourySystemStatusCodes.pendingDriver) {
        return FinancialLifecycle.active;
      }
      return FinancialLifecycle.unknown;
    }

    // Legacy fallback only when status_code missing.
    final halhOrder = (o.halhOrder ?? '').trim().toLowerCase();
    final halh = (o.halh ?? '').trim().toLowerCase();
    if (halhOrder == 'canceled' ||
        halhOrder == 'cancelled' ||
        halh == 'canceled' ||
        halh == 'cancelled') {
      return FinancialLifecycle.cancelled;
    }
    if (halh.contains('مكتمل') ||
        halh == 'completed' ||
        halhOrder == 'paid' && !o.allnow) {
      // Weak legacy signal — prefer unknown unless clear Arabic complete.
      if (halh.contains('مكتمل') || halh == 'completed') {
        return FinancialLifecycle.completed;
      }
    }
    if (o.allnow) return FinancialLifecycle.active;
    return FinancialLifecycle.unknown;
  }

  static FinancialPaymentState normalizedPaymentStatus(
    FinancialOrderSnapshot o,
  ) {
    final pay = (o.paymentStatus ?? '').trim().toLowerCase();
    if (pay.isNotEmpty) {
      if (pay == 'cash_pending' || pay == 'cash_due') {
        return FinancialPaymentState.pendingCash;
      }
      if (pay == TourySystemStatusCodes.paid || pay == 'paid') {
        return FinancialPaymentState.paid;
      }
      if (pay == TourySystemStatusCodes.cashCollected ||
          pay == 'cash_collected') {
        return FinancialPaymentState.cashCollected;
      }
      if (pay == 'captured') return FinancialPaymentState.captured;
      if (pay == TourySystemStatusCodes.pendingCash ||
          pay == 'pending_cash') {
        return FinancialPaymentState.pendingCash;
      }
      if (pay == TourySystemStatusCodes.unpaid || pay == 'unpaid') {
        return FinancialPaymentState.unpaid;
      }
      if (pay == TourySystemStatusCodes.processing || pay == 'processing') {
        return FinancialPaymentState.processing;
      }
      if (pay == 'failed') return FinancialPaymentState.failed;
      if (pay == 'refunded') return FinancialPaymentState.refunded;
      return FinancialPaymentState.unknown;
    }

    // Legacy fallback only when payment_status missing.
    final halhOrder = (o.halhOrder ?? '').trim().toLowerCase();
    final halh = (o.halh ?? '').trim().toLowerCase();
    if (halhOrder == 'paid' || halh == 'paid') {
      return FinancialPaymentState.paid;
    }
    if (halhOrder == 'cash' ||
        halh == 'pending_cash' ||
        halh == TourySystemStatusCodes.pendingCash) {
      return FinancialPaymentState.pendingCash;
    }
    if (halhOrder == 'pending') return FinancialPaymentState.unpaid;
    return FinancialPaymentState.unknown;
  }

  static bool isFinanciallyPaid(FinancialOrderSnapshot o) {
    final p = normalizedPaymentStatus(o);
    return p == FinancialPaymentState.paid ||
        p == FinancialPaymentState.cashCollected ||
        p == FinancialPaymentState.captured;
  }

  static bool isFinanciallyCompleted(FinancialOrderSnapshot o) =>
      normalizedLifecycleStatus(o) == FinancialLifecycle.completed;

  static FinancialPaymentChannel channelOf(FinancialOrderSnapshot o) {
    final raw = (o.paymentMethodRaw ?? '').trim().toLowerCase();
    if (raw.contains('cash')) return FinancialPaymentChannel.cash;
    if (raw.contains('online')) return FinancialPaymentChannel.online;
    // Infer from payment_status when method missing.
    final pay = normalizedPaymentStatus(o);
    if (pay == FinancialPaymentState.pendingCash ||
        pay == FinancialPaymentState.cashCollected) {
      return FinancialPaymentChannel.cash;
    }
    if (pay == FinancialPaymentState.paid ||
        pay == FinancialPaymentState.captured) {
      return FinancialPaymentChannel.online;
    }
    return FinancialPaymentChannel.unknown;
  }

  static FinancialCollectionBucket bucketOf({
    required FinancialLifecycle lifecycle,
    required FinancialPaymentState payment,
    required bool financiallyPaid,
  }) {
    final completed = lifecycle == FinancialLifecycle.completed;
    final cancelled = lifecycle == FinancialLifecycle.cancelled ||
        lifecycle == FinancialLifecycle.expired;

    if (cancelled) {
      // Cancelled+paid is review — not completed revenue.
      return FinancialCollectionBucket.cancelledOrExpired;
    }
    if (completed && financiallyPaid) {
      return FinancialCollectionBucket.completedAndCollected;
    }
    if (!completed && financiallyPaid) {
      return FinancialCollectionBucket.paidButNotCompleted;
    }
    if (completed &&
        (payment == FinancialPaymentState.pendingCash ||
            payment == FinancialPaymentState.unpaid ||
            payment == FinancialPaymentState.unknown)) {
      return FinancialCollectionBucket.completedButNotCollected;
    }
    if (lifecycle == FinancialLifecycle.pendingPayment ||
        payment == FinancialPaymentState.pendingCash ||
        payment == FinancialPaymentState.unpaid ||
        payment == FinancialPaymentState.processing) {
      return FinancialCollectionBucket.pendingPayment;
    }
    return FinancialCollectionBucket.other;
  }

  // ---------------------------------------------------------------------------
  // Driver net normalization
  // ---------------------------------------------------------------------------

  static ({MoneyAmount? net, FinancialConfidence confidence, List<String> notes})
      normalizeDriverNet({
    required String currency,
    required FinancialOrderSnapshot o,
  }) {
    final notes = <String>[];
    if (!CurrencyMoneyPolicy.isSupported(currency)) {
      return (
        net: null,
        confidence: FinancialConfidence.incomplete,
        notes: [CurrencyMoneyPolicy.unsupportedPrecision],
      );
    }

    final fee = o.hasTotalApp
        ? MoneyAmount.fromMajor(currency, o.totalApp ?? 0)
        : null;
    final vat = o.hasTotalVat
        ? MoneyAmount.fromMajor(currency, o.totalVat ?? 0)
        : null;
    final discount = o.hasKsm
        ? MoneyAmount.fromMajor(currency, o.ksm ?? 0)
        : MoneyAmount.zero(currency);
    final ksmMinor = discount?.minorUnits ?? 0;

    if (o.hasTotalMndob && o.totalMndob != null) {
      final stored = MoneyAmount.fromMajor(currency, o.totalMndob)!;
      if (o.hasTotalMndob2 &&
          o.totalMndob2 != null &&
          fee != null &&
          vat != null) {
        final gross = MoneyAmount.fromMajor(currency, o.totalMndob2)!;
        final expected = MoneyAmount(
          currency: currency,
          minorUnits: gross.minorUnits - fee.minorUnits - vat.minorUnits,
        );
        if ((stored.minorUnits - expected.minorUnits).abs() <=
            matchToleranceMinor) {
          return (
            net: stored,
            confidence: FinancialConfidence.high,
            notes: notes,
          );
        }
        notes.add('DRIVER_NET_MISMATCH_STORED_VS_GROSS_FORMULA');
        // Prefer stored snapshot for historical reporting.
        return (
          net: stored,
          confidence: FinancialConfidence.derived,
          notes: notes,
        );
      }
      if (ksmMinor == 0 &&
          o.hasTotal &&
          fee != null &&
          vat != null &&
          o.total != null) {
        final total = MoneyAmount.fromMajor(currency, o.total)!;
        final expected = MoneyAmount(
          currency: currency,
          minorUnits: total.minorUnits - fee.minorUnits - vat.minorUnits,
        );
        if ((stored.minorUnits - expected.minorUnits).abs() <=
            matchToleranceMinor) {
          return (
            net: stored,
            confidence: FinancialConfidence.high,
            notes: notes,
          );
        }
      }
      return (
        net: stored,
        confidence: FinancialConfidence.high,
        notes: notes,
      );
    }

    // Missing total_mndob
    if (fee == null || vat == null) {
      return (
        net: null,
        confidence: FinancialConfidence.incomplete,
        notes: ['MISSING_FEE_OR_VAT'],
      );
    }

    if (ksmMinor == 0) {
      if (!o.hasTotal || o.total == null) {
        return (
          net: null,
          confidence: FinancialConfidence.incomplete,
          notes: ['MISSING_TOTAL_FOR_DERIVE'],
        );
      }
      final total = MoneyAmount.fromMajor(currency, o.total)!;
      final net = MoneyAmount(
        currency: currency,
        minorUnits: total.minorUnits - fee.minorUnits - vat.minorUnits,
      );
      notes.add('DERIVED_FROM_TOTAL');
      return (
        net: net,
        confidence: FinancialConfidence.derived,
        notes: notes,
      );
    }

    // ksm > 0
    if (o.hasTotalMndob2 && o.totalMndob2 != null) {
      final gross = MoneyAmount.fromMajor(currency, o.totalMndob2)!;
      final net = MoneyAmount(
        currency: currency,
        minorUnits: gross.minorUnits - fee.minorUnits - vat.minorUnits,
      );
      notes.add('DERIVED_FROM_GROSS_BASE');
      return (
        net: net,
        confidence: FinancialConfidence.derived,
        notes: notes,
      );
    }

    return (
      net: null,
      confidence: FinancialConfidence.incomplete,
      notes: ['MISSING_GROSS_WITH_DISCOUNT'],
    );
  }

  // ---------------------------------------------------------------------------
  // Line builder
  // ---------------------------------------------------------------------------

  static FinancialOrderLine analyze(FinancialOrderSnapshot o) {
    final currency = CurrencyMoneyPolicy.normalizeCode(
      (o.currency ?? '').isNotEmpty ? o.currency : 'SAR',
    );
    final supported = CurrencyMoneyPolicy.isSupported(currency);
    final lifecycle = normalizedLifecycleStatus(o);
    final payment = normalizedPaymentStatus(o);
    final channel = channelOf(o);
    final paid = isFinanciallyPaid(o);
    final bucket = bucketOf(
      lifecycle: lifecycle,
      payment: payment,
      financiallyPaid: paid,
    );

    if (!supported) {
      return FinancialOrderLine(
        orderId: o.orderId,
        currency: currency,
        channel: channel,
        lifecycle: lifecycle,
        payment: payment,
        bucket: bucket,
        confidence: FinancialConfidence.incomplete,
        currencySupported: false,
        reconStatus: FinancialReconStatus.unsupported,
        settlementEligible: false,
        exclusionReason: 'UNSUPPORTED_CURRENCY',
        notes: [CurrencyMoneyPolicy.unsupportedPrecision],
      );
    }

    final customerPaid = o.hasTotal
        ? MoneyAmount.fromMajor(currency, o.total ?? 0)
        : null;
    final platformFee = o.hasTotalApp
        ? MoneyAmount.fromMajor(currency, o.totalApp ?? 0)
        : null;
    final recordedVat = o.hasTotalVat
        ? MoneyAmount.fromMajor(currency, o.totalVat ?? 0)
        : null;
    final recordedDiscount = o.hasKsm
        ? MoneyAmount.fromMajor(currency, o.ksm ?? 0)
        : MoneyAmount.zero(currency);
    final grossBase = o.hasTotalMndob2
        ? MoneyAmount.fromMajor(currency, o.totalMndob2)
        : (recordedDiscount != null &&
                recordedDiscount.isZero &&
                customerPaid != null
            ? customerPaid
            : null);

    final netResult = normalizeDriverNet(currency: currency, o: o);
    final notes = [...netResult.notes];

    MoneyAmount? cashHeld;
    MoneyAmount? signedCash;
    MoneyAmount? onlineHeld;
    MoneyAmount? onlineRemain;
    MoneyAmount? reconDiff;
    var reconStatus = FinancialReconStatus.notApplicable;

    final collected = paid &&
        lifecycle == FinancialLifecycle.completed &&
        netResult.confidence != FinancialConfidence.incomplete &&
        customerPaid != null &&
        netResult.net != null;

    if (collected && channel == FinancialPaymentChannel.cash) {
      final held = customerPaid;
      final net = netResult.net as MoneyAmount;
      cashHeld = held;
      signedCash = MoneyAmount(
        currency: currency,
        minorUnits: held.minorUnits - net.minorUnits,
      );
      if (platformFee != null &&
          recordedVat != null &&
          recordedDiscount != null) {
        final breakdown = MoneyAmount(
          currency: currency,
          minorUnits: platformFee.minorUnits +
              recordedVat.minorUnits -
              recordedDiscount.minorUnits,
        );
        final diffMinor = signedCash.minorUnits - breakdown.minorUnits;
        if (diffMinor.abs() > matchToleranceMinor) {
          reconDiff = MoneyAmount(currency: currency, minorUnits: diffMinor);
          reconStatus = FinancialReconStatus.difference;
          notes.add('RECONCILIATION_DIFFERENCE');
        } else {
          reconStatus = FinancialReconStatus.reconciled;
        }
      }
    }

    if (collected && channel == FinancialPaymentChannel.online) {
      final held = customerPaid;
      final net = netResult.net as MoneyAmount;
      onlineHeld = held;
      onlineRemain = MoneyAmount(
        currency: currency,
        minorUnits: held.minorUnits - net.minorUnits,
      );
      if (platformFee != null &&
          recordedVat != null &&
          recordedDiscount != null) {
        final breakdown = MoneyAmount(
          currency: currency,
          minorUnits: platformFee.minorUnits +
              recordedVat.minorUnits -
              recordedDiscount.minorUnits,
        );
        final diffMinor = onlineRemain.minorUnits - breakdown.minorUnits;
        if (diffMinor.abs() > matchToleranceMinor) {
          reconDiff = MoneyAmount(currency: currency, minorUnits: diffMinor);
          reconStatus = FinancialReconStatus.difference;
          notes.add('RECONCILIATION_DIFFERENCE');
        } else {
          reconStatus = FinancialReconStatus.reconciled;
        }
      }
    }

    // Cancelled + paid → flag for review, not collected revenue.
    if (lifecycle == FinancialLifecycle.cancelled && paid) {
      notes.add('CANCELLED_PAID_REVIEW');
    }

    String? exclusionReason;
    final eligible = collected &&
        reconStatus != FinancialReconStatus.difference &&
        netResult.confidence != FinancialConfidence.incomplete;
    if (!eligible) {
      if (!supported) {
        exclusionReason = 'UNSUPPORTED_CURRENCY';
      } else if (netResult.confidence == FinancialConfidence.incomplete) {
        exclusionReason = 'INCOMPLETE_FINANCIAL_DATA';
      } else if (lifecycle == FinancialLifecycle.cancelled ||
          lifecycle == FinancialLifecycle.expired) {
        exclusionReason = 'CANCELLED';
      } else if (lifecycle != FinancialLifecycle.completed) {
        exclusionReason = 'NOT_COMPLETED';
      } else if (!paid) {
        exclusionReason = 'NOT_COLLECTED';
      } else if (reconStatus == FinancialReconStatus.difference) {
        exclusionReason = 'RECONCILIATION_DIFFERENCE';
      } else {
        exclusionReason = 'EXCLUDED';
      }
    }

    return FinancialOrderLine(
      orderId: o.orderId,
      currency: currency,
      channel: channel,
      lifecycle: lifecycle,
      payment: payment,
      bucket: bucket,
      confidence: netResult.confidence,
      currencySupported: true,
      customerPaid: customerPaid,
      grossBase: grossBase,
      platformFee: platformFee,
      recordedVat: recordedVat,
      recordedDiscount: recordedDiscount,
      driverNet: netResult.net,
      cashHeldByDriver: cashHeld,
      signedCashPosition: signedCash,
      onlineHeldByCompany: onlineHeld,
      onlineRemainingPosition: onlineRemain,
      reconciliationDifference: reconDiff,
      reconStatus: reconStatus,
      settlementEligible: eligible,
      exclusionReason: exclusionReason,
      notes: notes,
    );
  }

  /// Aggregates lines grouped by currency. Never mixes currencies.
  static Map<String, FinancialCurrencyTotals> aggregateByCurrency(
    Iterable<FinancialOrderLine> lines,
  ) {
    final map = <String, FinancialCurrencyTotals>{};

    FinancialCurrencyTotals bucket(String currency) =>
        map.putIfAbsent(currency, () => FinancialCurrencyTotals(currency: currency));

    for (final line in lines) {
      if (!line.currencySupported) {
        final t = bucket(line.currency.isEmpty ? 'UNSUPPORTED' : line.currency);
        t.incompleteLines++;
        continue;
      }
      final t = bucket(line.currency);

      switch (line.confidence) {
        case FinancialConfidence.high:
          t.highCount++;
          break;
        case FinancialConfidence.derived:
          t.derivedCount++;
          break;
        case FinancialConfidence.incomplete:
          t.incompleteLines++;
          break;
      }

      switch (line.lifecycle) {
        case FinancialLifecycle.completed:
          t.lifecycleCompleted++;
          break;
        case FinancialLifecycle.cancelled:
          t.lifecycleCancelled++;
          break;
        case FinancialLifecycle.expired:
          t.lifecycleExpired++;
          break;
        default:
          break;
      }

      switch (line.bucket) {
        case FinancialCollectionBucket.completedAndCollected:
          t.completedAndCollected++;
          if (line.customerPaid != null) {
            t.completedAndCollectedMinor =
                t.completedAndCollectedMinor + line.customerPaid!;
          }
          break;
        case FinancialCollectionBucket.paidButNotCompleted:
          t.paidButNotCompleted++;
          break;
        case FinancialCollectionBucket.completedButNotCollected:
          t.completedButNotCollected++;
          if (line.customerPaid != null) {
            t.completedButNotCollectedMinor =
                t.completedButNotCollectedMinor + line.customerPaid!;
          }
          if (line.platformFee != null) {
            t.expectedPlatformAfterCollection =
                t.expectedPlatformAfterCollection + line.platformFee!;
          }
          if (line.driverNet != null) {
            t.expectedDriverNetAfterCollection =
                t.expectedDriverNetAfterCollection + line.driverNet!;
          }
          if (line.channel == FinancialPaymentChannel.cash) {
            t.cashCompletedPending++;
            if (line.customerPaid != null) {
              t.cashCompletedPendingMinor =
                  t.cashCompletedPendingMinor + line.customerPaid!;
            }
          } else if (line.channel == FinancialPaymentChannel.online) {
            t.onlineCompletedPending++;
            if (line.customerPaid != null) {
              t.onlineCompletedPendingMinor =
                  t.onlineCompletedPendingMinor + line.customerPaid!;
            }
          }
          break;
        case FinancialCollectionBucket.pendingPayment:
          t.pendingPayment++;
          break;
        case FinancialCollectionBucket.cancelledOrExpired:
          t.cancelledOrExpired++;
          if (line.customerPaid != null) {
            t.cancelledOrExpiredMinor =
                t.cancelledOrExpiredMinor + line.customerPaid!;
          }
          break;
        case FinancialCollectionBucket.other:
          break;
      }

      if (line.confidence == FinancialConfidence.incomplete &&
          line.customerPaid != null) {
        t.incompleteMinor = t.incompleteMinor + line.customerPaid!;
      }

      if (line.qualifiesCollectedCash) {
        t.cashCollectedTrips++;
        t.cashCustomerCollected = t.cashCustomerCollected + line.customerPaid!;
        t.cashHeldByDrivers = t.cashHeldByDrivers + line.cashHeldByDriver!;
        t.cashDriverEntitlements =
            t.cashDriverEntitlements + line.driverNet!;
        if (line.platformFee != null) {
          t.cashPlatformFees = t.cashPlatformFees + line.platformFee!;
        }
        if (line.recordedVat != null) {
          t.cashRecordedVat = t.cashRecordedVat + line.recordedVat!;
        }
        if (line.recordedDiscount != null) {
          t.cashDiscounts = t.cashDiscounts + line.recordedDiscount!;
        }
        final pos = line.signedCashPosition!;
        if (pos.isPositive) {
          t.cashDriversOweCompany = t.cashDriversOweCompany + pos;
        } else if (pos.isNegative) {
          t.cashCompanyOwesDrivers = t.cashCompanyOwesDrivers + pos.abs();
        }
        if (line.reconciliationDifference != null) {
          t.cashUnreconciled =
              t.cashUnreconciled + line.reconciliationDifference!.abs();
        }
        _addEconomics(t, line);
      } else if (line.qualifiesCollectedOnline) {
        t.onlinePaidTrips++;
        t.onlineCustomerPaid = t.onlineCustomerPaid + line.customerPaid!;
        t.onlineHeldByCompany =
            t.onlineHeldByCompany + line.onlineHeldByCompany!;
        t.onlineDriverEntitlements =
            t.onlineDriverEntitlements + line.driverNet!;
        if (line.platformFee != null) {
          t.onlinePlatformFees = t.onlinePlatformFees + line.platformFee!;
        }
        if (line.recordedVat != null) {
          t.onlineRecordedVat = t.onlineRecordedVat + line.recordedVat!;
        }
        if (line.recordedDiscount != null) {
          t.onlineDiscounts = t.onlineDiscounts + line.recordedDiscount!;
        }
        final rem = line.onlineRemainingPosition!;
        if (rem.isPositive) {
          t.onlineRemainingPosition = t.onlineRemainingPosition + rem;
        } else if (rem.isNegative) {
          t.onlineCompanyOwesDrivers =
              t.onlineCompanyOwesDrivers + rem.abs();
        }
        _addEconomics(t, line);
      }
    }

    return map;
  }

  static void _addEconomics(FinancialCurrencyTotals t, FinancialOrderLine line) {
    if (line.grossBase != null) {
      t.grossBaseFare = t.grossBaseFare + line.grossBase!;
    }
    if (line.customerPaid != null) {
      t.customerPaidAll = t.customerPaidAll + line.customerPaid!;
    }
    if (line.platformFee != null) {
      t.platformFeeAll = t.platformFeeAll + line.platformFee!;
    }
    if (line.recordedVat != null) {
      t.recordedVatAll = t.recordedVatAll + line.recordedVat!;
    }
    if (line.driverNet != null) {
      t.driverEntitlementAll = t.driverEntitlementAll + line.driverNet!;
    }
    if (line.recordedDiscount != null) {
      t.recordedDiscountsAll = t.recordedDiscountsAll + line.recordedDiscount!;
    }
  }
}

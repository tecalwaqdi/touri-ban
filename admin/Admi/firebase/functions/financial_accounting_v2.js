/**
 * Financial Accounting V2 — Admin read-only aggregation.
 * Mirrors Dart FinancialAccountingEngine (historical order snapshots).
 * NO writes. NO payment flow changes.
 */

'use strict';

const EXPONENT = {
  SAR: 2, AED: 2, QAR: 2, EGP: 2, USD: 2, EUR: 2, MAD: 2,
  TND: 3, KWD: 3, BHD: 3, OMR: 3, JOD: 3,
  KGS: 2, INR: 2, IDR: 2, MYR: 2, TRY: 2, RUB: 2, UZS: 2,
};

const MATCH_TOLERANCE = 1;

function normalizeCode(c) {
  return String(c || '').trim().toUpperCase();
}

function exponentOrNull(c) {
  const code = normalizeCode(c);
  return Object.prototype.hasOwnProperty.call(EXPONENT, code) ? EXPONENT[code] : null;
}

function toMinor(currency, major) {
  const exp = exponentOrNull(currency);
  if (exp == null || major == null || !Number.isFinite(Number(major))) return null;
  let factor = 1;
  for (let i = 0; i < exp; i++) factor *= 10;
  return Math.round(Number(major) * factor);
}

function hasField(data, key) {
  return Object.prototype.hasOwnProperty.call(data, key) && data[key] != null;
}

function str(v) {
  return v == null ? '' : String(v).trim();
}

function lifecycleOf(o) {
  const code = str(o.status_code).toLowerCase();
  if (code) {
    if (code === 'completed' || code === 'trip_completed') return 'completed';
    if (code.startsWith('cancelled') || code.startsWith('canceled')) return 'cancelled';
    if (code === 'expired') return 'expired';
    if (code === 'payment_pending' || code.includes('payment')) return 'pendingPayment';
    if (
      code.includes('progress') ||
      code.includes('accepted') ||
      code.includes('arrived') ||
      code.includes('driver') ||
      code === 'pending_driver'
    ) {
      return 'active';
    }
    return 'unknown';
  }
  const ho = str(o.halh_order).toLowerCase();
  const h = str(o.halh).toLowerCase();
  if (ho === 'canceled' || ho === 'cancelled' || h === 'canceled' || h === 'cancelled') {
    return 'cancelled';
  }
  if (h.includes('مكتمل') || h === 'completed') return 'completed';
  if (o.ALLNOW === true) return 'active';
  return 'unknown';
}

function paymentOf(o) {
  let pay = str(o.payment_status).toLowerCase();
  if (pay === 'cash_pending' || pay === 'cash_due') pay = 'pending_cash';
  if (pay) {
    if (pay === 'paid') return 'paid';
    if (pay === 'cash_collected') return 'cashCollected';
    if (pay === 'captured') return 'captured';
    if (pay === 'pending_cash') return 'pendingCash';
    if (pay === 'unpaid') return 'unpaid';
    if (pay === 'processing') return 'processing';
    if (pay === 'failed') return 'failed';
    if (pay === 'refunded') return 'refunded';
    return 'unknown';
  }
  const ho = str(o.halh_order).toLowerCase();
  const h = str(o.halh).toLowerCase();
  if (ho === 'paid' || h === 'paid') return 'paid';
  if (ho === 'cash' || h === 'pending_cash') return 'pendingCash';
  if (ho === 'pending') return 'unpaid';
  return 'unknown';
}

function isPaid(p) {
  return p === 'paid' || p === 'cashCollected' || p === 'captured';
}

function channelOf(o, payment) {
  const raw = str(o.PaymentMethod).toLowerCase();
  if (raw.includes('cash')) return 'cash';
  if (raw.includes('online')) return 'online';
  if (payment === 'pendingCash' || payment === 'cashCollected') return 'cash';
  if (payment === 'paid' || payment === 'captured') return 'online';
  return 'unknown';
}

function bucketOf(lifecycle, payment, paid) {
  const cancelled = lifecycle === 'cancelled' || lifecycle === 'expired';
  if (cancelled) return 'cancelledOrExpired';
  if (lifecycle === 'completed' && paid) return 'completedAndCollected';
  if (lifecycle !== 'completed' && paid) return 'paidButNotCompleted';
  if (
    lifecycle === 'completed' &&
    (payment === 'pendingCash' || payment === 'unpaid' || payment === 'unknown')
  ) {
    return 'completedButNotCollected';
  }
  if (
    lifecycle === 'pendingPayment' ||
    payment === 'pendingCash' ||
    payment === 'unpaid' ||
    payment === 'processing'
  ) {
    return 'pendingPayment';
  }
  return 'other';
}

function emptyCurrency(code) {
  return {
    currency: code,
    cashCollectedTrips: 0,
    onlinePaidTrips: 0,
    incompleteLines: 0,
    highCount: 0,
    derivedCount: 0,
    reconciledCount: 0,
    reconDifferenceCount: 0,
    cashCustomerCollectedMinor: 0,
    cashHeldByDriversMinor: 0,
    cashDriverEntitlementsMinor: 0,
    cashPlatformFeesMinor: 0,
    cashRecordedVatMinor: 0,
    cashDiscountsMinor: 0,
    cashDriversOweCompanyMinor: 0,
    cashCompanyOwesDriversMinor: 0,
    cashUnreconciledMinor: 0,
    onlineCustomerPaidMinor: 0,
    onlineHeldByCompanyMinor: 0,
    onlineDriverEntitlementsMinor: 0,
    onlinePlatformFeesMinor: 0,
    onlineRecordedVatMinor: 0,
    onlineDiscountsMinor: 0,
    onlineRemainingPositionMinor: 0,
    onlineCompanyOwesDriversMinor: 0,
    grossBaseFareMinor: 0,
    customerPaidAllMinor: 0,
    platformFeeAllMinor: 0,
    recordedVatAllMinor: 0,
    driverEntitlementAllMinor: 0,
    recordedDiscountsAllMinor: 0,
    completedAndCollected: 0,
    paidButNotCompleted: 0,
    completedButNotCollected: 0,
    pendingPayment: 0,
    cancelledOrExpired: 0,
    needsFinancialReview: 0,
    // bucket minors (customer paid where applicable)
    completedAndCollectedMinor: 0,
    paidButNotCompletedMinor: 0,
    completedButNotCollectedMinor: 0,
    pendingPaymentMinor: 0,
    cancelledOrExpiredMinor: 0,
    incompleteMinor: 0,
  };
}

function analyzeOrder(id, o) {
  const currency = normalizeCode(o.currency || o.currency_code || 'SAR') || 'SAR';
  const supported = exponentOrNull(currency) != null;
  const lifecycle = lifecycleOf(o);
  const payment = paymentOf(o);
  const channel = channelOf(o, payment);
  const paid = isPaid(payment);
  const bucket = bucketOf(lifecycle, payment, paid);
  const notes = [];

  if (!supported) {
    return {
      orderId: id,
      currency,
      channel,
      lifecycle,
      payment,
      bucket,
      confidence: 'incomplete',
      currencySupported: false,
      reconStatus: 'unsupported',
      notes: ['UNSUPPORTED_CURRENCY_PRECISION'],
      exclusionReason: 'UNSUPPORTED_CURRENCY',
    };
  }

  const hasTotal = hasField(o, 'total');
  const hasApp = hasField(o, 'total_app');
  const hasVat = hasField(o, 'total_vat');
  const hasMndob = hasField(o, 'total_mndob');
  const hasMndob2 = hasField(o, 'total_mndob2');
  const hasKsm = hasField(o, 'ksm');

  const customerPaid = hasTotal ? toMinor(currency, o.total) : null;
  const platformFee = hasApp ? toMinor(currency, o.total_app) : null;
  const recordedVat = hasVat ? toMinor(currency, o.total_vat) : null;
  const recordedDiscount = hasKsm ? toMinor(currency, o.ksm) : 0;
  const ksmMinor = recordedDiscount || 0;
  let grossBase = hasMndob2 ? toMinor(currency, o.total_mndob2) : null;
  if (grossBase == null && ksmMinor === 0 && customerPaid != null) {
    grossBase = customerPaid;
  }

  let driverNet = null;
  let confidence = 'incomplete';

  if (hasMndob) {
    driverNet = toMinor(currency, o.total_mndob);
    confidence = 'high';
    if (grossBase != null && platformFee != null && recordedVat != null) {
      const expected = grossBase - platformFee - recordedVat;
      if (Math.abs(driverNet - expected) > MATCH_TOLERANCE) {
        notes.push('DRIVER_NET_MISMATCH_STORED_VS_GROSS_FORMULA');
        confidence = 'derived';
      }
    }
  } else if (platformFee != null && recordedVat != null) {
    if (ksmMinor === 0) {
      if (customerPaid != null) {
        driverNet = customerPaid - platformFee - recordedVat;
        confidence = 'derived';
        notes.push('DERIVED_FROM_TOTAL');
      } else {
        notes.push('MISSING_TOTAL_FOR_DERIVE');
      }
    } else if (hasMndob2 && grossBase != null) {
      driverNet = grossBase - platformFee - recordedVat;
      confidence = 'derived';
      notes.push('DERIVED_FROM_GROSS_BASE');
    } else {
      notes.push('MISSING_GROSS_WITH_DISCOUNT');
    }
  } else {
    notes.push('MISSING_FEE_OR_VAT');
  }

  let cashHeld = null;
  let signedCash = null;
  let onlineHeld = null;
  let onlineRemain = null;
  let reconDiff = null;
  let reconStatus = 'n/a';

  const collected =
    paid &&
    lifecycle === 'completed' &&
    confidence !== 'incomplete' &&
    customerPaid != null &&
    driverNet != null;

  if (collected && channel === 'cash') {
    cashHeld = customerPaid;
    signedCash = customerPaid - driverNet;
    if (platformFee != null && recordedVat != null) {
      const breakdown = platformFee + recordedVat - ksmMinor;
      reconDiff = signedCash - breakdown;
      if (Math.abs(reconDiff) <= MATCH_TOLERANCE) {
        reconStatus = 'reconciled';
        reconDiff = 0;
      } else {
        reconStatus = 'difference';
        notes.push('RECONCILIATION_DIFFERENCE');
      }
    }
  }

  if (collected && channel === 'online') {
    onlineHeld = customerPaid;
    onlineRemain = customerPaid - driverNet;
    if (platformFee != null && recordedVat != null) {
      const breakdown = platformFee + recordedVat - ksmMinor;
      reconDiff = onlineRemain - breakdown;
      if (Math.abs(reconDiff) <= MATCH_TOLERANCE) {
        reconStatus = 'reconciled';
        reconDiff = 0;
      } else {
        reconStatus = 'difference';
        notes.push('RECONCILIATION_DIFFERENCE');
      }
    }
  }

  if (lifecycle === 'cancelled' && paid) {
    notes.push('CANCELLED_PAID_REVIEW');
  }

  let exclusionReason = null;
  const eligible =
    collected &&
    reconStatus !== 'difference' &&
    confidence !== 'incomplete';
  if (!eligible) {
    if (confidence === 'incomplete') exclusionReason = 'INCOMPLETE_FINANCIAL_DATA';
    else if (lifecycle === 'cancelled' || lifecycle === 'expired') exclusionReason = 'CANCELLED';
    else if (lifecycle !== 'completed') exclusionReason = 'NOT_COMPLETED';
    else if (!paid) exclusionReason = 'NOT_COLLECTED';
    else if (reconStatus === 'difference') exclusionReason = 'RECONCILIATION_DIFFERENCE';
    else if (!supported) exclusionReason = 'UNSUPPORTED_CURRENCY';
    else exclusionReason = 'EXCLUDED';
  }

  return {
    orderId: id,
    currency,
    channel,
    lifecycle,
    payment,
    bucket,
    confidence,
    currencySupported: true,
    customerPaidMinor: customerPaid,
    grossBaseMinor: grossBase,
    platformFeeMinor: platformFee,
    recordedVatMinor: recordedVat,
    recordedDiscountMinor: ksmMinor,
    driverNetMinor: driverNet,
    cashHeldMinor: cashHeld,
    signedCashMinor: signedCash,
    onlineHeldMinor: onlineHeld,
    onlineRemainMinor: onlineRemain,
    reconDiffMinor: reconDiff,
    reconStatus,
    notes,
    eligible,
    exclusionReason,
    missingFields: [
      !hasTotal && 'total',
      !hasApp && 'total_app',
      !hasVat && 'total_vat',
      !hasMndob && 'total_mndob',
    ].filter(Boolean),
    hasStatusCode: !!str(o.status_code),
    hasPaymentStatus: !!str(o.payment_status),
    driverId: (() => {
      const ref = o.mndob_user || o.MNDOB_USER;
      if (!ref) return null;
      if (ref.id) return ref.id;
      if (ref.path) return String(ref.path).split('/').pop();
      return null;
    })(),
    countryPath: (() => {
      const ref = o.Rev_dolh;
      if (!ref) return null;
      if (ref.path) return ref.path;
      return null;
    })(),
    dataOrder: o.data_order || null,
  };
}

function addEconomics(t, line) {
  if (line.grossBaseMinor != null) t.grossBaseFareMinor += line.grossBaseMinor;
  if (line.customerPaidMinor != null) t.customerPaidAllMinor += line.customerPaidMinor;
  if (line.platformFeeMinor != null) t.platformFeeAllMinor += line.platformFeeMinor;
  if (line.recordedVatMinor != null) t.recordedVatAllMinor += line.recordedVatMinor;
  if (line.driverNetMinor != null) t.driverEntitlementAllMinor += line.driverNetMinor;
  if (line.recordedDiscountMinor != null) {
    t.recordedDiscountsAllMinor += line.recordedDiscountMinor;
  }
}

function accumulate(byCurrency, line) {
  const code = line.currency || 'UNSUPPORTED';
  if (!byCurrency[code]) byCurrency[code] = emptyCurrency(code);
  const t = byCurrency[code];

  if (line.confidence === 'high') t.highCount++;
  else if (line.confidence === 'derived') t.derivedCount++;
  else {
    t.incompleteLines++;
    if (line.customerPaidMinor != null) t.incompleteMinor += line.customerPaidMinor;
  }

  if (line.reconStatus === 'reconciled') t.reconciledCount++;
  if (line.reconStatus === 'difference') t.reconDifferenceCount++;

  switch (line.bucket) {
    case 'completedAndCollected':
      t.completedAndCollected++;
      if (line.customerPaidMinor != null) t.completedAndCollectedMinor += line.customerPaidMinor;
      break;
    case 'paidButNotCompleted':
      t.paidButNotCompleted++;
      if (line.customerPaidMinor != null) t.paidButNotCompletedMinor += line.customerPaidMinor;
      break;
    case 'completedButNotCollected':
      t.completedButNotCollected++;
      if (line.customerPaidMinor != null) {
        t.completedButNotCollectedMinor += line.customerPaidMinor;
      }
      break;
    case 'pendingPayment':
      t.pendingPayment++;
      if (line.customerPaidMinor != null) t.pendingPaymentMinor += line.customerPaidMinor;
      break;
    case 'cancelledOrExpired':
      t.cancelledOrExpired++;
      if (line.customerPaidMinor != null) t.cancelledOrExpiredMinor += line.customerPaidMinor;
      if (line.notes && line.notes.includes('CANCELLED_PAID_REVIEW')) {
        t.needsFinancialReview++;
      }
      break;
    default:
      break;
  }

  const qualifiesCash =
    line.channel === 'cash' &&
    line.lifecycle === 'completed' &&
    (line.payment === 'paid' || line.payment === 'cashCollected' || line.payment === 'captured') &&
    line.confidence !== 'incomplete' &&
    line.currencySupported &&
    line.cashHeldMinor != null &&
    line.driverNetMinor != null;

  const qualifiesOnline =
    line.channel === 'online' &&
    line.lifecycle === 'completed' &&
    (line.payment === 'paid' || line.payment === 'cashCollected' || line.payment === 'captured') &&
    line.confidence !== 'incomplete' &&
    line.currencySupported &&
    line.onlineHeldMinor != null &&
    line.driverNetMinor != null;

  if (qualifiesCash) {
    t.cashCollectedTrips++;
    t.cashCustomerCollectedMinor += line.customerPaidMinor;
    t.cashHeldByDriversMinor += line.cashHeldMinor;
    t.cashDriverEntitlementsMinor += line.driverNetMinor;
    if (line.platformFeeMinor != null) t.cashPlatformFeesMinor += line.platformFeeMinor;
    if (line.recordedVatMinor != null) t.cashRecordedVatMinor += line.recordedVatMinor;
    if (line.recordedDiscountMinor != null) t.cashDiscountsMinor += line.recordedDiscountMinor;
    if (line.signedCashMinor > 0) t.cashDriversOweCompanyMinor += line.signedCashMinor;
    else if (line.signedCashMinor < 0) t.cashCompanyOwesDriversMinor += -line.signedCashMinor;
    if (line.reconDiffMinor) t.cashUnreconciledMinor += Math.abs(line.reconDiffMinor);
    addEconomics(t, line);
  } else if (qualifiesOnline) {
    t.onlinePaidTrips++;
    t.onlineCustomerPaidMinor += line.customerPaidMinor;
    t.onlineHeldByCompanyMinor += line.onlineHeldMinor;
    t.onlineDriverEntitlementsMinor += line.driverNetMinor;
    if (line.platformFeeMinor != null) t.onlinePlatformFeesMinor += line.platformFeeMinor;
    if (line.recordedVatMinor != null) t.onlineRecordedVatMinor += line.recordedVatMinor;
    if (line.recordedDiscountMinor != null) t.onlineDiscountsMinor += line.recordedDiscountMinor;
    if (line.onlineRemainMinor > 0) t.onlineRemainingPositionMinor += line.onlineRemainMinor;
    else if (line.onlineRemainMinor < 0) {
      t.onlineCompanyOwesDriversMinor += -line.onlineRemainMinor;
    }
    addEconomics(t, line);
  }
}

function matchesFilters(line, filters) {
  if (filters.channel && line.channel !== filters.channel) return false;
  if (filters.lifecycle && line.lifecycle !== filters.lifecycle) return false;
  if (filters.payment && line.payment !== filters.payment) return false;
  if (filters.confidence && line.confidence !== filters.confidence) return false;
  if (filters.currency && line.currency !== normalizeCode(filters.currency)) return false;
  if (filters.driverId && line.driverId !== filters.driverId) return false;
  return true;
}

function settlePreviewForDriver(lines, currency) {
  const code = normalizeCode(currency);
  let cashHeld = 0;
  let cashEntitlement = 0;
  let onlineEntitlement = 0;
  let included = 0;
  let excluded = 0;
  const exclusionCounts = {};
  const includedTrips = [];
  const excludedTrips = [];

  for (const line of lines) {
    if (line.currency !== code) continue;
    if (line.eligible) {
      included++;
      if (line.channel === 'cash') {
        cashHeld += line.cashHeldMinor || 0;
        cashEntitlement += line.driverNetMinor || 0;
      } else if (line.channel === 'online') {
        onlineEntitlement += line.driverNetMinor || 0;
      }
      includedTrips.push({
        orderId: line.orderId,
        channel: line.channel,
        customerPaidMinor: line.customerPaidMinor,
        driverNetMinor: line.driverNetMinor,
        confidence: line.confidence,
      });
    } else {
      excluded++;
      const reason = line.exclusionReason || 'EXCLUDED';
      exclusionCounts[reason] = (exclusionCounts[reason] || 0) + 1;
      excludedTrips.push({orderId: line.orderId, reason});
    }
  }

  const driverCashLiability = cashHeld - cashEntitlement;
  const companyOnlineLiability = onlineEntitlement;
  const net = driverCashLiability - companyOnlineLiability;
  let direction = 'balanced';
  if (net > 0) direction = 'driverPaysCompany';
  else if (net < 0) direction = 'companyPaysDriver';

  return {
    currency: code,
    includedTrips: included,
    excludedTrips: excluded,
    exclusionCounts,
    cashHeldMinor: cashHeld,
    cashDriverEntitlementMinor: cashEntitlement,
    driverCashLiabilityMinor: driverCashLiability,
    onlineDriverEntitlementMinor: onlineEntitlement,
    companyOnlineLiabilityMinor: companyOnlineLiability,
    netTripSettlementMinor: net,
    direction,
    sampleIncluded: includedTrips.slice(0, 50),
    sampleExcluded: excludedTrips.slice(0, 50),
  };
}

module.exports = {
  analyzeOrder,
  accumulate,
  matchesFilters,
  settlePreviewForDriver,
  emptyCurrency,
  normalizeCode,
  toMinor,
  MATCH_TOLERANCE,
};

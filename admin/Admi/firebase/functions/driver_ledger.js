'use strict';

/**
 * Company-books convention (per driver + currency):
 *
 * runningBalance > 0  → Debit / Receivable  (driver owes company)
 * runningBalance < 0  → Credit / Payable    (company owes driver)
 *
 * debit  increases driver-owes-company
 * credit decreases driver-owes-company (or increases company-owes-driver)
 *
 * runningBalance = cumulative (debit - credit)
 * Never mix currencies.
 */

const TYPE_RANK = {
  opening_balance: 10,
  cash_trip: 20,
  online_trip: 21,
  settlement_lock: 30,
  adjustment: 40,
  settlement_payment: 50,
  reversal: 60,
};

function typeRank(type) {
  return TYPE_RANK[type] || 99;
}

function compareLedgerKeys(a, b) {
  const ta = Date.parse(a.at) || 0;
  const tb = Date.parse(b.at) || 0;
  if (ta !== tb) return ta - tb;
  const ra = typeRank(a.type) - typeRank(b.type);
  if (ra !== 0) return ra;
  return String(a.id).localeCompare(String(b.id));
}

function signedDelta(entry) {
  const debit = Number(entry.debitMinor || 0);
  const credit = Number(entry.creditMinor || 0);
  return debit - credit;
}

/**
 * Build chronological running balance. Entries must already be single currency.
 */
function buildRunningBalance(entries) {
  const sorted = [...entries].sort(compareLedgerKeys);
  let running = 0;
  return sorted.map((e) => {
    running += signedDelta(e);
    return {
      ...e,
      debitMinor: Number(e.debitMinor || 0),
      creditMinor: Number(e.creditMinor || 0),
      runningBalanceMinor: running,
      runningLabel: running > 0
        ? 'DEBIT_RECEIVABLE'
        : running < 0
          ? 'CREDIT_PAYABLE'
          : 'BALANCED',
    };
  });
}

function tripEntry(line) {
  const at = line.orderDate || line.at || '1970-01-01T00:00:00.000Z';
  if (line.channel === 'cash' || line.type === 'cash_trip') {
    const debit = Math.max(0, Number(line.signedCashMinor || line.tripPositionMinor || 0));
    const credit = Math.max(0, -Number(line.signedCashMinor || 0));
    return {
      id: `trip:${line.orderId || line.id}`,
      at,
      type: 'cash_trip',
      reference: line.orderId || line.id,
      debitMinor: debit,
      creditMinor: credit,
    };
  }
  const credit = Number(line.driverNetMinor || 0);
  return {
    id: `trip:${line.orderId || line.id}`,
    at,
    type: 'online_trip',
    reference: line.orderId || line.id,
    debitMinor: 0,
    creditMinor: credit,
  };
}

function paymentEntry(p) {
  const at = p.confirmedAt || p.paidAt || p.createdAt;
  const amt = Number(p.amountMinor || 0);
  if (p.status === 'reversed' || p.type === 'reversal') {
    const rev = Number(p.reversalAmountMinor || amt);
    // Reversal undoes the payment direction.
    if (p.direction === 'COMPANY_TO_DRIVER') {
      return {
        id: `rev:${p.paymentId || p.id}`,
        at,
        type: 'reversal',
        reference: p.originalPaymentId || p.receiptNumber || p.paymentId,
        debitMinor: 0,
        creditMinor: rev,
      };
    }
    return {
      id: `rev:${p.paymentId || p.id}`,
      at,
      type: 'reversal',
      reference: p.originalPaymentId || p.receiptNumber || p.paymentId,
      debitMinor: rev,
      creditMinor: 0,
    };
  }
  if (p.status && p.status !== 'confirmed') return null;
  if (p.direction === 'COMPANY_TO_DRIVER') {
    return {
      id: `pay:${p.paymentId || p.id}`,
      at,
      type: 'settlement_payment',
      reference: p.receiptNumber || p.paymentId,
      debitMinor: amt,
      creditMinor: 0,
    };
  }
  return {
    id: `pay:${p.paymentId || p.id}`,
    at,
    type: 'settlement_payment',
    reference: p.receiptNumber || p.paymentId,
    debitMinor: 0,
    creditMinor: amt,
  };
}

function openingEntry(adj) {
  const amt = Number(adj.amountMinor || 0);
  const at = adj.effectiveDate || adj.approvedAt || adj.createdAt;
  const driverOwes = adj.direction === 'DRIVER_TO_COMPANY' || adj.direction === 'DRIVER_PAYS_COMPANY';
  return {
    id: `open:${adj.adjustmentId || adj.id}`,
    at,
    type: 'opening_balance',
    reference: adj.adjustmentId || adj.id,
    debitMinor: driverOwes ? amt : 0,
    creditMinor: driverOwes ? 0 : amt,
  };
}

function adjustmentEntry(adj) {
  if (adj.reasonCode === 'opening_balance') return openingEntry(adj);
  const amt = Number(adj.amountMinor || 0);
  const at = adj.effectiveDate || adj.approvedAt || adj.createdAt;
  const driverOwes = adj.direction === 'DRIVER_TO_COMPANY' || adj.direction === 'DRIVER_PAYS_COMPANY';
  return {
    id: `adj:${adj.adjustmentId || adj.id}`,
    at,
    type: 'adjustment',
    reference: adj.adjustmentId || adj.id,
    debitMinor: driverOwes ? amt : 0,
    creditMinor: driverOwes ? 0 : amt,
  };
}

function lockMemo(s) {
  return {
    id: `lock:${s.settlementId || s.id}`,
    at: s.lockedAt || s.createdAt,
    type: 'settlement_lock',
    reference: s.settlementCode || s.settlementId,
    debitMinor: 0,
    creditMinor: 0,
  };
}

function summarizeDriverAccount(rows) {
  const last = rows.length ? rows[rows.length - 1].runningBalanceMinor : 0;
  return {
    tripPositionMinor: rows
      .filter((r) => r.type === 'cash_trip' || r.type === 'online_trip')
      .reduce((s, r) => s + signedDelta(r), 0),
    settlementPaymentsMinor: rows
      .filter((r) => r.type === 'settlement_payment')
      .reduce((s, r) => s + signedDelta(r), 0),
    approvedAdjustmentsMinor: rows
      .filter((r) => r.type === 'adjustment')
      .reduce((s, r) => s + signedDelta(r), 0),
    openingBalanceMinor: rows
      .filter((r) => r.type === 'opening_balance')
      .reduce((s, r) => s + signedDelta(r), 0),
    outstandingMinor: last,
    outstandingLabel: last > 0 ? 'DEBIT_RECEIVABLE' : last < 0 ? 'CREDIT_PAYABLE' : 'BALANCED',
  };
}

module.exports = {
  TYPE_RANK,
  compareLedgerKeys,
  signedDelta,
  buildRunningBalance,
  tripEntry,
  paymentEntry,
  openingEntry,
  adjustmentEntry,
  lockMemo,
  summarizeDriverAccount,
};

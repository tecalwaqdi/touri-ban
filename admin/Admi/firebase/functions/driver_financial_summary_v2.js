'use strict';

/**
 * Driver Financial Summary V2 — READ-ONLY.
 * Aggregates completed+collected trips per driver using financial_accounting_v2.
 * Never writes Firestore.
 */

const v2 = require('./financial_accounting_v2');
const ledger = require('./settlement_ledger');

/** Saudi Arabia is UTC+3 year-round (no DST). */
const RIYADH_OFFSET_MS = 3 * 60 * 60 * 1000;

function riyadhParts(date = new Date()) {
  const t = date.getTime() + RIYADH_OFFSET_MS;
  const d = new Date(t);
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth(),
    day: d.getUTCDate(),
    weekday: d.getUTCDay(),
  };
}

function riyadhInstant(year, month, day) {
  return new Date(Date.UTC(year, month, day) - RIYADH_OFFSET_MS);
}

function boundsToday(now = new Date()) {
  const p = riyadhParts(now);
  return {
    start: riyadhInstant(p.year, p.month, p.day),
    end: riyadhInstant(p.year, p.month, p.day + 1),
  };
}

function boundsWeek(now = new Date()) {
  const p = riyadhParts(now);
  const startDay = p.day - p.weekday;
  return {
    start: riyadhInstant(p.year, p.month, startDay),
    end: riyadhInstant(p.year, p.month, startDay + 7),
  };
}

function boundsMonth(now = new Date()) {
  const p = riyadhParts(now);
  return {
    start: riyadhInstant(p.year, p.month, 1),
    end: riyadhInstant(p.year, p.month + 1, 1),
  };
}

function emptyBucket() {
  return {
    completedTrips: 0,
    grossMinor: 0,
    platformFeeMinor: 0,
    vatMinor: 0,
    driverNetMinor: 0,
    companyDueMinor: 0,
    cashTrips: 0,
    onlineTrips: 0,
    derivedDriverNetCount: 0,
    excludedIncompleteCount: 0,
  };
}

function addToBucket(bucket, line) {
  bucket.completedTrips += 1;
  if (line.grossBaseMinor != null) bucket.grossMinor += line.grossBaseMinor;
  if (line.platformFeeMinor != null) bucket.platformFeeMinor += line.platformFeeMinor;
  if (line.recordedVatMinor != null) bucket.vatMinor += line.recordedVatMinor;
  if (line.driverNetMinor != null) bucket.driverNetMinor += line.driverNetMinor;
  if (line.notes && line.notes.some((n) => n.startsWith('DERIVED'))) {
    bucket.derivedDriverNetCount += 1;
  }
  if (line.channel === 'cash') {
    bucket.cashTrips += 1;
    bucket.companyDueMinor += Math.max(0, Number(line.signedCashMinor || 0));
  } else if (line.channel === 'online') {
    bucket.onlineTrips += 1;
  }
}

function minorToMajor(minor, currency) {
  const exp = v2.normalizeCode(currency);
  const e = {SAR: 2, AED: 2, QAR: 2, EGP: 2, USD: 2, EUR: 2}[exp] ?? 2;
  let div = 1;
  for (let i = 0; i < e; i++) div *= 10;
  return Math.round(Number(minor || 0)) / div;
}

function formatBucket(bucket, currency) {
  return {
    completedTrips: bucket.completedTrips,
    gross: minorToMajor(bucket.grossMinor, currency),
    platformFee: minorToMajor(bucket.platformFeeMinor, currency),
    vat: minorToMajor(bucket.vatMinor, currency),
    driverNet: minorToMajor(bucket.driverNetMinor, currency),
    companyDue: minorToMajor(bucket.companyDueMinor, currency),
    cashTrips: bucket.cashTrips,
    onlineTrips: bucket.onlineTrips,
    derivedDriverNetCount: bucket.derivedDriverNetCount,
    excludedIncompleteCount: bucket.excludedIncompleteCount,
  };
}

function orderCompletedAt(line) {
  if (!line.dataOrder) return null;
  if (line.dataOrder.toDate) return line.dataOrder.toDate();
  const d = new Date(line.dataOrder);
  return Number.isNaN(d.getTime()) ? null : d;
}

function inRange(at, start, end) {
  if (!at) return false;
  return at >= start && at < end;
}

function isCompletedCollected(line) {
  if (line.lifecycle !== 'completed') return false;
  return line.payment === 'paid' ||
    line.payment === 'cashCollected' ||
    line.payment === 'captured';
}

async function settlementTotals(db, driverId, currency) {
  let paidMinor = 0;
  let pendingMinor = 0;
  try {
    const snap = await db
      .collection('financial_settlement_payments')
      .where('driverId', '==', driverId)
      .where('currency', '==', currency)
      .get();
    snap.forEach((doc) => {
      const p = doc.data() || {};
      const amt = Number(p.amountMinor || 0);
      if (p.status === 'confirmed') {
        if (p.direction === 'COMPANY_TO_DRIVER') return;
        paidMinor += amt;
      } else if (p.status === 'pending' || p.status === 'processing') {
        pendingMinor += amt;
      }
    });
  } catch (_) {
    // Collection may be empty / index missing — read-only degrade.
  }
  return {paidMinor, pendingMinor};
}

function canReadDriverSummary(auth, driverId) {
  if (!auth || !auth.uid) return false;
  if (driverId === auth.uid) return true;
  const t = auth.token || {};
  return t.super_admin === true || t.finance === true || t.country_admin === true;
}

/**
 * @param {{db: FirebaseFirestore.Firestore, auth: object, data: object}} ctx
 */
async function getDriverFinancialSummaryV2({db, auth, data}) {
  if (!auth || !auth.uid) {
    const err = new Error('Sign in required.');
    err.code = 'unauthenticated';
    throw err;
  }

  const driverId = String((data && data.driverId) || auth.uid).trim();
  if (!canReadDriverSummary(auth, driverId)) {
    const err = new Error('Drivers may only read their own financial summary.');
    err.code = 'permission-denied';
    throw err;
  }

  const currency = v2.normalizeCode((data && data.currency) || 'SAR') || 'SAR';
  const orders = await ledger.loadDriverOrders(db, driverId);

  const today = emptyBucket();
  const week = emptyBucket();
  const month = emptyBucket();
  const lifetime = emptyBucket();
  const anomalies = [];

  const bToday = boundsToday();
  const bWeek = boundsWeek();
  const bMonth = boundsMonth();

  for (const order of orders) {
    const line = v2.analyzeOrder(order.id, order);
    if (line.currency !== currency) continue;
    if (!isCompletedCollected(line)) continue;

    if (line.driverNetMinor == null || line.confidence === 'incomplete') {
      lifetime.excludedIncompleteCount += 1;
      anomalies.push({
        orderId: order.id,
        reason: line.exclusionReason || 'INCOMPLETE_FINANCIAL_DATA',
        notes: line.notes || [],
      });
      continue;
    }

    const at = orderCompletedAt(line);
    addToBucket(lifetime, line);
    if (inRange(at, bMonth.start, bMonth.end)) addToBucket(month, line);
    if (inRange(at, bWeek.start, bWeek.end)) addToBucket(week, line);
    if (inRange(at, bToday.start, bToday.end)) addToBucket(today, line);
  }

  const {paidMinor, pendingMinor} = await settlementTotals(db, driverId, currency);
  const outstandingMinor = Math.max(0, lifetime.companyDueMinor - paidMinor);

  return {
    ok: true,
    readOnly: true,
    driverId,
    currency,
    timezone: 'Asia/Riyadh',
    today: formatBucket(today, currency),
    week: formatBucket(week, currency),
    month: formatBucket(month, currency),
    lifetime: formatBucket(lifetime, currency),
    settlements: {
      paid: minorToMajor(paidMinor, currency),
      pending: minorToMajor(pendingMinor, currency),
      outstanding: minorToMajor(outstandingMinor, currency),
    },
    anomalies: anomalies.slice(0, 25),
    generatedAt: new Date().toISOString(),
  };
}

module.exports = {
  getDriverFinancialSummaryV2,
  boundsToday,
  boundsWeek,
  boundsMonth,
  formatBucket,
  emptyBucket,
  addToBucket,
  minorToMajor,
};

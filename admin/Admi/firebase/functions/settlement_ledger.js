'use strict';

/**
 * Settlement Ledger V2 — accounting records only.
 * Writes ONLY: financial_settlements, claims, lines, events, allocations, idempotency, counters.
 * NEVER writes: order, wallets, transactions, user, company_payments, payments.
 */

const crypto = require('crypto');
const v2 = require('./financial_accounting_v2');
const {loadFinancePolicy, assertChecker} = require('./finance_policy');
const {loadFinanceFeatureFlags, assertFlag} = require('./finance_feature_flags');

function periods() {
  return require('./finance_periods');
}

const ACCOUNTING_ENGINE_VERSION = 'financial_v2';
const MAX_SETTLEMENT_LINES = 200;

class SettlementError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details || null;
  }
}

function fail(code, message, details) {
  throw new SettlementError(code, message, details);
}

function canWriteSettlements(token) {
  if (!token) return false;
  if (token.super_admin === true) return true;
  if (token.finance === true && token.country_admin !== true && token.agent !== true) {
    return true;
  }
  return false;
}

function canReadSettlements(token) {
  if (!token) return false;
  return (
    token.super_admin === true ||
    token.finance === true ||
    token.country_admin === true
  );
}

function requireAuth(auth) {
  if (!auth || !auth.uid) fail('unauthenticated', 'Sign in required.');
}

function requireWriter(auth) {
  requireAuth(auth);
  const token = auth.token || {};
  if (!canWriteSettlements(token)) {
    fail('permission-denied', 'Settlement writes require SuperAdmin or Finance.');
  }
}

function enforceChecker(policy, makerUid, checkerUid, action) {
  try {
    return assertChecker({policy, makerUid, checkerUid, action});
  } catch (e) {
    fail('permission-denied', e.message, e.details);
  }
}

function idempotencyDocId(uid, op, key) {
  const raw = `${uid}|${op}|${String(key || '').trim()}`;
  return crypto.createHash('sha256').update(raw).digest('hex');
}

function stableStringify(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(',')}]`;
  }
  const keys = Object.keys(value).sort();
  return `{${keys.map((k) => `${JSON.stringify(k)}:${stableStringify(value[k])}`).join(',')}}`;
}

function computePreviewHash(payload) {
  return crypto.createHash('sha256').update(stableStringify(payload)).digest('hex');
}

function mapDirection(previewDirection) {
  if (previewDirection === 'driverPaysCompany') return 'DRIVER_PAYS_COMPANY';
  if (previewDirection === 'companyPaysDriver') return 'COMPANY_PAYS_DRIVER';
  return 'BALANCED';
}

function inPeriod(dataOrder, periodStart, periodEnd) {
  if (!dataOrder) return false;
  const d = dataOrder.toDate ? dataOrder.toDate() : new Date(dataOrder);
  if (Number.isNaN(d.getTime())) return false;
  if (periodStart && d < periodStart) return false;
  if (periodEnd && !(d < periodEnd)) return false;
  return true;
}

function orderDateIso(dataOrder) {
  if (!dataOrder) return null;
  const d = dataOrder.toDate ? dataOrder.toDate() : new Date(dataOrder);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

function lineTripPositionMinor(line) {
  if (line.channel === 'cash') return line.signedCashMinor || 0;
  if (line.channel === 'online') return -(line.driverNetMinor || 0);
  return 0;
}

function buildSnapshot(lines, currency) {
  const code = v2.normalizeCode(currency);
  const preview = v2.settlePreviewForDriver(lines, code);
  const by = {};
  for (const line of lines) {
    if (line.currency !== code) continue;
    v2.accumulate(by, line);
  }
  const t = by[code] || v2.emptyCurrency(code);
  const direction = mapDirection(preview.direction);
  return {
    cashCustomerCollectedMinor: preview.cashHeldMinor,
    cashDriverEntitlementMinor: preview.cashDriverEntitlementMinor,
    driverCashLiabilityMinor: preview.driverCashLiabilityMinor,
    onlineCustomerCollectedMinor: t.onlineCustomerPaidMinor,
    onlineDriverEntitlementMinor: preview.onlineDriverEntitlementMinor,
    companyOnlineLiabilityMinor: preview.companyOnlineLiabilityMinor,
    grossBaseMinor: t.grossBaseFareMinor,
    platformFeeMinor: t.platformFeeAllMinor,
    recordedVatMinor: t.recordedVatAllMinor,
    recordedDiscountMinor: t.recordedDiscountsAllMinor,
    netTripPositionMinor: preview.netTripSettlementMinor,
    eligibleTripCount: preview.includedTrips,
    excludedTripCount: preview.excludedTrips,
    highCount: t.highCount,
    derivedCount: t.derivedCount,
    direction,
    absoluteSettlementAmountMinor: Math.abs(preview.netTripSettlementMinor),
    exclusionCounts: preview.exclusionCounts,
  };
}

function hashInputFromLines(opts) {
  const eligible = opts.lines
    .filter((l) => l.eligible && l.currency === opts.currency)
    .map((l) => ({
      orderId: l.orderId,
      customerPaidMinor: l.customerPaidMinor,
      driverNetMinor: l.driverNetMinor,
      recon: l.reconStatus,
      confidence: l.confidence,
    }))
    .sort((a, b) => a.orderId.localeCompare(b.orderId));
  return {
    engine: ACCOUNTING_ENGINE_VERSION,
    driverId: opts.driverId,
    currency: opts.currency,
    periodStart: opts.periodStart ? opts.periodStart.toISOString() : '',
    periodEnd: opts.periodEnd ? opts.periodEnd.toISOString() : '',
    eligible,
    net: opts.snapshot.netTripPositionMinor,
    cashLiab: opts.snapshot.driverCashLiabilityMinor,
    onlineLiab: opts.snapshot.companyOnlineLiabilityMinor,
  };
}

function lockEligible(line, ctx) {
  if (!line.eligible) return false;
  if (line.driverId !== ctx.driverId) return false;
  if (line.currency !== ctx.currency) return false;
  if (line.confidence !== 'high' && line.confidence !== 'derived') return false;
  if (!inPeriod(line.dataOrder, ctx.periodStart, ctx.periodEnd)) return false;
  return true;
}

function eventId(type) {
  return `${type}_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
}

function eventRef(db, settlementId, id) {
  return db
    .collection('financial_settlements')
    .doc(settlementId)
    .collection('events')
    .doc(id);
}

function lineRef(db, settlementId, orderId) {
  return db
    .collection('financial_settlements')
    .doc(settlementId)
    .collection('lines')
    .doc(orderId);
}

function actorRole(token) {
  if (token.super_admin) return 'super_admin';
  if (token.finance) return 'finance';
  if (token.country_admin) return 'country_admin';
  return 'unknown';
}

async function loadDriverOrders(db, driverId) {
  const snap = await db
    .collection('order')
    .where('mndob_user', '==', db.doc(`user/${driverId}`))
    .get();
  const out = [];
  snap.forEach((doc) => {
    const data = doc.data() || {};
    out.push({id: doc.id, ...data});
  });
  return out;
}

function analyzeScoped(orders, ctx) {
  const lines = [];
  for (const order of orders) {
    const line = v2.analyzeOrder(order.id, order);
    if (ctx.countryPath) {
      if (line.countryPath && line.countryPath !== ctx.countryPath) continue;
    }
    if (!inPeriod(order.data_order, ctx.periodStart, ctx.periodEnd)) {
      // Still analyze for exclusion if same driver/currency window miss
      if (line.currency === ctx.currency) {
        line.eligible = false;
        line.exclusionReason = line.exclusionReason || 'OUT_OF_PERIOD';
      } else {
        continue;
      }
    }
    if (line.currency !== ctx.currency) continue;
    lines.push(line);
  }
  return lines;
}

async function nextSettlementCode(db, tx, year) {
  const ref = db.doc(`financial_settlement_counters/year_${year}`);
  const snap = await tx.get(ref);
  const seq = snap.exists ? (snap.data().seq || 0) + 1 : 1;
  tx.set(ref, {year, seq, updatedAt: new Date().toISOString()}, {merge: true});
  const padded = String(seq).padStart(6, '0');
  return `STL-${year}-${padded}`;
}

async function readIdempotency(db, tx, id) {
  const ref = db.doc(`financial_settlement_idempotency/${id}`);
  const snap = await tx.get(ref);
  return {ref, snap};
}

/**
 * Create draft — no claims.
 */
async function createSettlementDraft({db, auth, data, now}) {
  requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', fail);
  const driverId = String(data.driverId || '').trim();
  const countryId = String(data.countryId || data.countryPath || '').trim();
  const currency = v2.normalizeCode(data.currency);
  const periodStart = data.periodStart ? new Date(data.periodStart) : null;
  const periodEnd = data.periodEnd ? new Date(data.periodEnd) : null;
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!driverId) fail('invalid-argument', 'driverId required');
  if (!currency) fail('invalid-argument', 'currency required');
  if (!idempotencyKey) fail('invalid-argument', 'idempotencyKey required');
  if (!periodStart || !periodEnd || Number.isNaN(periodStart.getTime()) || Number.isNaN(periodEnd.getTime())) {
    fail('invalid-argument', 'periodStart and periodEnd required');
  }

  const countryPath = countryId.startsWith('countries/')
    ? countryId
    : countryId
      ? `countries/${countryId}`
      : null;

  const orders = await loadDriverOrders(db, driverId);
  const lines = analyzeScoped(orders, {
    currency,
    periodStart,
    periodEnd,
    countryPath,
  });
  const snapshot = buildSnapshot(lines, currency);
  const eligibleLines = lines.filter((l) => l.eligible);
  const excluded = lines
    .filter((l) => !l.eligible)
    .map((l) => ({orderId: l.orderId, reason: l.exclusionReason || 'EXCLUDED'}));

  const hash = computePreviewHash(
    hashInputFromLines({
      lines,
      currency,
      driverId,
      periodStart,
      periodEnd,
      snapshot,
    }),
  );
  const filterSignature = [
    driverId,
    countryPath || '',
    currency,
    periodStart.toISOString(),
    periodEnd.toISOString(),
  ].join('|');

  await periods().assertPeriodOpen(db, {
    countryRef: countryPath || 'all',
    currency,
    startAt: periodStart.toISOString(),
    endAt: periodEnd.toISOString(),
  });

  const idempId = idempotencyDocId(auth.uid, 'createDraft', idempotencyKey);
  const nowIso = (now || new Date()).toISOString();
  const year = (now || new Date()).getUTCFullYear();

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return idempSnap.data().result;
    }

    const settlementRef = db.collection('financial_settlements').doc();
    const code = await nextSettlementCode(db, tx, year);
    const settlementId = settlementRef.id;

    const doc = {
      settlementId,
      settlementCode: code,
      driverId,
      driverRef: `user/${driverId}`,
      countryId: countryPath,
      countryRef: countryPath,
      currency,
      periodStart: periodStart.toISOString(),
      periodEnd: periodEnd.toISOString(),
      status: 'draft',
      accountingEngineVersion: ACCOUNTING_ENGINE_VERSION,
      filterSignature,
      previewHash: hash,
      lockedHash: null,
      ...snapshot,
      eligibleOrderIds: eligibleLines.map((l) => l.orderId).sort(),
      excluded,
      createdBy: auth.uid,
      createdAt: nowIso,
      updatedAt: nowIso,
      idempotencyKey,
    };

    tx.set(settlementRef, doc);
    tx.set(eventRef(db, settlementId, eventId('CREATED_DRAFT')), {
      type: 'CREATED_DRAFT',
      actorUid: auth.uid,
      actorRole: actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: null,
      afterStatus: 'draft',
      reason: null,
      metadata: {previewHash: hash, eligible: snapshot.eligibleTripCount},
    });
    periods().writeAudit(tx, db, {
      eventType: 'CREATED_DRAFT',
      actorUid: auth.uid,
      timestamp: nowIso,
      settlementId,
      settlementCode: code,
      driverId,
    });
    const result = {settlementId, settlementCode: code, status: 'draft', previewHash: hash, currency, ...snapshot};
    tx.set(idempRef, {
      status: 'completed',
      op: 'createDraft',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function refreshSettlementDraft({db, auth, data, now}) {
  requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', fail);
  const settlementId = String(data.settlementId || '').trim();
  if (!settlementId) fail('invalid-argument', 'settlementId required');
  const settlementRef = db.collection('financial_settlements').doc(settlementId);
  const existing = await settlementRef.get();
  if (!existing.exists) fail('not-found', 'Settlement not found');
  const s = existing.data();
  if (s.status !== 'draft') fail('failed-precondition', 'Only drafts can refresh preview');

  const periodStart = new Date(s.periodStart);
  const periodEnd = new Date(s.periodEnd);
  const orders = await loadDriverOrders(db, s.driverId);
  const lines = analyzeScoped(orders, {
    currency: s.currency,
    periodStart,
    periodEnd,
    countryPath: s.countryId,
  });
  const snapshot = buildSnapshot(lines, s.currency);
  const eligibleLines = lines.filter((l) => l.eligible);
  const excluded = lines
    .filter((l) => !l.eligible)
    .map((l) => ({orderId: l.orderId, reason: l.exclusionReason || 'EXCLUDED'}));
  const hash = computePreviewHash(
    hashInputFromLines({
      lines,
      currency: s.currency,
      driverId: s.driverId,
      periodStart,
      periodEnd,
      snapshot,
    }),
  );
  const nowIso = (now || new Date()).toISOString();
  await settlementRef.update({
    ...snapshot,
    previewHash: hash,
    eligibleOrderIds: eligibleLines.map((l) => l.orderId).sort(),
    excluded,
    updatedAt: nowIso,
  });
  await eventRef(db, settlementId, eventId('PREVIEW_REFRESHED')).set({
    type: 'PREVIEW_REFRESHED',
    actorUid: auth.uid,
    actorRole: actorRole(auth.token || {}),
    timestamp: nowIso,
    beforeStatus: 'draft',
    afterStatus: 'draft',
    reason: null,
    metadata: {previewHash: hash},
  });
  return {settlementId, status: 'draft', previewHash: hash, currency: s.currency, ...snapshot};
}

async function lockSettlement({db, auth, data, now}) {
  requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', fail);
  const settlementId = String(data.settlementId || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!settlementId) fail('invalid-argument', 'settlementId required');
  if (!idempotencyKey) fail('invalid-argument', 'idempotencyKey required');

  const settlementRef = db.collection('financial_settlements').doc(settlementId);
  const existing = await settlementRef.get();
  if (!existing.exists) fail('not-found', 'Settlement not found');
  const s = existing.data();
  if (s.status === 'locked' || s.status === 'settled') {
    const idempId = idempotencyDocId(auth.uid, 'lock', idempotencyKey);
    const idempSnap = await db.doc(`financial_settlement_idempotency/${idempId}`).get();
    if (idempSnap.exists) return idempSnap.data().result;
    return {
      settlementId,
      status: s.status,
      lockedHash: s.lockedHash,
      idempotent: true,
    };
  }
  if (s.status !== 'draft') fail('failed-precondition', `Cannot lock status=${s.status}`);

  await periods().assertPeriodOpen(db, {
    countryRef: s.countryRef || s.countryId || 'all',
    currency: s.currency,
    startAt: s.periodStart,
    endAt: s.periodEnd,
  });

  const eligibleIds = s.eligibleOrderIds || [];
  if (eligibleIds.length > MAX_SETTLEMENT_LINES) {
    fail(
      'resource-exhausted',
      `MAX_SETTLEMENT_LINES=${MAX_SETTLEMENT_LINES}. Narrow the period.`,
      {count: eligibleIds.length, max: MAX_SETTLEMENT_LINES},
    );
  }

  const periodStart = new Date(s.periodStart);
  const periodEnd = new Date(s.periodEnd);
  const nowIso = (now || new Date()).toISOString();
  const idempId = idempotencyDocId(auth.uid, 'lock', idempotencyKey);

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return idempSnap.data().result;
    }

    const live = await tx.get(settlementRef);
    if (!live.exists) fail('not-found', 'Settlement not found');
    const cur = live.data();
    if (cur.status === 'locked' || cur.status === 'settled') {
      return {settlementId, status: cur.status, lockedHash: cur.lockedHash, idempotent: true};
    }
    if (cur.status !== 'draft') fail('failed-precondition', `Cannot lock status=${cur.status}`);

    const pol = await loadFinancePolicy(db, tx);
    const check = enforceChecker(pol, cur.createdBy, auth.uid, 'lock');

    const orderSnaps = [];
    const claimSnaps = [];
    for (const orderId of eligibleIds) {
      orderSnaps.push(await tx.get(db.collection('order').doc(orderId)));
      claimSnaps.push(await tx.get(db.collection('financial_settlement_claims').doc(orderId)));
    }

    const lines = [];
    for (const os of orderSnaps) {
      if (!os.exists) fail('failed-precondition', 'SETTLEMENT_PREVIEW_STALE', {missingOrder: os.id});
      lines.push(v2.analyzeOrder(os.id, os.data()));
    }

    const ctx = {
      driverId: cur.driverId,
      currency: cur.currency,
      periodStart,
      periodEnd,
    };
    for (const line of lines) {
      if (!lockEligible(line, ctx)) {
        fail('failed-precondition', 'SETTLEMENT_PREVIEW_STALE', {
          orderId: line.orderId,
          reason: line.exclusionReason || 'NOT_ELIGIBLE',
        });
      }
    }

    const snapshot = buildSnapshot(lines, cur.currency);
    const hash = computePreviewHash(
      hashInputFromLines({
        lines,
        currency: cur.currency,
        driverId: cur.driverId,
        periodStart,
        periodEnd,
        snapshot,
      }),
    );
    if (hash !== cur.previewHash) {
      fail('failed-precondition', 'SETTLEMENT_PREVIEW_STALE', {
        expected: cur.previewHash,
        actual: hash,
      });
    }

    for (const cs of claimSnaps) {
      if (cs.exists) {
        fail('already-exists', 'ORDER_ALREADY_CLAIMED', {
          orderId: cs.id,
          settlementId: cs.data().settlementId,
        });
      }
    }

    for (const line of lines) {
      tx.set(db.collection('financial_settlement_claims').doc(line.orderId), {
        orderId: line.orderId,
        settlementId,
        driverRef: cur.driverRef,
        driverId: cur.driverId,
        currency: cur.currency,
        claimedAt: nowIso,
        claimedBy: auth.uid,
      });
      tx.set(lineRef(db, settlementId, line.orderId), {
        orderId: line.orderId,
        driverRef: cur.driverRef,
        countryRef: cur.countryRef,
        currency: line.currency,
        orderDate: orderDateIso(line.dataOrder),
        paymentMethod: line.channel,
        lifecycleStatus: line.lifecycle,
        paymentStatus: line.payment,
        confidence: line.confidence,
        customerPaidMinor: line.customerPaidMinor,
        grossBaseMinor: line.grossBaseMinor,
        platformFeeMinor: line.platformFeeMinor,
        recordedVatMinor: line.recordedVatMinor,
        discountMinor: line.recordedDiscountMinor,
        driverNetMinor: line.driverNetMinor,
        tripPositionMinor: lineTripPositionMinor(line),
        reconciliationDifferenceMinor: line.reconDiffMinor || 0,
        includedAt: nowIso,
        accountingEngineVersion: ACCOUNTING_ENGINE_VERSION,
      });
    }

    tx.update(settlementRef, {
      status: 'locked',
      lockedHash: hash,
      lockedAt: nowIso,
      lockedBy: auth.uid,
      updatedAt: nowIso,
      paidConfirmedMinor: 0,
      outstandingMinor: snapshot.absoluteSettlementAmountMinor,
      paymentCount: 0,
      lastPaymentAt: null,
      paymentIds: [],
      ...snapshot,
    });
    tx.set(eventRef(db, settlementId, eventId('LOCKED')), {
      type: 'LOCKED',
      actorUid: auth.uid,
      actorRole: actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: 'draft',
      afterStatus: 'locked',
      reason: null,
      metadata: {
        lockedHash: hash,
        lines: lines.length,
        selfApproved: check.selfApproved === true,
      },
    });
    if (check.selfApproved) {
      tx.set(eventRef(db, settlementId, eventId('SELF_APPROVAL')), {
        type: 'SELF_APPROVAL',
        actorUid: auth.uid,
        actorRole: actorRole(auth.token || {}),
        timestamp: nowIso,
        beforeStatus: 'draft',
        afterStatus: 'locked',
        reason: 'allowSelfApproval',
        metadata: {action: 'lock'},
      });
    }
    periods().writeAudit(tx, db, {
      eventType: 'LOCKED',
      actorUid: auth.uid,
      timestamp: nowIso,
      settlementId,
      settlementCode: cur.settlementCode,
      driverId: cur.driverId,
      selfApproved: check.selfApproved === true,
    });
    const result = {
      settlementId,
      status: 'locked',
      lockedHash: hash,
      ...snapshot,
    };
    tx.set(idempRef, {
      status: 'completed',
      op: 'lock',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function markSettlementSettled({db, auth, data, now}) {
  requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', fail);
  assertFlag(flags, 'FINANCIAL_PAYMENT_CONFIRM_ENABLED', fail);
  const settlementId = String(data.settlementId || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  const method = String(data.settlementMethod || '').trim();
  const paymentReference = String(data.paymentReference || '').trim();
  const notes = data.notes ? String(data.notes) : '';
  const payer = String(data.payer || '').trim();
  const payee = String(data.payee || '').trim();
  if (!settlementId) fail('invalid-argument', 'settlementId required');
  if (!idempotencyKey) fail('invalid-argument', 'idempotencyKey required');
  const allowed = new Set([
    'bank_transfer',
    'cash',
    'external_transfer',
    'existing_company_payment',
    'other',
  ]);
  if (!allowed.has(method)) fail('invalid-argument', 'Invalid settlementMethod');
  if (!paymentReference) fail('invalid-argument', 'paymentReference required');

  const nowIso = (now || new Date()).toISOString();
  const settledAt = data.settledAt ? new Date(data.settledAt).toISOString() : nowIso;
  const idempId = idempotencyDocId(auth.uid, 'markSettled', idempotencyKey);
  const settlementRef = db.collection('financial_settlements').doc(settlementId);

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return idempSnap.data().result;
    }
    const live = await tx.get(settlementRef);
    if (!live.exists) fail('not-found', 'Settlement not found');
    const cur = live.data();
    if (cur.status === 'settled') {
      return {settlementId, status: 'settled', idempotent: true};
    }
    if ((cur.paymentIds || []).length > 0 || (cur.paidConfirmedMinor || 0) > 0) {
      fail('failed-precondition', 'USE_PAYMENT_LEDGER');
    }
    if (cur.status !== 'locked') fail('failed-precondition', 'Only locked settlements can be marked settled');
    const pol = await loadFinancePolicy(db, tx);
    enforceChecker(pol, cur.createdBy, auth.uid, 'markSettled');

    const amountMinor = Number(data.amountMinor);
    if (!Number.isInteger(amountMinor)) {
      fail('invalid-argument', 'amountMinor integer required');
    }
    if (amountMinor !== cur.absoluteSettlementAmountMinor) {
      fail('failed-precondition', 'AMOUNT_MISMATCH', {
        expected: cur.absoluteSettlementAmountMinor,
        actual: amountMinor,
      });
    }
    if (data.currency && v2.normalizeCode(data.currency) !== cur.currency) {
      fail('invalid-argument', 'Evidence currency must match settlement');
    }

    const evidence = {
      method,
      reference: paymentReference,
      amountMinor,
      currency: cur.currency,
      payer: payer || (cur.direction === 'DRIVER_PAYS_COMPANY' ? 'driver' : 'company'),
      payee: payee || (cur.direction === 'DRIVER_PAYS_COMPANY' ? 'company' : 'driver'),
      recordedBy: auth.uid,
      recordedAt: nowIso,
      settledAt,
      notes,
    };

    tx.update(settlementRef, {
      status: 'settled',
      paymentEvidence: evidence,
      settledAt,
      settledBy: auth.uid,
      updatedAt: nowIso,
    });
    tx.set(eventRef(db, settlementId, eventId('MARKED_SETTLED')), {
      type: 'MARKED_SETTLED',
      actorUid: auth.uid,
      actorRole: actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: 'locked',
      afterStatus: 'settled',
      reason: notes || null,
      metadata: evidence,
    });
    const result = {settlementId, status: 'settled', paymentEvidence: evidence};
    tx.set(idempRef, {
      status: 'completed',
      op: 'markSettled',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function voidSettlement({db, auth, data, now}) {
  requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', fail);
  const settlementId = String(data.settlementId || '').trim();
  const reason = String(data.reason || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!settlementId) fail('invalid-argument', 'settlementId required');
  if (!reason) fail('invalid-argument', 'Void reason required');
  if (!idempotencyKey) fail('invalid-argument', 'idempotencyKey required');

  const nowIso = (now || new Date()).toISOString();
  const idempId = idempotencyDocId(auth.uid, 'void', idempotencyKey);
  const settlementRef = db.collection('financial_settlements').doc(settlementId);

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return idempSnap.data().result;
    }
    const live = await tx.get(settlementRef);
    if (!live.exists) fail('not-found', 'Settlement not found');
    const cur = live.data();
    if (cur.status === 'settled') {
      fail('failed-precondition', 'VOID_SETTLED_FORBIDDEN');
    }
    if (cur.status === 'voided') {
      return {settlementId, status: 'voided', idempotent: true};
    }
    const pol = await loadFinancePolicy(db, tx);
    const check = enforceChecker(pol, cur.createdBy, auth.uid, 'void');
    const netPaid = Number(cur.paidConfirmedMinor || 0);
    if (netPaid > 0) {
      fail('failed-precondition', 'VOID_WITH_CONFIRMED_PAYMENTS_FORBIDDEN');
    }
    const paymentIds = cur.paymentIds || [];
    for (const pid of paymentIds) {
      const ps = await tx.get(db.collection('financial_settlement_payments').doc(pid));
      if (ps.exists && ps.data().status === 'confirmed') {
        fail('failed-precondition', 'VOID_WITH_CONFIRMED_PAYMENTS_FORBIDDEN');
      }
    }

    const ids = cur.eligibleOrderIds || [];
    const claimSnaps = [];
    for (const orderId of ids) {
      claimSnaps.push(await tx.get(db.collection('financial_settlement_claims').doc(orderId)));
    }
    if (cur.status === 'locked') {
      for (const cs of claimSnaps) {
        if (cs.exists && cs.data().settlementId === settlementId) {
          tx.delete(cs.ref);
        }
      }
    }

    tx.update(settlementRef, {
      status: 'voided',
      voidedAt: nowIso,
      voidedBy: auth.uid,
      voidReason: reason,
      updatedAt: nowIso,
    });
    tx.set(eventRef(db, settlementId, eventId('VOIDED')), {
      type: 'VOIDED',
      actorUid: auth.uid,
      actorRole: actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: cur.status,
      afterStatus: 'voided',
      reason,
      metadata: {releasedClaims: cur.status === 'locked', selfApproved: check.selfApproved === true},
    });
    periods().writeAudit(tx, db, {
      eventType: 'VOIDED',
      actorUid: auth.uid,
      timestamp: nowIso,
      settlementId,
      settlementCode: cur.settlementCode,
      driverId: cur.driverId,
      reason,
      selfApproved: check.selfApproved === true,
    });
    const result = {settlementId, status: 'voided'};
    tx.set(idempRef, {
      status: 'completed',
      op: 'void',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function allocateLegacyPayment(args) {
  return require('./settlement_payments').allocateExistingPayment(args);
}

module.exports = {
  ACCOUNTING_ENGINE_VERSION,
  MAX_SETTLEMENT_LINES,
  SettlementError,
  canWriteSettlements,
  canReadSettlements,
  computePreviewHash,
  buildSnapshot,
  createSettlementDraft,
  refreshSettlementDraft,
  lockSettlement,
  markSettlementSettled,
  voidSettlement,
  allocateLegacyPayment,
  fail,
  requireWriter,
  eventId,
  eventRef,
  actorRole,
  readIdempotency,
  idempotencyDocId,
  loadDriverOrders,
  analyzeScoped,
  hashInputFromLines,
  enforceChecker,
  loadFinancePolicy,
};

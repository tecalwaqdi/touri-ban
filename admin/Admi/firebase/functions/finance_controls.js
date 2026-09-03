'use strict';

/**
 * Phase 7A — financial controls: periods, adjustments, reconciliation,
 * statements, accountant home, audit search. No wallet / payout / order writes.
 */

const v2 = require('./financial_accounting_v2');
const ledger = require('./settlement_ledger');
const payments = require('./settlement_payments');
const periods = require('./finance_periods');
const policyMod = require('./finance_policy');
const driverLedger = require('./driver_ledger');
const {loadFinanceFeatureFlags, assertFlag} = require('./finance_feature_flags');

const ADJUSTMENT_REASONS = new Set([
  'correction',
  'manual_credit',
  'manual_debit',
  'rounding',
  'legacy_balance',
  'opening_balance',
  'other',
]);

const ADJUSTMENT_DIRECTIONS = new Set(['DRIVER_TO_COMPANY', 'COMPANY_TO_DRIVER']);

function requireReader(auth) {
  if (!auth || !auth.uid) ledger.fail('unauthenticated', 'Sign in required.');
  if (!ledger.canReadSettlements(auth.token || {})) {
    ledger.fail('permission-denied', 'Not authorized.');
  }
}

function isAgentOnly(auth) {
  const t = (auth && auth.token) || {};
  return t.country_admin === true && t.super_admin !== true && t.finance !== true;
}

function agentCountry(auth) {
  return (auth.token && auth.token.country_id) || null;
}

function inAgentScope(auth, countryRef) {
  if (!isAgentOnly(auth)) return true;
  const cid = agentCountry(auth);
  if (!cid) return false;
  return countryRef === cid;
}

function item(code, severity, blocksClose, count, sample, extra = {}) {
  return {
    code,
    severity,
    blocksClose: !!blocksClose,
    count: count || 0,
    sample: (sample || []).slice(0, 25),
    ...extra,
  };
}

function isQaFixtureOrder(order) {
  if (!order) return false;
  if (order.is_test_fixture === true || order.qa_fixture === true || order.test_fixture === true) {
    return true;
  }
  const id = String(order.id || '');
  return /^(fin7_ctrl_|fin9_ctrl_|fin_rt_cash_|fin_rt_cash_ui_|fin_rt_)/.test(id);
}

function missingFieldsOf(order, line) {
  const missing = [];
  if (line.confidence === 'incomplete') {
    if (!line.customerPaidMinor && line.customerPaidMinor !== 0) missing.push('total');
    if (line.platformFeeMinor == null) missing.push('total_app');
    if (line.recordedVatMinor == null) missing.push('total_vat');
    if (line.driverNetMinor == null) missing.push('total_mndob');
  }
  if (!order.status_code && !order.halh && !order.halh_order) missing.push('status_code');
  if (!order.payment_status && !order.halh && !order.halh_order) missing.push('payment_status');
  if (!line.driverId) missing.push('driver');
  return missing;
}

function classifyException(code) {
  const critical = new Set([
    'SETTLEMENT_TOTALS_MISMATCH',
    'DUPLICATE_CLAIM',
    'PAYMENT_EXCEEDS_DUE',
    'CURRENCY_MISMATCH',
    'REVERSAL_MISMATCH',
  ]);
  const high = new Set([
    'MISSING_PAYMENT_STATUS',
    'UNALLOCATED_PAYMENT',
    'INCOMPLETE_FINANCIAL_RECORD',
    'RECONCILIATION_DIFFERENCE',
    'LOCKED_UNPAID',
    'PAYMENT_PENDING',
    'DRAFT_SETTLEMENT',
    'ORPHAN_CLAIM',
    'MISSING_STATUS_CODE',
    'MISSING_DRIVER',
    'UNSUPPORTED_CURRENCY',
    'LOCKED_WITHOUT_LINES',
    'PAYMENT_TOTALS_MISMATCH',
  ]);
  if (critical.has(code)) return 'critical';
  if (high.has(code)) return 'high';
  return 'medium';
}

async function collectDocs(db, name) {
  const snap = await db.collection(name).get();
  const rows = [];
  snap.forEach((d) => rows.push({id: d.id, ...d.data()}));
  return rows;
}

async function scanOrders(db) {
  const snap = await db.collection('order').get();
  const rows = [];
  snap.forEach((d) => rows.push({id: d.id, ...d.data()}));
  return rows;
}

function orderDateMs(order) {
  const raw = order.data_order;
  if (!raw) return null;
  const d = raw.toDate ? raw.toDate() : new Date(raw);
  const t = d.getTime();
  return Number.isNaN(t) ? null : t;
}

function inRange(ms, from, to) {
  if (ms == null) return true;
  if (from != null && ms < from) return false;
  if (to != null && ms >= to) return false;
  return true;
}

async function buildPeriodCloseChecklist({db, auth, data}) {
  requireReader(auth);
  const periodId = data && data.periodId;
  let window = {
    startAt: data && data.startAt,
    endAt: data && data.endAt,
    countryRef: (data && (data.countryRef || data.countryId)) || 'all',
    currency: (data && data.currency) || 'all',
  };
  if (periodId) {
    const snap = await db.collection('financial_periods').doc(periodId).get();
    if (!snap.exists) ledger.fail('not-found', 'Period not found');
    const p = snap.data();
    window = {
      startAt: p.startAt,
      endAt: p.endAt,
      countryRef: p.countryRef || 'all',
      currency: p.currency || 'all',
    };
  }
  const from = window.startAt ? Date.parse(window.startAt) : null;
  const to = window.endAt ? Date.parse(window.endAt) : null;
  const exceptions = await scanFinancialExceptions({db, auth, data: window});
  const inWindow = (row, dateField) => {
    const raw = row[dateField] || row.createdAt || row.lockedAt || row.periodStart;
    if (!raw) return true;
    const ms = Date.parse(raw);
    return inRange(ms, from, to);
  };
  const items = exceptions.items.filter((it) => {
    if (!from && !to) return true;
    if (!it.sample || !it.sample.length) return it.count > 0;
    return true;
  });
  const settlements = await collectDocs(db, 'financial_settlements');
  const payRows = await collectDocs(db, 'financial_settlement_payments');
  const drafts = settlements.filter(
    (s) => s.status === 'draft' && inWindow(s, 'periodStart') && currencyOk(s, window),
  );
  const lockedUnpaid = settlements.filter(
    (s) =>
      (s.status === 'locked' || s.status === 'partially_paid') &&
      Number(s.outstandingMinor || 0) > 0 &&
      inWindow(s, 'periodStart') &&
      currencyOk(s, window),
  );
  const pendingPays = payRows.filter(
    (p) => p.status === 'pending' && inWindow(p, 'createdAt') && currencyOk(p, window),
  );
  const extra = [
    item('DRAFT_SETTLEMENT', 'high', true, drafts.length, drafts.map((s) => s.settlementCode)),
    item(
      'LOCKED_UNPAID',
      'high',
      true,
      lockedUnpaid.length,
      lockedUnpaid.map((s) => s.settlementCode),
    ),
    item(
      'PAYMENT_PENDING',
      'high',
      true,
      pendingPays.length,
      pendingPays.map((p) => p.paymentId),
    ),
  ];
  const merged = mergeItems([...items, ...extra]);
  return {
    periodId: periodId || null,
    window,
    items: merged,
    blockerCount: merged.filter((i) => i.blocksClose && i.count > 0).length,
    criticalCount: merged.filter((i) => i.severity === 'critical' && i.count > 0).length,
  };
}

function currencyOk(row, window) {
  if (!window || !window.currency || window.currency === 'all') return true;
  return row.currency === window.currency;
}

function mergeItems(list) {
  const by = {};
  for (const it of list) {
    if (!by[it.code]) {
      by[it.code] = {...it, sample: [...(it.sample || [])]};
    } else {
      by[it.code].count += it.count || 0;
      by[it.code].sample = [...by[it.code].sample, ...(it.sample || [])].slice(0, 25);
      by[it.code].blocksClose = by[it.code].blocksClose || it.blocksClose;
    }
  }
  return Object.values(by).filter((i) => i.count > 0);
}

async function scanFinancialExceptions({db, auth, data}) {
  requireReader(auth);
  const window = data || {};
  const from = window.startAt ? Date.parse(window.startAt) : null;
  const to = window.endAt ? Date.parse(window.endAt) : null;
  const orders = await scanOrders(db);
  const settlements = await collectDocs(db, 'financial_settlements');
  const claims = await collectDocs(db, 'financial_settlement_claims');
  const payRows = await collectDocs(db, 'financial_settlement_payments');
  const allocs = await collectDocs(db, 'financial_payment_allocations');
  const allocClaims = await collectDocs(db, 'financial_payment_allocation_claims');
  const companyPays = await collectDocs(db, 'company_payments');

  const buckets = {};
  const push = (code, sampleRow, extra = {}) => {
    const severity = extra.severity || classifyException(code);
    const blocksClose = Object.prototype.hasOwnProperty.call(extra, 'blocksClose')
      ? !!extra.blocksClose
      : severity === 'critical' || severity === 'high';
    const {severity: _sev, blocksClose: _bc, ...rest} = extra;
    if (!buckets[code]) {
      buckets[code] = item(code, severity, blocksClose, 0, [], rest);
    }
    buckets[code].count += 1;
    if (sampleRow) buckets[code].sample.push(sampleRow);
    if (Object.prototype.hasOwnProperty.call(extra, 'blocksClose')) {
      // Keep non-blocking if any sample is historical/QA-tagged non-blocker.
      buckets[code].blocksClose = buckets[code].blocksClose && blocksClose;
    }
  };

  const claimByOrder = {};
  for (const c of claims) {
    if (claimByOrder[c.orderId || c.id]) push('DUPLICATE_CLAIM', c.orderId || c.id);
    claimByOrder[c.orderId || c.id] = c;
  }

  for (const order of orders) {
    if (isAgentOnly(auth) && !inAgentScope(auth, order.Rev_dolh && order.Rev_dolh.path)) continue;
    const ms = orderDateMs(order);
    if (!inRange(ms, from, to)) continue;
    if (window.countryRef && window.countryRef !== 'all') {
      const cp = order.Rev_dolh && order.Rev_dolh.path;
      if (cp !== window.countryRef) continue;
    }
    const line = v2.analyzeOrder(order.id, order);
    if (window.currency && window.currency !== 'all' && line.currency !== window.currency) continue;

    const drill = {
      orderId: order.id,
      reason: line.exclusionReason || line.confidence,
      missingFields: missingFieldsOf(order, line),
      currency: line.currency,
      driverId: line.driverId,
      paymentMethod: line.channel,
      lifecycle: line.lifecycle,
      payment: line.payment,
      blocksSettlement: !line.eligible,
      notes: line.notes || [],
    };

    if (line.confidence === 'incomplete') {
      push('INCOMPLETE_FINANCIAL_RECORD', drill);
    }
    if (line.reconStatus === 'difference') {
      push('RECONCILIATION_DIFFERENCE', drill);
    }
    if (!order.payment_status && !order.halh && !order.halh_order) {
      push('MISSING_PAYMENT_STATUS', drill);
    }
    if (!order.status_code && !order.halh && !order.halh_order) {
      push('MISSING_STATUS_CODE', drill);
    }
    // Cancelled / expired / searching trips routinely have no driver.
    // Only completed lifecycle without a driver is a data-quality exception.
    if (!line.driverId && line.lifecycle === 'completed') {
      const qa = isQaFixtureOrder(order);
      push('MISSING_DRIVER', {
        ...drill,
        isTestFixture: qa,
      }, {
        // QA fixtures remain visible in Finance Audit but must not block period close.
        blocksClose: !qa,
        severity: qa ? 'medium' : 'high',
      });
    }
    if (line.currencySupported === false) push('UNSUPPORTED_CURRENCY', drill);
  }

  const settlementById = {};
  for (const s of settlements) settlementById[s.settlementId || s.id] = s;

  for (const c of claims) {
    const s = settlementById[c.settlementId];
    if (!s) push('ORPHAN_CLAIM', c.orderId || c.id);
    else if (s.status === 'voided') push('ORPHAN_CLAIM', c.orderId || c.id);
  }

  for (const s of settlements) {
    if (isAgentOnly(auth) && !inAgentScope(auth, s.countryRef || s.countryId)) continue;
    if (s.status === 'draft' || s.status === 'voided') continue;
    const lineSnap = await db
      .collection('financial_settlements')
      .doc(s.settlementId || s.id)
      .collection('lines')
      .get();
    const lines = [];
    lineSnap.forEach((d) => lines.push({id: d.id, ...d.data()}));
    if ((s.status === 'locked' || s.status === 'partially_paid' || s.status === 'settled') && !lines.length) {
      push('LOCKED_WITHOUT_LINES', s.settlementCode);
    }
    const sumPos = lines.reduce((acc, l) => acc + Number(l.tripPositionMinor || 0), 0);
    if (lines.length && Math.abs(Math.abs(sumPos) - Number(s.absoluteSettlementAmountMinor || 0)) > 1) {
      push('SETTLEMENT_TOTALS_MISMATCH', s.settlementCode);
    }
    for (const l of lines) {
      const cl = claimByOrder[l.orderId || l.id];
      if (!cl) push('SETTLEMENT_LINE_WITHOUT_CLAIM', l.orderId || l.id);
    }
    const relatedPays = payRows.filter((p) => p.settlementId === (s.settlementId || s.id));
    const net = payments.netPaidFromPayments(relatedPays);
    if (Number(s.paidConfirmedMinor || 0) !== net) {
      push('PAYMENT_TOTALS_MISMATCH', s.settlementCode);
    }
    if (net > Number(s.absoluteSettlementAmountMinor || 0) + 0) {
      push('PAYMENT_EXCEEDS_DUE', s.settlementCode);
    }
    const currencies = new Set(lines.map((l) => l.currency).filter(Boolean));
    if (currencies.size && ![...currencies].every((c) => c === s.currency)) {
      push('CURRENCY_MISMATCH', s.settlementCode);
    }
  }

  for (const p of payRows) {
    if (!p.settlementId || !settlementById[p.settlementId]) {
      push('PAYMENT_WITHOUT_SETTLEMENT', p.paymentId || p.id);
    }
  }

  const reversedByOrig = {};
  for (const p of payRows) {
    if (p.status === 'reversed' && p.originalPaymentId) {
      reversedByOrig[p.originalPaymentId] =
        (reversedByOrig[p.originalPaymentId] || 0) + Number(p.reversalAmountMinor || p.amountMinor || 0);
    }
  }
  for (const p of payRows) {
    if (p.status !== 'confirmed' || p.originalPaymentId) continue;
    const rev = reversedByOrig[p.paymentId || p.id] || 0;
    if (rev > Number(p.amountMinor || 0)) {
      push('REVERSAL_MISMATCH', p.paymentId || p.id);
    }
  }

  const claimedSources = new Set(allocClaims.map((c) => `${c.sourceType}_${c.sourceId}`));
  for (const cp of companyPays) {
    const st = String(cp.status || cp.Status || '').toLowerCase();
    if (st && st !== 'completed') continue;
    const key = `company_payment_${cp.id}`;
    if (!claimedSources.has(key)) {
      // Legacy company_payments are frozen historical artifacts (no migration).
      // Surface for review; do not permanently block period close.
      push('UNALLOCATED_PAYMENT', cp.id, {
        severity: 'high',
        blocksClose: false,
        historical: true,
        ledger: 'company_payments',
      });
    }
  }

  for (const a of allocs) {
    if (a.sourceType === 'company_payment') {
      const src = companyPays.find((c) => c.id === a.sourceId);
      if (!src) push('ALLOCATION_WITHOUT_SOURCE', a.allocationId || a.id);
    }
  }

  const receipts = {};
  for (const p of payRows) {
    if (!p.receiptNumber) continue;
    receipts[p.receiptNumber] = (receipts[p.receiptNumber] || 0) + 1;
  }
  for (const [code, n] of Object.entries(receipts)) {
    if (n > 1) push('DUPLICATE_RECEIPT_CODE', code);
  }

  const items = Object.values(buckets).map((b) => ({
    ...b,
    sample: b.sample.slice(0, 25),
  }));
  return {
    items,
    criticalCount: items.filter((i) => i.severity === 'critical').reduce((s, i) => s + i.count, 0),
    highCount: items.filter((i) => i.severity === 'high').reduce((s, i) => s + i.count, 0),
  };
}

async function listIncompleteOrders({db, auth, data}) {
  requireReader(auth);
  const scan = await scanFinancialExceptions({db, auth, data: data || {}});
  const row = scan.items.find((i) => i.code === 'INCOMPLETE_FINANCIAL_RECORD');
  return {
    count: row ? row.count : 0,
    orders: row ? row.sample : [],
  };
}

async function detectOrphans({db, auth, data}) {
  requireReader(auth);
  const scan = await scanFinancialExceptions({db, auth, data: data || {}});
  const codes = new Set([
    'ORPHAN_CLAIM',
    'SETTLEMENT_LINE_WITHOUT_CLAIM',
    'PAYMENT_WITHOUT_SETTLEMENT',
    'ALLOCATION_WITHOUT_SOURCE',
    'DUPLICATE_RECEIPT_CODE',
    'SETTLEMENT_TOTALS_MISMATCH',
    'PAYMENT_TOTALS_MISMATCH',
    'DUPLICATE_CLAIM',
  ]);
  return {
    repair: false,
    productionAutoFix: false,
    items: scan.items.filter((i) => codes.has(i.code)),
  };
}

async function closeFinancialPeriod({db, auth, data, now}) {
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', ledger.fail);
  const checklist = await buildPeriodCloseChecklist({db, auth, data});
  return periods.closeFinancialPeriod({db, auth, data, now, checklist});
}

async function createAdjustmentDraft({db, auth, data, now}) {
  ledger.requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', ledger.fail);
  const driverId = String(data.driverId || '').trim();
  const countryRef = String(data.countryRef || data.countryId || '').trim();
  const currency = v2.normalizeCode(data.currency);
  const amountMinor = Number(data.amountMinor);
  const direction = String(data.direction || '').trim();
  const reasonCode = String(data.reasonCode || '').trim();
  const notes = data.notes ? String(data.notes) : '';
  const effectiveDate = data.effectiveDate
    ? new Date(data.effectiveDate).toISOString()
    : (now || new Date()).toISOString();
  const postClosing = data.postClosing === true;
  if (!currency) ledger.fail('invalid-argument', 'currency required');
  if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
    ledger.fail('invalid-argument', 'amountMinor must be a positive integer');
  }
  if (!ADJUSTMENT_DIRECTIONS.has(direction)) {
    ledger.fail('invalid-argument', 'direction must be DRIVER_TO_COMPANY or COMPANY_TO_DRIVER');
  }
  if (!ADJUSTMENT_REASONS.has(reasonCode)) ledger.fail('invalid-argument', 'invalid reasonCode');
  if (!countryRef) ledger.fail('invalid-argument', 'countryRef required');
  await periods.assertPeriodOpen(
    db,
    {countryRef, currency, at: effectiveDate, startAt: effectiveDate, endAt: effectiveDate},
    {postClosing, superAdmin: auth.token && auth.token.super_admin === true},
  );
  if (postClosing && !(auth.token && auth.token.super_admin === true)) {
    ledger.fail('permission-denied', 'POST_CLOSING_REQUIRES_SUPERADMIN');
  }
  const nowIso = (now || new Date()).toISOString();
  const ref = db.collection('financial_adjustments').doc();
  const doc = {
    adjustmentId: ref.id,
    driverId: driverId || null,
    driverRef: driverId ? `user/${driverId}` : null,
    settlementId: data.settlementId ? String(data.settlementId) : null,
    countryRef,
    currency,
    amountMinor,
    direction,
    reasonCode,
    notes,
    status: 'draft',
    effectiveDate,
    createdBy: auth.uid,
    createdAt: nowIso,
    approvedBy: null,
    approvedAt: null,
    reversedBy: null,
    reversedAt: null,
    attachmentRef: data.attachmentRef ? String(data.attachmentRef) : null,
    reference: data.reference ? String(data.reference) : null,
    postClosing: postClosing || false,
  };
  await db.runTransaction(async (tx) => {
    tx.set(ref, doc);
    periods.writeAudit(tx, db, {
      eventType: 'ADJUSTMENT_CREATED',
      actorUid: auth.uid,
      timestamp: nowIso,
      adjustmentId: ref.id,
      driverId: driverId || null,
      metadata: {reasonCode, amountMinor, currency, postClosing: postClosing || false},
    });
  });
  return {adjustmentId: ref.id, status: 'draft'};
}

async function approveAdjustment({db, auth, data, now}) {
  ledger.requireWriter(auth);
  const adjustmentId = String(data.adjustmentId || '').trim();
  if (!adjustmentId) ledger.fail('invalid-argument', 'adjustmentId required');
  const nowIso = (now || new Date()).toISOString();
  const ref = db.collection('financial_adjustments').doc(adjustmentId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) ledger.fail('not-found', 'Adjustment not found');
    const cur = snap.data();
    if (cur.status === 'approved') return {adjustmentId, status: 'approved', idempotent: true};
    if (cur.status !== 'draft') ledger.fail('failed-precondition', `Cannot approve status=${cur.status}`);
    const pol = await policyMod.loadFinancePolicy(db, tx);
    let selfApproved = false;
    try {
      selfApproved = policyMod.assertChecker({
        policy: pol,
        makerUid: cur.createdBy,
        checkerUid: auth.uid,
        action: 'approveAdjustment',
      }).selfApproved;
    } catch (e) {
      ledger.fail('permission-denied', e.message, e.details);
    }
    tx.update(ref, {
      status: 'approved',
      approvedBy: auth.uid,
      approvedAt: nowIso,
      selfApproved,
    });
    periods.writeAudit(tx, db, {
      eventType: selfApproved ? 'ADJUSTMENT_APPROVED_SELF' : 'ADJUSTMENT_APPROVED',
      actorUid: auth.uid,
      timestamp: nowIso,
      adjustmentId,
      driverId: cur.driverId || null,
      selfApproved,
      metadata: {reasonCode: cur.reasonCode, amountMinor: cur.amountMinor},
    });
    return {adjustmentId, status: 'approved', selfApproved};
  });
}

async function reverseAdjustment({db, auth, data, now}) {
  ledger.requireWriter(auth);
  const adjustmentId = String(data.adjustmentId || '').trim();
  const reason = String(data.reason || '').trim();
  if (!adjustmentId || !reason) ledger.fail('invalid-argument', 'adjustmentId and reason required');
  const nowIso = (now || new Date()).toISOString();
  const ref = db.collection('financial_adjustments').doc(adjustmentId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) ledger.fail('not-found', 'Adjustment not found');
    const cur = snap.data();
    if (cur.status === 'reversed') return {adjustmentId, status: 'reversed', idempotent: true};
    if (cur.status !== 'approved') ledger.fail('failed-precondition', 'Only approved adjustments can be reversed');
    const pol = await policyMod.loadFinancePolicy(db, tx);
    let selfApproved = false;
    try {
      selfApproved = policyMod.assertChecker({
        policy: pol,
        makerUid: cur.createdBy,
        checkerUid: auth.uid,
        action: 'reverseAdjustment',
      }).selfApproved;
    } catch (e) {
      ledger.fail('permission-denied', e.message, e.details);
    }
    tx.update(ref, {
      status: 'reversed',
      reversedBy: auth.uid,
      reversedAt: nowIso,
      reverseReason: reason,
    });
    periods.writeAudit(tx, db, {
      eventType: 'ADJUSTMENT_REVERSED',
      actorUid: auth.uid,
      timestamp: nowIso,
      adjustmentId,
      driverId: cur.driverId || null,
      reason,
      selfApproved,
    });
    return {adjustmentId, status: 'reversed'};
  });
}

async function createOpeningBalance(args) {
  const data = {...(args.data || {}), reasonCode: 'opening_balance'};
  if (!data.driverId) ledger.fail('invalid-argument', 'driverId required for opening balance');
  return createAdjustmentDraft({...args, data});
}

async function loadDriverStatement({db, auth, data}) {
  requireReader(auth);
  const driverId = String(data.driverId || '').trim();
  const currency = v2.normalizeCode(data.currency);
  if (!driverId || !currency) ledger.fail('invalid-argument', 'driverId and currency required');
  const orders = await ledger.loadDriverOrders(db, driverId);
  const entries = [];
  for (const order of orders) {
    const line = v2.analyzeOrder(order.id, order);
    if (line.currency !== currency) continue;
    if (line.lifecycle !== 'completed' || !['paid', 'cashCollected', 'captured'].includes(line.payment)) {
      continue;
    }
    const at = line.dataOrder
      ? (line.dataOrder.toDate ? line.dataOrder.toDate().toISOString() : new Date(line.dataOrder).toISOString())
      : '1970-01-01T00:00:00.000Z';
    entries.push(
      driverLedger.tripEntry({
        ...line,
        at,
        orderDate: at,
      }),
    );
  }
  const settlements = await collectDocs(db, 'financial_settlements');
  for (const s of settlements) {
    if (s.driverId !== driverId || s.currency !== currency) continue;
    if (s.status === 'draft' || s.status === 'voided') continue;
    entries.push(driverLedger.lockMemo(s));
  }
  const payRows = await collectDocs(db, 'financial_settlement_payments');
  for (const p of payRows) {
    if (p.driverId !== driverId || p.currency !== currency) continue;
    const e = driverLedger.paymentEntry(p);
    if (e) entries.push(e);
  }
  const adjs = await collectDocs(db, 'financial_adjustments');
  for (const a of adjs) {
    if (a.driverId !== driverId || a.currency !== currency) continue;
    if (a.status !== 'approved' && a.status !== 'reversed') continue;
    entries.push(driverLedger.adjustmentEntry(a));
    if (a.status === 'reversed') {
      const base = driverLedger.adjustmentEntry(a);
      entries.push({
        ...base,
        id: `adjrev:${a.adjustmentId || a.id}`,
        at: a.reversedAt || a.effectiveDate,
        debitMinor: base.creditMinor,
        creditMinor: base.debitMinor,
      });
    }
  }
  const rows = driverLedger.buildRunningBalance(entries);
  const summary = driverLedger.summarizeDriverAccount(rows);
  return {
    driverId,
    currency,
    convention: {
      perspective: 'company_books',
      debit: 'DEBIT_RECEIVABLE — driver owes company',
      credit: 'CREDIT_PAYABLE — company owes driver',
      runningBalance: 'cumulative (debit - credit); never mix currencies',
    },
    lines: rows,
    ...summary,
  };
}

async function aggregateCompanyPosition({db, auth, data}) {
  requireReader(auth);
  const currencyFilter = data && data.currency ? v2.normalizeCode(data.currency) : null;
  const orders = await scanOrders(db);
  const by = {};
  const ensure = (code) => {
    if (!by[code]) {
      by[code] = {
        currency: code,
        tripReceivablesMinor: 0,
        tripPayablesMinor: 0,
        confirmedSettlementPaymentsMinor: 0,
        approvedAdjustmentsMinor: 0,
        openingBalancesMinor: 0,
        outstandingReceivablesMinor: 0,
        outstandingPayablesMinor: 0,
        netExposureMinor: 0,
      };
    }
    return by[code];
  };
  for (const order of orders) {
    if (isAgentOnly(auth) && !inAgentScope(auth, order.Rev_dolh && order.Rev_dolh.path)) continue;
    const line = v2.analyzeOrder(order.id, order);
    if (currencyFilter && line.currency !== currencyFilter) continue;
    if (line.lifecycle !== 'completed') continue;
    if (!['paid', 'cashCollected', 'captured'].includes(line.payment)) continue;
    const t = ensure(line.currency);
    if (line.channel === 'cash') {
      t.tripReceivablesMinor += Math.max(0, Number(line.signedCashMinor || 0));
    } else if (line.channel === 'online') {
      t.tripPayablesMinor += Number(line.driverNetMinor || 0);
    }
  }
  const payRows = await collectDocs(db, 'financial_settlement_payments');
  for (const p of payRows) {
    if (p.status !== 'confirmed' && p.status !== 'reversed') continue;
    if (currencyFilter && p.currency !== currencyFilter) continue;
    const t = ensure(p.currency);
    const signed =
      p.status === 'reversed'
        ? -Number(p.reversalAmountMinor || p.amountMinor || 0)
        : Number(p.amountMinor || 0);
    t.confirmedSettlementPaymentsMinor += signed;
  }
  const adjs = await collectDocs(db, 'financial_adjustments');
  for (const a of adjs) {
    if (a.status !== 'approved') continue;
    if (currencyFilter && a.currency !== currencyFilter) continue;
    const t = ensure(a.currency);
    const signed = a.direction === 'DRIVER_TO_COMPANY' ? a.amountMinor : -a.amountMinor;
    if (a.reasonCode === 'opening_balance') t.openingBalancesMinor += signed;
    else t.approvedAdjustmentsMinor += signed;
  }
  for (const t of Object.values(by)) {
    const tripNet = t.tripReceivablesMinor - t.tripPayablesMinor;
    const outstanding = tripNet - t.confirmedSettlementPaymentsMinor + t.approvedAdjustmentsMinor + t.openingBalancesMinor;
    t.netExposureMinor = outstanding;
    t.outstandingReceivablesMinor = Math.max(0, outstanding);
    t.outstandingPayablesMinor = Math.max(0, -outstanding);
  }
  return {byCurrency: by, mixedCurrencies: false};
}

async function periodDashboard({db, auth, data}) {
  requireReader(auth);
  const periodId = String((data && data.periodId) || '').trim();
  if (!periodId) ledger.fail('invalid-argument', 'periodId required');
  const snap = await db.collection('financial_periods').doc(periodId).get();
  if (!snap.exists) ledger.fail('not-found', 'Period not found');
  const p = snap.data();
  const from = Date.parse(p.startAt);
  const to = Date.parse(p.endAt);
  const orders = await scanOrders(db);
  const settlements = await collectDocs(db, 'financial_settlements');
  const exceptions = await scanFinancialExceptions({
    db,
    auth,
    data: {startAt: p.startAt, endAt: p.endAt, countryRef: p.countryRef, currency: p.currency},
  });
  const by = {};
  const ensure = (code) => {
    if (!by[code]) {
      by[code] = {
        currency: code,
        totalTrips: 0,
        eligible: 0,
        settled: 0,
        unsettled: 0,
        receivablesMinor: 0,
        payablesMinor: 0,
        paymentsConfirmedMinor: 0,
        outstandingMinor: 0,
        adjustmentsMinor: 0,
        reconciliationIssues: 0,
        dataQualityIssues: 0,
      };
    }
    return by[code];
  };
  for (const order of orders) {
    const ms = orderDateMs(order);
    if (!inRange(ms, from, to)) continue;
    const line = v2.analyzeOrder(order.id, order);
    if (p.currency && p.currency !== 'all' && line.currency !== p.currency) continue;
    const t = ensure(line.currency);
    t.totalTrips += 1;
    if (line.eligible) t.eligible += 1;
    if (line.confidence === 'incomplete') t.dataQualityIssues += 1;
    if (line.reconStatus === 'difference') t.reconciliationIssues += 1;
  }
  for (const s of settlements) {
    if (!inRange(Date.parse(s.periodStart || s.createdAt), from, to)) continue;
    if (s.status === 'draft' || s.status === 'voided') continue;
    const t = ensure(s.currency);
    if (s.status === 'settled') t.settled += Number(s.eligibleTripCount || 0);
    else t.unsettled += Number(s.eligibleTripCount || 0);
    t.paymentsConfirmedMinor += Number(s.paidConfirmedMinor || 0);
    t.outstandingMinor += Number(s.outstandingMinor || 0);
    if (s.direction === 'DRIVER_PAYS_COMPANY') t.receivablesMinor += Number(s.absoluteSettlementAmountMinor || 0);
    if (s.direction === 'COMPANY_PAYS_DRIVER') t.payablesMinor += Number(s.absoluteSettlementAmountMinor || 0);
  }
  const adjs = await collectDocs(db, 'financial_adjustments');
  for (const a of adjs) {
    if (a.status !== 'approved') continue;
    if (!inRange(Date.parse(a.effectiveDate), from, to)) continue;
    const t = ensure(a.currency);
    t.adjustmentsMinor += a.direction === 'DRIVER_TO_COMPANY' ? a.amountMinor : -a.amountMinor;
  }
  return {
    periodId,
    name: p.name,
    status: p.status,
    startAt: p.startAt,
    endAt: p.endAt,
    byCurrency: by,
    reconciliationIssues: exceptions.criticalCount + exceptions.highCount,
    dataQuality: exceptions.items
      .filter((i) => i.code === 'INCOMPLETE_FINANCIAL_RECORD' || i.code === 'MISSING_PAYMENT_STATUS')
      .reduce((s, i) => s + i.count, 0),
  };
}

function startOfUtcDay(d) {
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
}

async function accountantHome({db, auth, data, now}) {
  requireReader(auth);
  const at = now || new Date();
  const from = startOfUtcDay(at);
  const to = from + 86400000;
  const orders = await scanOrders(db);
  let newCompleted = 0;
  let cashCollectedMinor = {};
  let onlineCollectedMinor = {};
  for (const order of orders) {
    const ms = orderDateMs(order);
    if (!inRange(ms, from, to)) continue;
    const line = v2.analyzeOrder(order.id, order);
    if (line.lifecycle === 'completed') newCompleted += 1;
    if (line.payment === 'cashCollected' || (line.channel === 'cash' && line.payment === 'paid')) {
      cashCollectedMinor[line.currency] =
        (cashCollectedMinor[line.currency] || 0) + Number(line.customerPaidMinor || 0);
    }
    if (line.payment === 'paid' || line.payment === 'captured') {
      if (line.channel === 'online') {
        onlineCollectedMinor[line.currency] =
          (onlineCollectedMinor[line.currency] || 0) + Number(line.customerPaidMinor || 0);
      }
    }
  }
  const settlements = await collectDocs(db, 'financial_settlements');
  const payRows = await collectDocs(db, 'financial_settlement_payments');
  const awaitingLock = settlements.filter((s) => s.status === 'draft').length;
  const awaitingConfirm = payRows.filter((p) => p.status === 'pending').length;
  const exceptions = await scanFinancialExceptions({db, auth, data: data || {}});
  const unallocated =
    (exceptions.items.find((i) => i.code === 'UNALLOCATED_PAYMENT') || {}).count || 0;
  const incomplete =
    (exceptions.items.find((i) => i.code === 'INCOMPLETE_FINANCIAL_RECORD') || {}).count || 0;
  const missingStatus =
    ((exceptions.items.find((i) => i.code === 'MISSING_PAYMENT_STATUS') || {}).count || 0) +
    ((exceptions.items.find((i) => i.code === 'MISSING_STATUS_CODE') || {}).count || 0);
  const exposure = payments.aggregateExposure(
    settlements.filter((s) => s.status !== 'draft' && s.status !== 'voided'),
    at,
  );
  const openPeriods = (await periods.listPeriods(db)).filter(
    (p) => p.status === 'open' || p.status === 'reopened',
  );
  let closeBlockers = 0;
  for (const p of openPeriods) {
    const cl = await buildPeriodCloseChecklist({db, auth, data: {periodId: p.periodId || p.id}});
    closeBlockers += cl.blockerCount;
  }
  const badges = {
    pendingPaymentApprovals: awaitingConfirm,
    settlementApprovals: awaitingLock,
    periodCloseBlockers: closeBlockers,
    criticalReconciliation: exceptions.criticalCount,
  };
  const flags = await loadFinanceFeatureFlags(db);
  const policy = policyMod.describePolicy(await policyMod.loadFinancePolicy(db));

  let approvalCapableCount = 0;
  try {
    const usersSnap = await db
      .collection('user')
      .select('IsAdmin', 'isAdmin', 'isAdminRule', 'IsAdminRule', 'finance', 'super_admin', 'role')
      .get();
    usersSnap.forEach((doc) => {
      const x = doc.data() || {};
      const rule = x.isAdminRule ?? x.IsAdminRule ?? 0;
      const ruleNum = typeof rule === 'string' ? parseInt(rule, 10) : rule;
      const superCapable =
        x.super_admin === true ||
        x.IsAdmin === true ||
        x.isAdmin === true ||
        ruleNum === 1 ||
        String(x.role || '').toLowerCase().includes('super');
      const financeCapable =
        x.finance === true ||
        String(x.role || '').toLowerCase() === 'finance' ||
        superCapable;
      if (superCapable || financeCapable) approvalCapableCount++;
    });
  } catch (_) {
    approvalCapableCount = 0;
  }

  const independentConfigured =
    flags.hasIndependentApprover === true ||
    (flags.independentApproverUids && flags.independentApproverUids.length > 0) ||
    approvalCapableCount >= 2;
  const warnings = [];
  if (!policy.allowSelfApproval && !independentConfigured) {
    warnings.push('No independent finance approver configured');
    warnings.push('Financial pilot blocked: no independent approver configured');
  }
  if (!flags.FINANCIAL_SETTLEMENT_WRITES_ENABLED) {
    warnings.push('FINANCIAL_SETTLEMENT_WRITES_ENABLED=false');
  }
  if (!flags.FINANCIAL_PAYMENT_CONFIRM_ENABLED) {
    warnings.push('FINANCIAL_PAYMENT_CONFIRM_ENABLED=false');
  }
  if (!flags.WALLET_SETTLEMENT_ENABLED) {
    warnings.push('WALLET_SETTLEMENT_ENABLED=false');
  }
  if (!flags.AUTOMATIC_PAYOUT_ENABLED) {
    warnings.push('AUTOMATIC_PAYOUT_ENABLED=false');
  }
  return {
    today: {
      newCompletedTrips: newCompleted,
      cashCollectedMinor,
      onlineCollectedMinor,
    },
    actionRequired: {
      settlementsAwaitingApproval: awaitingLock,
      paymentsAwaitingConfirmation: awaitingConfirm,
      reconciliationIssues: exceptions.criticalCount + exceptions.highCount,
      unallocatedPayments: unallocated,
      periodCloseBlockers: closeBlockers,
      criticalReconciliation: exceptions.criticalCount,
      missingStatuses: missingStatus,
    },
    cashOnlinePosition: {
      cashCollectedMinor,
      onlineCollectedMinor,
    },
    exposure,
    aging: exposure,
    dataQuality: {incomplete, missingStatuses: missingStatus},
    badges,
    policy,
    featureFlags: {
      FINANCIAL_SETTLEMENT_WRITES_ENABLED: flags.FINANCIAL_SETTLEMENT_WRITES_ENABLED,
      FINANCIAL_PAYMENT_CONFIRM_ENABLED: flags.FINANCIAL_PAYMENT_CONFIRM_ENABLED,
      WALLET_SETTLEMENT_ENABLED: flags.WALLET_SETTLEMENT_ENABLED,
      AUTOMATIC_PAYOUT_ENABLED: flags.AUTOMATIC_PAYOUT_ENABLED,
    },
    independentApproverConfigured: independentConfigured,
    approvalCapableCount,
    warnings,
  };
}

async function verifySettlementAgainstSource({db, auth, data}) {
  requireReader(auth);
  const settlementId = String(data.settlementId || '').trim();
  if (!settlementId) ledger.fail('invalid-argument', 'settlementId required');
  const snap = await db.collection('financial_settlements').doc(settlementId).get();
  if (!snap.exists) ledger.fail('not-found', 'Settlement not found');
  const s = snap.data();
  if (s.status === 'draft') {
    return {comparable: false, reason: 'draft_has_no_lock_snapshot'};
  }
  const orders = await ledger.loadDriverOrders(db, s.driverId);
  const lines = ledger.analyzeScoped(orders, {
    currency: s.currency,
    periodStart: new Date(s.periodStart),
    periodEnd: new Date(s.periodEnd),
    countryPath: s.countryId,
  });
  const snapshot = ledger.buildSnapshot(lines, s.currency);
  const hash = ledger.computePreviewHash(
    ledger.hashInputFromLines({
      lines,
      currency: s.currency,
      driverId: s.driverId,
      periodStart: new Date(s.periodStart),
      periodEnd: new Date(s.periodEnd),
      snapshot,
    }),
  );
  const changed = hash !== s.lockedHash;
  return {
    settlementId,
    lockedHash: s.lockedHash,
    currentHash: hash,
    changed,
    flag: changed ? 'SOURCE_CHANGED_AFTER_LOCK' : null,
    mutated: false,
  };
}

async function searchFinanceAudit({db, auth, data}) {
  requireReader(auth);
  const settlementCode = data && data.settlementCode ? String(data.settlementCode).trim() : '';
  const paymentReceipt = data && data.paymentReceipt ? String(data.paymentReceipt).trim() : '';
  const driverId = data && data.driverId ? String(data.driverId).trim() : '';
  const actorUid = data && data.actorUid ? String(data.actorUid).trim() : '';
  const eventType = data && data.eventType ? String(data.eventType).trim() : '';
  const from = data && data.from ? Date.parse(data.from) : null;
  const to = data && data.to ? Date.parse(data.to) : null;
  const rows = await collectDocs(db, 'financial_audit_events');
  const matched = rows.filter((r) => {
    if (settlementCode && r.settlementCode !== settlementCode) return false;
    if (paymentReceipt && r.paymentReceipt !== paymentReceipt) return false;
    if (driverId && r.driverId !== driverId) return false;
    if (actorUid && r.actorUid !== actorUid) return false;
    if (eventType && r.eventType !== eventType) return false;
    const ms = Date.parse(r.timestamp);
    if (!inRange(ms, from, to)) return false;
    return true;
  });
  matched.sort((a, b) => String(a.timestamp).localeCompare(String(b.timestamp)));
  return {count: matched.length, events: matched.slice(0, 200)};
}

function csvEscape(v) {
  let s = v == null ? '' : String(v);
  // Neutralize spreadsheet formula injection when pasted into Excel/Sheets.
  if (/^[=+\-@\t\r]/.test(s)) {
    s = `'${s}`;
  }
  if (/[",\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

async function financialReport({db, auth, data, now}) {
  requireReader(auth);
  const type = String((data && data.type) || '').trim();
  const generatedAt = (now || new Date()).toISOString();
  const preparedBy = auth.uid;
  const filters = {
    from: data && data.from,
    to: data && data.to,
    countryRef: data && (data.countryRef || data.countryId),
    driverId: data && data.driverId,
    currency: data && data.currency,
    status: data && data.status,
  };
  let rows = [];
  let columns = [];
  if (type === 'driver_statement') {
    const stmt = await loadDriverStatement({db, auth, data: {driverId: filters.driverId, currency: filters.currency}});
    columns = ['date', 'reference', 'type', 'debitMinor', 'creditMinor', 'runningBalanceMinor'];
    rows = stmt.lines.map((l) => [l.at, l.reference, l.type, l.debitMinor, l.creditMinor, l.runningBalanceMinor]);
  } else if (type === 'settlement_statement') {
    const settlements = await collectDocs(db, 'financial_settlements');
    columns = ['code', 'driverId', 'currency', 'status', 'dueMinor', 'paidMinor', 'outstandingMinor'];
    rows = settlements
      .filter((s) => (!filters.driverId || s.driverId === filters.driverId) && (!filters.currency || s.currency === filters.currency) && (!filters.status || s.status === filters.status))
      .map((s) => [
        s.settlementCode,
        s.driverId,
        s.currency,
        s.status,
        s.absoluteSettlementAmountMinor,
        s.paidConfirmedMinor,
        s.outstandingMinor,
      ]);
  } else if (type === 'payment_register') {
    const payRows = await collectDocs(db, 'financial_settlement_payments');
    columns = ['receipt', 'settlement', 'driverId', 'currency', 'status', 'amountMinor', 'direction'];
    rows = payRows
      .filter((p) => (!filters.driverId || p.driverId === filters.driverId) && (!filters.currency || p.currency === filters.currency) && (!filters.status || p.status === filters.status))
      .map((p) => [p.receiptNumber, p.settlementCode, p.driverId, p.currency, p.status, p.amountMinor, p.direction]);
  } else if (type === 'adjustments_register') {
    const adjs = await collectDocs(db, 'financial_adjustments');
    columns = ['id', 'driverId', 'currency', 'reasonCode', 'status', 'amountMinor', 'direction', 'effectiveDate'];
    rows = adjs
      .filter((a) => (!filters.driverId || a.driverId === filters.driverId) && (!filters.currency || a.currency === filters.currency) && (!filters.status || a.status === filters.status))
      .map((a) => [a.adjustmentId, a.driverId, a.currency, a.reasonCode, a.status, a.amountMinor, a.direction, a.effectiveDate]);
  } else if (type === 'reconciliation_exceptions') {
    const scan = await scanFinancialExceptions({db, auth, data: filters});
    columns = ['code', 'severity', 'count'];
    rows = scan.items.map((i) => [i.code, i.severity, i.count]);
  } else if (type === 'receivables' || type === 'payables' || type === 'aging') {
    const settlements = await collectDocs(db, 'financial_settlements');
    const live = settlements.filter((s) => s.status !== 'draft' && s.status !== 'voided');
    const exp = payments.aggregateExposure(live, now || new Date());
    columns = ['currency', 'receivablesOutstandingMinor', 'payablesOutstandingMinor', 'collectedMinor'];
    rows = Object.values(exp).map((t) => [
      t.currency,
      t.receivablesOutstandingMinor,
      t.payablesOutstandingMinor,
      t.collectedMinor,
    ]);
  } else if (type === 'period_closing') {
    const cl = await buildPeriodCloseChecklist({db, auth, data});
    columns = ['code', 'severity', 'blocksClose', 'count'];
    rows = cl.items.map((i) => [i.code, i.severity, i.blocksClose, i.count]);
  } else {
    ledger.fail('invalid-argument', 'Unknown report type');
  }
  const header = [
    '# Internal accounting report — not a tax invoice. No ZATCA QR.',
    `# Generated at: ${generatedAt}`,
    `# Prepared by: ${preparedBy}`,
    `# Filters: ${JSON.stringify(filters)}`,
    `# Currency: ${filters.currency || 'per-row'}`,
  ];
  const csv = [
    ...header,
    columns.join(','),
    ...rows.map((r) => r.map(csvEscape).join(',')),
  ].join('\n');
  return {
    type,
    generatedAt,
    preparedBy,
    filters,
    columns,
    rows,
    csv,
    pdf: null,
    disclaimer: 'Internal accounting report — not a tax invoice',
  };
}

async function financeApprovalPolicy({db, auth}) {
  requireReader(auth);
  const pol = await policyMod.loadFinancePolicy(db);
  return policyMod.describePolicy(pol);
}

module.exports = {
  ADJUSTMENT_REASONS,
  createFinancialPeriod: periods.createFinancialPeriod,
  closeFinancialPeriod,
  reopenFinancialPeriod: periods.reopenFinancialPeriod,
  buildPeriodCloseChecklist,
  scanFinancialExceptions,
  listIncompleteOrders,
  detectOrphans,
  createAdjustmentDraft,
  approveAdjustment,
  reverseAdjustment,
  createOpeningBalance,
  loadDriverStatement,
  aggregateCompanyPosition,
  periodDashboard,
  accountantHome,
  verifySettlementAgainstSource,
  searchFinanceAudit,
  financialReport,
  financeApprovalPolicy,
};

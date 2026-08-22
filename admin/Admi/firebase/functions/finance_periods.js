'use strict';

const {loadFinancePolicy} = require('./finance_policy');

function ledger() {
  return require('./settlement_ledger');
}

const PERIOD_STATUSES = new Set(['open', 'closing', 'closed', 'reopened']);
const BLOCKING_STATUS = new Set(['closing', 'closed']);

function requireSuperAdmin(auth) {
  ledger().requireWriter(auth);
  if (!auth.token || auth.token.super_admin !== true) {
    ledger().fail('permission-denied', 'SUPERADMIN_REQUIRED');
  }
}

function periodBlocksPosting(period, filter) {
  if (!period || !BLOCKING_STATUS.has(period.status)) return false;
  const pCountry = period.countryRef || 'all';
  const pCur = period.currency || 'all';
  if (pCountry !== 'all' && filter.countryRef && pCountry !== filter.countryRef) {
    return false;
  }
  if (pCur !== 'all' && filter.currency && pCur !== filter.currency) {
    return false;
  }
  const pStart = Date.parse(period.startAt);
  const pEnd = Date.parse(period.endAt);
  const fStart = Date.parse(filter.startAt || filter.at || filter.effectiveDate);
  const fEnd = Date.parse(filter.endAt || filter.at || filter.effectiveDate);
  if (Number.isNaN(pStart) || Number.isNaN(pEnd) || Number.isNaN(fStart) || Number.isNaN(fEnd)) {
    return false;
  }
  if (fStart === fEnd) return fStart >= pStart && fStart < pEnd;
  return fStart < pEnd && pStart < fEnd;
}

async function listPeriods(db) {
  const snap = await db.collection('financial_periods').get();
  const rows = [];
  snap.forEach((d) => rows.push({id: d.id, ...d.data()}));
  return rows;
}

async function findBlockingPeriods(db, filter) {
  const rows = await listPeriods(db);
  return rows.filter((p) => periodBlocksPosting(p, filter));
}

async function assertPeriodOpen(db, filter, extra = {}) {
  if (extra.postClosing === true && extra.superAdmin === true) return {postClosing: true};
  const blocked = await findBlockingPeriods(db, filter);
  if (blocked.length) {
    ledger().fail('failed-precondition', 'PERIOD_CLOSED', {
      periodId: blocked[0].periodId || blocked[0].id,
      status: blocked[0].status,
    });
  }
}

function auditRef(db) {
  return db.collection('financial_audit_events').doc();
}

function writeAudit(tx, db, payload) {
  const ref = auditRef(db);
  tx.set(ref, {
    eventId: ref.id,
    settlementCode: payload.settlementCode || null,
    paymentReceipt: payload.paymentReceipt || null,
    driverId: payload.driverId || null,
    actorUid: payload.actorUid || null,
    eventType: payload.eventType,
    timestamp: payload.timestamp,
    settlementId: payload.settlementId || null,
    paymentId: payload.paymentId || null,
    periodId: payload.periodId || null,
    adjustmentId: payload.adjustmentId || null,
    selfApproved: payload.selfApproved === true,
    reason: payload.reason || null,
    metadata: payload.metadata || null,
  });
  return ref.id;
}

async function createFinancialPeriod({db, auth, data, now}) {
  ledger().requireWriter(auth);
  const name = String(data.name || '').trim();
  const countryRef = String(data.countryRef || data.countryId || 'all').trim() || 'all';
  const currency = String(data.currency || 'all').trim().toUpperCase() || 'all';
  const startAt = data.startAt ? new Date(data.startAt).toISOString() : null;
  const endAt = data.endAt ? new Date(data.endAt).toISOString() : null;
  if (!name) ledger().fail('invalid-argument', 'name required');
  if (!startAt || !endAt) ledger().fail('invalid-argument', 'startAt and endAt required');
  if (Date.parse(startAt) >= Date.parse(endAt)) {
    ledger().fail('invalid-argument', 'startAt must be before endAt');
  }
  const nowIso = (now || new Date()).toISOString();
  const ref = db.collection('financial_periods').doc();
  const doc = {
    periodId: ref.id,
    name,
    countryRef,
    currency: currency === 'ALL' ? 'all' : currency,
    startAt,
    endAt,
    status: 'open',
    closedBy: null,
    closedAt: null,
    reopenedBy: null,
    reopenedAt: null,
    reason: null,
    createdBy: auth.uid,
    createdAt: nowIso,
    updatedAt: nowIso,
  };
  await db.runTransaction(async (tx) => {
    tx.set(ref, doc);
    writeAudit(tx, db, {
      eventType: 'PERIOD_CREATED',
      actorUid: auth.uid,
      timestamp: nowIso,
      periodId: ref.id,
      metadata: {name, countryRef, currency: doc.currency},
    });
  });
  return {periodId: ref.id, status: 'open', name};
}

async function closeFinancialPeriod({db, auth, data, now, checklist}) {
  ledger().requireWriter(auth);
  const periodId = String(data.periodId || '').trim();
  const reason = String(data.reason || '').trim();
  const override = data.override === true;
  const overrideReason = String(data.overrideReason || '').trim();
  if (!periodId) ledger().fail('invalid-argument', 'periodId required');
  if (!reason) ledger().fail('invalid-argument', 'reason required');
  const blockers = (checklist && checklist.items || []).filter((i) => i.blocksClose);
  if (blockers.length) {
    if (!override) {
      ledger().fail('failed-precondition', 'PERIOD_CLOSE_BLOCKED', {
        blockers: blockers.map((b) => b.code),
        checklist,
      });
    }
    if (!auth.token || auth.token.super_admin !== true) {
      ledger().fail('permission-denied', 'PERIOD_CLOSE_OVERRIDE_REQUIRES_SUPERADMIN');
    }
    if (!overrideReason) ledger().fail('invalid-argument', 'overrideReason required');
  }
  const nowIso = (now || new Date()).toISOString();
  const ref = db.collection('financial_periods').doc(periodId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) ledger().fail('not-found', 'Period not found');
    const cur = snap.data();
    if (cur.status === 'closed') {
      return {periodId, status: 'closed', idempotent: true};
    }
    if (cur.status !== 'open' && cur.status !== 'reopened' && cur.status !== 'closing') {
      ledger().fail('failed-precondition', `Cannot close status=${cur.status}`);
    }
    tx.update(ref, {
      status: 'closed',
      closedBy: auth.uid,
      closedAt: nowIso,
      reason,
      override: override || false,
      overrideReason: override ? overrideReason : null,
      updatedAt: nowIso,
    });
    writeAudit(tx, db, {
      eventType: 'PERIOD_CLOSED',
      actorUid: auth.uid,
      timestamp: nowIso,
      periodId,
      reason,
      metadata: {override: override || false, blockerCount: blockers.length},
    });
    return {periodId, status: 'closed'};
  });
}

async function reopenFinancialPeriod({db, auth, data, now}) {
  requireSuperAdmin(auth);
  const periodId = String(data.periodId || '').trim();
  const reason = String(data.reason || '').trim();
  if (!periodId) ledger().fail('invalid-argument', 'periodId required');
  if (!reason) ledger().fail('invalid-argument', 'reason required');
  const nowIso = (now || new Date()).toISOString();
  const ref = db.collection('financial_periods').doc(periodId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) ledger().fail('not-found', 'Period not found');
    const cur = snap.data();
    if (cur.status !== 'closed' && cur.status !== 'closing') {
      ledger().fail('failed-precondition', `Cannot reopen status=${cur.status}`);
    }
    tx.update(ref, {
      status: 'reopened',
      reopenedBy: auth.uid,
      reopenedAt: nowIso,
      reason,
      updatedAt: nowIso,
    });
    writeAudit(tx, db, {
      eventType: 'PERIOD_REOPENED',
      actorUid: auth.uid,
      timestamp: nowIso,
      periodId,
      reason,
      metadata: {previousStatus: cur.status},
    });
    tx.set(
      ledger().eventRef(db, `_period_${periodId}`, ledger().eventId('PERIOD_REOPENED')),
      {
        type: 'PERIOD_REOPENED',
        actorUid: auth.uid,
        actorRole: ledger().actorRole(auth.token || {}),
        timestamp: nowIso,
        beforeStatus: cur.status,
        afterStatus: 'reopened',
        reason,
        metadata: {periodId},
      },
    );
    return {periodId, status: 'reopened', eventType: 'PERIOD_REOPENED'};
  });
}

module.exports = {
  PERIOD_STATUSES,
  periodBlocksPosting,
  listPeriods,
  findBlockingPeriods,
  assertPeriodOpen,
  createFinancialPeriod,
  closeFinancialPeriod,
  reopenFinancialPeriod,
  writeAudit,
  loadFinancePolicy,
  requireSuperAdmin,
};

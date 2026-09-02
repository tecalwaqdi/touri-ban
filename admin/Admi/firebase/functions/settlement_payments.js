'use strict';

/**
 * Settlement Payment Execution Ledger (Phase 6B).
 * Records settlement payments. No wallet debit, no bank/N-Genius payout, no order writes.
 */

const crypto = require('crypto');
const ledger = require('./settlement_ledger');
const {loadFinancePolicy} = require('./finance_policy');
const {loadFinanceFeatureFlags, assertFlag} = require('./finance_feature_flags');

function periods() {
  return require('./finance_periods');
}

const METHODS = new Set([
  'bank_transfer',
  'cash',
  'external_transfer',
  'existing_company_payment',
  'wallet',
  'other',
]);

function expectedPaymentDirection(settlementDirection) {
  if (settlementDirection === 'DRIVER_PAYS_COMPANY') return 'DRIVER_TO_COMPANY';
  if (settlementDirection === 'COMPANY_PAYS_DRIVER') return 'COMPANY_TO_DRIVER';
  return null;
}

function netPaidFromPayments(payments) {
  let paid = 0;
  let reversed = 0;
  for (const p of payments) {
    if (!p) continue;
    if (p.status === 'confirmed') paid += Number(p.amountMinor || 0);
    if (p.status === 'reversed') {
      reversed += Number(p.reversalAmountMinor || p.amountMinor || 0);
    }
  }
  return paid - reversed;
}

function statusFromPaid(amountMinor, paidMinor) {
  if (paidMinor <= 0) return 'locked';
  if (paidMinor >= amountMinor) return 'settled';
  return 'partially_paid';
}

function agingBucket(lockedAt, now) {
  if (!lockedAt) return '>90';
  const d = lockedAt.toDate ? lockedAt.toDate() : new Date(lockedAt);
  const days = Math.floor((now.getTime() - d.getTime()) / 86400000);
  if (days <= 7) return '0-7';
  if (days <= 30) return '8-30';
  if (days <= 60) return '31-60';
  if (days <= 90) return '61-90';
  return '>90';
}

async function loadPaymentsTx(db, tx, paymentIds) {
  const out = [];
  for (const id of paymentIds || []) {
    const snap = await tx.get(db.collection('financial_settlement_payments').doc(id));
    if (snap.exists) out.push({id: snap.id, ...snap.data()});
  }
  return out;
}

async function nextPayCode(db, tx, year) {
  const ref = db.doc(`financial_settlement_counters/pay_year_${year}`);
  const snap = await tx.get(ref);
  const seq = snap.exists ? (snap.data().seq || 0) + 1 : 1;
  tx.set(ref, {year, seq, updatedAt: new Date().toISOString()}, {merge: true});
  return `PAY-${year}-${String(seq).padStart(6, '0')}`;
}

function applySettlementPaymentSnapshot(tx, settlementRef, cur, paidMinor, nowIso, extra = {}) {
  const amount = Number(cur.absoluteSettlementAmountMinor || 0);
  const outstanding = amount - paidMinor;
  const nextStatus = statusFromPaid(amount, paidMinor);
  tx.update(settlementRef, {
    paidConfirmedMinor: paidMinor,
    outstandingMinor: outstanding,
    paymentCount: extra.paymentCount != null ? extra.paymentCount : (cur.paymentCount || 0),
    lastPaymentAt: extra.lastPaymentAt || cur.lastPaymentAt || null,
    paymentIds: extra.paymentIds || cur.paymentIds || [],
    status: nextStatus,
    updatedAt: nowIso,
    ...(nextStatus === 'settled'
      ? {settledAt: nowIso, settledBy: extra.actorUid || cur.settledBy || null}
      : {}),
  });
  return {outstandingMinor: outstanding, status: nextStatus, paidConfirmedMinor: paidMinor};
}

async function createSettlementPayment({db, auth, data, now}) {
  ledger.requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', ledger.fail);
  assertFlag(flags, 'FINANCIAL_PAYMENT_CONFIRM_ENABLED', ledger.fail);
  const settlementId = String(data.settlementId || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  const method = String(data.method || '').trim();
  const direction = String(data.direction || '').trim();
  const amountMinor = Number(data.amountMinor);
  const externalReference = String(data.externalReference || data.reference || '').trim();
  if (!settlementId || !idempotencyKey) {
    ledger.fail('invalid-argument', 'settlementId and idempotencyKey required');
  }
  if (!METHODS.has(method)) ledger.fail('invalid-argument', 'Invalid payment method');
  if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
    ledger.fail('invalid-argument', 'amountMinor must be a positive integer');
  }
  if (method === 'cash' && !String(data.receivedBy || '').trim()) {
    ledger.fail('invalid-argument', 'receivedBy required for cash payments');
  }
  if ((method === 'bank_transfer' || method === 'external_transfer') && !externalReference) {
    ledger.fail('invalid-argument', 'reference required for bank/external transfer');
  }
  if (method === 'cash' && !externalReference) {
    ledger.fail('invalid-argument', 'receipt/reference required for cash payments');
  }

  const nowIso = (now || new Date()).toISOString();
  const paidAt = data.paidAt ? new Date(data.paidAt).toISOString() : nowIso;
  const idempId = ledger.idempotencyDocId(auth.uid, 'createPayment', idempotencyKey);
  const settlementRef = db.collection('financial_settlements').doc(settlementId);

  const pre = await settlementRef.get();
  if (pre.exists) {
    const s = pre.data();
    await periods().assertPeriodOpen(db, {
      countryRef: s.countryRef || s.countryId || 'all',
      currency: s.currency,
      at: paidAt,
      startAt: paidAt,
      endAt: paidAt,
    });
  }

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await ledger.readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return {...idempSnap.data().result, idempotent: true};
    }
    const live = await tx.get(settlementRef);
    if (!live.exists) ledger.fail('not-found', 'Settlement not found');
    const cur = live.data();
    if (cur.status !== 'locked' && cur.status !== 'partially_paid') {
      ledger.fail('failed-precondition', `Cannot record payment on status=${cur.status}`);
    }
    const expected = expectedPaymentDirection(cur.direction);
    if (!expected) ledger.fail('failed-precondition', 'BALANCED settlement has no amount due');
    if (direction && direction !== expected) {
      ledger.fail('failed-precondition', 'WRONG_PAYMENT_DIRECTION', {expected, actual: direction});
    }
    const payRef = db.collection('financial_settlement_payments').doc();
    const payment = {
      paymentId: payRef.id,
      settlementId,
      settlementCode: cur.settlementCode,
      driverId: cur.driverId,
      driverRef: cur.driverRef,
      countryId: cur.countryId,
      countryRef: cur.countryRef,
      currency: cur.currency,
      direction: expected,
      method,
      amountMinor,
      status: 'pending',
      externalReference,
      notes: data.notes ? String(data.notes) : '',
      paidAt,
      createdAt: nowIso,
      createdBy: auth.uid,
      confirmedAt: null,
      confirmedBy: null,
      receiptNumber: null,
      receivedBy: data.receivedBy ? String(data.receivedBy) : null,
      receivedAt: data.receivedAt ? new Date(data.receivedAt).toISOString() : (method === 'cash' ? paidAt : null),
      bankName: data.bankName ? String(data.bankName) : null,
      transferReference: data.transferReference ? String(data.transferReference) : null,
      idempotencyKey,
    };
    const paymentIds = [...(cur.paymentIds || []), payRef.id];
    tx.set(payRef, payment);
    tx.update(settlementRef, {
      paymentIds,
      paymentCount: paymentIds.length,
      updatedAt: nowIso,
    });
    tx.set(ledger.eventRef(db, settlementId, ledger.eventId('PAYMENT_CREATED')), {
      type: 'PAYMENT_CREATED',
      actorUid: auth.uid,
      actorRole: ledger.actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: cur.status,
      afterStatus: cur.status,
      reason: null,
      metadata: {paymentId: payRef.id, amountMinor, method, status: 'pending'},
    });
    const result = {paymentId: payRef.id, status: 'pending', settlementId, amountMinor};
    tx.set(idempRef, {
      status: 'completed',
      op: 'createPayment',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function confirmSettlementPayment({db, auth, data, now}) {
  ledger.requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_PAYMENT_CONFIRM_ENABLED', ledger.fail);
  const paymentId = String(data.paymentId || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!paymentId || !idempotencyKey) {
    ledger.fail('invalid-argument', 'paymentId and idempotencyKey required');
  }
  const nowIso = (now || new Date()).toISOString();
  const idempId = ledger.idempotencyDocId(auth.uid, 'confirmPayment', idempotencyKey);
  const payRef = db.collection('financial_settlement_payments').doc(paymentId);

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await ledger.readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return {...idempSnap.data().result, idempotent: true};
    }
    const paySnap = await tx.get(payRef);
    if (!paySnap.exists) ledger.fail('not-found', 'Payment not found');
    const pay = paySnap.data();
    if (pay.method === 'wallet') {
      ledger.fail('failed-precondition', 'WALLET_CONFIRM_DISABLED');
    }
    if (pay.status === 'confirmed') {
      return {paymentId, status: 'confirmed', idempotent: true, receiptNumber: pay.receiptNumber};
    }
    if (pay.status !== 'pending') {
      ledger.fail('failed-precondition', `Cannot confirm status=${pay.status}`);
    }
    const pol = await loadFinancePolicy(db, tx);
    const check = ledger.enforceChecker(pol, pay.createdBy, auth.uid, 'confirm');
    const settlementRef = db.collection('financial_settlements').doc(pay.settlementId);
    const live = await tx.get(settlementRef);
    if (!live.exists) ledger.fail('not-found', 'Settlement not found');
    const cur = live.data();
    if (cur.status !== 'locked' && cur.status !== 'partially_paid') {
      ledger.fail('failed-precondition', `Cannot confirm on settlement status=${cur.status}`);
    }
    const expected = expectedPaymentDirection(cur.direction);
    if (pay.direction !== expected) {
      ledger.fail('failed-precondition', 'WRONG_PAYMENT_DIRECTION');
    }
    const others = await loadPaymentsTx(db, tx, cur.paymentIds);
    const paidBefore = netPaidFromPayments(others);
    const outstandingBefore = Number(cur.absoluteSettlementAmountMinor || 0) - paidBefore;
    if (pay.amountMinor > outstandingBefore) {
      ledger.fail('failed-precondition', 'PAYMENT_EXCEEDS_OUTSTANDING', {
        outstanding: outstandingBefore,
        amount: pay.amountMinor,
      });
    }
    const year = (now || new Date()).getUTCFullYear();
    const receiptNumber = await nextPayCode(db, tx, year);
    tx.update(payRef, {
      status: 'confirmed',
      confirmedAt: nowIso,
      confirmedBy: auth.uid,
      receiptNumber,
    });
    const paidAfter = paidBefore + pay.amountMinor;
    const snap = applySettlementPaymentSnapshot(tx, settlementRef, cur, paidAfter, nowIso, {
      lastPaymentAt: nowIso,
      actorUid: auth.uid,
      paymentIds: cur.paymentIds,
      paymentCount: (cur.paymentIds || []).length,
    });
    const eventType = snap.status === 'settled' ? 'SETTLEMENT_SETTLED_BY_PAYMENTS' : 'PAYMENT_CONFIRMED';
    tx.set(ledger.eventRef(db, pay.settlementId, ledger.eventId(eventType)), {
      type: eventType,
      actorUid: auth.uid,
      actorRole: ledger.actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: cur.status,
      afterStatus: snap.status,
      reason: null,
      metadata: {
        paymentId,
        amountMinor: pay.amountMinor,
        method: pay.method,
        receiptNumber,
        paidBefore,
        paidAfter,
        outstandingAfter: snap.outstandingMinor,
        selfApproved: check.selfApproved === true,
      },
    });
    if (check.selfApproved) {
      tx.set(ledger.eventRef(db, pay.settlementId, ledger.eventId('SELF_APPROVAL')), {
        type: 'SELF_APPROVAL',
        actorUid: auth.uid,
        actorRole: ledger.actorRole(auth.token || {}),
        timestamp: nowIso,
        beforeStatus: cur.status,
        afterStatus: snap.status,
        reason: 'allowSelfApproval',
        metadata: {action: 'confirm', paymentId},
      });
    }
    periods().writeAudit(tx, db, {
      eventType: 'PAYMENT_CONFIRMED',
      actorUid: auth.uid,
      timestamp: nowIso,
      settlementId: pay.settlementId,
      settlementCode: cur.settlementCode,
      paymentReceipt: receiptNumber,
      paymentId,
      driverId: cur.driverId,
      selfApproved: check.selfApproved === true,
    });
    if (pay.method === 'cash') {
      tx.set(ledger.eventRef(db, pay.settlementId, ledger.eventId('CASH_PAYMENT_CONFIRMED')), {
        type: 'CASH_PAYMENT_CONFIRMED',
        actorUid: auth.uid,
        actorRole: ledger.actorRole(auth.token || {}),
        timestamp: nowIso,
        beforeStatus: cur.status,
        afterStatus: snap.status,
        reason: null,
        metadata: {paymentId, amountMinor: pay.amountMinor, receivedBy: pay.receivedBy},
      });
    }
    const result = {
      paymentId,
      status: 'confirmed',
      receiptNumber,
      settlementStatus: snap.status,
      paidConfirmedMinor: snap.paidConfirmedMinor,
      outstandingMinor: snap.outstandingMinor,
    };
    tx.set(idempRef, {
      status: 'completed',
      op: 'confirmPayment',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function reverseSettlementPayment({db, auth, data, now}) {
  ledger.requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_PAYMENT_CONFIRM_ENABLED', ledger.fail);
  const paymentId = String(data.paymentId || '').trim();
  const reason = String(data.reason || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!paymentId || !reason || !idempotencyKey) {
    ledger.fail('invalid-argument', 'paymentId, reason, idempotencyKey required');
  }
  const nowIso = (now || new Date()).toISOString();
  const idempId = ledger.idempotencyDocId(auth.uid, 'reversePayment', idempotencyKey);
  const origRef = db.collection('financial_settlement_payments').doc(paymentId);

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await ledger.readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return {...idempSnap.data().result, idempotent: true};
    }
    const origSnap = await tx.get(origRef);
    if (!origSnap.exists) ledger.fail('not-found', 'Payment not found');
    const orig = origSnap.data();
    if (orig.status !== 'confirmed') {
      ledger.fail('failed-precondition', 'Only confirmed payments can be reversed');
    }
    const settlementRef = db.collection('financial_settlements').doc(orig.settlementId);
    const live = await tx.get(settlementRef);
    if (!live.exists) ledger.fail('not-found', 'Settlement not found');
    const cur = live.data();
    const others = await loadPaymentsTx(db, tx, cur.paymentIds);
    const reversedSoFar = others
      .filter((p) => p.status === 'reversed' && p.originalPaymentId === paymentId)
      .reduce((s, p) => s + Number(p.reversalAmountMinor || p.amountMinor || 0), 0);
    const remaining = Number(orig.amountMinor || 0) - reversedSoFar;
    if (remaining <= 0) ledger.fail('already-exists', 'PAYMENT_ALREADY_REVERSED');
    const requested = data.reversalAmountMinor != null ? Number(data.reversalAmountMinor) : remaining;
    if (!Number.isInteger(requested) || requested <= 0 || requested > remaining) {
      ledger.fail('invalid-argument', 'INVALID_REVERSAL_AMOUNT', {remaining, requested});
    }
    const pol = await loadFinancePolicy(db, tx);
    const check = ledger.enforceChecker(pol, orig.createdBy, auth.uid, 'reverse');

    const revRef = db.collection('financial_settlement_payments').doc();
    const reversalAmount = requested;
    const reversal = {
      paymentId: revRef.id,
      settlementId: orig.settlementId,
      settlementCode: orig.settlementCode,
      driverId: orig.driverId,
      driverRef: orig.driverRef,
      countryId: orig.countryId,
      countryRef: orig.countryRef,
      currency: orig.currency,
      direction: orig.direction,
      method: orig.method,
      amountMinor: reversalAmount,
      reversalAmountMinor: reversalAmount,
      originalPaymentId: paymentId,
      status: 'reversed',
      externalReference: orig.externalReference,
      notes: reason,
      paidAt: nowIso,
      createdAt: nowIso,
      createdBy: auth.uid,
      confirmedAt: nowIso,
      confirmedBy: auth.uid,
      receiptNumber: null,
      idempotencyKey,
    };
    const paymentIds = [...(cur.paymentIds || []), revRef.id];
    tx.set(revRef, reversal);
    const paidAfter = netPaidFromPayments([...others, reversal]);
    const snap = applySettlementPaymentSnapshot(tx, settlementRef, cur, paidAfter, nowIso, {
      paymentIds,
      paymentCount: paymentIds.length,
      actorUid: auth.uid,
    });
    tx.set(ledger.eventRef(db, orig.settlementId, ledger.eventId('PAYMENT_REVERSED')), {
      type: 'PAYMENT_REVERSED',
      actorUid: auth.uid,
      actorRole: ledger.actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: cur.status,
      afterStatus: snap.status,
      reason,
      metadata: {
        originalPaymentId: paymentId,
        reversalId: revRef.id,
        reversalAmountMinor: reversalAmount,
        remainingAfter: remaining - reversalAmount,
        selfApproved: check.selfApproved === true,
      },
    });
    periods().writeAudit(tx, db, {
      eventType: 'PAYMENT_REVERSED',
      actorUid: auth.uid,
      timestamp: nowIso,
      settlementId: orig.settlementId,
      settlementCode: orig.settlementCode,
      paymentId: revRef.id,
      driverId: orig.driverId,
      reason,
      selfApproved: check.selfApproved === true,
      metadata: {originalPaymentId: paymentId, reversalAmountMinor: reversalAmount},
    });
    const result = {
      reversalId: revRef.id,
      originalPaymentId: paymentId,
      outstandingMinor: snap.outstandingMinor,
      settlementStatus: snap.status,
    };
    tx.set(idempRef, {
      status: 'completed',
      op: 'reversePayment',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function allocateExistingPayment({db, auth, data, now}) {
  ledger.requireWriter(auth);
  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_SETTLEMENT_WRITES_ENABLED', ledger.fail);
  assertFlag(flags, 'FINANCIAL_PAYMENT_CONFIRM_ENABLED', ledger.fail);
  const settlementId = String(data.settlementId || '').trim();
  const sourceId = String(data.sourceId || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  const sourceType = String(data.sourceType || 'company_payment').trim();
  if (!settlementId || !sourceId || !idempotencyKey) {
    ledger.fail('invalid-argument', 'settlementId, sourceId, idempotencyKey required');
  }
  if (sourceType !== 'company_payment') {
    ledger.fail('invalid-argument', 'Only company_payment allocation is supported');
  }
  const nowIso = (now || new Date()).toISOString();
  const idempId = ledger.idempotencyDocId(auth.uid, 'allocatePayment', idempotencyKey);
  const claimId = `${sourceType}_${sourceId}`;
  const claimRef = db.collection('financial_payment_allocation_claims').doc(claimId);
  const settlementRef = db.collection('financial_settlements').doc(settlementId);
  const sourceRef = db.collection('company_payments').doc(sourceId);

  return db.runTransaction(async (tx) => {
    const {ref: idempRef, snap: idempSnap} = await ledger.readIdempotency(db, tx, idempId);
    if (idempSnap.exists && idempSnap.data().status === 'completed') {
      return {...idempSnap.data().result, idempotent: true};
    }
    const sSnap = await tx.get(settlementRef);
    const srcSnap = await tx.get(sourceRef);
    const cSnap = await tx.get(claimRef);
    if (!sSnap.exists) ledger.fail('not-found', 'Settlement not found');
    if (!srcSnap.exists) ledger.fail('not-found', 'company_payment not found');
    if (cSnap.exists) ledger.fail('already-exists', 'ALLOCATION_DUPLICATE');
    const s = sSnap.data();
    if (s.status !== 'locked' && s.status !== 'partially_paid') {
      ledger.fail('failed-precondition', `Cannot allocate onto status=${s.status}`);
    }
    const requestOnly = data.requestOnly === true || data._requestOnly === true;
    let check = {selfApproved: false};
    if (!requestOnly) {
      const pol = await loadFinancePolicy(db, tx);
      check = ledger.enforceChecker(pol, s.createdBy, auth.uid, 'allocate');
    }
    const p = srcSnap.data();
    const payDriver = p.driverId || p.driver_id || (p.mndob_user && p.mndob_user.id);
    if (String(payDriver) !== String(s.driverId)) {
      ledger.fail('failed-precondition', 'ALLOCATION_DRIVER_MISMATCH');
    }
    const payCur = String(p.currency || p.Currency || '').trim().toUpperCase() || s.currency;
    if (payCur !== s.currency) ledger.fail('failed-precondition', 'ALLOCATION_CURRENCY_MISMATCH');
    const st = String(p.status || p.Status || '').toLowerCase();
    if (st && st !== 'completed') ledger.fail('failed-precondition', 'ALLOCATION_NOT_COMPLETED');

    const amountMinor = Number.isInteger(data.amountMinor) ? data.amountMinor : null;
    if (amountMinor == null || amountMinor <= 0) {
      ledger.fail('invalid-argument', 'amountMinor required');
    }
    const expected = expectedPaymentDirection(s.direction);
    if (!expected) ledger.fail('failed-precondition', 'BALANCED settlement has no amount due');
    const others = await loadPaymentsTx(db, tx, s.paymentIds);
    const paidBefore = netPaidFromPayments(others);
    const outstandingBefore = Number(s.absoluteSettlementAmountMinor || 0) - paidBefore;
    if (amountMinor > outstandingBefore) {
      ledger.fail('failed-precondition', 'PAYMENT_EXCEEDS_OUTSTANDING', {
        outstanding: outstandingBefore,
        amount: amountMinor,
      });
    }

    const allocRef = db.collection('financial_payment_allocations').doc();
    const payRef = db.collection('financial_settlement_payments').doc();
    const year = (now || new Date()).getUTCFullYear();
    const receiptNumber = requestOnly ? null : await nextPayCode(db, tx, year);
    const allocation = {
      allocationId: allocRef.id,
      sourceType,
      sourceId,
      settlementId,
      paymentId: payRef.id,
      driverRef: s.driverRef,
      currency: s.currency,
      amountMinor,
      status: requestOnly ? 'pending' : 'approved',
      createdBy: auth.uid,
      createdAt: nowIso,
    };
    const payment = {
      paymentId: payRef.id,
      settlementId,
      settlementCode: s.settlementCode,
      driverId: s.driverId,
      driverRef: s.driverRef,
      countryId: s.countryId,
      countryRef: s.countryRef,
      currency: s.currency,
      direction: expected,
      method: 'existing_company_payment',
      amountMinor,
      status: requestOnly ? 'pending' : 'confirmed',
      externalReference: sourceId,
      notes: 'Allocated legacy company_payment',
      paidAt: nowIso,
      createdAt: nowIso,
      createdBy: auth.uid,
      confirmedAt: requestOnly ? null : nowIso,
      confirmedBy: requestOnly ? null : auth.uid,
      receiptNumber,
      allocationId: allocRef.id,
      idempotencyKey,
    };
    const paymentIds = [...(s.paymentIds || []), payRef.id];
    tx.set(allocRef, allocation);
    tx.set(claimRef, {
      sourceType,
      sourceId,
      allocationId: allocRef.id,
      settlementId,
      paymentId: payRef.id,
      createdAt: nowIso,
    });
    tx.set(payRef, payment);
    let snap = {
      outstandingMinor: outstandingBefore,
      status: s.status,
      paidConfirmedMinor: paidBefore,
    };
    if (!requestOnly) {
      const paidAfter = paidBefore + amountMinor;
      snap = applySettlementPaymentSnapshot(tx, settlementRef, s, paidAfter, nowIso, {
        paymentIds,
        paymentCount: paymentIds.length,
        lastPaymentAt: nowIso,
        actorUid: auth.uid,
      });
    } else {
      tx.update(settlementRef, {
        paymentIds,
        paymentCount: paymentIds.length,
        updatedAt: nowIso,
      });
    }
    tx.set(ledger.eventRef(db, settlementId, ledger.eventId('LEGACY_PAYMENT_ALLOCATED')), {
      type: 'LEGACY_PAYMENT_ALLOCATED',
      actorUid: auth.uid,
      actorRole: ledger.actorRole(auth.token || {}),
      timestamp: nowIso,
      beforeStatus: s.status,
      afterStatus: snap.status,
      reason: null,
      metadata: {...allocation, selfApproved: check.selfApproved === true},
    });
    periods().writeAudit(tx, db, {
      eventType: 'LEGACY_PAYMENT_ALLOCATED',
      actorUid: auth.uid,
      timestamp: nowIso,
      settlementId,
      settlementCode: s.settlementCode,
      paymentReceipt: receiptNumber,
      paymentId: payRef.id,
      driverId: s.driverId,
      selfApproved: check.selfApproved === true,
    });
    const result = {
      allocationId: allocRef.id,
      paymentId: payRef.id,
      receiptNumber,
      outstandingMinor: snap.outstandingMinor,
      settlementStatus: snap.status,
    };
    tx.set(idempRef, {
      status: 'completed',
      op: 'allocatePayment',
      actorUid: auth.uid,
      result,
      createdAt: nowIso,
    });
    return result;
  });
}

async function requestExistingPaymentAllocation(args) {
  return allocateExistingPayment({
    ...args,
    data: {...(args.data || {}), requestOnly: true},
  });
}

function emptyAging() {
  return {'0-7': 0, '8-30': 0, '31-60': 0, '61-90': 0, '>90': 0};
}

function aggregateExposure(settlements, now) {
  const byCurrency = {};
  for (const s of settlements) {
    const cur = s.currency || 'UNKNOWN';
    if (!byCurrency[cur]) {
      byCurrency[cur] = {
        currency: cur,
        receivablesOutstandingMinor: 0,
        payablesOutstandingMinor: 0,
        collectedMinor: 0,
        partiallyPaidCount: 0,
        lockedCount: 0,
        settledCount: 0,
        receivablesAging: emptyAging(),
        payablesAging: emptyAging(),
      };
    }
    const t = byCurrency[cur];
    const outstanding = Number(s.outstandingMinor != null
      ? s.outstandingMinor
      : (s.absoluteSettlementAmountMinor || 0) - (s.paidConfirmedMinor || 0));
    const paid = Number(s.paidConfirmedMinor || 0);
    if (s.status === 'partially_paid') t.partiallyPaidCount++;
    if (s.status === 'locked') t.lockedCount++;
    if (s.status === 'settled') t.settledCount++;
    t.collectedMinor += paid;
    const bucket = agingBucket(s.lockedAt, now);
    if (s.direction === 'DRIVER_PAYS_COMPANY') {
      t.receivablesOutstandingMinor += Math.max(0, outstanding);
      if (outstanding > 0) t.receivablesAging[bucket] += outstanding;
    } else if (s.direction === 'COMPANY_PAYS_DRIVER') {
      t.payablesOutstandingMinor += Math.max(0, outstanding);
      if (outstanding > 0) t.payablesAging[bucket] += outstanding;
    }
  }
  return byCurrency;
}

async function aggregateSettlementExposure({db, auth}) {
  if (!auth || !auth.uid) ledger.fail('unauthenticated', 'Sign in required.');
  if (!ledger.canReadSettlements(auth.token || {})) {
    ledger.fail('permission-denied', 'Not authorized.');
  }
  const snap = await db.collection('financial_settlements').get();
  const rows = [];
  snap.forEach((d) => {
    const s = d.data();
    if (s.status === 'draft' || s.status === 'voided') return;
    if (
      auth.token &&
      auth.token.country_admin &&
      !auth.token.super_admin &&
      !auth.token.finance
    ) {
      const cid = auth.token.country_id;
      if (cid && s.countryId !== cid && s.countryRef !== cid) return;
    }
    rows.push(s);
  });
  return {
    source: 'server_v2',
    byCurrency: aggregateExposure(rows, new Date()),
    settlementCount: rows.length,
  };
}

module.exports = {
  METHODS,
  expectedPaymentDirection,
  netPaidFromPayments,
  statusFromPaid,
  agingBucket,
  aggregateExposure,
  createSettlementPayment,
  confirmSettlementPayment,
  reverseSettlementPayment,
  allocateExistingPayment,
  aggregateSettlementExposure,
  requestExistingPaymentAllocation,
};

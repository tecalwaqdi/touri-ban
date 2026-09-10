'use strict';

/**
 * Phase C — Cash collection realization (server authoritative, idempotent).
 * Does NOT create settlements. Does NOT modify historical orders automatically.
 */

const v2 = require('./financial_accounting_v2');
const {loadFinanceFeatureFlags, assertFlag} = require('./finance_feature_flags');

const REALIZATION_VERSION = 1;

function fail(code, message, details) {
  const err = new Error(message);
  err.code = code;
  err.details = details || null;
  throw err;
}

function driverRefPath(order) {
  const ref = order.mndob_user || order.mndobUser;
  if (!ref) return null;
  if (typeof ref === 'string') return ref;
  if (ref.path) return ref.path;
  return null;
}

function normalizePaymentStatus(order) {
  let pay = String(order.payment_status || '').trim().toLowerCase();
  if (pay === 'cash_pending' || pay === 'cash_due') pay = 'pending_cash';
  return pay;
}

function isCashPaymentMethod(order) {
  return String(order.PaymentMethod || '').toLowerCase().includes('cash');
}

function isAlreadyCashCollected(order) {
  if (!isCashPaymentMethod(order)) return false;
  if (order.cashCollectedByDriver === true) return true;
  if (order.cash_collection_status === 'collected') return true;
  const pay = normalizePaymentStatus(order);
  return pay === 'cash_collected';
}

function lifecycleCode(order) {
  return String(order.status_code || '').trim().toLowerCase();
}

function buildResponse(orderId, order, line, code, extra = {}) {
  return {
    orderId,
    status: order.status_code || 'completed',
    paymentStatus: 'cash_collected',
    financialRealized: true,
    code,
    currency: line.currency,
    grossMinor: line.customerPaidMinor,
    platformMinor: line.platformFeeMinor,
    vatMinor: line.recordedVatMinor,
    driverNetMinor: line.driverNetMinor,
    companyDueMinor: line.signedCashMinor,
    settlementEligible: line.eligible === true,
    confidence: line.confidence,
    ...extra,
  };
}

function validateCashRealization(orderId, order) {
  if (!isCashPaymentMethod(order)) {
    fail('failed-precondition', 'NOT_CASH', {orderId});
  }

  const code = lifecycleCode(order);
  if (code.startsWith('cancelled') || code.startsWith('canceled') || code === 'expired') {
    fail('failed-precondition', 'INVALID_STATE', {orderId, status_code: code});
  }
  if (code !== 'completed' && code !== 'trip_completed') {
    fail('failed-precondition', 'INVALID_STATE', {orderId, status_code: code});
  }

  if (isAlreadyCashCollected(order)) {
    const line = v2.analyzeOrder(orderId, {
      ...order,
      payment_status: 'cash_collected',
      cash_collection_status: 'collected',
    });
    return line;
  }

  const line = v2.analyzeOrder(orderId, {
    ...order,
    payment_status: 'cash_collected',
    cash_collection_status: 'collected',
  });
  if (line.channel !== 'cash') {
    fail('failed-precondition', 'NOT_CASH', {orderId, channel: line.channel});
  }
  if (line.lifecycle !== 'completed') {
    fail('failed-precondition', 'INVALID_STATE', {orderId, lifecycle: line.lifecycle});
  }
  if (line.confidence === 'incomplete') {
    fail('failed-precondition', 'FINANCE_DATA_INCOMPLETE', {
      orderId,
      missingFields: line.missingFields || [],
      notes: line.notes || [],
    });
  }
  if (!line.eligible) {
    fail('failed-precondition', 'FINANCE_DATA_INCOMPLETE', {
      orderId,
      exclusionReason: line.exclusionReason,
      notes: line.notes || [],
    });
  }
  return line;
}

/**
 * Callable: confirm cash collection for a completed cash trip.
 * Idempotent via financial_realization_idempotency/{operationId}.
 */
async function confirmCashCollectionV2({db, auth, data, admin, now}) {
  if (!auth || !auth.uid) {
    fail('unauthenticated', 'Sign in required.');
  }

  const orderId = String(data.orderId || '').trim();
  if (!orderId) fail('invalid-argument', 'orderId required');

  const operationId = String(
    data.operationId || data.idempotencyKey || `cash_realization:${orderId}`,
  ).trim();
  if (!operationId) fail('invalid-argument', 'operationId required');

  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_CASH_REALIZATION_V2_ENABLED', fail);

  return runCashRealizationTx({
    db,
    auth,
    admin,
    now,
    orderId,
    operationId,
    mode: 'driver',
  });
}

/**
 * Admin/finance exception path for stuck pending_cash orders.
 * Same flag + transaction semantics; requires reason; audits realized_by_role=admin.
 */
async function adminConfirmCashCollectionV2({db, auth, data, admin, now}) {
  if (!auth || !auth.uid) {
    fail('unauthenticated', 'Sign in required.');
  }
  const token = auth.token || {};
  if (token.super_admin !== true && token.finance !== true) {
    fail('permission-denied', 'ADMIN_OR_FINANCE_REQUIRED');
  }

  const orderId = String(data.orderId || '').trim();
  if (!orderId) fail('invalid-argument', 'orderId required');
  const reason = String(data.reason || '').trim();
  if (reason.length < 3) fail('invalid-argument', 'reason required (min 3 chars)');

  const operationId = String(
    data.operationId ||
      data.idempotencyKey ||
      `admin_cash_realization:${orderId}`,
  ).trim();

  const flags = await loadFinanceFeatureFlags(db);
  assertFlag(flags, 'FINANCIAL_CASH_REALIZATION_V2_ENABLED', fail);

  return runCashRealizationTx({
    db,
    auth,
    admin,
    now,
    orderId,
    operationId,
    mode: 'admin',
    reason,
  });
}

async function runCashRealizationTx({
  db,
  auth,
  admin,
  now,
  orderId,
  operationId,
  mode,
  reason,
}) {
  const FieldValue = admin.firestore.FieldValue;
  const orderRef = db.collection('order').doc(orderId);
  const idemRef = db.collection('financial_realization_idempotency').doc(operationId);
  const tsIso = (now || new Date()).toISOString();

  return db.runTransaction(async (tx) => {
    const idemSnap = await tx.get(idemRef);
    if (idemSnap.exists) {
      const idem = idemSnap.data() || {};
      if (idem.orderId === orderId && idem.status === 'success' && idem.response) {
        return {...idem.response, idempotent: true};
      }
    }

    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) fail('not-found', 'Order not found', {orderId});
    const order = orderSnap.data();

    if (mode === 'driver') {
      const assigned = driverRefPath(order);
      const caller = `user/${auth.uid}`;
      if (!assigned || assigned !== caller) {
        fail('permission-denied', 'NOT_ASSIGNED_DRIVER', {orderId, assigned});
      }
    }

    if (!isCashPaymentMethod(order)) {
      fail('failed-precondition', 'NOT_CASH', {orderId, paymentMethod: order.PaymentMethod});
    }

    if (isAlreadyCashCollected(order)) {
      const line = v2.analyzeOrder(orderId, {
        ...order,
        payment_status: 'cash_collected',
        cash_collection_status: 'collected',
      });
      const response = buildResponse(orderId, order, line, 'ALREADY_REALIZED', {
        idempotent: true,
      });
      tx.set(
        idemRef,
        {
          orderId,
          status: 'success',
          response,
          createdAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return response;
    }

    const line = validateCashRealization(orderId, order);
    const assigned = driverRefPath(order);

    tx.update(orderRef, {
      payment_status: 'cash_collected',
      cashCollectedByDriver: mode === 'driver',
      cashCollectedAt: FieldValue.serverTimestamp(),
      cash_collection_status: 'collected',
      halh: 'paid',
      halh_order: 'Paid',
      financial_realized_at: FieldValue.serverTimestamp(),
      financial_realization_version: REALIZATION_VERSION,
      cash_confirm_operation_id: operationId,
      ...(mode === 'admin'
        ? {
            cash_realized_by_admin: true,
            cash_realized_by_uid: auth.uid,
            cash_realized_admin_reason: reason,
          }
        : {}),
    });

    const auditRef = db.collection('financial_audit_events').doc();
    tx.set(auditRef, {
      eventId: auditRef.id,
      eventType: 'CASH_COLLECTION_REALIZED',
      actorUid: auth.uid,
      driverId: assigned ? String(assigned).replace(/^user\//, '') : null,
      orderId,
      timestamp: tsIso,
      metadata: {
        grossMinor: line.customerPaidMinor,
        platformMinor: line.platformFeeMinor,
        vatMinor: line.recordedVatMinor,
        driverNetMinor: line.driverNetMinor,
        companyDueMinor: line.signedCashMinor,
        currency: line.currency,
        realizationVersion: REALIZATION_VERSION,
        operationId,
        realized_by_role: mode === 'admin' ? 'admin' : 'driver',
        reason: mode === 'admin' ? reason : null,
      },
    });

    const response = buildResponse(orderId, order, line, 'COLLECTED', {
      realizedByRole: mode === 'admin' ? 'admin' : 'driver',
    });
    tx.set(
      idemRef,
      {
        orderId,
        status: 'success',
        response,
        createdAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    return response;
  });
}

module.exports = {
  REALIZATION_VERSION,
  confirmCashCollectionV2,
  adminConfirmCashCollectionV2,
  validateCashRealization,
  isAlreadyCashCollected,
  isCashPaymentMethod,
  buildResponse,
};

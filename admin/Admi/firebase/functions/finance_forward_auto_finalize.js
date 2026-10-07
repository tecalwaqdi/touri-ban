/**
 * Finance forward auto-finalize — Cloud Functions → Admin Next S2S client.
 *
 * After order becomes completed + payment final (cash_collected|paid|captured),
 * POST /api/finance/accounting-snapshots/auto-finalize with Google OIDC.
 *
 * Failures MUST NOT throw into the order write path — audit + retry only.
 */

'use strict';

const functions = require('firebase-functions');

const ADMIN_NEXT_BASE =
  process.env.ADMIN_NEXT_BASE_URL || 'https://touri-admin-next.vercel.app';
const AUTO_FINALIZE_PATH = '/api/finance/accounting-snapshots/auto-finalize';
const AUDIENCE = process.env.FINANCE_FORWARD_S2S_AUDIENCE || ADMIN_NEXT_BASE;

const PAYMENT_FINAL = new Set(['cash_collected', 'paid', 'captured']);

function normalizePay(order) {
  let pay = String(order.payment_status || '').trim().toLowerCase();
  if (pay === 'cash_pending' || pay === 'cash_due') pay = 'pending_cash';
  return pay;
}

function lifecycleCompleted(order) {
  const code = String(order.status_code || '').trim().toLowerCase();
  return code === 'completed' || code === 'trip_completed';
}

function isFinanceEligible(order) {
  if (!order || typeof order !== 'object') return false;
  if (!lifecycleCompleted(order)) return false;
  return PAYMENT_FINAL.has(normalizePay(order));
}

function becameFinanceEligible(before, after) {
  return isFinanceEligible(after) && !isFinanceEligible(before || {});
}

/**
 * Metadata-server Google ID token (Cloud Functions runtime). No static secrets.
 */
async function fetchRuntimeIdToken(audience) {
  const url =
    'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=' +
    encodeURIComponent(audience);
  const res = await fetch(url, {
    headers: {'Metadata-Flavor': 'Google'},
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`metadata_identity_${res.status}:${text.slice(0, 120)}`);
  }
  return (await res.text()).trim();
}

async function writeFailureAudit(db, admin, orderId, err, source) {
  try {
    const ref = db.collection('financial_audit_events').doc();
    await ref.set({
      eventId: ref.id,
      eventType: 'FINANCE_FORWARD_AUTO_FINALIZE_FAILED',
      orderId,
      timestamp: new Date().toISOString(),
      metadata: {
        source,
        error: String(err && err.message ? err.message : err).slice(0, 500),
        retryable: true,
        targetPath: AUTO_FINALIZE_PATH,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (auditErr) {
    functions.logger.error('finance_forward_audit_write_failed', {
      orderId,
      auditErr: String(auditErr && auditErr.message ? auditErr.message : auditErr),
    });
  }
}

/**
 * Fire-and-forget HTTP call. Never throws to caller when swallowErrors=true.
 */
async function invokeAdminNextAutoFinalize({
  db,
  admin,
  orderId,
  source,
  dryRun = false,
  swallowErrors = true,
  fetchIdToken = fetchRuntimeIdToken,
  httpFetch = fetch,
}) {
  const started = Date.now();
  try {
    const token = await fetchIdToken(AUDIENCE);
    const res = await httpFetch(`${ADMIN_NEXT_BASE}${AUTO_FINALIZE_PATH}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'x-correlation-id': `cf_ff_${orderId}_${started}`,
      },
      body: JSON.stringify({
        orderId,
        dryRun: dryRun === true,
        correlationId: `cf_ff_${orderId}_${started}`,
      }),
    });
    const text = await res.text().catch(() => '');
    let body = null;
    try {
      body = text ? JSON.parse(text) : null;
    } catch (_) {
      body = {raw: text.slice(0, 200)};
    }
    if (!res.ok) {
      throw new Error(`auto_finalize_http_${res.status}:${text.slice(0, 200)}`);
    }
    functions.logger.info('finance_forward_auto_finalize_ok', {
      orderId,
      source,
      outcome: body && body.outcome,
      ms: Date.now() - started,
    });
    return body;
  } catch (err) {
    functions.logger.error('finance_forward_auto_finalize_failed', {
      orderId,
      source,
      err: String(err && err.message ? err.message : err),
      ms: Date.now() - started,
    });
    if (db && admin) {
      await writeFailureAudit(db, admin, orderId, err, source);
    }
    if (!swallowErrors) throw err;
    return {
      outcome: 'error',
      orderId,
      swallowed: true,
      error: String(err && err.message ? err.message : err),
    };
  }
}

/**
 * Firestore onUpdate — canonical path when order becomes financially final.
 * Does not mutate order. Snapshot writes happen only in Admin Next.
 */
function createOnOrderFinanceForwardEligible({db, admin}) {
  return functions
    .region('us-central1')
    .runWith({timeoutSeconds: 60, memory: '256MB'})
    .firestore.document('order/{orderId}')
    .onUpdate(async (change, context) => {
      const orderId = context.params.orderId;
      const before = change.before.data() || {};
      const after = change.after.data() || {};
      if (!becameFinanceEligible(before, after)) {
        return null;
      }
      // Never block / roll back order — fire after eligibility is authoritative.
      await invokeAdminNextAutoFinalize({
        db,
        admin,
        orderId,
        source: 'order_onUpdate_became_eligible',
        dryRun: false,
        swallowErrors: true,
      });
      return null;
    });
}

module.exports = {
  ADMIN_NEXT_BASE,
  AUDIENCE,
  AUTO_FINALIZE_PATH,
  isFinanceEligible,
  becameFinanceEligible,
  invokeAdminNextAutoFinalize,
  createOnOrderFinanceForwardEligible,
  fetchRuntimeIdToken,
};

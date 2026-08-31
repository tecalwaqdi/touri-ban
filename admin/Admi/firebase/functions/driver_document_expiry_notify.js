/**
 * Scheduled / helper FCM for driver document expiry warnings.
 * FCM is UX only — Firestore expiryDate remains SoT.
 * Also denormalizes doc_expiry_bucket for Admin queues.
 */
'use strict';

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const {
  DOC_FIELD_BY_TYPE,
  buildExpiryEventId,
  firstBlockingExpiredDocument,
} = require('./driver_document_review.js');

function utcDay(d) {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function parseExpiryDate(raw) {
  if (!raw) return null;
  if (raw.toDate) return raw.toDate();
  if (raw instanceof Date) return raw;
  if (typeof raw === 'string') {
    const t = Date.parse(raw);
    return Number.isNaN(t) ? null : new Date(t);
  }
  return null;
}

function daysUntil(expiry, now) {
  const a = utcDay(now).getTime();
  const b = utcDay(expiry).getTime();
  return Math.round((b - a) / 86400000);
}

async function queuePushOnce({eventId, driverId, type, title, body, data}) {
  const notifRef = admin.firestore().doc(`driver_registration_notifications/${eventId}`);
  const existing = await notifRef.get();
  if (existing.exists) return {ok: true, idempotent: true};

  await notifRef.set({
    driverId,
    type,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    deliveryStatus: 'queued',
  });

  try {
    const user = await admin.firestore().doc(`user/${driverId}`).get();
    const udata = user.data() || {};
    const set = new Set();
    if (udata.fcm_token) set.add(String(udata.fcm_token));
    (udata.fcm_tokens || []).forEach((t) => t && set.add(String(t)));
    if (!set.size) {
      await notifRef.set({deliveryStatus: 'failed', pushError: 'NO_TOKENS'}, {merge: true});
      return {ok: false, stage: 'no_tokens'};
    }
    await admin.messaging().sendEachForMulticast({
      tokens: [...set],
      notification: {title, body},
      data: Object.assign(
        {
          type,
          target: 'driver_application_status',
          initialPageName: 'DriverPendingApproval',
        },
        data || {},
      ),
    });
    await notifRef.set({deliveryStatus: 'sent'}, {merge: true});
    return {ok: true};
  } catch (e) {
    await notifRef.set(
      {deliveryStatus: 'failed', pushError: String(e && e.message).slice(0, 300)},
      {merge: true},
    );
    return {ok: false, stage: 'push'};
  }
}

/**
 * Inspect one driver + country requirements; enqueue at most one event per
 * document/threshold/expiryDate. Updates denormalized Admin queue fields.
 */
async function notifyDriverDocumentExpiryForUser(driverId, driver, countryRequirements, now = new Date()) {
  const reqs = countryRequirements && typeof countryRequirements === 'object'
    ? countryRequirements
    : null;
  if (!reqs) {
    await admin.firestore().doc(`user/${driverId}`).set(
      {
        doc_expiry_bucket: 'none',
        doc_expiry_document_type: '',
        doc_expiry_operational_impact: 'allowed',
        doc_expiry_scanned_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    return {sent: 0, skipped: 'NO_COUNTRY_CONFIG'};
  }

  let sent = 0;
  let worst = {bucket: 'ok', type: '', days: null, expiry: null, impact: 'allowed'};

  for (const [type, field] of Object.entries(DOC_FIELD_BY_TYPE)) {
    if (type.includes('_')) continue;
    const cfg = reqs[type];
    if (!cfg || cfg.enabled === false) continue;
    if (cfg.required !== true || cfg.expiryRequired !== true) continue;
    const slot = driver[field];
    if (!slot || typeof slot !== 'object') continue;
    const expiry = parseExpiryDate(slot.expiryDate || slot.expiry_date);
    if (!expiry) continue;
    const warn = Number(cfg.expiryWarningDays || 30);
    const remaining = daysUntil(expiry, now);
    const expiryIso = utcDay(expiry).toISOString().slice(0, 10);
    const locale = String(driver.preferred_locale || 'ar').slice(0, 2);
    const blockingOn = cfg.operationalBlockingOnExpiry === true;

    if (remaining < 0) {
      if (worst.bucket !== 'expired') {
        worst = {
          bucket: 'expired',
          type,
          days: Math.abs(remaining),
          expiry,
          impact: blockingOn ? 'blocked' : 'allowed',
        };
      }
      const eventId = buildExpiryEventId({
        uid: driverId,
        documentType: type,
        kind: 'expired',
        expiryIso,
        threshold: '0',
      });
      const title =
        locale === 'ar' ? 'انتهت صلاحية إحدى وثائقك' : 'A document has expired';
      const body =
        locale === 'ar'
          ? 'حدّث الوثيقة المطلوبة لاستعادة إمكانية استقبال الرحلات.'
          : 'Update the required document to receive trips again.';
      const r = await queuePushOnce({
        eventId,
        driverId,
        type: 'driver_document_expired',
        title,
        body,
        data: {documentType: type},
      });
      if (r.ok && !r.idempotent) sent += 1;
      continue;
    }

    if (remaining <= warn) {
      if (worst.bucket === 'ok') {
        worst = {
          bucket: 'expiring_soon',
          type,
          days: remaining,
          expiry,
          impact: 'allowed',
        };
      }
      const eventId = buildExpiryEventId({
        uid: driverId,
        documentType: type,
        kind: 'expiring',
        expiryIso,
        threshold: String(warn),
      });
      const title =
        locale === 'ar' ? 'وثيقة ستنتهي قريبًا' : 'Document expiring soon';
      const body =
        locale === 'ar'
          ? 'حدّث الوثيقة قبل انتهاء صلاحيتها لتجنب توقف استقبال الرحلات.'
          : 'Update the document before it expires to keep receiving trips.';
      const r = await queuePushOnce({
        eventId,
        driverId,
        type: 'driver_document_expiring',
        title,
        body,
        data: {documentType: type},
      });
      if (r.ok && !r.idempotent) sent += 1;
    }
  }

  await admin.firestore().doc(`user/${driverId}`).set(
    {
      doc_expiry_bucket: worst.bucket,
      doc_expiry_document_type: worst.type || '',
      doc_expiry_days: worst.days,
      doc_expiry_date: worst.expiry || null,
      doc_expiry_operational_impact: worst.impact,
      doc_expiry_scanned_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  return {
    sent,
    bucket: worst.bucket,
    blocking: firstBlockingExpiredDocument(driver, reqs, now),
  };
}

exports.notifyDriverDocumentExpiryForUser = notifyDriverDocumentExpiryForUser;

exports.scanDriverDocumentExpiry = functions
  .region('us-central1')
  .pubsub.schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();
    const metrics = {
      DRIVERS_SCANNED: 0,
      COUNTRIES_SCANNED: 0,
      DOCS_READ_PER_SCAN: 0,
      NOTIFICATIONS_GENERATED: 0,
    };
    // Bounded scan — operational drivers only (not entire user collection).
    const snap = await db
      .collection('user')
      .where('actev_mndob', '==', true)
      .limit(400)
      .get();
    metrics.DRIVERS_SCANNED = snap.size;
    metrics.DOCS_READ_PER_SCAN += snap.size;

    const countryCache = new Map();
    let total = 0;
    for (const doc of snap.docs) {
      const driver = doc.data() || {};
      let reqs = null;
      const cref = driver.Rev_dolh || driver.rev_dolh;
      if (cref) {
        const key = cref.path || String(cref);
        if (countryCache.has(key)) {
          reqs = countryCache.get(key);
        } else {
          try {
            const c = await cref.get();
            metrics.DOCS_READ_PER_SCAN += 1;
            metrics.COUNTRIES_SCANNED += 1;
            reqs = c.exists ? (c.data() || {}).driver_requirements || null : null;
          } catch (_) {
            reqs = null;
          }
          countryCache.set(key, reqs);
        }
      }
      const r = await notifyDriverDocumentExpiryForUser(doc.id, driver, reqs);
      total += r.sent || 0;
    }
    metrics.NOTIFICATIONS_GENERATED = total;
    console.log('scanDriverDocumentExpiry_metrics', JSON.stringify(metrics));
    return null;
  });

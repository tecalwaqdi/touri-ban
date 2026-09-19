'use strict';

/**
 * Play-compliant account deletion (Gen1 callable).
 *
 * Primary path: requestAccountDeletion
 * Safety net: runAccountDeletionCleanup (used by onUserDeleted)
 *
 * - UID only from auth context (no client-supplied target uid).
 * - Cleanup before Auth delete.
 * - FINANCIAL FREEZE: never mutate order / wallets / transactions /
 *   Paymenthistory / financial_* / settlements amounts or identity fields
 *   inside those records. Preserve accounting integrity exactly.
 * - Driver identity docs in Storage are retained until legal retention
 *   is confirmed (see PRIVACY_POLICY_GAPS).
 */

const DELETED_USER_LABEL = 'Deleted User';
const DELETED_DRIVER_LABEL = 'Deleted Driver';

const ACTIVE_DRIVER_HALH = new Set([
  'مقبول',
  'وصل المندوب',
  'تم البدء في الرحلة',
  'Accepted',
  'Pending',
]);

const OPEN_SETTLEMENT_STATUSES = new Set(['draft', 'locked']);

class AccountDeletionError extends Error {
  constructor(code, message, details) {
    super(message || code);
    this.code = code;
    this.details = details || {};
    this.httpsCode =
      code === 'unauthenticated'
        ? 'unauthenticated'
        : code.startsWith('ACCOUNT_DELETION_BLOCKED')
          ? 'failed-precondition'
          : code === 'invalid-argument'
            ? 'invalid-argument'
            : 'failed-precondition';
  }
}

function userRef(db, uid) {
  return db.doc(`user/${uid}`);
}

function isDriverProfile(data) {
  return data.ismndob === true || data.ismndom === true;
}

function asNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

async function deleteQueryInBatches(db, query, batchSize = 200) {
  let total = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await query.limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    total += snap.size;
    if (snap.size < batchSize) break;
  }
  return total;
}

async function updateQueryInBatches(db, query, patchFn, batchSize = 100) {
  let total = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await query.limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((doc) => {
      const patch = patchFn(doc.data() || {}, doc);
      if (patch && Object.keys(patch).length) {
        batch.update(doc.ref, patch);
        total += 1;
      }
    });
    await batch.commit();
    if (snap.size < batchSize) break;
  }
  return total;
}

async function assertDriverDeletionAllowed({db, uid, FieldValue}) {
  const driverDoc = userRef(db, uid);
  const blockers = [];

  // Active / open trips assigned to this driver.
  const byActive = await db
    .collection('order')
    .where('mndob_user', '==', driverDoc)
    .where('ActiveOrder', '==', true)
    .limit(5)
    .get();
  if (!byActive.empty) {
    blockers.push({
      code: 'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP',
      count: byActive.size,
    });
  }

  const byDriver = await db
    .collection('order')
    .where('mndob_user', '==', driverDoc)
    .limit(40)
    .get();
  const openOrders = byDriver.docs.filter((doc) => {
    const d = doc.data() || {};
    if (d.ActiveOrder === true) return true;
    const halh = String(d.halh_text || d.halh || '').trim();
    if (ACTIVE_DRIVER_HALH.has(halh)) return true;
    const status = String(d.status_code || d.halh_order || '').trim();
    return (
      status === 'Accepted' ||
      status === 'Pending' ||
      status === 'InProgress' ||
      status === 'Arrived'
    );
  });
  if (openOrders.length && blockers.every((b) => b.code !== 'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP')) {
    blockers.push({
      code: 'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP',
      count: openOrders.length,
    });
  }

  // Open settlement drafts / locked settlements (real statuses from settlement_ledger).
  const settlements = await db
    .collection('financial_settlements')
    .where('driverId', '==', uid)
    .limit(40)
    .get();
  const openSettlements = settlements.docs.filter((doc) =>
    OPEN_SETTLEMENT_STATUSES.has(String((doc.data() || {}).status || '')),
  );
  if (openSettlements.length) {
    blockers.push({
      code: 'ACCOUNT_DELETION_BLOCKED_PENDING_SETTLEMENT',
      count: openSettlements.length,
      statuses: openSettlements.map((d) => d.data().status),
    });
  }

  // Pending wallet ledger rows (not balances alone).
  const pendingTx = await db
    .collection('transactions')
    .where('userRef', '==', driverDoc)
    .where('status', '==', 'pending')
    .limit(10)
    .get();
  if (!pendingTx.empty) {
    blockers.push({
      code: 'ACCOUNT_DELETION_BLOCKED_PENDING_WALLET_TX',
      count: pendingTx.size,
    });
  }

  // Wallet obligation signal: non-zero balance with company-pay / unsettled path.
  // Do not invent multi-bucket accounting — only block clearly non-zero live wallet
  // when there is also no settled-only history (conservative gate).
  const wallets = await db
    .collection('wallets')
    .where('userRef', '==', driverDoc)
    .limit(5)
    .get();
  for (const w of wallets.docs) {
    const bal = asNumber((w.data() || {}).currentBalance);
    if (Math.abs(bal) >= 0.01) {
      blockers.push({
        code: 'ACCOUNT_DELETION_BLOCKED_WALLET_BALANCE',
        walletId: w.id,
        currentBalance: bal,
      });
    }
  }

  if (blockers.length) {
    throw new AccountDeletionError(
      blockers[0].code,
      blockers[0].code,
      {blockers},
    );
  }

  // Mark online flag off before cleanup (best-effort).
  if (FieldValue) {
    try {
      await driverDoc.set({ngl: false}, {merge: true});
    } catch (_) {
      /* ignore */
    }
  }
}

async function collectRetentionStoragePaths(userData) {
  const keep = new Set();
  const fields = [
    'img_id',
    'img_id_rksh',
    'img_id_car',
    'imgId',
    'imgIdRksh',
    'imgIdCar',
  ];
  for (const f of fields) {
    const v = userData[f];
    if (typeof v === 'string' && v.startsWith('users/')) keep.add(v.trim());
  }
  for (const key of Object.keys(userData || {})) {
    if (!key.startsWith('doc_')) continue;
    const slot = userData[key];
    if (slot && typeof slot === 'object' && typeof slot.storagePath === 'string') {
      const p = slot.storagePath.trim();
      if (p.startsWith('users/')) keep.add(p);
    }
  }
  return keep;
}

async function cleanupUserStorage({storage, uid, retainPaths}) {
  const bucket = storage.bucket();
  const prefix = `users/${uid}/`;
  let files = [];
  try {
    const listed = await bucket.getFiles({prefix});
    files = listed[0] || [];
  } catch (e) {
    // Best-effort: missing Storage IAM must not abort Auth/profile deletion.
    console.warn('account_deletion storage list failed', prefix, e && e.message);
    return {
      deleted: 0,
      retained: 0,
      scanned: 0,
      listError: String((e && e.message) || e).slice(0, 200),
    };
  }
  let deleted = 0;
  let retained = 0;
  for (const file of files) {
    const name = file.name;
    if (retainPaths.has(name)) {
      retained += 1;
      continue;
    }
    // Always allow profile photo deletion.
    try {
      await file.delete({ignoreNotFound: true});
      deleted += 1;
    } catch (e) {
      // Continue — idempotent retry can finish leftovers.
      console.warn('account_deletion storage delete failed', name, e.message);
    }
  }
  return {deleted, retained, scanned: files.length};
}

async function anonymizeChats({db, uid}) {
  const ref = userRef(db, uid);
  // Preserve message body for disputes; strip display name only.
  // Does NOT touch order / wallet / financial collections.
  return updateQueryInBatches(
    db,
    db.collection('chat').where('user1', '==', ref),
    () => ({
      naim: DELETED_USER_LABEL,
      account_deletion_anonymized: true,
    }),
  );
}

async function anonymizeSupport({db, uid}) {
  const ref = userRef(db, uid);
  return updateQueryInBatches(
    db,
    db.collection('support').where('RefUser', '==', ref),
    () => ({
      naim: DELETED_USER_LABEL,
      account_deletion_anonymized: true,
    }),
  );
}

async function anonymizeReviews({db, uid}) {
  const ref = userRef(db, uid);
  let n = 0;
  try {
    n += await updateQueryInBatches(
      db,
      db.collection('ReviewsUser').where('user', '==', ref),
      () => ({
        naim: DELETED_USER_LABEL,
        account_deletion_anonymized: true,
      }),
    );
  } catch (_) {
    /* field name variants */
  }
  return n;
}

async function deletePersonalCollections({db, uid}) {
  const ref = userRef(db, uid);
  const counts = {};
  counts.ADRESSUSER = await deleteQueryInBatches(
    db,
    db.collection('ADRESSUSER').where('USER', '==', ref),
  );
  counts.list_address = await deleteQueryInBatches(
    db,
    db.collection('list_address').where('user', '==', ref),
  );
  // Saved card instruments only (not Paymenthistory / ledger).
  counts.PaymentMethods = await deleteQueryInBatches(
    db,
    db.collection('PaymentMethods').where('userRev', '==', ref),
  );
  counts.fcm_tokens = await deleteQueryInBatches(
    db,
    db.collection('user').doc(uid).collection('fcm_tokens'),
  );
  // OTP cooldown docs keyed by email hash may remain — best-effort by uid if present.
  try {
    counts.email_otp_cooldown = await deleteQueryInBatches(
      db,
      db.collection('email_otp_cooldown').where('uid', '==', uid),
    );
  } catch (_) {
    counts.email_otp_cooldown = 0;
  }
  return counts;
}

/**
 * Redact personal profile fields on user/{uid} only.
 * Does NOT touch total_mndob / total_app or any financial collections.
 * KYC Storage objects are retained separately; profile URL fields are cleared
 * from the live profile document after Auth deletion path.
 */
async function redactUserProfile({db, uid, FieldValue, isDriver, retainNote}) {
  const ref = userRef(db, uid);
  const label = isDriver ? DELETED_DRIVER_LABEL : DELETED_USER_LABEL;
  const patch = {
    email: FieldValue.delete(),
    display_name: label,
    photo_url: FieldValue.delete(),
    phone_number: FieldValue.delete(),
    phone_n: FieldValue.delete(),
    address: FieldValue.delete(),
    adresslist: FieldValue.delete(),
    data_cart: FieldValue.delete(),
    fcm_token: FieldValue.delete(),
    // Clear live profile links to media; Storage KYC paths may still be retained.
    img_id: FieldValue.delete(),
    img_id_rksh: FieldValue.delete(),
    img_id_car: FieldValue.delete(),
    actev_user: false,
    actev_mndob: false,
    ngl: false,
    accountDeletion: {
      status: 'cleanup_complete',
      completedAt: new Date().toISOString(),
      retentionNote: retainNote || null,
    },
    account_deleted: true,
    deleted_at: FieldValue.serverTimestamp(),
  };
  await ref.set(patch, {merge: true});
}

async function writeAudit({db, uid, isDriver, summary}) {
  try {
    await db.collection('admin_audit_log').add({
      action: 'account_deletion',
      actorUid: uid,
      target: `user/${uid}`,
      role: isDriver ? 'driver' : 'customer',
      at: new Date().toISOString(),
      summary: summary || {},
      // No email/phone/name in audit.
    });
  } catch (e) {
    console.warn('account_deletion audit failed', e.message);
  }
}

/**
 * Idempotent cleanup used by callable + onUserDeleted safety net.
 */
async function runAccountDeletionCleanup({
  db,
  auth,
  storage,
  uid,
  FieldValue,
  deleteAuthUser = false,
  skipDriverGates = false,
}) {
  if (!uid) {
    throw new AccountDeletionError('invalid-argument', 'uid required');
  }

  const snap = await userRef(db, uid).get();
  const userData = snap.exists ? snap.data() || {} : {};
  const existingStatus = (userData.accountDeletion || {}).status;
  if (existingStatus === 'completed' && !deleteAuthUser) {
    return {ok: true, idempotent: true, status: 'completed'};
  }
  // Safety-net path (onUserDeleted): if primary callable already removed the
  // profile, do not recreate a zombie user/{uid} document.
  if (!snap.exists && !deleteAuthUser) {
    return {
      ok: true,
      idempotent: true,
      status: 'completed',
      reason: 'profile_already_gone',
    };
  }

  const isDriver = isDriverProfile(userData);

  if (isDriver && !skipDriverGates && existingStatus !== 'cleanup_complete') {
    await assertDriverDeletionAllowed({db, uid, FieldValue});
  }

  if (!isDriver && !skipDriverGates && existingStatus !== 'cleanup_complete') {
    const customerRef = userRef(db, uid);
    const active = await db
      .collection('order')
      .where('USER', '==', customerRef)
      .where('ActiveOrder', '==', true)
      .limit(1)
      .get();
    if (!active.empty) {
      throw new AccountDeletionError(
        'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP',
        'ACCOUNT_DELETION_BLOCKED_ACTIVE_TRIP',
        {role: 'customer'},
      );
    }
  }

  await userRef(db, uid).set(
    {
      accountDeletion: {
        status: 'in_progress',
        startedAt: new Date().toISOString(),
        requestedAt:
          (userData.accountDeletion && userData.accountDeletion.requestedAt) ||
          new Date().toISOString(),
      },
    },
    {merge: true},
  );

  const retainPaths = await collectRetentionStoragePaths(userData);
  const personalDeletes = await deletePersonalCollections({db, uid});
  // FINANCIAL FREEZE: do not mutate order / wallets / transactions /
  // Paymenthistory / financial_* — preserve amounts and embedded identity.
  const chats = await anonymizeChats({db, uid});
  const support = await anonymizeSupport({db, uid});
  const reviews = await anonymizeReviews({db, uid});

  let storageResult = {deleted: 0, retained: 0, scanned: 0};
  if (storage) {
    storageResult = await cleanupUserStorage({
      storage,
      uid,
      retainPaths,
    });
  }

  const retainNote =
    retainPaths.size > 0
      ? 'Driver identity/vehicle documents retained in Storage pending legal retention decision'
      : null;

  if (snap.exists) {
    await redactUserProfile({
      db,
      uid,
      FieldValue,
      isDriver,
      retainNote,
    });
  }

  const summary = {
    personalDeletes,
    ordersAnonymized: 0,
    walletsTouched: 0,
    chatsAnonymized: chats,
    supportAnonymized: support,
    reviewsAnonymized: reviews,
    storage: storageResult,
    retainedStoragePaths: retainPaths.size,
    financialFreeze: true,
  };

  await writeAudit({db, uid, isDriver, summary});

  if (deleteAuthUser) {
    try {
      await auth.deleteUser(uid);
    } catch (e) {
      if (e && e.code === 'auth/user-not-found') {
        // idempotent
      } else {
        await userRef(db, uid).set(
          {
            accountDeletion: {
              status: 'cleanup_complete_auth_pending',
              completedAt: new Date().toISOString(),
              authError: String(e.message || e).slice(0, 200),
            },
          },
          {merge: true},
        );
        throw new AccountDeletionError(
          'ACCOUNT_DELETION_AUTH_DELETE_FAILED',
          e.message || 'Auth delete failed',
          {uid},
        );
      }
    }
  }

  // Final tombstone if Auth delete left the doc (onDelete may race).
  try {
    const after = await userRef(db, uid).get();
    if (after.exists) {
      await after.ref.set(
        {
          account_deleted: true,
          accountDeletion: {
            status: deleteAuthUser ? 'completed' : 'cleanup_complete',
            completedAt: new Date().toISOString(),
          },
        },
        {merge: true},
      );
      // Prefer removing the profile doc after cleanup when Auth is gone
      // (primary path or safety-net after Auth delete).
      await after.ref.delete();
    }
  } catch (_) {
    /* ignore race with onUserDeleted */
  }

  return {ok: true, status: 'completed', summary, isDriver};
}

async function requestAccountDeletion(data, context, deps) {
  const {
    db,
    auth,
    storage,
    FieldValue,
    logger,
  } = deps;

  if (!context.auth || !context.auth.uid) {
    throw new AccountDeletionError('unauthenticated', 'Sign in required.');
  }
  const uid = context.auth.uid;
  if (data && data.uid && String(data.uid) !== uid) {
    throw new AccountDeletionError(
      'permission-denied',
      'Cannot delete another user.',
    );
  }
  if (data && data.confirm !== true) {
    throw new AccountDeletionError(
      'invalid-argument',
      'confirm=true required',
    );
  }

  const snap = await userRef(db, uid).get();
  const userData = snap.exists ? snap.data() || {} : {};
  await userRef(db, uid).set(
    {
      accountDeletion: {
        status: 'requested',
        requestedAt: new Date().toISOString(),
        source: 'app',
      },
    },
    {merge: true},
  );

  try {
    const result = await runAccountDeletionCleanup({
      db,
      auth,
      storage,
      uid,
      FieldValue,
      deleteAuthUser: true,
      skipDriverGates: false,
    });
    if (logger) {
      logger.info('requestAccountDeletion completed', {
        uid,
        isDriver: result.isDriver,
      });
    }
    return {
      ok: true,
      status: result.status,
      idempotent: result.idempotent === true,
    };
  } catch (e) {
    if (e instanceof AccountDeletionError) {
      // Reset status so user can retry after resolving blockers.
      try {
        await userRef(db, uid).set(
          {
            accountDeletion: {
              status: 'blocked',
              code: e.code,
              at: new Date().toISOString(),
            },
          },
          {merge: true},
        );
      } catch (_) {
        /* ignore */
      }
      throw e;
    }
    throw e;
  }
}

/**
 * Public web form → support ticket only (no Auth deletion).
 */
async function createAccountDeletionRequest(data, context, deps) {
  const {db, FieldValue} = deps;
  const accountType = String((data && data.accountType) || '').trim();
  const contact = String((data && data.contact) || '').trim();
  const locale = String((data && data.locale) || 'ar').trim();
  const note = String((data && data.note) || '').trim().slice(0, 1000);

  if (!['customer', 'driver'].includes(accountType)) {
    throw new AccountDeletionError(
      'invalid-argument',
      'accountType must be customer or driver',
    );
  }
  if (contact.length < 5 || contact.length > 120) {
    throw new AccountDeletionError(
      'invalid-argument',
      'contact email or phone required',
    );
  }

  const doc = await db.collection('account_deletion_requests').add({
    accountType,
    contact,
    locale,
    note,
    status: 'pending_verification',
    createdAt: FieldValue.serverTimestamp(),
    source: 'website',
    // Never auto-delete from public form.
    authUid: context.auth ? context.auth.uid : null,
  });

  try {
    await db.collection('support').add({
      naim: 'Account deletion request',
      osf: `طلب حذف حساب (${accountType}): ${contact}`,
      tsnef: 'حذف حساب',
      data: FieldValue.serverTimestamp(),
      halh: 'Open',
      source: 'website_delete_account',
      requestId: doc.id,
    });
  } catch (_) {
    /* support ticket best-effort */
  }

  return {ok: true, requestId: doc.id, status: 'pending_verification'};
}

module.exports = {
  AccountDeletionError,
  requestAccountDeletion,
  createAccountDeletionRequest,
  runAccountDeletionCleanup,
  assertDriverDeletionAllowed,
  DELETED_USER_LABEL,
  DELETED_DRIVER_LABEL,
  ACTIVE_DRIVER_HALH,
  OPEN_SETTLEMENT_STATUSES,
};

'use strict';

/**
 * F3-C3 — One country = max one active agent (server-authoritative).
 *
 * Lock collection: agent_country_assignment/{countryDocId}
 *   country_path, active_agent_id, updated_at, updated_by, source
 *
 * Does NOT silently replace an existing active agent.
 * Explicit reassignment required to transfer.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {
  str,
  countryPathFromRef,
  countryDocId,
  isAgentActiveAt,
  agentEffectiveWindow,
  windowsOverlap,
} = require('./agent_active.js');

const ASSIGNMENT_COLLECTION = 'agent_country_assignment';
const AUDIT_COLLECTION = 'admin_audit_log';
const ERR_CONFLICT = 'AGENT_COUNTRY_ALREADY_HAS_ACTIVE_AGENT';
const ERR_DATE_OVERLAP = 'AGENT_COUNTRY_DATE_OVERLAP';
const ERR_UNAUTHORIZED = 'AGENT_ASSIGNMENT_UNAUTHORIZED';

function db() {
  return admin.firestore();
}

function assignmentRef(firestore, countryPath) {
  const id = countryDocId(countryPath);
  if (!id) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'countryPath required',
    );
  }
  return firestore.collection(ASSIGNMENT_COLLECTION).doc(id);
}

function requireSuperOrCountryAdmin(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }
  const token = context.auth.token || {};
  if (!token.super_admin && !token.country_admin) {
    throw new functions.https.HttpsError('permission-denied', ERR_UNAUTHORIZED);
  }
  return token;
}

function assertCountryScope(token, countryPath) {
  if (token.super_admin) return;
  const claim = str(token.country_id);
  const path = countryPathFromRef(countryPath);
  if (!claim || claim !== path) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Country scope mismatch.',
    );
  }
}

async function writeAudit(firestore, {
  actorUid,
  action,
  countryPath,
  agentId,
  previousAgentId,
  newAgentId,
  reason,
  source,
}) {
  await firestore.collection(AUDIT_COLLECTION).add({
    action,
    target_type: 'agent_country_assignment',
    target_id: countryDocId(countryPath) || countryPath,
    actor_uid: actorUid || null,
    country_path: countryPathFromRef(countryPath),
    agent_id: agentId || null,
    previous_active_agent_id: previousAgentId || null,
    new_active_agent_id: newAgentId || null,
    reason: reason || null,
    source: source || 'f3c3',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function listCountryAgentDocs(firestore, countryPath) {
  const path = countryPathFromRef(countryPath);
  const countryRef = firestore.doc(path);
  const snap = await firestore
    .collection('user')
    .where('Isagent', '==', true)
    .where('Rev_dloh_agent', '==', countryRef)
    .get();
  return snap.docs;
}

/**
 * Find other currently-active agents for country (excluding agentId).
 */
async function findOtherActiveAgents(firestore, countryPath, excludeAgentId, at) {
  const docs = await listCountryAgentDocs(firestore, countryPath);
  return docs.filter((d) => {
    if (excludeAgentId && d.id === excludeAgentId) return false;
    return isAgentActiveAt(d.data() || {}, at);
  });
}

/**
 * Overlap among assigned agents (Isagent + actev_user !== false) for country.
 */
function findDateOverlap(docs, candidateId, candidateData) {
  if (!candidateData || candidateData.actev_user === false) return null;
  if (candidateData.Isagent !== true && candidateData.isagent !== true) {
    return null;
  }
  const candWin = agentEffectiveWindow(candidateData);
  for (const d of docs) {
    if (d.id === candidateId) continue;
    const data = d.data() || {};
    if (data.actev_user === false) continue;
    if (data.Isagent !== true && data.isagent !== true) continue;
    if (windowsOverlap(candWin, agentEffectiveWindow(data))) {
      return d.id;
    }
  }
  return null;
}

/**
 * Atomically claim country for agentId (0→1 or idempotent same agent).
 * Rejects if another agent holds the lock / is currently active.
 */
async function claimCountryAgent({
  firestore,
  countryPath,
  agentId,
  actorUid,
  source,
  reason,
  agentPatch,
}) {
  const path = countryPathFromRef(countryPath);
  if (!path || !agentId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'countryPath and agentId required',
    );
  }
  const lockRef = assignmentRef(firestore, path);
  const agentRef = firestore.collection('user').doc(agentId);
  const now = new Date();

  const others = await findOtherActiveAgents(firestore, path, agentId, now);
  if (others.length > 0) {
    const err = new functions.https.HttpsError(
      'failed-precondition',
      ERR_CONFLICT,
      {
        code: ERR_CONFLICT,
        countryPath: path,
        currentActiveAgentId: others[0].id,
        conflictingAgentIds: others.map((d) => d.id),
      },
    );
    throw err;
  }

  const countryAgents = await listCountryAgentDocs(firestore, path);
  // Include prospective patch for overlap vs peers.
  const overlapId = findDateOverlap(
    countryAgents,
    agentId,
    agentPatch || {Isagent: true, actev_user: true},
  );
  if (overlapId) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      ERR_DATE_OVERLAP,
      {code: ERR_DATE_OVERLAP, countryPath: path, overlappingAgentId: overlapId},
    );
  }

  let previous = null;
  await firestore.runTransaction(async (tx) => {
    const [lockSnap, agentSnap] = await Promise.all([
      tx.get(lockRef),
      tx.get(agentRef),
    ]);
    const hasPatch = !!(agentPatch && Object.keys(agentPatch).length);
    // createPanelUser: Auth uid exists but user/{uid} is created in this txn.
    if (!agentSnap.exists && !hasPatch) {
      throw new functions.https.HttpsError('not-found', 'Agent not found.');
    }
    const lock = lockSnap.exists ? lockSnap.data() || {} : {};
    previous = lock.active_agent_id || null;

    if (previous && previous !== agentId) {
      // Double-check holder still active; if stale lock, allow reclaim.
      const holderRef = firestore.collection('user').doc(previous);
      const holderSnap = await tx.get(holderRef);
      const holderActive =
        holderSnap.exists &&
        isAgentActiveAt(holderSnap.data() || {}, now) &&
        countryPathFromRef(holderSnap.data().Rev_dloh_agent) === path;
      if (holderActive) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          ERR_CONFLICT,
          {
            code: ERR_CONFLICT,
            countryPath: path,
            currentActiveAgentId: previous,
          },
        );
      }
    }

    if (previous === agentId && agentSnap.exists) {
      // Idempotent claim — still apply optional patch.
      if (hasPatch) {
        tx.set(agentRef, agentPatch, {merge: true});
      }
      tx.set(
        lockRef,
        {
          country_path: path,
          active_agent_id: agentId,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: actorUid || null,
          source: source || 'f3c3_claim_idempotent',
        },
        {merge: true},
      );
      return;
    }

    if (hasPatch) {
      tx.set(agentRef, agentPatch, {merge: true});
    }
    tx.set(
      lockRef,
      {
        country_path: path,
        active_agent_id: agentId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: actorUid || null,
        source: source || 'f3c3_claim',
      },
      {merge: true},
    );
  });

  await writeAudit(firestore, {
    actorUid,
    action: previous === agentId ? 'agent_country_claim_idempotent' : 'agent_country_claim',
    countryPath: path,
    agentId,
    previousAgentId: previous,
    newAgentId: agentId,
    reason,
    source,
  });

  return {
    countryPath: path,
    activeAgentId: agentId,
    previousActiveAgentId: previous || null,
    idempotent: previous === agentId,
  };
}

async function releaseCountryAgent({
  firestore,
  countryPath,
  agentId,
  actorUid,
  source,
  reason,
  deactivateAgent,
}) {
  const path = countryPathFromRef(countryPath);
  const lockRef = assignmentRef(firestore, path);
  const agentRef = firestore.collection('user').doc(agentId);

  let previous = null;
  await firestore.runTransaction(async (tx) => {
    const lockSnap = await tx.get(lockRef);
    previous = lockSnap.exists ? (lockSnap.data() || {}).active_agent_id || null : null;
    if (previous && previous !== agentId) {
      // Only the holder (or explicit clear of matching agent) may release.
      throw new functions.https.HttpsError(
        'failed-precondition',
        'AGENT_COUNTRY_LOCK_HOLDER_MISMATCH',
        {code: 'AGENT_COUNTRY_LOCK_HOLDER_MISMATCH', currentActiveAgentId: previous},
      );
    }
    if (deactivateAgent) {
      tx.set(
        agentRef,
        {
          actev_user: false,
        },
        {merge: true},
      );
    }
    tx.set(
      lockRef,
      {
        country_path: path,
        active_agent_id: null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: actorUid || null,
        source: source || 'f3c3_release',
      },
      {merge: true},
    );
  });

  await writeAudit(firestore, {
    actorUid,
    action: 'agent_country_release',
    countryPath: path,
    agentId,
    previousAgentId: previous,
    newAgentId: null,
    reason,
    source,
  });

  return {countryPath: path, releasedAgentId: agentId};
}

/**
 * Explicit transfer: deactivate old, activate new, update lock — one transaction.
 */
async function reassignCountryAgent({
  firestore,
  countryPath,
  newAgentId,
  actorUid,
  source,
  reason,
  newAgentPatch,
}) {
  const path = countryPathFromRef(countryPath);
  const lockRef = assignmentRef(firestore, path);
  const newRef = firestore.collection('user').doc(newAgentId);
  const now = new Date();

  let previous = null;
  await firestore.runTransaction(async (tx) => {
    const [lockSnap, newSnap] = await Promise.all([
      tx.get(lockRef),
      tx.get(newRef),
    ]);
    if (!newSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'New agent not found.');
    }
    previous = lockSnap.exists ? (lockSnap.data() || {}).active_agent_id || null : null;

    if (previous === newAgentId) {
      if (newAgentPatch) tx.set(newRef, newAgentPatch, {merge: true});
      return;
    }

    if (previous) {
      const oldRef = firestore.collection('user').doc(previous);
      const oldSnap = await tx.get(oldRef);
      if (oldSnap.exists) {
        tx.set(oldRef, {actev_user: false}, {merge: true});
      }
    }

    const patch = {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: firestore.doc(path),
      ...(newAgentPatch || {}),
    };
    tx.set(newRef, patch, {merge: true});
    tx.set(
      lockRef,
      {
        country_path: path,
        active_agent_id: newAgentId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: actorUid || null,
        source: source || 'f3c3_reassign',
      },
      {merge: true},
    );
  });

  const peers = await findOtherActiveAgents(firestore, path, newAgentId, now);
  if (peers.length > 0) {
    console.error('reassignCountryAgent residual active peers', path, peers.map((p) => p.id));
  }

  await writeAudit(firestore, {
    actorUid,
    action: 'agent_country_reassign',
    countryPath: path,
    agentId: newAgentId,
    previousAgentId: previous,
    newAgentId,
    reason,
    source,
  });

  return {
    countryPath: path,
    previousActiveAgentId: previous,
    newActiveAgentId: newAgentId,
  };
}

/**
 * Same agent moves country while remaining active — single transaction.
 * Clears old lock and claims new lock without an intermediate empty window.
 */
async function moveActiveAgentCountry({
  firestore,
  agentId,
  fromCountryPath,
  toCountryPath,
  actorUid,
  source,
  reason,
  agentPatch,
}) {
  const fromPath = countryPathFromRef(fromCountryPath);
  const toPath = countryPathFromRef(toCountryPath);
  if (!fromPath || !toPath || fromPath === toPath) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'fromCountryPath and toCountryPath required and distinct',
    );
  }
  const fromLock = assignmentRef(firestore, fromPath);
  const toLock = assignmentRef(firestore, toPath);
  const agentRef = firestore.collection('user').doc(agentId);
  const now = new Date();

  const others = await findOtherActiveAgents(firestore, toPath, agentId, now);
  if (others.length > 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      ERR_CONFLICT,
      {
        code: ERR_CONFLICT,
        countryPath: toPath,
        currentActiveAgentId: others[0].id,
        conflictingAgentIds: others.map((d) => d.id),
      },
    );
  }

  await firestore.runTransaction(async (tx) => {
    const [fromSnap, toSnap, agentSnap] = await Promise.all([
      tx.get(fromLock),
      tx.get(toLock),
      tx.get(agentRef),
    ]);
    if (!agentSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Agent not found.');
    }

    const toHolder = toSnap.exists ? (toSnap.data() || {}).active_agent_id || null : null;
    if (toHolder && toHolder !== agentId) {
      const holderRef = firestore.collection('user').doc(toHolder);
      const holderSnap = await tx.get(holderRef);
      const holderActive =
        holderSnap.exists &&
        isAgentActiveAt(holderSnap.data() || {}, now) &&
        countryPathFromRef(holderSnap.data().Rev_dloh_agent) === toPath;
      if (holderActive) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          ERR_CONFLICT,
          {code: ERR_CONFLICT, countryPath: toPath, currentActiveAgentId: toHolder},
        );
      }
    }

    const fromHolder = fromSnap.exists
      ? (fromSnap.data() || {}).active_agent_id || null
      : null;
    // Clear old lock if we hold it (or it is already empty/stale for us).
    if (!fromHolder || fromHolder === agentId) {
      tx.set(
        fromLock,
        {
          country_path: fromPath,
          active_agent_id: null,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: actorUid || null,
          source: source || 'f3c3_move_release',
        },
        {merge: true},
      );
    }

    const patch = {
      Isagent: true,
      actev_user: true,
      Rev_dloh_agent: firestore.doc(toPath),
      ...(agentPatch || {}),
    };
    tx.set(agentRef, patch, {merge: true});
    tx.set(
      toLock,
      {
        country_path: toPath,
        active_agent_id: agentId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: actorUid || null,
        source: source || 'f3c3_move_claim',
      },
      {merge: true},
    );
  });

  await writeAudit(firestore, {
    actorUid,
    action: 'agent_country_move',
    countryPath: toPath,
    agentId,
    previousAgentId: agentId,
    newAgentId: agentId,
    reason: reason || `moved_from:${fromPath}`,
    source,
  });

  return {fromCountryPath: fromPath, toCountryPath: toPath, agentId};
}

/**
 * Used by createPanelUser before/while writing a new active agent.
 */
async function assertCanActivateNewAgent(firestore, countryPath, excludeAgentId) {
  const path = countryPathFromRef(countryPath);
  if (!path) return;
  const others = await findOtherActiveAgents(
    firestore,
    path,
    excludeAgentId || null,
    new Date(),
  );
  if (others.length > 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      ERR_CONFLICT,
      {
        code: ERR_CONFLICT,
        countryPath: path,
        currentActiveAgentId: others[0].id,
        conflictingAgentIds: others.map((d) => d.id),
      },
    );
  }
  const lockSnap = await assignmentRef(firestore, path).get();
  if (lockSnap.exists) {
    const holder = (lockSnap.data() || {}).active_agent_id;
    if (holder && holder !== excludeAgentId) {
      const holderSnap = await firestore.collection('user').doc(holder).get();
      if (
        holderSnap.exists &&
        isAgentActiveAt(holderSnap.data() || {}) &&
        countryPathFromRef(holderSnap.data().Rev_dloh_agent) === path
      ) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          ERR_CONFLICT,
          {
            code: ERR_CONFLICT,
            countryPath: path,
            currentActiveAgentId: holder,
          },
        );
      }
    }
  }
}

// ── Callables ───────────────────────────────────────────────────────────────

exports.assignActiveCountryAgent = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const token = requireSuperOrCountryAdmin(context);
    const agentId = str(data.agentId);
    const firestore = db();
    const agentSnap = await firestore.collection('user').doc(agentId).get();
    if (!agentSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Agent not found.');
    }
    const agent = agentSnap.data() || {};
    const countryPath =
      countryPathFromRef(data.countryPath) ||
      countryPathFromRef(agent.Rev_dloh_agent);
    assertCountryScope(token, countryPath);

    return claimCountryAgent({
      firestore,
      countryPath,
      agentId,
      actorUid: context.auth.uid,
      source: 'assignActiveCountryAgent',
      reason: str(data.reason) || null,
      agentPatch: {
        Isagent: true,
        actev_user: true,
        Rev_dloh_agent: firestore.doc(countryPathFromRef(countryPath)),
      },
    });
  });

exports.reassignActiveCountryAgent = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const token = requireSuperOrCountryAdmin(context);
    if (!token.super_admin) {
      // Explicit transfer is Super Admin only (no surprise country-agent self-replace).
      throw new functions.https.HttpsError('permission-denied', ERR_UNAUTHORIZED);
    }
    const countryPath = countryPathFromRef(data.countryPath);
    const newAgentId = str(data.newAgentId);
    if (!countryPath || !newAgentId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'countryPath and newAgentId required',
      );
    }
    return reassignCountryAgent({
      firestore: db(),
      countryPath,
      newAgentId,
      actorUid: context.auth.uid,
      source: 'reassignActiveCountryAgent',
      reason: str(data.reason) || 'explicit_reassignment',
    });
  });

exports.deactivateCountryAgent = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const token = requireSuperOrCountryAdmin(context);
    const agentId = str(data.agentId);
    const firestore = db();
    const agentSnap = await firestore.collection('user').doc(agentId).get();
    if (!agentSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Agent not found.');
    }
    const countryPath =
      countryPathFromRef(data.countryPath) ||
      countryPathFromRef(agentSnap.data().Rev_dloh_agent);
    assertCountryScope(token, countryPath);
    return releaseCountryAgent({
      firestore,
      countryPath,
      agentId,
      actorUid: context.auth.uid,
      source: 'deactivateCountryAgent',
      reason: str(data.reason) || null,
      deactivateAgent: true,
    });
  });

/**
 * Super-Admin agent profile update with uniqueness enforcement.
 */
exports.updateCountryAgentAssignment = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const token = requireSuperOrCountryAdmin(context);
    if (!token.super_admin) {
      throw new functions.https.HttpsError('permission-denied', ERR_UNAUTHORIZED);
    }
    const firestore = db();
    const agentId = str(data.agentId);
    const agentRef = firestore.collection('user').doc(agentId);
    const before = await agentRef.get();
    if (!before.exists) {
      throw new functions.https.HttpsError('not-found', 'Agent not found.');
    }
    const prev = before.data() || {};
    const nextCountry =
      countryPathFromRef(data.countryPath) ||
      countryPathFromRef(prev.Rev_dloh_agent);
    const nextActive = data.actevUser !== false;
    const patch = {};
    if (data.displayName != null) patch.display_name = str(data.displayName);
    if (data.phoneNumber != null) patch.phone_number = str(data.phoneNumber);
    if (data.agentTotal != null) patch.Agent_total = Number(data.agentTotal);
    if (data.vatPercent != null) patch.vat_percent = Number(data.vatPercent);
    if (data.appCommissionPercent != null) {
      patch.app_commission_percent = Number(data.appCommissionPercent);
    }
    if (data.dolhAgent != null) patch.dolh_agent = str(data.dolhAgent);
    if (data.agentDateReg != null) {
      patch.agent_date_reg = admin.firestore.Timestamp.fromDate(
        new Date(data.agentDateReg),
      );
    }
    if (data.agentDateEnd != null) {
      patch.agent_date_end = admin.firestore.Timestamp.fromDate(
        new Date(data.agentDateEnd),
      );
    }
    patch.actev_user = nextActive;
    patch.Isagent = true;
    patch.Rev_dloh_agent = firestore.doc(nextCountry);

    const wasActive = isAgentActiveAt(prev);
    const prevCountry = countryPathFromRef(prev.Rev_dloh_agent);

    if (nextActive) {
      if (wasActive && prevCountry && prevCountry !== nextCountry) {
        await moveActiveAgentCountry({
          firestore,
          agentId,
          fromCountryPath: prevCountry,
          toCountryPath: nextCountry,
          actorUid: context.auth.uid,
          source: 'updateCountryAgentAssignment',
          reason: str(data.reason) || 'profile_country_move',
          agentPatch: patch,
        });
      } else {
        await claimCountryAgent({
          firestore,
          countryPath: nextCountry,
          agentId,
          actorUid: context.auth.uid,
          source: 'updateCountryAgentAssignment',
          reason: str(data.reason) || 'profile_update',
          agentPatch: patch,
        });
      }
    } else {
      await agentRef.set(patch, {merge: true});
      if (wasActive && prevCountry) {
        try {
          await releaseCountryAgent({
            firestore,
            countryPath: prevCountry,
            agentId,
            actorUid: context.auth.uid,
            source: 'updateCountryAgentAssignment_deactivate',
            deactivateAgent: false,
          });
        } catch (e) {
          // Lock mismatch is non-fatal if already cleared.
          if (e && e.details && e.details.code === 'AGENT_COUNTRY_LOCK_HOLDER_MISMATCH') {
            /* ignore */
          } else if (
            e instanceof functions.https.HttpsError &&
            e.message === 'AGENT_COUNTRY_LOCK_HOLDER_MISMATCH'
          ) {
            /* ignore */
          } else {
            throw e;
          }
        }
      }
    }

    return {ok: true, agentId, countryPath: nextCountry, active: nextActive};
  });

exports.__test = {
  ASSIGNMENT_COLLECTION,
  ERR_CONFLICT,
  ERR_DATE_OVERLAP,
  claimCountryAgent,
  releaseCountryAgent,
  reassignCountryAgent,
  moveActiveAgentCountry,
  assertCanActivateNewAgent,
  findOtherActiveAgents,
  findDateOverlap,
  assignmentRef,
};

module.exports.claimCountryAgent = claimCountryAgent;
module.exports.releaseCountryAgent = releaseCountryAgent;
module.exports.reassignCountryAgent = reassignCountryAgent;
module.exports.moveActiveAgentCountry = moveActiveAgentCountry;
module.exports.assertCanActivateNewAgent = assertCanActivateNewAgent;
module.exports.ASSIGNMENT_COLLECTION = ASSIGNMENT_COLLECTION;
module.exports.ERR_CONFLICT = ERR_CONFLICT;
module.exports.ERR_DATE_OVERLAP = ERR_DATE_OVERLAP;

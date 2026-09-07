'use strict';

/**
 * F3-C3 — Auth/Firestore compensation after failed createPanelUser assignment.
 * Auth create cannot join a Firestore transaction; this is the recovery path.
 */

async function compensateFailedPanelUserCreate({
  auth,
  firestore,
  uid,
  auditWriter,
  actorUid,
  reason,
}) {
  const result = {
    uid,
    authDeleted: false,
    userDocDeleted: false,
    authDeleteError: null,
    userDocDeleteError: null,
  };

  try {
    await auth.deleteUser(uid);
    result.authDeleted = true;
  } catch (e) {
    result.authDeleteError = (e && e.message) || String(e);
  }

  try {
    await firestore.doc(`user/${uid}`).delete();
    result.userDocDeleted = true;
  } catch (e) {
    result.userDocDeleteError = (e && e.message) || String(e);
  }

  if (typeof auditWriter === 'function') {
    try {
      await auditWriter({
        action: 'create_panel_user_compensation',
        actor_uid: actorUid || null,
        target_uid: uid,
        reason: reason || null,
        auth_deleted: result.authDeleted,
        user_doc_deleted: result.userDocDeleted,
        auth_delete_error: result.authDeleteError,
        user_doc_delete_error: result.userDocDeleteError,
        created_at: new Date().toISOString(),
      });
    } catch (_) {
      /* never block compensation on audit */
    }
  }

  result.ok = result.authDeleted && result.userDocDeleted;
  result.authOrphan = !result.authDeleted;
  result.userDocOrphan = !result.userDocDeleted;
  return result;
}

module.exports = {
  compensateFailedPanelUserCreate,
};

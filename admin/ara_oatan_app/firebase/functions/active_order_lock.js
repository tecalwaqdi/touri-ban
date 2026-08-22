/**
 * Customer single-active-booking lock on user/{uid}.active_order_id.
 * Active = payment_pending + pending_driver + trip stages until terminal.
 */

const TERMINAL_STATUS_CODES = new Set([
  "completed",
  "trip_completed",
  "cancelled",
  "canceled",
  "cancelled_by_customer",
  "cancelled_by_driver",
  "cancelled_by_admin",
  "expired",
]);

function normalizeStatusCode(code) {
  return String(code || "").trim().toLowerCase();
}

function isCustomerActiveStatusCode(code) {
  const c = normalizeStatusCode(code);
  if (!c) return false;
  return !TERMINAL_STATUS_CODES.has(c);
}

/**
 * All reads must happen before writes inside the caller's transaction.
 *
 * @returns {{ ok: true } | { ok: false, activeOrderId: string }}
 */
async function assertAndClaimActiveOrderSlot(params) {
  const {
    transaction,
    firestore,
    userRef,
    orderId,
    FieldValue,
  } = params;

  const userSnap = await transaction.get(userRef);
  const userData = userSnap.exists ? userSnap.data() || {} : {};
  const currentId = String(userData.active_order_id || "").trim();

  if (currentId && currentId !== orderId) {
    const otherRef = firestore.collection("order").doc(currentId);
    const otherSnap = await transaction.get(otherRef);
    if (otherSnap.exists) {
      const otherCode = otherSnap.data()?.status_code;
      if (isCustomerActiveStatusCode(otherCode)) {
        return { ok: false, activeOrderId: currentId };
      }
    }
  }

  // Claim after all reads — caller performs remaining writes after this returns ok.
  transaction.set(
    userRef,
    {
      active_order_id: orderId,
      active_order_updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return { ok: true };
}

/**
 * Clears the lock when this order is the active one.
 * Must be called after reading userSnap (or this helper reads it).
 */
async function releaseActiveOrderSlot(params) {
  const { transaction, userRef, orderId, FieldValue } = params;
  const userSnap = await transaction.get(userRef);
  if (!userSnap.exists) return;
  const currentId = String(userSnap.data()?.active_order_id || "").trim();
  if (currentId && currentId !== orderId) return;
  if (!currentId) return;
  transaction.set(
    userRef,
    {
      active_order_id: FieldValue.delete(),
      active_order_updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

module.exports = {
  TERMINAL_STATUS_CODES,
  isCustomerActiveStatusCode,
  assertAndClaimActiveOrderSlot,
  releaseActiveOrderSlot,
};

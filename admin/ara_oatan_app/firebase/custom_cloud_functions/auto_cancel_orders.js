const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { releaseActiveOrderSlot } = require("./active_order_lock.js");

if (!admin.apps.length) {
  admin.initializeApp();
}

const PENDING_HALH_TEXT = "بإنتظار قبول المندوب";
const PENDING_STATUS_CODES = ["pending_driver", "awaiting_driver"];
const ONE_HOUR_MS = 60 * 60 * 1000;

function deadlineMs(data) {
  if (data.acceptanceDeadline && typeof data.acceptanceDeadline.toMillis === "function") {
    return data.acceptanceDeadline.toMillis();
  }
  if (typeof data.acceptance_deadline_ms === "number") {
    return data.acceptance_deadline_ms;
  }
  const created =
    data.data_order ||
    data.createdAt ||
    data.created_at ||
    null;
  if (created) {
    const orderTimeMs = created.toMillis
      ? created.toMillis()
      : new Date(created).getTime();
    if (!isNaN(orderTimeMs)) return orderTimeMs + ONE_HOUR_MS;
  }
  return null;
}

function isCashOrder(data) {
  const method = String(data.PaymentMethod || data.paymentMethod || "").toLowerCase();
  const payStatus = String(data.payment_status || "").toLowerCase();
  const payth = String(data.payth || data.payment_method || "");
  return (
    method.includes("cash") ||
    payStatus === "pending_cash" ||
    payStatus === "cash_pending" ||
    payth === "TOURY_PAY_CASH"
  );
}

function isOnlinePaid(data) {
  const method = String(data.PaymentMethod || "").toLowerCase();
  const payStatus = String(data.payment_status || "").toLowerCase();
  return (
    (method.includes("online") || method.includes("card")) &&
    (payStatus === "paid" || payStatus === "processing")
  );
}

/**
 * Expires bookings still awaiting a driver after acceptanceDeadline (1 hour).
 * Uses per-doc transactions so accept vs timeout cannot both win.
 * Online paid → marks refund_pending (refund job / admin / payment-api).
 * Cash → expire only (no refund).
 */
exports.autoCancelOrders = functions.pubsub
  .schedule("every 1 minutes")
  .timeZone("Asia/Riyadh")
  .onRun(async () => {
    const nowMs = Date.now();
    const ordersRef = admin.firestore().collection("order");

    const [byHalh, ...byCodeSnaps] = await Promise.all([
      ordersRef.where("halh_text", "==", PENDING_HALH_TEXT).get(),
      ...PENDING_STATUS_CODES.map((code) =>
        ordersRef.where("status_code", "==", code).get(),
      ),
    ]);

    const docsById = new Map();
    for (const snap of [byHalh, ...byCodeSnaps]) {
      snap.forEach((doc) => docsById.set(doc.id, doc));
    }

    if (docsById.size === 0) {
      console.log("No orders awaiting acceptance.");
      return null;
    }

    let expired = 0;
    let refundPending = 0;
    let skipped = 0;

    for (const doc of docsById.values()) {
      const due = deadlineMs(doc.data());
      if (due == null || nowMs < due) {
        skipped += 1;
        continue;
      }

      try {
        const result = await admin.firestore().runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return { action: "missing" };
          const data = fresh.data() || {};

          if (data.mndob_user) return { action: "accepted" };

          const statusCode = String(data.status_code || "");
          const stillWaiting =
            PENDING_STATUS_CODES.includes(statusCode) ||
            String(data.halh_text || "") === PENDING_HALH_TEXT;
          if (!stillWaiting) return { action: "not_waiting" };

          const freshDue = deadlineMs(data);
          if (freshDue == null || Date.now() < freshDue) {
            return { action: "not_due" };
          }

          const patch = {
            halh_text: "ملغي",
            status_code: "expired",
            expired_at: admin.firestore.FieldValue.serverTimestamp(),
            cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
            expiry_reason: "no_driver_within_deadline",
            ALLNOW: false,
            ActiveOrder: false,
          };

          if (isOnlinePaid(data)) {
            patch.payment_status = "refund_pending";
            patch.refundStatus = "refund_pending";
            patch.refundReason = "no_driver_within_deadline";
            patch.refundRequestedAt =
              admin.firestore.FieldValue.serverTimestamp();
            patch.originalPaymentId =
              data.payment_session_id || data.ngeniusOrderId || null;
          }

          // USER may be a DocumentReference or path string.
          let userRef = null;
          const userField = data.USER;
          if (userField && typeof userField === "object" && userField.path) {
            userRef = admin.firestore().doc(userField.path);
          } else if (typeof userField === "string" && userField.length > 0) {
            const path = userField.replace(/^\//, "");
            userRef = admin.firestore().doc(
              path.startsWith("user/") ? path : `user/${path}`,
            );
          }
          if (userRef) {
            await releaseActiveOrderSlot({
              transaction: tx,
              userRef,
              orderId: doc.id,
              FieldValue: admin.firestore.FieldValue,
            });
          }

          tx.update(doc.ref, patch);
          return {
            action: isOnlinePaid(data) ? "expired_refund_pending" : "expired",
            sessionId: data.payment_session_id || null,
          };
        });

        if (result.action === "expired") expired += 1;
        if (result.action === "expired_refund_pending") {
          expired += 1;
          refundPending += 1;
        }
      } catch (error) {
        console.error("autoCancelOrders txn error", doc.id, error.message);
      }
    }

    console.log(
      JSON.stringify({
        message: "autoCancelOrders_done",
        expired,
        refundPending,
        skipped,
        candidates: docsById.size,
      }),
    );
    return null;
  });

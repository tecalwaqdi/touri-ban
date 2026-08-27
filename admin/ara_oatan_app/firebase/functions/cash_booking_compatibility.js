/**
 * Normalize cash / Card→Cash bookings for installed Customer app visibility.
 *
 * Installed client Card→Cash patch only writes:
 *   payment_method, payth, payment_status, status_code, ALLNOW,
 *   ElectronicPayment, last_payment_attempt_status, updated_at
 * and does NOT refresh acceptanceDeadline / PaymentMethod / halh_order.
 *
 * autoCancelOrders then expires using stale data_order (+1h) → Active tab empty.
 */
"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

const PENDING_DRIVER_TEXT = "بإنتظار قبول المندوب";
const ONE_HOUR_MS = 60 * 60 * 1000;
const TOURY_PAY_CASH = "TOURY_PAY_CASH";

const TERMINAL_STATUS = new Set([
  "completed",
  "trip_completed",
  "cancelled",
  "canceled",
  "cancelled_by_customer",
  "cancelled_by_driver",
  "cancelled_by_admin",
  "driver_assigned",
  "driver_arriving",
  "driver_arrived",
  "trip_started",
  "trip_in_progress",
]);

function isCashPaymentStatus(status) {
  const s = String(status || "").trim().toLowerCase();
  return s === "pending_cash" || s === "cash_pending" || s === "cash_collected";
}

function isCardToCashSwitch(data) {
  if (!data) return false;
  if (String(data.last_payment_attempt_status || "") === "switched_to_cash") {
    return true;
  }
  const payth = String(data.payth || "");
  const paymentMethodKey = String(data.payment_method || "");
  return (
    (payth === TOURY_PAY_CASH || paymentMethodKey === TOURY_PAY_CASH) &&
    isCashPaymentStatus(data.payment_status)
  );
}

function needsCashCompatibility(data) {
  if (!data) return false;
  if (!isCashPaymentStatus(data.payment_status) && !isCardToCashSwitch(data)) {
    return false;
  }
  const status = String(data.status_code || "").trim();
  // Revive wrongly-expired card→cash; ignore other terminals.
  if (status === "expired" && isCardToCashSwitch(data) && !data.mndob_user) {
    return true;
  }
  if (TERMINAL_STATUS.has(status)) return false;
  if (data.mndob_user) return false;

  const method = String(data.PaymentMethod || "");
  const halhOrder = String(data.halh_order || "");
  const halh = String(data.halh || "");
  const allNow = data.ALLNOW === true;
  const hasDeadline =
    data.acceptanceDeadline != null ||
    typeof data.acceptance_deadline_ms === "number";

  if (method !== "Cash") return true;
  if (halhOrder !== "Cash") return true;
  if (halh !== "pending_cash" && status === "pending_driver") return true;
  if (!allNow && status === "pending_driver") return true;
  if (!hasDeadline && status === "pending_driver") return true;
  if (String(data.halh_text || "") !== PENDING_DRIVER_TEXT && status === "pending_driver") {
    return true;
  }
  return false;
}

/**
 * Build idempotent Admin patch. Returns null when already normalized.
 * @param {FirebaseFirestore.DocumentData} data
 * @param {{ nowMs?: number }} [opts]
 */
function buildCashCompatibilityPatch(data, opts = {}) {
  if (!needsCashCompatibility(data)) return null;

  const nowMs = opts.nowMs || Date.now();
  const deadlineMs = nowMs + ONE_HOUR_MS;
  const status = String(data.status_code || "").trim();
  const reviveExpired =
    status === "expired" && isCardToCashSwitch(data) && !data.mndob_user;

  const patch = {
    PaymentMethod: "Cash",
    payment_method: TOURY_PAY_CASH,
    payth: TOURY_PAY_CASH,
    ElectronicPayment: false,
    payment_status: isCashPaymentStatus(data.payment_status)
      ? data.payment_status
      : "cash_pending",
    status_code: "pending_driver",
    ALLNOW: true,
    ActiveOrder: false,
    halh_order: "Cash",
    halh: "pending_cash",
    halh_text: PENDING_DRIVER_TEXT,
    cash_collection_status:
      data.cash_collection_status || "uncollected",
    acceptance_deadline_ms: deadlineMs,
    acceptanceDeadline: admin.firestore.Timestamp.fromMillis(deadlineMs),
    cash_compat_normalized_at: admin.firestore.FieldValue.serverTimestamp(),
    cash_compat_version: 1,
  };

  if (reviveExpired) {
    patch.expiry_reason = admin.firestore.FieldValue.delete();
    patch.expired_at = admin.firestore.FieldValue.delete();
    patch.cancelled_at = admin.firestore.FieldValue.delete();
    patch.cash_compat_revived_from_expired = true;
  }

  return patch;
}

exports.buildCashCompatibilityPatch = buildCashCompatibilityPatch;
exports.needsCashCompatibility = needsCashCompatibility;
exports.isCardToCashSwitch = isCardToCashSwitch;

exports.normalizeCashBookingCompatibility = functions
  .region("us-central1")
  .firestore.document("order/{orderId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;
    const after = change.after.data() || {};
    const patch = buildCashCompatibilityPatch(after);
    if (!patch) return null;

    // Idempotency: skip if already stamped for this pending_driver cash shape.
    if (
      after.cash_compat_version === 1 &&
      after.PaymentMethod === "Cash" &&
      after.halh_order === "Cash" &&
      after.status_code === "pending_driver" &&
      after.ALLNOW === true &&
      (after.acceptanceDeadline != null ||
        typeof after.acceptance_deadline_ms === "number")
    ) {
      return null;
    }

    console.log("cash_compat_normalize", {
      orderId: context.params.orderId,
      fromStatus: after.status_code,
      payment_status: after.payment_status,
      revive: Boolean(patch.cash_compat_revived_from_expired),
    });

    await change.after.ref.update(patch);
    return null;
  });

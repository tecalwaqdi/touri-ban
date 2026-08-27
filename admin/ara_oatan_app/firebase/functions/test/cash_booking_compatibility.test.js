"use strict";

const assert = require("assert");

// Avoid initializing Admin in unit tests — stub Timestamp/FieldValue used by patch builder.
const admin = require("firebase-admin");
if (!admin.apps.length) {
  try {
    admin.initializeApp({ projectId: "demo-cash-compat" });
  } catch (_) {
    /* ignore */
  }
}

const {
  buildCashCompatibilityPatch,
  needsCashCompatibility,
  isCardToCashSwitch,
} = require("../cash_booking_compatibility.js");

function assertPatch(data, expectNull) {
  const patch = buildCashCompatibilityPatch(data, { nowMs: 1_700_000_000_000 });
  if (expectNull) {
    assert.strictEqual(patch, null, JSON.stringify(data));
    return null;
  }
  assert.ok(patch, "expected patch");
  assert.strictEqual(patch.PaymentMethod, "Cash");
  assert.strictEqual(patch.halh_order, "Cash");
  assert.strictEqual(patch.status_code, "pending_driver");
  assert.strictEqual(patch.ALLNOW, true);
  assert.strictEqual(patch.ActiveOrder, false);
  assert.strictEqual(patch.payment_method, "TOURY_PAY_CASH");
  assert.ok(typeof patch.acceptance_deadline_ms === "number");
  return patch;
}

// Card→Cash installed patch shape — needs normalize + deadline refresh.
assert.strictEqual(
  isCardToCashSwitch({
    last_payment_attempt_status: "switched_to_cash",
    payment_status: "cash_pending",
    payment_method: "TOURY_PAY_CASH",
    payth: "TOURY_PAY_CASH",
    PaymentMethod: "OnlinePayment",
    status_code: "pending_driver",
    ALLNOW: true,
  }),
  true,
);

assert.strictEqual(
  needsCashCompatibility({
    last_payment_attempt_status: "switched_to_cash",
    payment_status: "cash_pending",
    payment_method: "TOURY_PAY_CASH",
    payth: "TOURY_PAY_CASH",
    PaymentMethod: "OnlinePayment",
    status_code: "pending_driver",
    ALLNOW: true,
    halh_order: "Pending",
  }),
  true,
);

const cardToCash = assertPatch({
  last_payment_attempt_status: "switched_to_cash",
  payment_status: "cash_pending",
  payment_method: "TOURY_PAY_CASH",
  payth: "TOURY_PAY_CASH",
  PaymentMethod: "OnlinePayment",
  status_code: "pending_driver",
  ALLNOW: true,
  ElectronicPayment: false,
});
assert.strictEqual(cardToCash.payment_status, "cash_pending");

// Wrongly expired after Card→Cash — revive.
const revived = assertPatch({
  last_payment_attempt_status: "switched_to_cash",
  payment_status: "cash_pending",
  payment_method: "TOURY_PAY_CASH",
  payth: "TOURY_PAY_CASH",
  PaymentMethod: "OnlinePayment",
  status_code: "expired",
  ALLNOW: false,
  halh_order: "Canceled",
  halh_text: "ملغي",
  mndob_user: null,
});
assert.strictEqual(revived.cash_compat_revived_from_expired, true);

// Already normalized pending cash — no patch.
assertPatch(
  {
    PaymentMethod: "Cash",
    payment_status: "pending_cash",
    status_code: "pending_driver",
    ALLNOW: true,
    ActiveOrder: false,
    halh_order: "Cash",
    halh: "pending_cash",
    halh_text: "بإنتظار قبول المندوب",
    acceptance_deadline_ms: 1_700_000_100_000,
    acceptanceDeadline: { seconds: 1 },
    cash_compat_version: 1,
  },
  true,
);

// Assigned driver — never rewrite.
assertPatch(
  {
    PaymentMethod: "Cash",
    payment_status: "pending_cash",
    status_code: "driver_assigned",
    ALLNOW: true,
    mndob_user: { path: "user/driver1" },
  },
  true,
);

// Completed — never rewrite.
assertPatch(
  {
    PaymentMethod: "Cash",
    payment_status: "pending_cash",
    status_code: "completed",
    ALLNOW: false,
  },
  true,
);

console.log("cash_booking_compatibility unit checks passed.");

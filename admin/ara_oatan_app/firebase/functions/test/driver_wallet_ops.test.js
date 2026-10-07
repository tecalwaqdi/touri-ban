const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

test("driver_wallet_ops exports accept + pay company", () => {
  const src = fs.readFileSync(
    path.join(__dirname, "..", "driver_wallet_ops.js"),
    "utf8",
  );
  assert.match(src, /exports\.acceptDriverOrder/);
  assert.match(src, /exports\.payCompanyFromWallet/);
  assert.match(src, /MIN_CASH_WALLET_SAR = 50|MIN_CASH_WALLET = countryFinance.MIN_CASH_WALLET_SAR/);
  assert.match(src, /company_due_payment/);
  assert.doesNotMatch(src, /data\.outstandingDue/);
  assert.match(src, /decideCompanyDuePayment/);
  assert.match(src, /balanceBefore/);
  assert.match(src, /balanceAfter/);
  assert.match(src, /BELOW_MIN_REQUIRES_CONFIRM/);
});

test("acceptDriverOrder heals stale busy and dual-writes busy fields", () => {
  const src = fs.readFileSync(
    path.join(__dirname, "..", "driver_wallet_ops.js"),
    "utf8",
  );
  assert.match(src, /stale_busy_healed/);
  assert.match(src, /isTrulyActiveDriverTrip/);
  assert.match(src, /mndon_newacc:\s*true/);
  assert.match(src, /clearDriverBusyPatch|setDriverBusyPatch/);
});

test("busy helpers: stale flags without live trip", () => {
  // Load helpers without initializing Firebase Admin fully.
  const mod = require("../driver_wallet_ops.js");
  const { driverBusyFlagsSet, isTrulyActiveDriverTrip } = mod._test;

  assert.equal(
    driverBusyFlagsSet({ mndonNewacc: true }),
    true,
    "camelCase busy",
  );
  assert.equal(
    driverBusyFlagsSet({ mndon_newacc: true }),
    true,
    "snake_case busy",
  );
  assert.equal(
    driverBusyFlagsSet({ active_order_id: "o1" }),
    true,
    "active_order_id busy",
  );
  assert.equal(driverBusyFlagsSet({}), false);

  assert.equal(
    isTrulyActiveDriverTrip(null, "user/d1"),
    false,
    "missing order",
  );
  assert.equal(
    isTrulyActiveDriverTrip(
      { status_code: "completed", mndob_user: { path: "user/d1" } },
      "user/d1",
    ),
    false,
    "terminal",
  );
  assert.equal(
    isTrulyActiveDriverTrip(
      { status_code: "driver_assigned", mndob_user: { path: "user/other" } },
      "user/d1",
    ),
    false,
    "other driver",
  );
  assert.equal(
    isTrulyActiveDriverTrip(
      { status_code: "driver_assigned", mndob_user: { path: "user/d1" } },
      "user/d1",
    ),
    true,
    "live trip",
  );
  assert.equal(
    isTrulyActiveDriverTrip(
      { status_code: "pending_driver" },
      "user/d1",
    ),
    false,
    "unassigned pending",
  );
});

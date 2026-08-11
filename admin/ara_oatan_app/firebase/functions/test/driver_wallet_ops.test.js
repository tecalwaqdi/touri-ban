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
  assert.match(src, /MIN_CASH_WALLET = 200/);
  assert.match(src, /company_payment/);
  assert.match(src, /balanceBefore/);
  assert.match(src, /balanceAfter/);
  assert.match(src, /BELOW_MIN_REQUIRES_CONFIRM/);
});

test("index exports driver wallet callables", () => {
  const src = fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8");
  assert.match(src, /acceptDriverOrder/);
  assert.match(src, /payCompanyFromWallet/);
});

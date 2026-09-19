"use strict";
const {test} = require("node:test");
const assert = require("node:assert/strict");
const {assertEligible, buildQuote, endTimeFor} = require("../extra_hours");
const start = new Date("2026-09-15T08:00:00Z");
function order(patch = {}) {
  return {USER: {path: "user/u"}, mndob_user: {path: "user/d"},
    status_code: "trip_in_progress", PaymentMethod: "Cash", payment_status: "pending_cash",
    total_taim: 2, START: start, endTime: new Date("2026-09-15T10:00:00Z"),
    SrSAAH: 100, currency: "SAR", total: 190, total_mndob2: 200,
    total_app: 30, total_vat: 30, total_mndob: 140, ksm: 10, ...patch};
}
const quote = (o, h = 1) => buildQuote(o, {sr: 999}, {}, "u", "order/o", h);
for (const status of ["driver_assigned", "driver_arriving", "driver_arrived", "trip_started", "trip_in_progress"]) {
  test(`canonical ${status} is eligible without legacy Accepted`, () => {
    assert.equal(assertEligible(order({status_code: status}), "u"), "cash");
  });
}
for (const status of ["completed", "trip_completed", "cancelled", "cancelled_by_customer", "cancelled_by_driver", "cancelled_by_admin", "expired", "refunded", "payment_pending", "pending_driver", "unknown"]) {
  test(`reject ${status} even with stale legacy Accepted`, () => {
    assert.throws(() => quote(order({status_code: status, halhOrderMndob: "Accepted"})), /EXTRA_HOURS_NOT_ACTIVE/);
  });
}
test("requires owner, driver, and collected online base fare", () => {
  assert.throws(() => assertEligible(order(), "other"), /NOT_OWNER/);
  assert.throws(() => quote(order({mndob_user: null})), /NOT_ACTIVE/);
  for (const status of ["unpaid", "processing", "refunded", "authorized"]) {
    assert.throws(() => quote(order({PaymentMethod: "OnlinePayment", payment_status: status})), /PAYMENT_NOT_ELIGIBLE/);
  }
  assert.equal(quote(order({PaymentMethod: "OnlinePayment", payment_status: "paid"})).method, "online");
});
test("booked price wins; retain original discount, VAT and commission basis", () => {
  const q = quote(order());
  assert.equal(q.hourlyMinor, 10000);
  assert.equal(q.amountMinor, 10000);
  assert.equal(q.currentTotalMinor, 19000);
  assert.equal(q.newTotalMinor, 29000);
  assert.equal(q.appFeeMinor, 1500);
  assert.equal(q.vatMinor, 1500);
  assert.equal(q.driverMinor, 7000);
  assert.equal(q.newHours, 3);
  assert.equal(q.newEndTime, "2026-09-15T11:00:00.000Z");
});
test("legacy hourly rate falls back to vehicle, currency uses correct minor units", () => {
  const q = buildQuote(order({SrSAAH: null, currency: "KWD"}), {sr: 25}, {}, "u", "order/o", 2);
  assert.equal(q.amountMinor, 50000);
  assert.equal(q.factor, 1000);
});
test("price fingerprint detects duration and financial edits", () => {
  assert.notEqual(quote(order()).quoteToken, quote(order({total_taim: 3})).quoteToken);
  assert.notEqual(quote(order()).quoteToken, quote(order({SrSAAH: 110})).quoteToken);
  assert.equal(quote(order()).quoteToken, quote(order({START: new Date()})).quoteToken);
});
test("use later canonical deadline, also support not-yet-started assigned trips", () => {
  assert.equal(endTimeFor(order({endTime: new Date("2026-09-15T09:00:00Z")}), 1), Date.parse("2026-09-15T11:00:00Z"));
  assert.equal(endTimeFor(order({endTime: new Date("2026-09-15T11:00:00Z")}), 1), Date.parse("2026-09-15T12:00:00Z"));
  assert.equal(endTimeFor(order({START: null, endTime: null, Schedule: start}), 1), Date.parse("2026-09-15T11:00:00Z"));
});
test("invalid durations and incomplete or frozen finances fail closed", () => {
  for (const h of [0, -1, 1.5, 169, NaN]) assert.throws(() => quote(order(), h), /INVALID_HOURS/);
  assert.throws(() => quote(order({total_taim: 720})), /INVALID_HOURS/);
  assert.throws(() => quote(order({total_app: null})), /FINANCE_INCOMPLETE/);
  assert.throws(() => quote(order({financial_snapshot: {}})), /FINANCE_LOCKED/);
  assert.throws(() => quote(order({payment_status: "cash_collected"})), /PAYMENT_NOT_ELIGIBLE/);
});

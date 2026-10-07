"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  sanitizeProposedValues,
  ALLOWED_APPLY_KEYS,
} = require("../driver_profile_change_request.js");

test("sanitizeProposedValues keeps whitelist keys only", () => {
  const out = sanitizeProposedValues({
    display_name: "New Name",
    number_lohh_car: "ABC123",
    wallet: 999,
    actev_mndob: false,
    personal_info: { requested: true },
    empty: "  ",
  });
  assert.equal(out.display_name, "New Name");
  assert.equal(out.number_lohh_car, "ABC123");
  assert.equal(out.wallet, undefined);
  assert.equal(out.actev_mndob, undefined);
  assert.equal(out.personal_info, undefined);
  assert.ok(ALLOWED_APPLY_KEYS.has("display_name"));
});

test("sanitizeProposedValues rejects non-objects", () => {
  assert.deepEqual(sanitizeProposedValues(null), {});
  assert.deepEqual(sanitizeProposedValues("x"), {});
});

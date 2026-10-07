/**
 * Unit tests for nearest-driver offer wave gating (no Firebase).
 */
const test = require("node:test");
const assert = require("node:assert/strict");
const { isUidInCurrentOfferWave } = require("../order_offer_waves.js");

test("legacy order without wave fields allows accept", () => {
  assert.equal(isUidInCurrentOfferWave({}, "a"), true);
  assert.equal(isUidInCurrentOfferWave({ status_code: "pending_driver" }, "a"), true);
});

test("wave-gated: only current/notified uids", () => {
  const order = {
    offer_wave_index: 0,
    offer_wave_uids: ["a", "b"],
    offer_notified_uids: ["a", "b"],
    offer_ranked_uids: ["a", "b", "c"],
  };
  assert.equal(isUidInCurrentOfferWave(order, "a"), true);
  assert.equal(isUidInCurrentOfferWave(order, "c"), false);
});

test("prior wave remains eligible after expansion", () => {
  const order = {
    offer_wave_index: 1,
    offer_wave_uids: ["c"],
    offer_notified_uids: ["a", "b", "c"],
    offer_ranked_uids: ["a", "b", "c"],
  };
  assert.equal(isUidInCurrentOfferWave(order, "a"), true);
  assert.equal(isUidInCurrentOfferWave(order, "c"), true);
  assert.equal(isUidInCurrentOfferWave(order, "z"), false);
});

test("offer_wave_open allows all", () => {
  assert.equal(
    isUidInCurrentOfferWave({ offer_wave_open: true, offer_wave_index: 9 }, "z"),
    true,
  );
});

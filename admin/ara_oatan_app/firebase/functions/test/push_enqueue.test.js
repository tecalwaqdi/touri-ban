"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeUserRefs,
  stringifyParameterData,
} = require("../push_enqueue.js");

test("normalizeUserRefs accepts comma string and paths", () => {
  assert.deepEqual(normalizeUserRefs("user/a, user/b"), ["user/a", "user/b"]);
  assert.deepEqual(normalizeUserRefs(["user/a", "user/b"]), ["user/a", "user/b"]);
  assert.deepEqual(normalizeUserRefs(["order/x", "user/c"]), ["user/c"]);
  assert.deepEqual(normalizeUserRefs([{ path: "user/d" }]), ["user/d"]);
  assert.deepEqual(normalizeUserRefs(null), []);
});

test("stringifyParameterData serializes objects", () => {
  assert.equal(stringifyParameterData(""), "");
  assert.equal(stringifyParameterData('{"a":1}'), '{"a":1}');
  assert.equal(stringifyParameterData({ idorder: "order/1" }), '{"idorder":"order/1"}');
});

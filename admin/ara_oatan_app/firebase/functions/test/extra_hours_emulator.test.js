"use strict";
const {test, before, beforeEach, after} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const {initializeTestEnvironment, assertFails, assertSucceeds} = require("@firebase/rules-unit-testing");
const {doc, updateDoc, getDoc, onSnapshot, Timestamp: ClientTimestamp} = require("firebase/firestore");
const {getQuote, reservePayment, applyExtension} = require("../extra_hours");
const {FieldValue, Timestamp} = admin.firestore;
const projectId = "demo-extra-hours";
let env, db, app;

before(async () => {
  if (!/^127\.0\.0\.1:\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || "")) throw Error("LOCAL_EMULATOR_REQUIRED");
  const port = Number(process.env.FIRESTORE_EMULATOR_HOST.split(":")[1]);
  env = await initializeTestEnvironment({projectId, firestore: {host: "127.0.0.1", port,
    rules: fs.readFileSync(path.resolve(__dirname, "../../firestore.rules"), "utf8")}});
  app = admin.initializeApp({projectId});
  db = app.firestore();
});
beforeEach(async () => { await env.clearFirestore(); await seed(); });
after(async () => { if (env) await env.cleanup(); if (app) await app.delete(); });

async function seed(patch = {}) {
  const start = Date.now() - 2 * 3600000;
  await db.doc("user/u").set({actev_user: true});
  await db.doc("user/d").set({ismndob: true, ismndom: true, actev_mndob: true, actev_user: true});
  await db.doc("countries/sa").set({currency_code: "SAR", acctev: true});
  await db.doc("type_car/c").set({sr: 999, acctev: true});
  await db.doc("order/o").set({USER: db.doc("user/u"), mndob_user: db.doc("user/d"),
    status_code: "trip_in_progress", halhOrderMndob: "Accepted", ActiveOrder: true,
    PaymentMethod: "Cash", payment_status: "pending_cash", cash_collection_status: "pending",
    total_taim: 2, START: Timestamp.fromMillis(start), endTime: Timestamp.fromMillis(start + 7200000),
    data_order: Timestamp.fromMillis(start), SrSAAH: 100, currency: "SAR",
    total: 190, amount_halalas: 19000, total_mndob2: 200, total_app: 30, total_vat: 30,
    total_mndob: 140, ksm: 10, carRev: db.doc("type_car/c"), Rev_dolh: db.doc("countries/sa"), ...patch});
}
async function request(hours = 1, key = "request-123") {
  const quote = await getQuote(db, "u", {orderPath: "order/o", extraHours: hours});
  return {orderPath: "order/o", extraHours: hours, quoteToken: quote.quoteToken, idempotencyKey: key};
}
const cash = (data) => applyExtension({db, FieldValue, Timestamp, uid: "u", data});
const paid = (sessionId) => applyExtension({db, FieldValue, Timestamp, uid: "u", sessionId});
async function reserve(data) { return reservePayment(db, FieldValue, "u", data); }
async function online() { await seed({PaymentMethod: "OnlinePayment", payment_status: "paid"}); }
function watchHours(auth) {
  const client = env.authenticatedContext(auth, auth === "a" ? {super_admin: true} : {}).firestore();
  return new Promise((resolve, reject) => {
    let stop;
    const timeout = setTimeout(() => { stop?.(); reject(Error("SYNC_TIMEOUT")); }, 15000);
    stop = onSnapshot(doc(client, "order/o"), (snap) => {
      if (snap.data()?.total_taim === 3) { clearTimeout(timeout); stop(); resolve(snap.data()); }
    }, (error) => { clearTimeout(timeout); reject(error); });
  });
}

test("cash atomically updates original order, amount, end time and all three live readers", async () => {
  const views = [watchHours("u"), watchHours("d"), watchHours("a")];
  const oldEnd = (await db.doc("order/o").get()).data().endTime.toMillis();
  const result = await cash(await request());
  assert.equal(result.applied, true);
  const data = (await db.doc("order/o").get()).data();
  assert.equal(data.endTime.toMillis(), oldEnd + 3600000);
  assert.equal(data.total, 290);
  assert.equal(data.total_app, 45);
  assert.equal(data.total_vat, 45);
  assert.equal(data.total_mndob, 210);
  assert.equal(data.ksm, 10);
  assert.equal(data.payment_status, "pending_cash");
  assert.equal((await db.collection("order").get()).size, 1);
  assert.equal((await db.collection("ExtraHours").get()).size, 1);
  assert.equal((await db.collection("Paymenthistory").get()).size, 0);
  const synced = await Promise.all(views);
  for (const view of synced) { assert.equal(view.total, 290); assert.equal(view.endTime.toMillis(), data.endTime.toMillis()); }
});
test("simultaneous duplicate cash confirmations apply once, including retries after completion", async () => {
  const data = await request();
  const results = await Promise.all([cash(data), cash(data)]);
  assert.equal(results.filter((r) => !r.alreadyApplied).length, 1);
  await db.doc("order/o").update({status_code: "completed"});
  assert.equal((await cash(data)).alreadyApplied, true);
  assert.equal((await db.doc("order/o").get()).data().total_taim, 3);
});
test("different concurrent extension requests cannot both consume one quote revision", async () => {
  const a = await request(1, "request-one");
  const b = await request(2, "request-two");
  const results = await Promise.allSettled([cash(a), cash(b)]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal((await db.collection("ExtraHours").get()).size, 1);
});
test("reject changed quote, wrong payment channel and settlement-claimed order", async () => {
  const data = await request();
  await assert.rejects(cash({...data, quoteToken: "forged"}), /QUOTE_CHANGED/);
  await assert.rejects(reserve(data), /PAYMENT_NOT_ELIGIBLE/);
  await db.doc("financial_settlement_claims/o").set({settlementId: "s"});
  await assert.rejects(cash(data), /FINANCE_LOCKED/);
});
test("online reservation is single-flight and recoverable without another payment", async () => {
  await online();
  const data = await request();
  const results = await Promise.all([reserve(data), reserve(data)]);
  assert.equal(results.filter((r) => !r.existingData).length, 1);
  const quote = await getQuote(db, "u", {orderPath: "order/o", extraHours: 4});
  assert.equal(quote.resumeSessionId, results[0].ref.id);
  assert.equal(quote.extraHours, 1);
  await assert.rejects(reserve({...data, idempotencyKey: "other-request"}), /PAYMENT_PENDING/);
  assert.equal((await db.doc("order/o").get()).data().total_taim, 2);
  assert.equal((await db.collection("payment_sessions").get()).size, 1);
});
test("online extension applies once only after verified payment; no new booking", async () => {
  await online();
  const {ref} = await reserve(await request());
  await assert.rejects(paid(ref.id), /PAYMENT_NOT_VERIFIED/);
  await ref.update({status: "paid"});
  await assert.rejects(paid(ref.id), /PAYMENT_NOT_VERIFIED/);
  await ref.update({verified_at: FieldValue.serverTimestamp()});
  const results = await Promise.all([paid(ref.id), paid(ref.id)]);
  assert.equal(results.filter((r) => !r.alreadyApplied).length, 1);
  assert.equal((await db.doc("order/o").get()).data().total, 290);
  assert.equal((await db.doc("order/o").get()).data().payment_status, "paid");
  assert.equal((await db.collection("order").get()).size, 1);
  assert.equal((await db.collection("Paymenthistory").get()).size, 1);
});
test("late paid callback never extends a completed trip", async () => {
  await online();
  const {ref} = await reserve(await request());
  await ref.update({status: "paid", verified_at: FieldValue.serverTimestamp()});
  await db.doc("order/o").update({status_code: "completed"});
  await assert.rejects(paid(ref.id), /NOT_ACTIVE/);
  assert.equal((await db.doc("order/o").get()).data().total_taim, 2);
  assert.equal((await ref.get()).data().status, "paid");
});
test("agent identity and rate are retained using the existing commission formula", async () => {
  await db.doc("order/o").update({agent_attribution_status: "attributed", agent_id: "agent1",
    agent_rate: 20, agent_rate_type: "percent_of_platform_fee", agent_amount_minor: 600});
  await cash(await request());
  const order = (await db.doc("order/o").get()).data();
  assert.equal(order.agent_id, "agent1"); assert.equal(order.agent_rate, 20);
  assert.equal(order.agent_amount_minor, 900);
});
test("rules reject direct customer extensions and forged receipts", async () => {
  const client = env.authenticatedContext("u").firestore();
  await assertFails(updateDoc(doc(client, "order/o"), {total_taim: 10}));
  const {setDoc} = require("firebase/firestore");
  await assertFails(setDoc(doc(client, "ExtraHours/fake"), {RevOrder: doc(client, "order/o"), addSaat: 1}));
});
test("rules block completion/shortening before the extended deadline, allow after it", async () => {
  await cash(await request());
  const driver = env.authenticatedContext("d").firestore();
  const ref = doc(driver, "order/o");
  await assertFails(updateDoc(ref, {status_code: "completed", ActiveOrder: false}));
  await assertFails(updateDoc(ref, {endTime: ClientTimestamp.fromMillis(Date.now() - 1)}));
  await assertFails(updateDoc(ref, {total_taim: 1}));
  await assertFails(updateDoc(ref, {extra_hours_updated_at: null}));
  await db.doc("order/o").update({START: Timestamp.fromMillis(Date.now() - 4 * 3600000),
    endTime: Timestamp.fromMillis(Date.now() - 3600000)});
  await assertSucceeds(updateDoc(ref, {status_code: "completed", ActiveOrder: false}));
});
test("an extended assigned trip starts using the new total duration", async () => {
  await seed({status_code: "driver_arrived", START: null, endTime: null});
  await cash(await request());
  const driver = env.authenticatedContext("d").firestore();
  const ref = doc(driver, "order/o");
  const start = Date.now();
  await assertFails(updateDoc(ref, {status_code: "trip_in_progress", START: ClientTimestamp.fromMillis(start),
    endTime: ClientTimestamp.fromMillis(start + 7200000)}));
  await assertSucceeds(updateDoc(ref, {status_code: "trip_in_progress", START: ClientTimestamp.fromMillis(start),
    endTime: ClientTimestamp.fromMillis(start + 10800000)}));
  assert.equal((await getDoc(ref)).data().total_taim, 3);
});

// Exercise the same provider-response verification used by polling and webhook.
// No gateway/network call is made: only the fetched provider response is stubbed.
const {syncSessionFromGateway} = require("../ngenius_payments").__test;
function gateway(state, amount = 10000, currency = "SAR") {
  return {state, amount: {value: amount, currencyCode: currency}};
}
test("provider authorization alone never applies; capture applies and repeated webhook is harmless", async () => {
  await online();
  const {ref} = await reserve(await request());
  let session = (await ref.get()).data();
  await syncSessionFromGateway(ref, session, gateway("AUTHORISED"));
  assert.equal((await db.doc("order/o").get()).data().total_taim, 2);
  session = (await ref.get()).data();
  const result = await syncSessionFromGateway(ref, session, gateway("CAPTURED"));
  assert.equal(result.purpose, "extra_hours");
  assert.equal(result.orderId, "o");
  assert.equal(result.id, ref.id);
  await syncSessionFromGateway(ref, session, gateway("CAPTURED"));
  assert.equal((await db.doc("order/o").get()).data().total_taim, 3);
  assert.equal((await db.collection("Paymenthistory").get()).size, 1);
});
test("provider amount/currency mismatch never applies or marks payment paid", async () => {
  await online();
  const {ref} = await reserve(await request());
  const session = (await ref.get()).data();
  await assert.rejects(syncSessionFromGateway(ref, session, gateway("CAPTURED", 1)));
  await assert.rejects(syncSessionFromGateway(ref, session, gateway("CAPTURED", 10000, "USD")));
  assert.equal((await ref.get()).data().status, "security_review");
  assert.equal((await db.doc("order/o").get()).data().total_taim, 2);
});
test("late provider capture is retained and flagged for review without extending terminal order", async () => {
  await online();
  const {ref} = await reserve(await request());
  await db.doc("order/o").update({status_code: "completed"});
  await syncSessionFromGateway(ref, (await ref.get()).data(), gateway("CAPTURED"));
  const session = (await ref.get()).data();
  assert.equal(session.status, "paid");
  assert.equal(session.extra_hours_requires_review, true);
  assert.equal((await db.doc("order/o").get()).data().total_taim, 2);
});

test("existing payment callable ignores client price and creates one gateway session on concurrent clicks", async () => {
  await online();
  const axios = require("axios");
  const originalPost = axios.post;
  const names = ["NGENIUS_API_KEY", "NGENIUS_OUTLET_REF", "NGENIUS_PRODUCTION", "NGENIUS_REQUIRE_APP_CHECK"];
  const previous = names.map((name) => process.env[name]);
  process.env.NGENIUS_API_KEY = "test-only";
  process.env.NGENIUS_OUTLET_REF = "test-only";
  process.env.NGENIUS_PRODUCTION = "false";
  process.env.NGENIUS_REQUIRE_APP_CHECK = "false";
  let creates = 0;
  axios.post = async (url, payload) => {
    if (url.endsWith("access-token")) return {data: {access_token: "stub"}};
    assert.ok(url.endsWith("/orders"));
    creates++;
    assert.deepEqual(payload.amount, {currencyCode: "SAR", value: 10000});
    return {data: {reference: "gateway-ref", _links: {payment: {href: "https://gateway.example/checkout"}}}};
  };
  try {
    const data = {...await request(), paymentPurpose: "extra_hours", amount: 1, currency: "USD"};
    const callable = require("../ngenius_payments").createNGeniusPayment;
    const results = await Promise.all([callable.run(data, {auth: {uid: "u"}}), callable.run(data, {auth: {uid: "u"}})]);
    assert.equal(creates, 1);
    assert.equal(results[0].id, results[1].id);
    assert.equal(results[0].purpose, "extra_hours");
    assert.equal(results[0].orderId, "o");
    assert.equal((await db.doc("order/o").get()).data().total_taim, 2);
  } finally {
    axios.post = originalPost;
    names.forEach((name, i) => {
      if (previous[i] === undefined) delete process.env[name];
      else process.env[name] = previous[i];
    });
  }
});

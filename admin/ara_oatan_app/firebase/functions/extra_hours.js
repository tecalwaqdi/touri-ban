"use strict";

// Shared implementation of the existing ExtraHours operation. All money and
// duration changes are committed on the original order, alongside its receipt.
const crypto = require("crypto");
const {computeAgentAmountMinor} = require("./agent_order_snapshot.js");

const ACTIVE = new Set([
  "driver_assigned", "driver_arriving", "driver_arrived",
  "trip_started", "trip_in_progress",
]);
const EXPONENT = {SAR: 2, AED: 2, KWD: 3, BHD: 3, OMR: 3, USD: 2,
  EUR: 2, GBP: 2, RUB: 2, KGS: 2, UZS: 2, QAR: 2, EGP: 2,
  MAD: 2, TND: 3, JOD: 3, INR: 2, IDR: 2, MYR: 2, TRY: 2};
const MONEY_FIELDS = ["total", "total_mndob2", "total_app", "total_vat", "total_mndob"];

function fail(code, details = {}) {
  const error = new Error(code);
  error.extensionCode = code;
  error.details = details;
  throw error;
}
function pathOf(value) {
  return typeof value === "string" ? value : value && value.path;
}
function millis(value) {
  if (value == null) return null;
  const result = value.toMillis ? value.toMillis() :
    value instanceof Date ? value.getTime() : Date.parse(value);
  return Number.isFinite(result) ? result : null;
}
function statusOf(order) {
  if (order.status_code) return String(order.status_code).toLowerCase();
  const aliases = {"مقبول": "driver_assigned", "وصل المندوب": "driver_arrived",
    "تم البدء في الرحلة": "trip_in_progress"};
  return aliases[order.halh_text] || "";
}
function assertEligible(order, uid) {
  if (pathOf(order.USER) !== `user/${uid}`) fail("EXTRA_HOURS_NOT_OWNER");
  if (!ACTIVE.has(statusOf(order)) || !pathOf(order.mndob_user) ||
      ["completed", "cancelled", "canceled"].includes(String(order.halhOrderMndob || "").toLowerCase()) ||
      order.completedAt || order.cancelledAt) fail("EXTRA_HOURS_NOT_ACTIVE");
  if (order.financial_snapshot || order.settlement_id) fail("EXTRA_HOURS_FINANCE_LOCKED");
  const method = String(order.PaymentMethod || "").toLowerCase();
  const payment = String(order.payment_status || "").toLowerCase();
  if (method === "cash" && ["pending_cash", "cash_pending", "cash_due"].includes(payment)) return "cash";
  if (method === "onlinepayment" && ["paid", "captured"].includes(payment)) return "online";
  fail("EXTRA_HOURS_PAYMENT_NOT_ELIGIBLE");
}
function basisOf(order) {
  return {hours: Number(order.total_taim), money: MONEY_FIELDS.map((key) => Number(order[key])),
    agent: [order.agent_id || null, order.agent_rate ?? null, order.agent_rate_type || null,
      order.agent_amount_minor ?? null]};
}
function endTimeFor(order, hours) {
  const started = millis(order.START) ?? millis(order.trip_started_at);
  const bookedEnd = millis(order.endTime);
  const currentHours = Number(order.total_taim);
  const currentEnd = Math.max(bookedEnd || 0, started == null ? 0 : started + currentHours * 3600000);
  if (currentEnd > 0) return currentEnd + hours * 3600000;
  const anchor = millis(order.Schedule) ?? millis(order.data_order);
  if (anchor == null) fail("EXTRA_HOURS_DURATION_UNAVAILABLE");
  return anchor + (currentHours + hours) * 3600000;
}

function buildQuote(order, car, country, uid, orderPath, extraHours) {
  const method = assertEligible(order, uid);
  if (!Number.isInteger(extraHours) || extraHours < 1 || extraHours > 168) fail("EXTRA_HOURS_INVALID_HOURS");
  const currentHours = Number(order.total_taim);
  if (!Number.isInteger(currentHours) || currentHours < 1 || currentHours + extraHours > 720) fail("EXTRA_HOURS_INVALID_HOURS");
  const currency = String(order.currency || order.currency_code || country.currency_code || country.currency || "").toUpperCase();
  if (EXPONENT[currency] == null) fail("EXTRA_HOURS_CURRENCY_UNSUPPORTED");
  const factor = 10 ** EXPONENT[currency];
  // Preserve the booked hourly price when present; only legacy orders need
  // the current vehicle price. Never read the customer's checkout AppState.
  const hourlyRate = Number(order.SrSAAH) > 0 ? Number(order.SrSAAH) : Number(car.sr);
  const hourlyMinor = Math.round(hourlyRate * factor);
  if (!Number.isSafeInteger(hourlyMinor) || hourlyMinor <= 0) fail("EXTRA_HOURS_PRICE_UNAVAILABLE");
  const amounts = MONEY_FIELDS.map((key) => {
    if (order[key] == null || !Number.isFinite(Number(order[key])) || Number(order[key]) < 0) fail("EXTRA_HOURS_FINANCE_INCOMPLETE");
    const minor = Math.round(Number(order[key]) * factor);
    if (!Number.isSafeInteger(minor)) fail("EXTRA_HOURS_FINANCE_INCOMPLETE");
    return minor;
  });
  const [total, gross, commission, vat, driver] = amounts;
  if (gross <= 0 || Math.abs(gross - commission - vat - driver) > 1) fail("EXTRA_HOURS_FINANCE_INCOMPLETE");
  const amountMinor = hourlyMinor * extraHours;
  if (!Number.isSafeInteger(amountMinor) || !Number.isSafeInteger(total + amountMinor)) fail("EXTRA_HOURS_PRICE_UNAVAILABLE");
  if (order.agent_attribution_status === "attributed" &&
      (order.agent_rate_type !== "percent_of_platform_fee" ||
       computeAgentAmountMinor(commission, order.agent_rate) == null)) fail("EXTRA_HOURS_FINANCE_INCOMPLETE");
  // The existing extra-hours tariff is full hourly rate (no new discount).
  // Preserve the trip's recorded commission/VAT basis, including rounding.
  const appFeeMinor = Math.round((gross + amountMinor) * commission / gross) - commission;
  const vatMinor = Math.round((gross + amountMinor) * vat / gross) - vat;
  const driverMinor = amountMinor - appFeeMinor - vatMinor;
  if (driverMinor < 0) fail("EXTRA_HOURS_FINANCE_INCOMPLETE");
  const basis = basisOf(order);
  const quote = {orderPath, extraHours, currentHours, newHours: currentHours + extraHours,
    method, currency, factor, hourlyMinor, amountMinor, amountHalalas: amountMinor,
    currentTotalMinor: total, newTotalMinor: total + amountMinor,
    appFeeMinor, vatMinor, driverMinor, basis};
  const quoteToken = crypto.createHash("sha256").update(JSON.stringify({uid, ...quote})).digest("hex");
  return {...quote, quoteToken, newEndTime: new Date(endTimeFor(order, extraHours)).toISOString()};
}

function definitelyFailed(session) {
  // A transport timeout is NOT evidence that a provider charge cannot arrive.
  if (session.extra_hours_retry_safe === true) return true;
  return Boolean(session.verified_at) &&
    ["failed", "cancelled", "expired"].includes(session.status);
}
async function loadOrder(db, tx, uid, orderPath) {
  if (!/^order\/[^/]+$/.test(orderPath || "")) fail("EXTRA_HOURS_INVALID_ORDER");
  const ref = db.doc(orderPath);
  const snap = await tx.get(ref);
  if (!snap.exists) fail("EXTRA_HOURS_NOT_ACTIVE");
  const order = snap.data();
  assertEligible(order, uid);
  const claim = await tx.get(db.doc(`financial_settlement_claims/${ref.id}`));
  if (claim.exists) fail("EXTRA_HOURS_FINANCE_LOCKED");
  return {ref, order};
}
async function quoteInTransaction(db, tx, uid, data) {
  const loaded = await loadOrder(db, tx, uid, data.orderPath);
  const {order} = loaded;
  if (order.extra_hours_pending_session) {
    const pending = await tx.get(db.doc(`payment_sessions/${order.extra_hours_pending_session}`));
    if (pending.exists && !pending.data().extra_hours_applied && !definitelyFailed(pending.data())) {
      fail("EXTRA_HOURS_PAYMENT_PENDING", {sessionId: pending.id, quote: pending.data().extension_quote});
    }
  }
  const carPath = pathOf(order.carRev);
  const countryPath = pathOf(order.Rev_dolh);
  if (!/^type_car\/[^/]+$/.test(carPath || "") || !/^countries\/[^/]+$/.test(countryPath || "")) fail("EXTRA_HOURS_PRICE_UNAVAILABLE");
  const car = await tx.get(db.doc(carPath));
  const country = await tx.get(db.doc(countryPath));
  if (!car.exists || !country.exists || car.data().acctev === false || car.data().actev === false || country.data().acctev === false) fail("EXTRA_HOURS_PRICE_UNAVAILABLE");
  const carCountry = pathOf(car.data().Rev_dolh || car.data().countryRef);
  if (carCountry && carCountry !== countryPath) fail("EXTRA_HOURS_PRICE_UNAVAILABLE");
  return {...loaded, quote: buildQuote(order, car.data(), country.data(), uid, data.orderPath, data.extraHours)};
}
async function getQuote(db, uid, data) {
  try {
    return await db.runTransaction(async (tx) => (await quoteInTransaction(db, tx, uid, data)).quote);
  } catch (e) {
    if (e.extensionCode === "EXTRA_HOURS_PAYMENT_PENDING" && e.details.quote) {
      return {...e.details.quote, resumeSessionId: e.details.sessionId};
    }
    throw e;
  }
}
function assertQuote(quote, data) {
  if (data.quoteToken !== quote.quoteToken) fail("EXTRA_HOURS_QUOTE_CHANGED");
}
function requestId(uid, data) {
  if (!/^[a-zA-Z0-9_.:-]{8,96}$/.test(data.idempotencyKey || "")) fail("EXTRA_HOURS_INVALID_REQUEST");
  return crypto.createHash("sha256").update(`${uid}:extra_hours:${data.idempotencyKey}`).digest("hex");
}
function assertSameRequest(stored, data, uid) {
  if (stored.user_id !== uid || stored.orderPath !== data.orderPath ||
      stored.extraHours !== data.extraHours || stored.quoteToken !== data.quoteToken) fail("EXTRA_HOURS_REQUEST_CONFLICT");
}

async function reservePayment(db, FieldValue, uid, data) {
  const id = requestId(uid, data);
  const ref = db.doc(`payment_sessions/${id}`);
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) {
      assertSameRequest(existing.data().extension_quote || {}, data, uid);
      return {ref, quote: existing.data().extension_quote, existingData: existing.data()};
    }
    const {ref: orderRef, quote} = await quoteInTransaction(db, tx, uid, data);
    assertQuote(quote, data);
    if (quote.method !== "online") fail("EXTRA_HOURS_PAYMENT_NOT_ELIGIBLE");
    const storedQuote = {...quote, user_id: uid};
    tx.create(ref, {user_id: uid, purpose: "extra_hours", provider: "ngenius",
      backend_source: "firebase_functions", orderPath: data.orderPath,
      extraHours: data.extraHours, amount_halalas: quote.amountMinor,
      currency: quote.currency, status: "creating", extension_quote: storedQuote,
      created_at: FieldValue.serverTimestamp(), updated_at: FieldValue.serverTimestamp()});
    tx.update(orderRef, {extra_hours_pending_session: id});
    return {ref, quote: storedQuote, existingData: null};
  });
}

async function applyExtension({db, FieldValue, Timestamp, uid, data, sessionId}) {
  const id = sessionId || requestId(uid, data);
  const receiptRef = db.doc(`ExtraHours/${id}`);
  return db.runTransaction(async (tx) => {
    const receipt = await tx.get(receiptRef);
    if (receipt.exists) {
      if (pathOf(receipt.data().revUser) !== `user/${uid}`) fail("EXTRA_HOURS_NOT_OWNER");
      if (!sessionId) assertSameRequest(receipt.data().request, data, uid);
      return {...receipt.data().result, alreadyApplied: true};
    }
    let loaded;
    let sessionRef;
    let quote;
    if (sessionId) {
      sessionRef = db.doc(`payment_sessions/${sessionId}`);
      const session = await tx.get(sessionRef);
      if (!session.exists || session.data().user_id !== uid || session.data().purpose !== "extra_hours" ||
          session.data().status !== "paid" || !session.data().verified_at) fail("EXTRA_HOURS_PAYMENT_NOT_VERIFIED");
      quote = session.data().extension_quote;
      if (!quote || quote.amountMinor !== session.data().amount_halalas || quote.currency !== session.data().currency) fail("EXTRA_HOURS_QUOTE_CHANGED");
      loaded = await loadOrder(db, tx, uid, quote.orderPath);
      if (assertEligible(loaded.order, uid) !== "online" ||
          loaded.order.extra_hours_pending_session !== sessionId ||
          JSON.stringify(basisOf(loaded.order)) !== JSON.stringify({hours: quote.basis.hours, money: quote.basis.money, agent: quote.basis.agent})) fail("EXTRA_HOURS_QUOTE_CHANGED");
    } else {
      loaded = await quoteInTransaction(db, tx, uid, data);
      quote = loaded.quote;
      assertQuote(quote, data);
      if (quote.method !== "cash") fail("EXTRA_HOURS_PAYMENT_NOT_ELIGIBLE");
    }
    const {order, ref: orderRef} = loaded;
    const newEndTime = endTimeFor(order, quote.extraHours);
    const factor = quote.factor;
    const add = (key, minor) => (Math.round(Number(order[key]) * factor) + minor) / factor;
    const result = {orderId: orderRef.id, applied: true, alreadyApplied: false,
      newHours: quote.newHours, newEndTime: new Date(newEndTime).toISOString(),
      newTotalMinor: quote.newTotalMinor, currency: quote.currency,
      status: sessionId ? "paid" : "pending_cash"};
    const update = {total_taim: quote.newHours, endTime: Timestamp.fromMillis(newEndTime),
      pricing_hours: quote.newHours,
      additional_hours: Number(order.additional_hours || 0) + quote.extraHours,
      total: quote.newTotalMinor / factor, amount_halalas: quote.newTotalMinor,
      pricing_quote_halalas: quote.newTotalMinor,
      total_mndob2: add("total_mndob2", quote.amountMinor),
      total_app: add("total_app", quote.appFeeMinor), total_vat: add("total_vat", quote.vatMinor),
      total_mndob: add("total_mndob", quote.driverMinor),
      extra_hours_updated_at: FieldValue.serverTimestamp(), updated_at: FieldValue.serverTimestamp()};
    if (order.agent_attribution_status === "attributed") {
      // Same recorded agent/rate and existing FIN-9 formula; no reassignment.
      const agentMinor = computeAgentAmountMinor(Math.round(update.total_app * factor), order.agent_rate);
      update.agent_amount_minor = agentMinor;
      update.agent_amount = agentMinor / factor;
    }
    if (sessionId) update.extra_hours_pending_session = FieldValue.delete();
    // Preserve payment method/status: cash remains due; the online increment
    // reaches here only after actual provider verification.
    tx.update(orderRef, update);
    tx.create(receiptRef, {revUser: db.doc(`user/${uid}`), RevOrder: orderRef,
      RevMndob: order.mndob_user, addSaat: quote.extraHours, Total: quote.amountMinor / factor,
      currency: quote.currency, dateAdd: FieldValue.serverTimestamp(), halh: "Completed",
      payment_status: result.status, paymentGatewayOrderId: sessionId || null,
      idOrder: String(order.IDorder || ""), request: {...quote, user_id: uid}, result});
    if (sessionId) {
      tx.set(sessionRef, {extra_hours_applied: true, extra_hours_applied_at: FieldValue.serverTimestamp()}, {merge: true});
      tx.create(db.doc(`Paymenthistory/${id}`), {revOrder: orderRef, RevUser: db.doc(`user/${uid}`),
        Osf: "extra_hours", DateAdd: FieldValue.serverTimestamp(), total: quote.amountMinor / factor,
        currency: quote.currency, ngeniusSessionId: id});
    }
    return result;
  });
}

module.exports = {assertEligible, buildQuote, endTimeFor, getQuote, reservePayment, applyExtension};

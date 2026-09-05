const assert = require("assert");
const fs = require("fs");
const path = require("path");

const paymentModule = require("../ngenius_payments.js");
const {
  extractPaymentUrl,
  normalizeStatus,
  sanitizeMerchantOrderReference,
  sessionIdFor,
  parseProductionFlag,
  resolveWalletPackageFromCatalog,
  webhookPayloadHash,
  webhookEventDocId,
} = paymentModule.__test;

function expectHttpsError(fn, code) {
  try {
    fn();
    assert.fail("expected HttpsError");
  } catch (error) {
    assert.strictEqual(error.code, code, String(error.message || error));
  }
}

// --- status mapping ---
assert.strictEqual(normalizeStatus("PURCHASED"), "paid");
assert.strictEqual(normalizeStatus("CAPTURED"), "paid");
assert.strictEqual(normalizeStatus("AUTHORISED"), "pending");
assert.strictEqual(normalizeStatus("STARTED"), "pending");
assert.strictEqual(normalizeStatus("DECLINED"), "failed");
assert.strictEqual(normalizeStatus("FAILED"), "failed");
assert.strictEqual(normalizeStatus("CANCELLED"), "cancelled");
assert.strictEqual(normalizeStatus("CANCELED"), "cancelled");
assert.strictEqual(normalizeStatus("EXPIRED"), "expired");
assert.strictEqual(normalizeStatus("REFUNDED"), "refunded");
assert.strictEqual(normalizeStatus("PARTIALLY_REFUNDED"), "partially_refunded");

assert.strictEqual(
  extractPaymentUrl({_links: {payment: {href: "https://pay.example/order"}}}),
  "https://pay.example/order",
);
assert.strictEqual(extractPaymentUrl({}), null);

// --- duplicate create payment idempotency key ---
const first = sessionIdFor("user-1", "attempt-1");
assert.strictEqual(first, sessionIdFor("user-1", "attempt-1"));
assert.notStrictEqual(first, sessionIdFor("user-1", "attempt-2"));
assert.strictEqual(first.length, 64);

assert.strictEqual(
  sanitizeMerchantOrderReference("Touri Taxi / booking # 42"),
  "Touri-Taxi-booking-42",
);

// --- production flag missing / invalid ⇒ sandbox ---
assert.strictEqual(parseProductionFlag(undefined), false);
assert.strictEqual(parseProductionFlag(null), false);
assert.strictEqual(parseProductionFlag(""), false);
assert.strictEqual(parseProductionFlag("false"), false);
assert.strictEqual(parseProductionFlag("sandbox"), false);
assert.strictEqual(parseProductionFlag("maybe"), false);
assert.strictEqual(parseProductionFlag("TRUE"), true);
assert.strictEqual(parseProductionFlag("production"), true);

// --- wallet package catalog ---
const catalog = {
  minAmountMinor: 1000,
  maxAmountMinor: 500000,
  allowedCurrencies: ["SAR"],
  packages: [
    {
      packageId: "seed_sar_50",
      amountMinor: 5000,
      currency: "SAR",
      enabled: true,
      countryCode: "SA",
      sortOrder: 1,
    },
    {
      packageId: "seed_sar_disabled",
      amountMinor: 10000,
      currency: "SAR",
      enabled: false,
      countryCode: "SA",
      sortOrder: 2,
    },
    {
      packageId: "seed_usd_bad",
      amountMinor: 5000,
      currency: "USD",
      enabled: true,
      countryCode: "US",
      sortOrder: 3,
    },
  ],
};

const ok = resolveWalletPackageFromCatalog(catalog, "seed_sar_50");
assert.strictEqual(ok.amountHalalas, 5000);
assert.strictEqual(ok.currency, "SAR");
assert.strictEqual(ok.packageId, "seed_sar_50");

// Client-supplied amount must never affect resolved amountMinor.
const tampered = resolveWalletPackageFromCatalog(
  catalog,
  "seed_sar_50",
  {countryCode: "SA"},
);
assert.strictEqual(tampered.amountHalalas, 5000);

expectHttpsError(
  () => resolveWalletPackageFromCatalog(catalog, "missing_pkg"),
  "not-found",
);
expectHttpsError(
  () => resolveWalletPackageFromCatalog(catalog, "seed_sar_disabled"),
  "failed-precondition",
);
expectHttpsError(
  () => resolveWalletPackageFromCatalog(catalog, "seed_usd_bad"),
  "failed-precondition",
);
expectHttpsError(
  () => resolveWalletPackageFromCatalog(catalog, "seed_sar_50", {countryCode: "KG"}),
  "failed-precondition",
);
expectHttpsError(
  () => resolveWalletPackageFromCatalog(catalog, ""),
  "invalid-argument",
);

// --- webhook event id / hash stability ---
const hashA = webhookPayloadHash({eventId: "evt-1", order: {reference: "o1"}});
const hashB = webhookPayloadHash({eventId: "evt-1", order: {reference: "o1"}});
const hashC = webhookPayloadHash({eventId: "evt-2", order: {reference: "o1"}});
assert.strictEqual(hashA, hashB);
assert.notStrictEqual(hashA, hashC);
assert.strictEqual(webhookEventDocId("evt-1!", hashA), "evt-1");
assert.ok(webhookEventDocId("", hashA).startsWith("hash_"));

// --- paid before order: order uses session id; duplicate finalize guarded in CF ---
// Static source guarantees (no card PAN fields; no default production true).
const source = fs.readFileSync(
  path.join(__dirname, "..", "ngenius_payments.js"),
  "utf8",
);
for (const forbidden of [
  "cardNumber",
  "card_number",
  "cvv",
  "cvc",
  "cardholderName",
]) {
  assert.strictEqual(
    source.includes(forbidden),
    false,
    `Cloud Functions must not process ${forbidden}`,
  );
}
assert.strictEqual(
  source.includes('process.env.NGENIUS_PRODUCTION || "true"'),
  false,
  "Production must not be the default",
);
assert.ok(source.includes("NGENIUS_ALLOW_PRODUCTION"));
assert.ok(source.includes("webhook_events"));
assert.ok(source.includes("settings/wallet_topup_packages"));
assert.ok(source.includes("Never charge using Flutter-supplied amount"));
assert.ok(source.includes("NGENIUS_OUTLET_REF"));
assert.ok(
  /NGENIUS_PAYMENT_SECRETS[\s\S]*NGENIUS_OUTLET_REF/.test(source),
  "payment secrets must bind NGENIUS_OUTLET_REF",
);
assert.ok(
  /NGENIUS_WEBHOOK_SECRETS[\s\S]*NGENIUS_WEBHOOK_SECRET/.test(source),
  "webhook secrets must bind NGENIUS_WEBHOOK_SECRET",
);

// --- F3-C1: booking financial snapshot majors from verified quote ---
const {
  bookingFinancialMajorsFromQuote,
  requireBookingFinancialMajors,
} = paymentModule.__test;

// Controlled 50 / 7.50 / 0 / 42.50 via canonical halalas (same as verifiedBookingAmount).
const quote50 = {
  baseFareHalalas: 5000,
  appFeeHalalas: 750,
  vatHalalas: 0,
  amountHalalas: 5000,
  discountHalalas: 0,
};
const majors50 = bookingFinancialMajorsFromQuote(quote50);
assert.ok(majors50);
assert.strictEqual(majors50.total_mndob2, 50);
assert.strictEqual(majors50.total_app, 7.5);
assert.strictEqual(majors50.total_vat, 0);
assert.strictEqual(majors50.total_mndob, 42.5);
assert.strictEqual(majors50.total, 50);
assert.strictEqual(typeof majors50.total_mndob2, "number");
assert.strictEqual(typeof majors50.total_mndob, "number");
assert.strictEqual(typeof majors50.total_app, "number");
assert.strictEqual(typeof majors50.total_vat, "number");
assert.strictEqual(typeof majors50.total, "number");

// Online session shape (spread verified quote onto payment session).
const sessionOnline = {
  amount_halalas: 5000,
  baseFareHalalas: 5000,
  appFeeHalalas: 750,
  vatHalalas: 0,
  discountHalalas: 0,
};
const majorsOnline = bookingFinancialMajorsFromQuote(sessionOnline);
assert.deepStrictEqual(majorsOnline, majors50);

// Discounted customer total still uses gross-based driver net (not amount - fee).
const quoteDiscounted = {
  baseFareHalalas: 5000,
  appFeeHalalas: 750,
  vatHalalas: 0,
  amountHalalas: 4000,
  discountHalalas: 1000,
};
const majorsDisc = bookingFinancialMajorsFromQuote(quoteDiscounted);
assert.strictEqual(majorsDisc.total, 40);
assert.strictEqual(majorsDisc.total_mndob2, 50);
assert.strictEqual(majorsDisc.total_mndob, 42.5);

// No zero fallback for missing authoritative fields.
assert.strictEqual(bookingFinancialMajorsFromQuote({}), null);
assert.strictEqual(
  bookingFinancialMajorsFromQuote({
    baseFareHalalas: 5000,
    appFeeHalalas: 750,
    // vat missing
    amountHalalas: 5000,
  }),
  null,
);
expectHttpsError(
  () => requireBookingFinancialMajors({amountHalalas: 5000}, "unit"),
  "failed-precondition",
);

// Source: both create paths persist total_mndob2 + total_mndob atomically in orderData.
assert.ok(source.includes("bookingFinancialMajorsFromQuote"));
assert.ok(source.includes("requireBookingFinancialMajors"));
assert.ok(source.includes('total_mndob2: money.total_mndob2'));
assert.ok(source.includes('total_mndob: money.total_mndob'));
assert.ok(
  (source.match(/total_mndob2: money\.total_mndob2/g) || []).length >= 2,
  "cash + online create must both write total_mndob2",
);
assert.ok(
  (source.match(/total_mndob: money\.total_mndob/g) || []).length >= 2,
  "cash + online create must both write total_mndob",
);
assert.ok(source.includes("buildBookingAgentSnapshot"));
assert.ok(
  (source.match(/\.\.\.agentFields/g) || []).length >= 2,
  "cash + online create must both write agent snapshot fields",
);

process.stdout.write("N-Genius unit checks passed.\n");
process.exit(0);

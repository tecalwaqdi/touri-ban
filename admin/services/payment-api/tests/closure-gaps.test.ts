import {createRequire} from "node:module";
import {describe, expect, it} from "vitest";

const require = createRequire(import.meta.url);
const fin = require("../../../shared/country_finance.js");
const due = require("../../../shared/company_due.js");
const push = require("../../../shared/push_locale.js");

describe("support phone fallback", () => {
  it("uses the Saudi number only when the Saudi Agent phone is missing", () => {
    const result = fin.resolveSupportPhone({
      iso2: "SA",
      countryPath: "countries/saudi_arabia",
      agentPhone: "",
    });
    expect(result.ok).toBe(true);
    expect(result.digits).toBe("966533356126");
    expect(result.fallback).toBe(true);
  });

  it("does not use the Saudi number for Kyrgyzstan or Russia", () => {
    for (const country of [
      {iso2: "KG", countryPath: "countries/kyrgyzstan"},
      {iso2: "RU", countryPath: "countries/russia"},
    ]) {
      const result = fin.resolveSupportPhone({...country, agentPhone: ""});
      expect(result.ok).toBe(false);
      expect(result.code).toBe("SUPPORT_NOT_CONFIGURED");
      expect(result.digits).toBe("");
    }
  });

  it("uses a configured foreign Agent number", () => {
    const result = fin.resolveSupportPhone({
      iso2: "KG",
      countryPath: "countries/kyrgyzstan",
      agentPhone: "+996 555 123 456",
    });
    expect(result.digits).toBe("996555123456");
    expect(result.fallback).toBe(false);
  });
});

describe("server-owned company due", () => {
  it("rejects a client due that is larger than the server due", () => {
    const decision = due.decideCompanyDuePayment({
      requested: 500,
      walletBalance: 1000,
      walletCurrency: "KGS",
      serverDue: 100,
      serverCurrency: "KGS",
    });
    expect(decision.ok).toBe(false);
    expect(decision.code).toBe("PAYMENT_EXCEEDS_COMPANY_DUE");
  });

  it("returns the stable refusal codes", () => {
    expect(due.decideCompanyDuePayment({
      requested: 10,
      walletBalance: 100,
      walletCurrency: "SAR",
      serverDue: 0,
      serverCurrency: "SAR",
    }).code).toBe("NO_COMPANY_DUE");
    expect(due.decideCompanyDuePayment({
      requested: 80,
      walletBalance: 50,
      walletCurrency: "SAR",
      serverDue: 100,
      serverCurrency: "SAR",
    }).code).toBe("INSUFFICIENT_WALLET_BALANCE");
    expect(due.decideCompanyDuePayment({
      requested: 10,
      walletBalance: 50,
      walletCurrency: "KGS",
      serverDue: 10,
      serverCurrency: "SAR",
    }).code).toBe("CURRENCY_MISMATCH");
  });
});

describe("customer booking FX snapshot", () => {
  const frozenAt = new Date("2026-10-03T12:00:00.000Z");

  it("converts a KGS booking and keeps the commercial amount local", () => {
    const snap = fin.bookingGatewaySnapshot(2700, {
      id: "kyrgyzstan",
      iso_code: "KG",
      currency_code: "KGS",
      vat_percent: 10,
      local_units_per_sar: 75,
    }, {now: frozenAt});
    expect(snap.local_amount).toBe(2700);
    expect(snap.local_currency).toBe("KGS");
    expect(snap.gateway_currency).toBe("SAR");
    expect(snap.gateway_minor_sar).toBe(3600);
    expect(snap.fx_local_per_sar).toBe(75);
  });

  it("converts a RUB booking from configured FX", () => {
    const snap = fin.bookingGatewaySnapshot(7500, {
      id: "russia",
      iso_code: "RU",
      currency_code: "RUB",
      vat_percent: 0,
      local_units_per_sar: 25,
    }, {now: frozenAt});
    expect(snap.local_currency).toBe("RUB");
    expect(snap.gateway_minor_sar).toBe(30000);
  });

  it("keeps a SAR booking on the same minor amount", () => {
    const snap = fin.bookingGatewaySnapshot(50, {
      id: "saudi_arabia",
      iso_code: "SA",
      currency_code: "SAR",
      vat_percent: 15,
    }, {now: frozenAt});
    expect(snap.local_currency).toBe("SAR");
    expect(snap.gateway_minor_sar).toBe(5000);
    expect(snap.fx_local_per_sar).toBe(1);
  });

  it("does not change a stored session when country FX changes later", () => {
    const first = fin.bookingGatewaySnapshot(2700, {
      id: "kyrgyzstan",
      iso_code: "KG",
      currency_code: "KGS",
      vat_percent: 10,
      local_units_per_sar: 75,
    }, {now: frozenAt});
    const later = fin.bookingGatewaySnapshot(2700, {
      id: "kyrgyzstan",
      iso_code: "KG",
      currency_code: "KGS",
      vat_percent: 10,
      local_units_per_sar: 80,
    }, {now: new Date("2026-11-01T00:00:00.000Z")});
    expect(fin.expectedGatewayMinor(first)).toBe(3600);
    expect(later.gateway_minor_sar).not.toBe(first.gateway_minor_sar);
    expect(() => fin.assertGatewayAmountMatches(first, later.gateway_minor_sar)).toThrow(
      /PAYMENT_AMOUNT_MISMATCH/,
    );
  });

  it("ignores a tampered gateway amount and checks the stored snapshot", () => {
    const session = fin.bookingGatewaySnapshot(2700, {
      id: "kyrgyzstan",
      iso_code: "KG",
      currency_code: "KGS",
      vat_percent: 10,
      local_units_per_sar: 75,
    }, {now: frozenAt});
    expect(() => fin.assertGatewayAmountMatches(session, 1)).toThrow(/PAYMENT_AMOUNT_MISMATCH/);
    expect(fin.assertGatewayAmountMatches(session, session.gateway_minor_sar)).toBe(3600);
  });
});

describe("push locale resolution", () => {
  const types = Object.keys(push.COPY || {}).filter(
    (key) => key.endsWith("_title") && push.COPY[key.replace(/_title$/, "_body")],
  );
  for (const locale of push.LOCALES) {
    for (const type of [
      "notification_order_accepted_title",
      "notification_trip_started_title",
      "notification_driver_arrived_title",
      "notification_order_cancelled_by_driver_title",
      "notification_private_message_title",
      "notification_payment_success_title",
      "notification_paid_order_admin_title",
      "notification_wallet_topup_title",
      "notification_new_order_driver_title",
    ]) {
      it(`resolves ${type} for ${locale}`, () => {
        const copy = push.resolvePair(type, locale, {
          driver: "Ali",
          bookingId: "B1",
          hours: "3",
          amount: "10",
          currency: "KGS",
          message: "hello",
        });
        expect(copy).not.toBeNull();
        expect(copy!.locale).toBe(locale);
        expect(copy!.title.trim().length).toBeGreaterThan(0);
        expect(copy!.body.trim().length).toBeGreaterThan(0);
        expect(copy!.title).not.toBe(type);
        expect(copy!.body).not.toContain("{driver}");
        expect(copy!.body).not.toContain("{bookingId}");
        if (locale !== "en") {
          const en = push.resolvePair(type, "en", {
            driver: "Ali",
            bookingId: "B1",
            hours: "3",
            amount: "10",
            currency: "KGS",
            message: "hello",
          });
          if (type !== "notification_private_message_title") {
            expect(copy!.title === en!.title && copy!.body === en!.body).toBe(false);
          }
        }
      });
    }
  }
  it("keeps the chat message as the private-message body", () => {
    const copy = push.resolvePair("notification_private_message_title", "ru", {
      message: "مرحبا",
    });
    expect(copy!.body).toBe("مرحبا");
    expect(copy!.title).not.toMatch(/^[A-Za-z ]+$/);
  });
  it("lists every paired notification type", () => {
    expect(types.length).toBeGreaterThan(5);
  });
});

import {createRequire} from "node:module";
import {describe, expect, it} from "vitest";

const require = createRequire(import.meta.url);
const fin = require("../../../shared/country_finance.js");

describe("country finance", () => {
  it("reads config and marks Saudi FX=1 when the field is absent", () => {
    const status = fin.financeStatus({
      iso_code: "SA",
      currency_code: "SAR",
      vat_percent: 15,
    });
    expect(status).toBe("CONFIGURED");
    expect(fin.resolvedFx(fin.readCountry({iso_code: "SA", currency_code: "SAR", vat_percent: 15}))).toBe(1);
  });

  it("does not invent FX for a non-SAR country", () => {
    expect(fin.financeStatus({iso_code: "KG", currency_code: "KGS", vat_percent: 10})).toBe("FX MISSING");
  });

  it("reports VAT MISSING without treating it as zero", () => {
    expect(fin.financeStatus({iso_code: "SA", currency_code: "SAR", local_units_per_sar: 1})).toBe("VAT MISSING");
  });

  it("rejects invalid VAT", () => {
    expect(() => fin.splitGross(100, 90)).toThrow(/INVALID_VAT/);
    expect(fin.financeStatus({iso_code: "SA", currency_code: "SAR", vat_percent: 90})).toBe("INVALID");
  });

  it("splits gross with 15% commission and country tax", () => {
    const line = fin.splitGross(2700, 15);
    expect(line.commission).toBe(405);
    expect(line.tax).toBe(405);
    expect(line.companyDue).toBe(810);
    expect(line.driverNet).toBe(1890);
  });

  it("converts local to SAR halalas and keeps the snapshot immutable inputs", () => {
    const fx = fin.localToGatewaySar(1500, 100);
    expect(fx.gatewayAmountSar).toBe(15);
    expect(fx.gatewayMinorSar).toBe(1500);
    expect(fx.gatewayCurrency).toBe("SAR");
    const later = fin.localToGatewaySar(1500, 80);
    expect(later.gatewayMinorSar).not.toBe(fx.gatewayMinorSar);
    expect(fx.fxLocalPerSar).toBe(100);
  });

  it("rounds halalas", () => {
    expect(fin.localToGatewaySar(1, 3).gatewayMinorSar).toBe(33);
  });

  it("sets the cash minimum to 50 SAR equivalent", () => {
    expect(fin.minCashLocal(1)).toBe(50);
    expect(fin.quickTopUpLocal(12.5)).toBe(625);
  });

  it("builds a WhatsApp link and Saudi fallback digits", () => {
    expect(fin.normalizeWhatsappDigits("+966533356126")).toBe("966533356126");
    expect(fin.whatsappHref(fin.SAUDI_FALLBACK_PHONE, "Touri Taxi")).toContain("https://wa.me/966533356126?text=");
    expect(fin.whatsappHref("https://wa.me/message/LHEPTGBXGS7UJ1", "x")).not.toContain("/message/");
  });

  it("online payment fails closed when FX is missing", () => {
    expect(() => fin.assertNewFinanceConfig({
      iso_code: "KG",
      currency_code: "KGS",
      vat_percent: 10,
    }, {requireOnline: true})).toThrow(/FX_CONFIG_MISSING/);
  });
});

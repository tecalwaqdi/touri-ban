/**
 * F07 Payment API — pure scope helpers (tsx + node:test; no vitest/rollup).
 */
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  assertResourceCountryAccess,
  resourceCountryFromDoc,
  type FinanceAccess,
} from "./verify.ts";
import { ApiError, PaymentErrorCode } from "../errors/codes.ts";

describe("payment-api F07 finance access scope", () => {
  it("global access allows any resource country", () => {
    const access: FinanceAccess = { kind: "global" };
    assert.doesNotThrow(() =>
      assertResourceCountryAccess(access, "countries/spain"),
    );
  });

  it("India country access DENY Spain session", () => {
    const access: FinanceAccess = {
      kind: "country",
      countryPath: "countries/india",
    };
    assert.throws(
      () => assertResourceCountryAccess(access, "countries/spain"),
      (err: unknown) =>
        err instanceof ApiError && err.code === PaymentErrorCode.FORBIDDEN,
    );
  });

  it("India country access ALLOW India session", () => {
    const access: FinanceAccess = {
      kind: "country",
      countryPath: "countries/india",
    };
    assert.doesNotThrow(() =>
      assertResourceCountryAccess(access, "countries/india"),
    );
  });

  it("country-scoped DENY when session has no country", () => {
    const access: FinanceAccess = {
      kind: "country",
      countryPath: "countries/india",
    };
    assert.throws(
      () => assertResourceCountryAccess(access, null),
      (err: unknown) =>
        err instanceof ApiError && err.code === PaymentErrorCode.FORBIDDEN,
    );
  });

  it("resourceCountryFromDoc reads countryPath / Rev_dolh", () => {
    assert.equal(
      resourceCountryFromDoc({ countryPath: "countries/india" }),
      "countries/india",
    );
    assert.equal(
      resourceCountryFromDoc({ Rev_dolh: { path: "countries/spain" } }),
      "countries/spain",
    );
  });
});

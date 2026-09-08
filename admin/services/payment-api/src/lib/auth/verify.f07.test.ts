/**
 * F07 Payment API — country_admin / rule=2 must not be global.
 */
import { describe, expect, it } from "vitest";
import {
  assertResourceCountryAccess,
  resourceCountryFromDoc,
  type FinanceAccess,
} from "./verify";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

function expectForbidden(fn: () => void) {
  try {
    fn();
    expect.fail("expected throw");
  } catch (e) {
    expect(e).toBeInstanceOf(ApiError);
    expect((e as ApiError).code).toBe(PaymentErrorCode.FORBIDDEN);
  }
}

describe("payment-api F07 finance access scope", () => {
  it("global access allows any resource country", () => {
    const access: FinanceAccess = { kind: "global" };
    expect(() =>
      assertResourceCountryAccess(access, "countries/spain"),
    ).not.toThrow();
  });

  it("India country access DENY Spain session", () => {
    const access: FinanceAccess = {
      kind: "country",
      countryPath: "countries/india",
    };
    expectForbidden(() =>
      assertResourceCountryAccess(access, "countries/spain"),
    );
  });

  it("India country access ALLOW India session", () => {
    const access: FinanceAccess = {
      kind: "country",
      countryPath: "countries/india",
    };
    expect(() =>
      assertResourceCountryAccess(access, "countries/india"),
    ).not.toThrow();
  });

  it("country-scoped DENY when session has no country", () => {
    const access: FinanceAccess = {
      kind: "country",
      countryPath: "countries/india",
    };
    expectForbidden(() => assertResourceCountryAccess(access, null));
  });

  it("resourceCountryFromDoc reads countryPath / Rev_dolh", () => {
    expect(resourceCountryFromDoc({ countryPath: "countries/india" })).toBe(
      "countries/india",
    );
    expect(
      resourceCountryFromDoc({ Rev_dolh: { path: "countries/spain" } }),
    ).toBe("countries/spain");
  });
});

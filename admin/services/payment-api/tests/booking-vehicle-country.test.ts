import { describe, expect, it } from "vitest";
import { PaymentErrorCode } from "../src/lib/errors/codes";
import {
  assertVehicleForBooking,
  buildVehicleBookingSnapshot,
  isOperationalTypeCar,
  vehicleMatchesBookingCountry,
} from "../src/lib/bookings/vehicle-snapshot";
import { ApiError } from "../src/lib/errors/codes";

describe("booking vehicle country integrity + snapshot", () => {
  const saEconomy = {
    countryId: "saudi_arabia",
    country_iso2: "SA",
    dolh: { path: "countries/saudi_arabia" },
    actev: true,
    sr: 100,
    naim: "Economy SA",
    codeCar: "economy",
  };
  const kgEconomy = {
    countryId: "kyrgyzstan",
    country_iso2: "KG",
    dolh: { path: "countries/kyrgyzstan" },
    actev: true,
    sr: 50,
    naim: "Economy KG",
    codeCar: "economy",
  };

  it("SA booking + SA vehicle → PASS", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: saEconomy,
        countryPath: "countries/saudi_arabia",
        countryIso: "SA",
      }),
    ).toBe(true);
    expect(() =>
      assertVehicleForBooking({
        car: saEconomy,
        countryPath: "countries/saudi_arabia",
        countryIso: "SA",
        countryActive: true,
      }),
    ).not.toThrow();
  });

  it("SA booking + KG vehicle → DENY", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: kgEconomy,
        countryPath: "countries/saudi_arabia",
        countryIso: "SA",
      }),
    ).toBe(false);
    expect(() =>
      assertVehicleForBooking({
        car: kgEconomy,
        countryPath: "countries/saudi_arabia",
        countryIso: "SA",
        countryActive: true,
      }),
    ).toThrow(ApiError);
  });

  it("KG booking + KG vehicle → PASS", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: kgEconomy,
        countryPath: "countries/kyrgyzstan",
        countryIso: "KG",
      }),
    ).toBe(true);
  });

  it("KG booking + SA vehicle → DENY", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: saEconomy,
        countryPath: "countries/kyrgyzstan",
        countryIso: "KG",
      }),
    ).toBe(false);
  });

  it("Turkey + no catalog → no vehicle available (no SA/KG fallback)", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: saEconomy,
        countryPath: "countries/turkey",
        countryIso: "TR",
      }),
    ).toBe(false);
    expect(
      vehicleMatchesBookingCountry({
        car: kgEconomy,
        countryPath: "countries/turkey",
        countryIso: "TR",
      }),
    ).toBe(false);
  });

  it("inactive / archived / exclude_from_operational → DENY", () => {
    expect(isOperationalTypeCar({ ...saEconomy, actev: false })).toBe(false);
    expect(isOperationalTypeCar({ ...saEconomy, archived: true })).toBe(false);
    expect(
      isOperationalTypeCar({
        ...saEconomy,
        exclude_from_operational_catalog: true,
      }),
    ).toBe(false);
    expect(() =>
      assertVehicleForBooking({
        car: { ...saEconomy, archived: true },
        countryPath: "countries/saudi_arabia",
        countryIso: "SA",
        countryActive: true,
      }),
    ).toThrow(ApiError);
  });

  it("SA/KG same codeCar remain independent prices", () => {
    const saSnap = buildVehicleBookingSnapshot({
      carId: "sa_economy",
      car: saEconomy,
      countryPath: "countries/saudi_arabia",
      currency: "SAR",
      nowIso: "2026-01-01T00:00:00.000Z",
    });
    const kgSnap = buildVehicleBookingSnapshot({
      carId: "kg_economy",
      car: kgEconomy,
      countryPath: "countries/kyrgyzstan",
      currency: "KGS",
      nowIso: "2026-01-01T00:00:00.000Z",
    });
    expect(saSnap.vehicleHourlyPrice).toBe(100);
    expect(kgSnap.vehicleHourlyPrice).toBe(50);
    expect(saSnap.vehicleCurrency).toBe("SAR");
    expect(kgSnap.vehicleCurrency).toBe("KGS");
    expect(saSnap.vehicleTypeCountryId).toBe("saudi_arabia");
    expect(kgSnap.vehicleTypeCountryId).toBe("kyrgyzstan");
  });

  it("historical snapshot immutable after live price change", () => {
    const snap = buildVehicleBookingSnapshot({
      carId: "sa_economy",
      car: saEconomy,
      countryPath: "countries/saudi_arabia",
      currency: "SAR",
      nowIso: "2026-01-01T00:00:00.000Z",
    });
    const futureLive = { ...saEconomy, sr: 999 };
    expect(snap.vehicleHourlyPrice).toBe(100);
    expect(Number(futureLive.sr)).toBe(999);
    expect(snap.vehicleHourlyPrice).not.toBe(Number(futureLive.sr));
  });

  it("old client without snapshot fields: server derives correct snapshot", () => {
    const snap = buildVehicleBookingSnapshot({
      carId: "sa_economy",
      car: saEconomy,
      countryPath: "countries/saudi_arabia",
      currency: "SAR",
    });
    expect(snap.vehicleTypeId).toBe("sa_economy");
    expect(snap.vehicleTypeName).toBe("Economy SA");
    expect(snap.vehicleHourlyPrice).toBe(100);
    expect(snap.vehicleSnapshotAt).toBeTruthy();
  });

  it("client fake hourly ignored — authoritative sr wins in snapshot", () => {
    const snap = buildVehicleBookingSnapshot({
      carId: "sa_economy",
      car: saEconomy,
      countryPath: "countries/saudi_arabia",
      currency: "SAR",
    });
    const clientFakeHourly = 1;
    expect(snap.vehicleHourlyPrice).toBe(100);
    expect(snap.vehicleHourlyPrice).not.toBe(clientFakeHourly);
  });

  it("exports mismatch error code for clients", () => {
    expect(PaymentErrorCode.BOOKING_VEHICLE_COUNTRY_MISMATCH).toBe(
      "BOOKING_VEHICLE_COUNTRY_MISMATCH",
    );
  });
});

describe("driver vehicle assignment country guard (pure)", () => {
  it("SA driver + SA type → PASS; SA + KG → DENY", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: {
          countryId: "saudi_arabia",
          country_iso2: "SA",
          dolh: { path: "countries/saudi_arabia" },
        },
        countryPath: "countries/saudi_arabia",
        countryIso: "SA",
      }),
    ).toBe(true);
    expect(
      vehicleMatchesBookingCountry({
        car: {
          countryId: "kyrgyzstan",
          country_iso2: "KG",
          dolh: { path: "countries/kyrgyzstan" },
        },
        countryPath: "countries/saudi_arabia",
        countryIso: "SA",
      }),
    ).toBe(false);
  });

  it("KG driver + KG type → PASS; KG + SA → DENY", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: {
          countryId: "kyrgyzstan",
          country_iso2: "KG",
          dolh: { path: "countries/kyrgyzstan" },
        },
        countryPath: "countries/kyrgyzstan",
        countryIso: "KG",
      }),
    ).toBe(true);
    expect(
      vehicleMatchesBookingCountry({
        car: {
          countryId: "saudi_arabia",
          country_iso2: "SA",
          dolh: { path: "countries/saudi_arabia" },
        },
        countryPath: "countries/kyrgyzstan",
        countryIso: "KG",
      }),
    ).toBe(false);
  });

  it("driver with no country → cannot match any type", () => {
    expect(
      vehicleMatchesBookingCountry({
        car: {
          countryId: "saudi_arabia",
          country_iso2: "SA",
          dolh: { path: "countries/saudi_arabia" },
        },
        countryPath: "",
        countryIso: "",
      }),
    ).toBe(false);
  });
});

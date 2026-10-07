import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";

export type TypeCarLike = {
  countryId?: unknown;
  country_iso2?: unknown;
  dolh?: unknown;
  actev?: unknown;
  acctev?: unknown;
  archived?: unknown;
  exclude_from_operational_catalog?: unknown;
  sr?: unknown;
  naim?: unknown;
  name?: unknown;
  codeCar?: unknown;
};

export function countryIdFromPath(countryPath: string): string {
  const parts = String(countryPath || "")
    .split("/")
    .filter(Boolean);
  return parts.length ? parts[parts.length - 1]! : "";
}

export function isOperationalTypeCar(car: TypeCarLike): boolean {
  if (car.archived === true) return false;
  if (car.exclude_from_operational_catalog === true) return false;
  if (Object.prototype.hasOwnProperty.call(car, "actev")) {
    return car.actev === true;
  }
  if (Object.prototype.hasOwnProperty.call(car, "acctev")) {
    return car.acctev === true;
  }
  return true;
}

/**
 * Country match for booking/driver assignment.
 * No SA/KG/global fallback — empty catalog cannot borrow another country.
 */
export function vehicleMatchesBookingCountry(input: {
  car: TypeCarLike;
  countryPath: string;
  countryIso: string;
}): boolean {
  const countryId = countryIdFromPath(input.countryPath);
  const myCountryId = String(input.car.countryId || "").trim();
  if (myCountryId && countryId && myCountryId === countryId) return true;

  const carIso = String(input.car.country_iso2 || "")
    .trim()
    .toUpperCase();
  const dolh = input.car.dolh as { path?: string } | string | null | undefined;
  const dolhPath =
    dolh && typeof dolh === "object" && typeof dolh.path === "string"
      ? dolh.path
      : typeof dolh === "string"
        ? dolh
        : "";
  const isoMatch = Boolean(
    carIso && input.countryIso && carIso === input.countryIso,
  );
  const refMatch = Boolean(dolhPath && dolhPath === input.countryPath);
  return isoMatch || refMatch;
}

export function assertVehicleForBooking(input: {
  car: TypeCarLike;
  countryPath: string;
  countryIso: string;
  countryActive: boolean;
}): void {
  if (!input.countryActive || !isOperationalTypeCar(input.car)) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 400);
  }
  if (
    !vehicleMatchesBookingCountry({
      car: input.car,
      countryPath: input.countryPath,
      countryIso: input.countryIso,
    })
  ) {
    throw new ApiError(
      PaymentErrorCode.BOOKING_VEHICLE_COUNTRY_MISMATCH,
      400,
      "booking_vehicle_country_mismatch",
    );
  }
}

export type VehicleBookingSnapshot = {
  vehicleTypeId: string;
  vehicleTypeName: string;
  vehicleTypeCountryId: string;
  vehicleHourlyPrice: number | null;
  vehicleCurrency: string;
  vehicleSnapshotAt: string;
};

/** Immutable booking evidence — derived server-side; not a live price source. */
export function buildVehicleBookingSnapshot(input: {
  carId: string;
  car: TypeCarLike;
  countryPath: string;
  currency: string;
  nowIso?: string;
}): VehicleBookingSnapshot {
  const resolvedCountryId =
    String(input.car.countryId || "").trim() ||
    countryIdFromPath(input.countryPath);
  const name = String(
    input.car.naim || input.car.name || input.car.codeCar || input.carId || "",
  ).trim();
  const hourly = Number(input.car.sr);
  return {
    vehicleTypeId: String(input.carId || "").trim(),
    vehicleTypeName: name,
    vehicleTypeCountryId: resolvedCountryId,
    vehicleHourlyPrice: Number.isFinite(hourly) ? hourly : null,
    vehicleCurrency:
      String(input.currency || "SAR").trim().toUpperCase() || "SAR",
    vehicleSnapshotAt: input.nowIso || new Date().toISOString(),
  };
}

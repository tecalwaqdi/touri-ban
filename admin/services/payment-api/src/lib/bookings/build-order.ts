import { FieldValue, GeoPoint, Timestamp } from "firebase-admin/firestore";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { COLLECTIONS, db } from "@/lib/firebase/admin";

export type BookingDraft = {
  pickupLat: number;
  pickupLng: number;
  cityPath?: string | null;
  villagePath?: string | null;
  cityName?: string | null;
  carName?: string | null;
  schedule?: string | null;
  scheduleLabel?: string | null;
  driverGuide?: boolean;
  tripType?: string | null;
  luggageEstimate?: number;
  routeProvider?: string | null;
  plannedDistanceMeters?: number;
  plannedDurationSeconds?: number;
  plannedWaypoints?: Array<{ lat: number; lng: number }>;
  stops?: Array<{
    name?: string;
    address?: string;
    city?: string;
    lat?: number;
    lng?: number;
    placePath?: string;
  }>;
};

function sanitizeString(value: unknown, maxLen: number): string {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLen);
}

function safeCoordinate(value: unknown, min: number, max: number, field: string): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
    throw new ApiError(
      PaymentErrorCode.INVALID_REQUEST,
      400,
      `Invalid ${field}`,
    );
  }
  return parsed;
}

function documentPath(value: string, collectionName: string): string {
  const parts = value.trim().split("/");
  if (parts.length !== 2 || parts[0] !== collectionName || !parts[1]) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, `Invalid ${collectionName}`);
  }
  return value.trim();
}

/** Validate and normalize booking draft from Flutter (same shape as CF). */
export function parseBookingDraft(raw: unknown): BookingDraft {
  if (!raw || typeof raw !== "object") {
    throw new ApiError(
      PaymentErrorCode.BOOKING_NOT_PAYABLE,
      400,
      "Booking draft is required for card payment",
    );
  }
  const booking = raw as Record<string, unknown>;
  const pickupLat = safeCoordinate(booking.pickupLat, -90, 90, "pickup latitude");
  const pickupLng = safeCoordinate(booking.pickupLng, -180, 180, "pickup longitude");

  const waypoints = Array.isArray(booking.plannedWaypoints)
    ? booking.plannedWaypoints.slice(0, 30).map((point) => {
        const p = point as { lat?: number; lng?: number };
        return {
          lat: safeCoordinate(p.lat, -90, 90, "waypoint latitude"),
          lng: safeCoordinate(p.lng, -180, 180, "waypoint longitude"),
        };
      })
    : [];

  const stops = Array.isArray(booking.stops)
    ? booking.stops.slice(0, 30).map((stop) => {
        const s = stop as Record<string, unknown>;
        const out: {
          name?: string;
          address?: string;
          city?: string;
          lat?: number;
          lng?: number;
          placePath?: string;
        } = {
          name: sanitizeString(s.name, 180),
          address: sanitizeString(s.address, 300),
          city: sanitizeString(s.city, 160),
        };
        if (s.lat != null && s.lng != null) {
          out.lat = safeCoordinate(s.lat, -90, 90, "stop latitude");
          out.lng = safeCoordinate(s.lng, -180, 180, "stop longitude");
        }
        if (typeof s.placePath === "string" && s.placePath) {
          out.placePath = documentPath(s.placePath, "mkan");
        }
        return out;
      })
    : [];

  return {
    pickupLat,
    pickupLng,
    cityPath: booking.cityPath ? documentPath(String(booking.cityPath), "cities") : null,
    villagePath: booking.villagePath
      ? documentPath(String(booking.villagePath), "villages")
      : null,
    cityName: sanitizeString(booking.cityName, 180) || null,
    carName: sanitizeString(booking.carName, 160) || null,
    schedule: typeof booking.schedule === "string" ? booking.schedule : null,
    scheduleLabel: sanitizeString(booking.scheduleLabel, 180) || null,
    driverGuide: booking.driverGuide === true,
    tripType: sanitizeString(booking.tripType, 32) || "one_way",
    luggageEstimate: Math.max(0, Number(booking.luggageEstimate) || 0),
    routeProvider: sanitizeString(booking.routeProvider, 32) || "waypoints",
    plannedDistanceMeters: Math.max(0, Number(booking.plannedDistanceMeters) || 0),
    plannedDurationSeconds: Math.max(0, Number(booking.plannedDurationSeconds) || 0),
    plannedWaypoints: waypoints,
    stops,
  };
}

function optionalTimestamp(value: string | null | undefined) {
  if (!value) return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, "Invalid booking schedule");
  }
  return Timestamp.fromDate(parsed);
}

export type SessionQuote = {
  user_id: string;
  carPath: string;
  countryPath: string;
  amount_halalas?: number;
  amount_minor?: number;
  currency?: string;
  bookingHours?: number;
  additionalHours?: number;
  baseFareHalalas?: number;
  appFeeHalalas?: number;
  vatHalalas?: number;
  discountHalalas?: number;
  provider_order_ref?: string;
  booking_draft?: BookingDraft;
};

/**
 * Build production-compatible order fields matching finalizeNGeniusBooking / createCashBooking.
 */
export async function buildPaidOnlineOrderData(
  sessionId: string,
  session: SessionQuote,
  draft: BookingDraft,
): Promise<Record<string, unknown>> {
  const uid = session.user_id;
  if (!uid || !session.carPath || !session.countryPath) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 400);
  }

  const amountMinor = Number(session.amount_minor ?? session.amount_halalas);
  if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
    throw new ApiError(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH, 400);
  }

  const userRef = db().collection(COLLECTIONS.users).doc(uid);
  const userSnap = await userRef.get();
  const user = userSnap.exists ? userSnap.data() || {} : {};
  const now = FieldValue.serverTimestamp();
  const hours = Math.max(1, Number(session.bookingHours) || 1);
  const additionalHours = Math.max(0, Number(session.additionalHours) || 0);
  const baseFare = Number(session.baseFareHalalas) || amountMinor;
  const appFee = Number(session.appFeeHalalas) || 0;
  const vat = Number(session.vatHalalas) || 0;
  const discount = Number(session.discountHalalas) || 0;
  // Driver net mirrors client TouryPriceQuote (base − app fee − vat).
  const driverNetMinor = Math.max(0, baseFare - appFee - vat);

  const stops = (draft.stops || []).map((stop) => {
    const result: Record<string, unknown> = {
      naim: stop.name || "",
      address: stop.address || "",
      textivill: stop.city || "",
      user: userRef,
    };
    if (stop.lat != null && stop.lng != null) {
      result.loceshn = new GeoPoint(stop.lat, stop.lng);
    }
    if (stop.placePath) {
      result.Revmkan = db().doc(stop.placePath);
    }
    return result;
  });

  const orderData: Record<string, unknown> = {
    USER: userRef,
    total: amountMinor / 100,
    amount_halalas: amountMinor,
    currency: session.currency || "SAR",
    data_order: now,
    // Server-side accept window (1 hour). Absolute timestamp — not a Flutter timer.
    acceptanceDeadline: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
    acceptance_deadline_ms: Date.now() + 60 * 60 * 1000,
    LOKESHN: new GeoPoint(draft.pickupLat, draft.pickupLng),
    mapuser: new GeoPoint(draft.pickupLat, draft.pickupLng),
    originLatitude: draft.pickupLat,
    originLongitude: draft.pickupLng,
    carRev: db().doc(session.carPath),
    Rev_dolh: db().doc(session.countryPath),
    cities_user_now: draft.cityPath ? db().doc(draft.cityPath) : null,
    vill: draft.villagePath ? db().doc(draft.villagePath) : null,
    vill_text: draft.cityName || "",
    cartext: draft.carName || "",
    naim_user_text: sanitizeString(user.display_name || user.name, 160),
    phone_numper: Number(user.phone_n || user.phoneN || 0),
    imgProfileClent: sanitizeString(user.photo_url || user.photoUrl, 500),
    total_taim: hours,
    additional_hours: additionalHours,
    total_app: appFee / 100,
    total_vat: vat / 100,
    ksm: discount / 100,
    // Hourly rate (major) — same formula as CF finalizeNGeniusBooking
    SrSAAH: baseFare / hours / 100,
    // Pricing snapshot used by admin finance / reporting (legacy field names)
    total_mndob2: baseFare / 100,
    total_mndob: driverNetMinor / 100,
    pricing_quote_halalas: amountMinor,
    pricing_hourly_halalas: Math.round(baseFare / hours),
    pricing_hours: hours,
    DriverGuide: draft.driverGuide === true,
    Schedule: optionalTimestamp(draft.schedule),
    fullSchedule: draft.scheduleLabel || "",
    listAmakn: stops,
    plannedWaypoints: draft.plannedWaypoints || [],
    trip_type: draft.tripType || "one_way",
    luggage_estimate: draft.luggageEstimate || 0,
    routeProvider: draft.routeProvider || "waypoints",
    routeVersion: 1,
    plannedDistanceMeters: draft.plannedDistanceMeters || 0,
    plannedDurationSeconds: draft.plannedDurationSeconds || 0,
    IDorder: sessionId.slice(0, 12).toUpperCase(),
    // Match CF finalizeNGeniusBooking lifecycle fields
    halh_order: "Paid",
    halh: "paid",
    halh_text: "بإنتظار قبول المندوب",
    status_code: "pending_driver",
    payment_status: "paid",
    PaymentMethod: "OnlinePayment",
    ngeniusOrderId: session.provider_order_ref || sessionId,
    payment_session_id: sessionId,
    payment_verified_at: now,
    ALLNOW: true,
    ActiveOrder: false,
    ReviewMndonsend: false,
    backend_source: "external_api",
    pricing_authority: "server",
    created_by_function: true,
  };

  Object.keys(orderData).forEach((key) => {
    if (orderData[key] == null || orderData[key] === "") {
      // Keep empty strings for some text fields used by UI; drop null refs only
      if (orderData[key] == null) delete orderData[key];
    }
  });

  return orderData;
}

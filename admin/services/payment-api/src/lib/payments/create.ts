import { FieldValue } from "firebase-admin/firestore";
import { z } from "zod";
import { verifyBearerToken } from "@/lib/auth/verify";
import { COLLECTIONS, db, sessionIdFor } from "@/lib/firebase/admin";
import {
  createNGeniusOrder,
  isHostedPaymentPageUrl,
  paymentHrefHost,
} from "@/lib/ngenius/client";
import { calculateBookingQuote } from "@/lib/pricing/booking";
import { getEnv } from "@/lib/security/env";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { PaymentStatus, toLegacyStatus } from "@/lib/payments/status";
import { logger } from "@/lib/logging/logger";
import { parseBookingDraft } from "@/lib/bookings/build-order";
import {
  ensureUnpaidBookingOrder,
  loadPayableUnpaidOrder,
} from "@/lib/bookings/unpaid-order";
import { normalizePaymentPurpose } from "@/lib/payments/guards";
import { isFirebaseAdcMode } from "@/lib/security/env";

function backendSourceLabel(): string {
  return isFirebaseAdcMode() ? "firebase_functions" : "external_api";
}

const createSchema = z.object({
  paymentMethod: z.literal("card"),
  paymentPurpose: z
    .enum([
      "booking",
      "booking_payment",
      "wallet",
      "wallet_topup",
      "extra_hours",
    ])
    .default("booking"),
  locale: z.enum(["ar", "en", "ru", "ky"]).optional(),
  idempotencyKey: z.string().min(8).max(96).regex(/^[a-zA-Z0-9_.:-]+$/),
  // Booking intent identifiers only — never trust client amount
  carPath: z.string().optional(),
  countryPath: z.string().optional(),
  bookingHours: z.number().int().optional(),
  additionalHours: z.number().int().optional(),
  orderPath: z.string().optional(),
  extraHours: z.number().int().optional(),
  packageId: z.string().optional(),
  countryCode: z.string().optional(),
  email: z.string().email().optional(),
  description: z.string().max(120).optional(),
  bookingDraftId: z.string().max(128).optional(),
  /** Required for booking purpose — trip details for webhook/finalize */
  booking: z.unknown().optional(),
  /** Wallet top-up: package id or server-validated amountMajor (SAR). */
  amountMajor: z.number().positive().optional(),
});

const REUSABLE_SESSION_STATUSES = new Set([
  PaymentStatus.created,
  PaymentStatus.pending,
  PaymentStatus.authentication_required,
  "created",
  "pending",
  "authentication_required",
]);

const TERMINAL_PAID_STATUSES = new Set([
  PaymentStatus.paid,
  PaymentStatus.captured,
  PaymentStatus.authorized,
  "paid",
  "captured",
  "authorized",
]);

function documentPath(value: string, collectionName: string): string {
  const parts = value.trim().split("/");
  if (parts.length !== 2 || parts[0] !== collectionName || !parts[1]) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400);
  }
  return value.trim();
}

async function quoteBooking(data: z.infer<typeof createSchema>) {
  if (!data.carPath || !data.countryPath || data.bookingHours == null) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 400);
  }
  const carPath = documentPath(data.carPath, "type_car");
  const countryPath = documentPath(data.countryPath, "countries");
  const [carSnap, countrySnap] = await Promise.all([
    db().doc(carPath).get(),
    db().doc(countryPath).get(),
  ]);
  if (!carSnap.exists || !countrySnap.exists) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 400);
  }
  const car = carSnap.data() || {};
  const country = countrySnap.data() || {};
  if (car.actev === false || car.acctev === false || country.acctev === false) {
    throw new ApiError(PaymentErrorCode.BOOKING_NOT_PAYABLE, 400);
  }

  const currency = String(
    country.currency_code ||
      country.currencyCode ||
      country.currency ||
      country.Currency ||
      "SAR",
  )
    .trim()
    .toUpperCase() || "SAR";
  const quote = calculateBookingQuote({
    hourlyRateMajor: Number(car.sr),
    bookingHours: data.bookingHours,
    additionalHours: data.additionalHours ?? 0,
    discountPercentOnAdditional: Number(car.NesbahkKsm) || 0,
    discountCapMajor: Number(car.TotalKsmUb) || 0,
    platformFeePercent: 15,
    vatPercent: Number(country.vat) || 0,
    applyVat: country.isvat === true,
    currency,
  });

  return {
    ...quote,
    carPath,
    countryPath,
    // legacy field name for compatibility with existing Flutter/CF readers
    amount_halalas: quote.amountMinor,
    baseFareHalalas: quote.baseFareMinor,
    appFeeHalalas: quote.platformFeeMinor,
    vatHalalas: quote.vatMinor,
    discountHalalas: quote.discountMinor,
  };
}

async function quoteWalletTopUp(data: z.infer<typeof createSchema>) {
  // Prefer curated packages from settings; allow amountMajor only for allow-listed values.
  const allowedMajors = new Set([100, 200, 300, 500]);
  let amountMajor = 0;
  if (data.packageId) {
    const packSnap = await db().doc("settings/wallet_topup_packages").get();
    const packs = (packSnap.data()?.packages || packSnap.data()?.items || []) as Array<{
      id?: string;
      amount?: number;
      amountSar?: number;
    }>;
    const found = packs.find((p) => String(p.id) === String(data.packageId));
    amountMajor = Number(found?.amountSar ?? found?.amount ?? 0);
  } else if (data.amountMajor != null) {
    amountMajor = Number(data.amountMajor);
  }
  if (!Number.isFinite(amountMajor) || !allowedMajors.has(amountMajor)) {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, "Invalid wallet top-up amount");
  }
  const amountMinor = Math.round(amountMajor * 100);
  return {
    amountMinor,
    currency: "SAR",
    amount_halalas: amountMinor,
    bookingHours: 0,
    additionalHours: 0,
    baseFareHalalas: amountMinor,
    appFeeHalalas: 0,
    vatHalalas: 0,
    discountHalalas: 0,
    carPath: null as string | null,
    countryPath: null as string | null,
  };
}

export function canReuseHostedPaymentSession(
  existing: Record<string, unknown>,
  currentEnv: string,
): boolean {
  const status = String(existing.normalized_status || existing.status || "");
  if (TERMINAL_PAID_STATUSES.has(status)) return false;
  if (!REUSABLE_SESSION_STATUSES.has(status)) return false;
  const sessionEnv = String(existing.environment || "");
  if (sessionEnv && sessionEnv !== currentEnv) return false;
  const url = String(existing.payment_url || existing.three_ds_url || "");
  return isHostedPaymentPageUrl(url);
}

export async function handleCreatePayment(req: Request) {
  const user = await verifyBearerToken(req.headers.get("authorization"));
  let body: z.infer<typeof createSchema>;
  try {
    body = createSchema.parse(await req.json());
  } catch {
    throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400);
  }
  const env = getEnv();
  const purpose = normalizePaymentPurpose(body.paymentPurpose);

  let unpaidOrderId: string | null = null;
  let bookingDraft =
    purpose === "booking" && body.booking != null
      ? parseBookingDraft(body.booking)
      : null;

  let verifiedQuote:
    | Awaited<ReturnType<typeof quoteBooking>>
    | Awaited<ReturnType<typeof quoteWalletTopUp>>;

  if (purpose === "wallet") {
    verifiedQuote = await quoteWalletTopUp(body);
  } else if (body.orderPath) {
    // Retry payment for an existing unpaid order — use server-stored pricing.
    const unpaid = await loadPayableUnpaidOrder({
      orderPath: body.orderPath,
      userId: user.uid,
    });
    unpaidOrderId = unpaid.orderId;
    // Re-quote from car/country on the order (never trust client amount).
    verifiedQuote = await quoteBooking({
      ...body,
      carPath: unpaid.carPath,
      countryPath: unpaid.countryPath,
      bookingHours: unpaid.bookingHours,
      additionalHours: unpaid.additionalHours,
    });
    if (Number(verifiedQuote.amountMinor) !== Number(unpaid.amountMinor)) {
      // Keep the amount already shown on the unpaid order to avoid surprise charges.
      verifiedQuote = {
        ...verifiedQuote,
        amountMinor: unpaid.amountMinor,
        amount_halalas: unpaid.amountMinor,
      };
    }
    if (unpaid.draft) {
      try {
        bookingDraft = parseBookingDraft(unpaid.draft);
      } catch {
        // Order already has route fields; session draft optional for activation.
      }
    }
    if (!bookingDraft && body.booking != null) {
      bookingDraft = parseBookingDraft(body.booking);
    }
    if (!bookingDraft) {
      throw new ApiError(
        PaymentErrorCode.BOOKING_NOT_PAYABLE,
        409,
        "Unpaid order is missing booking draft",
      );
    }
  } else {
    bookingDraft = parseBookingDraft(body.booking);
    verifiedQuote = await quoteBooking(body);
  }

  const sessionId = sessionIdFor(user.uid, body.idempotencyKey);
  const sessionRef = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);

  let existingData: Record<string, unknown> | undefined;
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(sessionRef);
    if (snap.exists) {
      existingData = snap.data() as Record<string, unknown>;
      return;
    }
    tx.create(sessionRef, {
      user_id: user.uid,
      purpose,
      purpose_alias: body.paymentPurpose,
      provider: "ngenius",
      backend_source: backendSourceLabel(),
      environment: env.NGENIUS_ENV,
      idempotency_key_hash: sessionId,
      amount_halalas: verifiedQuote.amountMinor,
      amount_minor: verifiedQuote.amountMinor,
      currency: verifiedQuote.currency,
      status: PaymentStatus.created,
      normalized_status: PaymentStatus.created,
      booking_draft_id: body.bookingDraftId || null,
      booking_draft: bookingDraft,
      booking_created: false,
      wallet_credited: false,
      carPath: verifiedQuote.carPath,
      countryPath: verifiedQuote.countryPath,
      bookingHours: verifiedQuote.bookingHours,
      additionalHours: verifiedQuote.additionalHours,
      baseFareHalalas: verifiedQuote.baseFareHalalas,
      appFeeHalalas: verifiedQuote.appFeeHalalas,
      vatHalalas: verifiedQuote.vatHalalas,
      discountHalalas: verifiedQuote.discountHalalas,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
  });

  if (existingData) {
    if (existingData.user_id !== user.uid) {
      throw new ApiError(PaymentErrorCode.FORBIDDEN, 403);
    }

    const status = String(existingData.normalized_status || existingData.status);
    if (TERMINAL_PAID_STATUSES.has(status)) {
      return {
        id: sessionId,
        status,
        amountMinor: Number(existingData.amount_minor ?? existingData.amount_halalas),
        currency: String(existingData.currency),
        paymentUrl: null,
        threeDsUrl: null,
        backendSource: String(existingData.backend_source || backendSourceLabel()),
        environment: String(existingData.environment || env.NGENIUS_ENV),
        purpose,
        bookingId: existingData.booking_id || existingData.unpaid_order_id || sessionId,
        bookingStatus: "paid",
        bookingCreated: Boolean(existingData.booking_created),
      };
    }

    if (canReuseHostedPaymentSession(existingData, env.NGENIUS_ENV)) {
      const url = String(existingData.payment_url || existingData.three_ds_url);
      logger.info("payment_session_hpp_reused", {
        sessionIdPrefix: sessionId.slice(0, 8),
        environment: env.NGENIUS_ENV,
        paymentHrefHost: paymentHrefHost(url),
        status,
      });
      const reuseBookingId = String(
        existingData.booking_id ||
          existingData.unpaid_order_id ||
          unpaidOrderId ||
          sessionId,
      );
      if (purpose === "booking" && bookingDraft) {
        await ensureUnpaidBookingOrder({
          orderId: reuseBookingId,
          sessionId,
          userId: user.uid,
          sessionQuote: {
            user_id: user.uid,
            carPath: String(verifiedQuote.carPath),
            countryPath: String(verifiedQuote.countryPath),
            amount_minor: Number(
              existingData.amount_minor ?? existingData.amount_halalas,
            ),
            amount_halalas: Number(
              existingData.amount_minor ?? existingData.amount_halalas,
            ),
            currency: String(existingData.currency),
            bookingHours: Number(verifiedQuote.bookingHours || 0),
            additionalHours: Number(verifiedQuote.additionalHours || 0),
            baseFareHalalas: Number(verifiedQuote.baseFareHalalas || 0),
            appFeeHalalas: Number(verifiedQuote.appFeeHalalas || 0),
            vatHalalas: Number(verifiedQuote.vatHalalas || 0),
            discountHalalas: Number(verifiedQuote.discountHalalas || 0),
            provider_order_ref: existingData.provider_order_ref
              ? String(existingData.provider_order_ref)
              : undefined,
            booking_draft: bookingDraft,
          },
          draft: bookingDraft,
        });
      }
      return {
        id: sessionId,
        status,
        amountMinor: Number(existingData.amount_minor ?? existingData.amount_halalas),
        currency: String(existingData.currency),
        paymentUrl: url,
        threeDsUrl: url,
        backendSource: String(existingData.backend_source || backendSourceLabel()),
        environment: String(existingData.environment || env.NGENIUS_ENV),
        purpose,
        bookingId: reuseBookingId,
        bookingStatus: "payment_pending",
      };
    }

    logger.warn("payment_session_hpp_refresh", {
      sessionIdPrefix: sessionId.slice(0, 8),
      environment: env.NGENIUS_ENV,
      priorStatus: status,
      priorEnv: existingData.environment || null,
      hadValidHpp: isHostedPaymentPageUrl(
        String(existingData.payment_url || existingData.three_ds_url || ""),
      ),
    });
    // Fall through: mint a fresh N-Genius order on the same session doc.
  }

  try {
    const order = await createNGeniusOrder({
      amountMinor: verifiedQuote.amountMinor,
      currency: verifiedQuote.currency,
      email: body.email || user.email,
      merchantOrderReference: body.description || `Toury-${sessionId.slice(0, 16)}`,
    });
    await sessionRef.set(
      {
        provider_order_ref: order.providerOrderRef,
        payment_url: order.paymentUrl,
        status: toLegacyStatus(PaymentStatus.pending),
        normalized_status: PaymentStatus.pending,
        // Hosted Payment Page URL for Flutter WebView (exact provider href).
        three_ds_url: order.paymentUrl,
        gateway_state: order.rawState,
        outlet_reference: env.NGENIUS_OUTLET_REF,
        environment: env.NGENIUS_ENV,
        purpose,
        hpp_refreshed_at: existingData
          ? FieldValue.serverTimestamp()
          : undefined,
        failure_code: FieldValue.delete(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    let bookingId: string | null = unpaidOrderId;
    if (purpose === "booking" && bookingDraft) {
      const ensured = await ensureUnpaidBookingOrder({
        orderId: unpaidOrderId || sessionId,
        sessionId,
        userId: user.uid,
        sessionQuote: {
          user_id: user.uid,
          carPath: String(verifiedQuote.carPath),
          countryPath: String(verifiedQuote.countryPath),
          amount_minor: verifiedQuote.amountMinor,
          amount_halalas: verifiedQuote.amountMinor,
          currency: verifiedQuote.currency,
          bookingHours: Number(verifiedQuote.bookingHours || 0),
          additionalHours: Number(verifiedQuote.additionalHours || 0),
          baseFareHalalas: Number(verifiedQuote.baseFareHalalas || 0),
          appFeeHalalas: Number(verifiedQuote.appFeeHalalas || 0),
          vatHalalas: Number(verifiedQuote.vatHalalas || 0),
          discountHalalas: Number(verifiedQuote.discountHalalas || 0),
          provider_order_ref: order.providerOrderRef,
          booking_draft: bookingDraft,
        },
        draft: bookingDraft,
      });
      bookingId = ensured.orderId;
    }

    return {
      id: sessionId,
      status: order.rawState?.toUpperCase().includes("3DS")
        ? PaymentStatus.authentication_required
        : PaymentStatus.pending,
      amountMinor: verifiedQuote.amountMinor,
      currency: verifiedQuote.currency,
      paymentUrl: order.paymentUrl,
      threeDsUrl: order.paymentUrl,
      backendSource: backendSourceLabel(),
      environment: env.NGENIUS_ENV,
      purpose,
      bookingId,
      bookingStatus: bookingId ? "payment_pending" : null,
    };
  } catch (error) {
    const failureCode =
      error instanceof ApiError
        ? error.code
        : PaymentErrorCode.PROVIDER_UNAVAILABLE;
    await sessionRef.set(
      {
        status: toLegacyStatus(PaymentStatus.failed),
        normalized_status: PaymentStatus.failed,
        failure_code: failureCode,
        booking_created: false,
        payment_url: FieldValue.delete(),
        three_ds_url: FieldValue.delete(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (purpose === "booking" && bookingDraft) {
      try {
        await ensureUnpaidBookingOrder({
          orderId: unpaidOrderId || sessionId,
          sessionId,
          userId: user.uid,
          sessionQuote: {
            user_id: user.uid,
            carPath: String(verifiedQuote.carPath || ""),
            countryPath: String(verifiedQuote.countryPath || ""),
            amount_minor: verifiedQuote.amountMinor,
            amount_halalas: verifiedQuote.amountMinor,
            currency: verifiedQuote.currency,
            bookingHours: Number(verifiedQuote.bookingHours || 0),
            additionalHours: Number(verifiedQuote.additionalHours || 0),
            baseFareHalalas: Number(verifiedQuote.baseFareHalalas || 0),
            appFeeHalalas: Number(verifiedQuote.appFeeHalalas || 0),
            vatHalalas: Number(verifiedQuote.vatHalalas || 0),
            discountHalalas: Number(verifiedQuote.discountHalalas || 0),
            booking_draft: bookingDraft,
          },
          draft: bookingDraft,
        });
      } catch (ensureErr) {
        logger.warn("unpaid_order_ensure_after_fail", {
          sessionIdPrefix: sessionId.slice(0, 8),
          err: ensureErr instanceof Error ? ensureErr.message : "unknown",
        });
      }
    }
    logger.error("create_payment_failed", {
      sessionIdPrefix: sessionId.slice(0, 8),
      failureCode,
      purpose,
    });
    throw error;
  }
}

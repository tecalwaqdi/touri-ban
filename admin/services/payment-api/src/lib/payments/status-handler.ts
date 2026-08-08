import { FieldValue } from "firebase-admin/firestore";
import { verifyBearerToken, requireFinanceOrAdmin } from "@/lib/auth/verify";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import {
  extractGatewayAmount,
  extractGatewayState,
  fetchNGeniusOrder,
} from "@/lib/ngenius/client";
import { getEnv } from "@/lib/security/env";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import {
  mapNGeniusState,
  PaymentStatus,
  toLegacyStatus,
  transitionStatus,
} from "@/lib/payments/status";
import { createBookingFromPaidSession } from "@/lib/bookings/create-from-session";

async function loadOwnedSession(sessionId: string, uid: string, asAdmin: boolean) {
  if (!/^[a-f0-9]{64}$/.test(sessionId)) {
    throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
  }
  const ref = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new ApiError(PaymentErrorCode.PAYMENT_SESSION_NOT_FOUND, 404);
  }
  const data = snap.data() || {};
  if (!asAdmin && data.user_id !== uid) {
    throw new ApiError(PaymentErrorCode.FORBIDDEN, 403);
  }
  return { ref, data };
}

export async function handlePaymentStatus(req: Request, sessionId: string) {
  const user = await verifyBearerToken(req.headers.get("authorization"));
  let asAdmin = false;
  try {
    await requireFinanceOrAdmin(user);
    asAdmin = true;
  } catch {
    asAdmin = false;
  }

  const { ref, data } = await loadOwnedSession(sessionId, user.uid, asAdmin);
  if (!data.provider_order_ref) {
    return {
      id: sessionId,
      status: data.normalized_status || data.status || PaymentStatus.created,
      amountMinor: data.amount_minor ?? data.amount_halalas,
      currency: data.currency,
      bookingCreated: Boolean(data.booking_created),
      bookingId: data.booking_id || null,
      providerStatus: data.gateway_state || null,
      environment: data.environment || getEnv().NGENIUS_ENV,
      backendSource: data.backend_source || "external_api",
    };
  }

  const orderData = await fetchNGeniusOrder(String(data.provider_order_ref));
  const gatewayState = extractGatewayState(orderData);
  const mapped = mapNGeniusState(gatewayState);
  const current = (data.normalized_status ||
    mapNGeniusState(String(data.gateway_state || data.status))) as PaymentStatus;
  const next = transitionStatus(current as PaymentStatus, mapped);

  const amount = extractGatewayAmount(orderData);
  if (
    amount.value != null &&
    Number(data.amount_minor ?? data.amount_halalas) !== Number(amount.value)
  ) {
    await ref.set(
      {
        security_review: true,
        security_error: PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    throw new ApiError(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH, 409);
  }
  if (
    amount.currency &&
    String(data.currency).toUpperCase() !== String(amount.currency).toUpperCase()
  ) {
    throw new ApiError(PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH, 409);
  }

  await ref.set(
    {
      status: toLegacyStatus(next),
      normalized_status: next,
      gateway_state: gatewayState,
      last_verified_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  let bookingCreated = Boolean(data.booking_created);
  let bookingId = (data.booking_id as string) || null;
  if (
    (next === PaymentStatus.paid || next === PaymentStatus.captured) &&
    data.purpose === "booking" &&
    !bookingCreated
  ) {
    const created = await createBookingFromPaidSession(sessionId, {
      ...data,
      status: toLegacyStatus(next),
      normalized_status: next,
    });
    bookingCreated = true;
    bookingId = created.bookingId;
  }

  return {
    id: sessionId,
    status: next,
    amountMinor: data.amount_minor ?? data.amount_halalas,
    currency: data.currency,
    bookingCreated,
    bookingId,
    providerStatus: gatewayState,
    environment: data.environment || getEnv().NGENIUS_ENV,
    backendSource: data.backend_source || "external_api",
  };
}

import { createHash } from "crypto";
import { FieldValue } from "firebase-admin/firestore";
import { COLLECTIONS, db } from "@/lib/firebase/admin";
import {
  extractGatewayAmount,
  extractGatewayState,
  extractOrderReference,
  fetchNGeniusOrder,
} from "@/lib/ngenius/client";
import { getEnv } from "@/lib/security/env";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { logger } from "@/lib/logging/logger";
import {
  mapNGeniusState,
  PaymentStatus,
  toLegacyStatus,
  transitionStatus,
} from "@/lib/payments/status";
import { createBookingFromPaidSession } from "@/lib/bookings/create-from-session";
import { creditWalletFromPaidSession } from "@/lib/wallet/credit";
import {
  assertAmountMatch,
  assertCurrencyMatch,
  assertOutletMatch,
  assertWebhookSecret,
} from "@/lib/payments/guards";

function eventDocId(eventId: string, payloadHash: string): string {
  return createHash("sha256").update(`${eventId}:${payloadHash}`).digest("hex");
}

function payloadHash(body: unknown): string {
  return createHash("sha256").update(JSON.stringify(body)).digest("hex");
}

export async function handleNGeniusWebhook(req: Request) {
  const env = getEnv();
  const headerName = env.NGENIUS_WEBHOOK_HEADER.toLowerCase();
  const provided =
    req.headers.get(headerName) ||
    req.headers.get("x-toury-webhook-token") ||
    "";
  assertWebhookSecret(provided, env.NGENIUS_WEBHOOK_SECRET);

  const body = await req.json();
  const hash = payloadHash(body);
  // N-Genius posts { eventName, outletId, order: { reference, ... } }.
  const nestedOrder =
    body && typeof body === "object" && "order" in (body as object)
      ? (body as { order: unknown }).order
      : undefined;
  const providerOrderId =
    extractOrderReference(nestedOrder) || extractOrderReference(body) || "";
  const eventId =
    String((body as { eventId?: string }).eventId || "") ||
    `${providerOrderId}:${hash.slice(0, 16)}`;
  const docId = eventDocId(eventId, hash);
  const eventRef = db().collection(COLLECTIONS.webhookEvents).doc(docId);

  const existing = await eventRef.get();
  if (existing.exists && existing.data()?.processed === true) {
    return { ok: true, duplicate: true };
  }

  await eventRef.set(
    {
      provider: "ngenius",
      providerEventId: eventId,
      providerOrderId,
      type: String((body as { eventName?: string }).eventName || "unknown"),
      processed: false,
      processing: true,
      receivedAt: FieldValue.serverTimestamp(),
      payloadHash: hash,
      backend_source: "external_api",
    },
    { merge: true },
  );

  try {
    if (!providerOrderId) {
      await eventRef.set(
        { ignored: true, processed: true, processing: false },
        { merge: true },
      );
      return { ok: true, ignored: true };
    }

    const sessions = await db()
      .collection(COLLECTIONS.paymentSessions)
      .where("provider_order_ref", "==", providerOrderId)
      .limit(1)
      .get();

    if (sessions.empty) {
      await eventRef.set(
        { ignored: true, processed: true, processing: false },
        { merge: true },
      );
      return { ok: true, ignored: true };
    }

    const sessionDoc = sessions.docs[0];
    const session = sessionDoc.data();
    const orderData = await fetchNGeniusOrder(providerOrderId);
    const gatewayState = extractGatewayState(orderData);
    const mapped = mapNGeniusState(gatewayState);
    const current = (session.normalized_status ||
      mapNGeniusState(String(session.gateway_state || session.status))) as PaymentStatus;
    const next = transitionStatus(current, mapped);

    const amount = extractGatewayAmount(orderData);
    assertAmountMatch(
      Number(session.amount_minor ?? session.amount_halalas),
      amount.value,
    );
    assertCurrencyMatch(String(session.currency || ""), amount.currency);
    assertOutletMatch(
      session.outlet_reference as string | undefined,
      env.NGENIUS_OUTLET_REF,
    );
    const eventOutlet = String((body as { outletId?: string }).outletId || "");
    if (eventOutlet) {
      assertOutletMatch(eventOutlet, env.NGENIUS_OUTLET_REF);
    }

    await sessionDoc.ref.set(
      {
        status: toLegacyStatus(next),
        normalized_status: next,
        gateway_state: gatewayState,
        last_verified_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (next === PaymentStatus.paid && session.purpose === "booking") {
      await createBookingFromPaidSession(sessionDoc.id, {
        ...session,
        status: toLegacyStatus(next),
        normalized_status: next,
      });
    }

    if (next === PaymentStatus.paid && session.purpose === "wallet") {
      await creditWalletFromPaidSession(sessionDoc.id, {
        ...session,
        status: toLegacyStatus(next),
        normalized_status: next,
      });
    }

    await eventRef.set(
      {
        processed: true,
        processing: false,
        sessionId: sessionDoc.id,
      },
      { merge: true },
    );
    return { ok: true };
  } catch (error) {
    logger.error("webhook_processing_failed", {
      eventPrefix: eventId.slice(0, 12),
    });
    await eventRef.set(
      {
        processing: false,
        error: error instanceof ApiError ? error.code : "UNKNOWN_ERROR",
      },
      { merge: true },
    );
    throw error;
  }
}

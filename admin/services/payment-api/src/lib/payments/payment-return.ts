/**
 * N-Genius HPP return / cancel callback.
 * Never treats browser landing as payment success — optional gateway re-fetch
 * is hint-only; Customer app must verify via status/finalize.
 */

import type { Request, Response } from "express";
import { FieldValue } from "firebase-admin/firestore";

import { COLLECTIONS, db } from "@/lib/firebase/admin";
import {
  extractGatewayState,
  fetchNGeniusOrder,
} from "@/lib/ngenius/client";
import { logger } from "@/lib/logging/logger";
import {
  mapNGeniusState,
  PaymentStatus,
  toLegacyStatus,
  transitionStatus,
} from "@/lib/payments/status";

export const DEFAULT_PAYMENT_RETURN_URL =
  "https://touri-ban.onrender.com/payment-return";

export const CUSTOMER_PAYMENT_DEEPLINK_BASE =
  "araoatanapp://araoatanapp.com/paymentConfirm";

type ReturnOutcome = "success" | "pending" | "cancel" | "failed";

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function firstQuery(req: Request, keys: string[]): string {
  for (const key of keys) {
    const raw = req.query[key];
    if (typeof raw === "string" && raw.trim()) return raw.trim();
    if (Array.isArray(raw) && typeof raw[0] === "string" && raw[0].trim()) {
      return raw[0].trim();
    }
  }
  return "";
}

function outcomeFromStatus(status: PaymentStatus | string): ReturnOutcome {
  if (
    status === PaymentStatus.paid ||
    status === PaymentStatus.captured ||
    status === PaymentStatus.authorized
  ) {
    return "success";
  }
  if (
    status === PaymentStatus.cancelled ||
    status === PaymentStatus.expired
  ) {
    return "cancel";
  }
  if (status === PaymentStatus.failed) {
    return "failed";
  }
  return "pending";
}

function buildDeepLink(opts: {
  outcome: ReturnOutcome;
  sessionId?: string;
}): string {
  const fromWebView =
    opts.outcome === "cancel" || opts.outcome === "failed" ? "true" : "false";
  const params = new URLSearchParams({
    fromWebView,
    awaitingExternalHpp: "false",
  });
  if (opts.sessionId) {
    params.set("sessionId", opts.sessionId);
  }
  if (opts.outcome === "cancel" || opts.outcome === "failed") {
    params.set("outcome", opts.outcome);
  }
  return `${CUSTOMER_PAYMENT_DEEPLINK_BASE}?${params.toString()}`;
}

/**
 * Best-effort: resolve provider order ref → session, re-fetch N-Genius,
 * sync gateway fields. Does not create bookings (authenticated paths do).
 */
async function hintVerifyFromGateway(providerOrderRef: string): Promise<{
  sessionId: string | null;
  outcome: ReturnOutcome;
}> {
  let sessionId: string | null = null;
  let outcome: ReturnOutcome = "pending";

  try {
    const q = await db()
      .collection(COLLECTIONS.paymentSessions)
      .where("provider_order_ref", "==", providerOrderRef)
      .limit(1)
      .get();
    if (!q.empty) {
      sessionId = q.docs[0].id;
    }
  } catch (err) {
    logger.error("payment_return_session_lookup_failed", {
      message: err instanceof Error ? err.message : String(err),
    });
  }

  try {
    const orderData = await fetchNGeniusOrder(providerOrderRef);
    const gatewayState = extractGatewayState(orderData);
    const mapped = mapNGeniusState(gatewayState);
    outcome = outcomeFromStatus(mapped);

    if (sessionId) {
      const ref = db().collection(COLLECTIONS.paymentSessions).doc(sessionId);
      const snap = await ref.get();
      const data = snap.data() || {};
      const current = (data.normalized_status ||
        mapNGeniusState(String(data.gateway_state || data.status))) as PaymentStatus;
      const next = transitionStatus(current, mapped);
      // Persist gateway observation only — no booking/wallet side effects here.
      await ref.set(
        {
          status: toLegacyStatus(next),
          normalized_status: next,
          gateway_state: gatewayState,
          last_verified_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          return_callback_seen_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      outcome = outcomeFromStatus(next);
    }
  } catch (err) {
    logger.error("payment_return_gateway_hint_failed", {
      message: err instanceof Error ? err.message : String(err),
    });
  }

  return { sessionId, outcome };
}

function renderReturnHtml(opts: {
  deepLink: string;
  outcome: ReturnOutcome;
}): string {
  const title =
    opts.outcome === "cancel" || opts.outcome === "failed"
      ? "Payment not completed"
      : "Return to Touri Taxi";
  const titleAr =
    opts.outcome === "cancel" || opts.outcome === "failed"
      ? "لم تكتمل عملية الدفع"
      : "العودة إلى توري تاكسي";
  const body =
    opts.outcome === "cancel" || opts.outcome === "failed"
      ? "Opening Touri Taxi so you can retry or choose another payment method. Payment is only confirmed after server verification with N-Genius."
      : "Opening Touri Taxi. The app will securely verify payment status with N-Genius before confirming.";
  const bodyAr =
    opts.outcome === "cancel" || opts.outcome === "failed"
      ? "جارٍ فتح تطبيق توري تاكسي لإعادة المحاولة أو اختيار طريقة دفع أخرى. يتم تأكيد الدفع فقط بعد التحقق من الخادم مع N-Genius."
      : "جارٍ فتح تطبيق توري تاكسي. سيتحقق التطبيق بأمان من حالة الدفع عبر N-Genius قبل التأكيد.";

  const deepLink = escapeHtml(opts.deepLink);
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light dark">
    <meta http-equiv="refresh" content="0;url=${deepLink}">
    <title>Touri Taxi payment</title>
    <style>
      :root {
        font-family: system-ui, sans-serif;
        color: #123b3a;
        background: #f7fbfa;
      }
      body {
        min-height: 100vh;
        margin: 0;
        display: grid;
        place-items: center;
      }
      main {
        width: min(34rem, calc(100% - 3rem));
        text-align: center;
      }
      .mark {
        width: 3.5rem;
        height: 3.5rem;
        margin: 0 auto 1rem;
        display: grid;
        place-items: center;
        border-radius: 50%;
        color: white;
        background: ${
          opts.outcome === "cancel" || opts.outcome === "failed"
            ? "#b45309"
            : "#008f86"
        };
        font-size: 1.75rem;
      }
      h1 { font-size: 1.35rem; }
      p { line-height: 1.6; color: #4b6664; }
      a.btn {
        display: inline-block;
        margin-top: 1.25rem;
        padding: 0.75rem 1.25rem;
        border-radius: 0.5rem;
        background: #008f86;
        color: #fff;
        text-decoration: none;
        font-weight: 600;
      }
      @media (prefers-color-scheme: dark) {
        :root { color: #e8f7f5; background: #101918; }
        p { color: #b7cfcc; }
      }
    </style>
    <script>
      (function () {
        var target = ${JSON.stringify(opts.deepLink)};
        try { window.location.replace(target); } catch (e) {}
        setTimeout(function () {
          try { window.location.href = target; } catch (e2) {}
        }, 400);
      })();
    </script>
  </head>
  <body>
    <main>
      <div class="mark" aria-hidden="true">${
        opts.outcome === "cancel" || opts.outcome === "failed" ? "!" : "&#10003;"
      }</div>
      <h1>${escapeHtml(title)}</h1>
      <p>${escapeHtml(body)}</p>
      <p dir="rtl">${escapeHtml(bodyAr)}</p>
      <p dir="rtl"><strong>${escapeHtml(titleAr)}</strong></p>
      <a class="btn" href="${deepLink}">Open Touri Taxi</a>
    </main>
  </body>
</html>`;
}

export async function handlePaymentReturn(
  req: Request,
  res: Response,
): Promise<void> {
  const outcomeHint = firstQuery(req, ["outcome", "status"]).toLowerCase();
  const providerOrderRef = firstQuery(req, [
    "ref",
    "orderRef",
    "orderReference",
    "providerOrderRef",
  ]);
  const sessionIdQuery = firstQuery(req, ["sessionId", "session_id"]);

  let outcome: ReturnOutcome = "pending";
  if (
    outcomeHint === "cancel" ||
    outcomeHint === "cancelled" ||
    outcomeHint === "canceled"
  ) {
    outcome = "cancel";
  } else if (outcomeHint === "failed" || outcomeHint === "fail") {
    outcome = "failed";
  }

  let sessionId = sessionIdQuery || null;
  if (providerOrderRef) {
    const hint = await hintVerifyFromGateway(providerOrderRef);
    if (hint.sessionId) sessionId = hint.sessionId;
    // Query cancel wins over gateway pending; gateway fail/cancel overrides pending.
    if (outcome === "pending") {
      outcome = hint.outcome;
    } else if (
      (hint.outcome === "failed" || hint.outcome === "cancel") &&
      outcome === "success"
    ) {
      outcome = hint.outcome;
    }
  }

  const deepLink = buildDeepLink({
    outcome,
    sessionId: sessionId || undefined,
  });

  logger.info("payment_return_served", {
    outcome,
    hasProviderRef: Boolean(providerOrderRef),
    hasSessionId: Boolean(sessionId),
  });

  res
    .status(200)
    .type("html")
    .set("Cache-Control", "no-store")
    .send(renderReturnHtml({ deepLink, outcome }));
}

import cors from "cors";
import express, { type NextFunction, type Request, type Response } from "express";
import { config as loadEnv } from "dotenv";

import { handleCreatePayment } from "@/lib/payments/create";
import { handlePaymentStatus } from "@/lib/payments/status-handler";
import { handleNGeniusWebhook } from "@/lib/payments/webhook";
import {
  probeNGeniusHostedPaymentPage,
  probeNGeniusIdentity,
} from "@/lib/ngenius/diagnostics";
import { envPresence, getEnv } from "@/lib/security/env";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { logger } from "@/lib/logging/logger";
import { toFetchRequest, sendJson } from "@/http/express-bridge";

loadEnv();

const app = express();
const PORT = Number(process.env.PORT || 3010);

app.disable("x-powered-by");
app.use(
  cors({
    origin: (origin, cb) => {
      try {
        const env = getEnv({ requireSecrets: false });
        if (!origin) return cb(null, true);
        if (env.allowedOrigins.length === 0) return cb(null, true);
        if (env.allowedOrigins.includes(origin)) return cb(null, true);
        return cb(new Error("CORS_DENIED"));
      } catch {
        return cb(null, true);
      }
    },
  }),
);
app.use(express.json({ limit: "1mb" }));

function asyncRoute(
  fn: (req: Request, res: Response) => Promise<void>,
): (req: Request, res: Response, next: NextFunction) => void {
  return (req, res, next) => {
    fn(req, res).catch(next);
  };
}

/** GET /health — no secrets required */
app.get(
  "/health",
  asyncRoute(async (_req, res) => {
    const presence = envPresence();
    const env = getEnv({ requireSecrets: false });
    sendJson(res, 200, {
      ok: true,
      service: "touri-payment-api",
      runtime: "express",
      version: env.SERVICE_VERSION,
      ngeniusEnv: env.NGENIUS_ENV,
      configured: presence,
    });
  }),
);

/**
 * GET /health/provider — identity probe (legacy path).
 * Prefer GET /health/ngenius for fuller safe diagnostics.
 */
app.get(
  "/health/provider",
  asyncRoute(async (_req, res) => {
    const report = await probeNGeniusIdentity();
    sendJson(res, report.identityStatus === "ok" ? 200 : 502, report);
  }),
);

/**
 * GET /health/ngenius — safe N-Genius diagnostics (no secrets).
 * Fields: environment, base host, realm, identity status, masked outlet, provider errors.
 */
app.get(
  "/health/ngenius",
  asyncRoute(async (_req, res) => {
    const report = await probeNGeniusIdentity();
    sendJson(res, report.identityStatus === "ok" ? 200 : 502, report);
  }),
);

/**
 * POST /health/ngenius/hpp-probe — identity + create hosted-payment order only.
 * Requires ALLOW_HPP_PROBE=true. Does not capture/pay a card.
 * Success with payment URL → readiness PRODUCTION_HPP_READY (when NGENIUS_ENV=production).
 */
app.post(
  "/health/ngenius/hpp-probe",
  asyncRoute(async (_req, res) => {
    const report = await probeNGeniusHostedPaymentPage();
    const ok =
      report.createOrderStatus === "ok" &&
      (report.readiness === "PRODUCTION_HPP_READY" ||
        report.readiness === "SANDBOX_HPP_READY");
    sendJson(res, ok ? 200 : 502, report);
  }),
);

/** POST /payments/create — Firebase ID token + server-side pricing */
app.post(
  "/payments/create",
  asyncRoute(async (req, res) => {
    const fetchReq = toFetchRequest(req);
    const result = await handleCreatePayment(fetchReq);
    sendJson(res, 200, result);
  }),
);

/**
 * GET /payments/status?sessionId=...
 * Also accepts /payments/status/:sessionId for clients that prefer path params.
 */
app.get(
  ["/payments/status", "/payments/status/:sessionId"],
  asyncRoute(async (req, res) => {
    const sessionId = String(
      req.params.sessionId || req.query.sessionId || "",
    ).trim();
    if (!sessionId) {
      throw new ApiError(PaymentErrorCode.INVALID_REQUEST, 400, "sessionId required");
    }
    const fetchReq = toFetchRequest(req);
    const result = await handlePaymentStatus(fetchReq, sessionId);
    sendJson(res, 200, result);
  }),
);

/** POST /webhooks/ngenius — provider webhook → update session → create order */
app.post(
  "/webhooks/ngenius",
  asyncRoute(async (req, res) => {
    const fetchReq = toFetchRequest(req);
    const result = await handleNGeniusWebhook(fetchReq);
    sendJson(res, 200, result);
  }),
);

app.use((_req, res) => {
  sendJson(res, 404, {
    error: { code: "NOT_FOUND", message: "Route not found" },
  });
});

app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof Error && err.message === "CORS_DENIED") {
    sendJson(res, 403, {
      error: { code: PaymentErrorCode.FORBIDDEN, message: "Origin not allowed" },
    });
    return;
  }
  if (err instanceof ApiError) {
    sendJson(res, err.status, {
      error: { code: err.code, message: err.message },
    });
    return;
  }
  logger.error("unhandled_express_error", {
    name: err instanceof Error ? err.name : "unknown",
  });
  sendJson(res, 500, {
    error: {
      code: PaymentErrorCode.UNKNOWN_ERROR,
      message: "Unexpected server error",
    },
  });
});

if (require.main === module) {
  try {
    // Fail closed: refuse to listen without critical secrets.
    getEnv({ requireSecrets: true });
  } catch (err) {
    logger.error("payment_api_startup_config_error", {
      message: err instanceof Error ? err.message : "CONFIG_ERROR",
    });
    process.exit(1);
  }
  app.listen(PORT, () => {
    const env = getEnv({ requireSecrets: false });
    logger.info("payment_api_listening", {
      port: PORT,
      ngeniusEnv: env.NGENIUS_ENV,
      baseHost: (() => {
        try {
          return new URL(env.ngeniusBaseUrl).host;
        } catch {
          return "invalid";
        }
      })(),
      realm: env.ngeniusRealm,
    });
  });
}

export default app;

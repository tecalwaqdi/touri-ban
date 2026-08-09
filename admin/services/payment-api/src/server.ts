import cors from "cors";
import express, { type NextFunction, type Request, type Response } from "express";
import { config as loadEnv } from "dotenv";

import { handleCreatePayment } from "@/lib/payments/create";
import { handlePaymentStatus } from "@/lib/payments/status-handler";
import { handleNGeniusWebhook } from "@/lib/payments/webhook";
import {
  getNGeniusAccessToken,
  resetNGeniusTokenCacheForTests,
} from "@/lib/ngenius/client";
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
 * GET /health/provider — probes N-Genius identity only (no secrets in response).
 * Use after deploy to confirm API key/realm/base URL before Flutter QA.
 */
app.get(
  "/health/provider",
  asyncRoute(async (_req, res) => {
    const env = getEnv();
    resetNGeniusTokenCacheForTests();
    try {
      await getNGeniusAccessToken();
      sendJson(res, 200, {
        ok: true,
        identity: "ok",
        ngeniusEnv: env.NGENIUS_ENV,
        baseHost: new URL(env.ngeniusBaseUrl).host,
        realm: env.ngeniusRealm,
      });
    } catch (error) {
      const code =
        error instanceof ApiError ? error.code : PaymentErrorCode.PROVIDER_UNAVAILABLE;
      sendJson(res, 502, {
        ok: false,
        identity: "failed",
        code,
        ngeniusEnv: env.NGENIUS_ENV,
        baseHost: new URL(env.ngeniusBaseUrl).host,
        realm: env.ngeniusRealm,
      });
    }
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
    logger.info("payment_api_listening", { port: PORT });
  });
}

export default app;

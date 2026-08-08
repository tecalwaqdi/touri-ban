import { describe, expect, it, beforeEach } from "vitest";
import {
  buildNGeniusIdentityBody,
  buildNGeniusIdentityRequest,
  normalizeNGeniusApiKeyForBasicAuth,
  NGENIUS_IDENTITY_CONTENT_TYPE,
} from "@/lib/ngenius/client";
import {
  getEnv,
  resetEnvCacheForTests,
  NGENIUS_KSA_SANDBOX_BASE_URL,
  NGENIUS_KSA_PRODUCTION_BASE_URL,
  NGENIUS_KSA_SANDBOX_REALM,
  NGENIUS_KSA_PRODUCTION_REALM,
} from "@/lib/security/env";

describe("N-Genius KSA sandbox identity request", () => {
  beforeEach(() => {
    resetEnvCacheForTests();
    process.env.NGENIUS_ENV = "sandbox";
    process.env.NGENIUS_API_KEY = "sandbox-api-key-material";
    process.env.NGENIUS_OUTLET_REF = "outlet";
    process.env.NGENIUS_WEBHOOK_SECRET = "webhook-secret-16chars";
    delete process.env.NGENIUS_REALM;
    delete process.env.NGENIUS_SANDBOX_BASE_URL;
    delete process.env.NGENIUS_PRODUCTION_BASE_URL;
    process.env.FIREBASE_PROJECT_ID = "demo";
    process.env.FIREBASE_CLIENT_EMAIL = "demo@demo.iam.gserviceaccount.com";
    process.env.FIREBASE_PRIVATE_KEY =
      "-----BEGIN PRIVATE KEY-----\\nABC\\n-----END PRIVATE KEY-----\\n";
  });

  it("defaults to KSA sandbox base URL", () => {
    const env = getEnv();
    expect(env.ngeniusBaseUrl).toBe(NGENIUS_KSA_SANDBOX_BASE_URL);
    expect(env.ngeniusIdentityUrl).toBe(
      `${NGENIUS_KSA_SANDBOX_BASE_URL}/identity/auth/access-token`,
    );
    expect(env.ngeniusRealm).toBe(NGENIUS_KSA_SANDBOX_REALM);
  });

  it("uses official realmName body (not grant_type/client_credentials)", () => {
    expect(buildNGeniusIdentityBody("ni")).toEqual({ realmName: "ni" });
    expect(buildNGeniusIdentityBody("ni")).not.toHaveProperty("grant_type");
    expect(buildNGeniusIdentityBody("ni")).not.toHaveProperty("realm");
  });

  it("builds KSA sandbox identity URL /identity/auth/access-token", () => {
    const env = getEnv();
    const req = buildNGeniusIdentityRequest(env);
    expect(req.url).toBe(
      "https://api-gateway.sandbox.ksa.ngenius-payments.com/identity/auth/access-token",
    );
    expect(req.method).toBe("POST");
    expect(req.bodyJson).toEqual({ realmName: "ni" });
    expect(JSON.parse(req.body)).toEqual({ realmName: "ni" });
  });

  it("order/create base uses the same KSA sandbox host", () => {
    const env = getEnv();
    const ordersUrl = `${env.ngeniusBaseUrl}/transactions/outlets/${env.NGENIUS_OUTLET_REF}/orders`;
    expect(ordersUrl).toBe(
      "https://api-gateway.sandbox.ksa.ngenius-payments.com/transactions/outlets/outlet/orders",
    );
  });

  it("uses ni-identity Content-Type and Basic auth without re-encoding", () => {
    const env = getEnv();
    const req = buildNGeniusIdentityRequest(env);
    expect(req.headers["Content-Type"]).toBe(NGENIUS_IDENTITY_CONTENT_TYPE);
    expect(req.headers.Accept).toBe(NGENIUS_IDENTITY_CONTENT_TYPE);
    expect(req.headers.Authorization).toBe("Basic sandbox-api-key-material");
    expect(req.headers.Authorization).not.toMatch(/^Basic Basic /i);
  });

  it("strips accidental Basic prefix from pasted API keys", () => {
    expect(normalizeNGeniusApiKeyForBasicAuth("Basic abc123")).toBe("abc123");
    expect(normalizeNGeniusApiKeyForBasicAuth("  basic   xyz  ")).toBe("xyz");
  });

  it("defaults production to KSA production host + networkinternational realm", () => {
    resetEnvCacheForTests();
    process.env.NGENIUS_ENV = "production";
    const env = getEnv();
    expect(env.ngeniusBaseUrl).toBe(NGENIUS_KSA_PRODUCTION_BASE_URL);
    expect(env.ngeniusRealm).toBe(NGENIUS_KSA_PRODUCTION_REALM);
    expect(env.ngeniusIdentityUrl).toBe(
      `${NGENIUS_KSA_PRODUCTION_BASE_URL}/identity/auth/access-token`,
    );
  });
});

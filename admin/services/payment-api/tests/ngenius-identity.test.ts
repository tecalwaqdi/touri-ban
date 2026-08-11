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
  NGENIUS_GLOBAL_SANDBOX_BASE_URL,
  NGENIUS_KSA_SANDBOX_BASE_URL,
  NGENIUS_KSA_PRODUCTION_BASE_URL,
  NGENIUS_KSA_SANDBOX_REALM,
  NGENIUS_KSA_PRODUCTION_REALM,
} from "@/lib/security/env";

describe("N-Genius sandbox identity request", () => {
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

  it("defaults to global sandbox base URL (verified for current MSA)", () => {
    const env = getEnv();
    expect(env.ngeniusBaseUrl).toBe(NGENIUS_GLOBAL_SANDBOX_BASE_URL);
    expect(env.ngeniusIdentityUrl).toBe(
      `${NGENIUS_GLOBAL_SANDBOX_BASE_URL}/identity/auth/access-token`,
    );
    expect(env.ngeniusRealm).toBe(NGENIUS_KSA_SANDBOX_REALM);
  });

  it("allows optional KSA sandbox override via env", () => {
    resetEnvCacheForTests();
    process.env.NGENIUS_SANDBOX_BASE_URL = NGENIUS_KSA_SANDBOX_BASE_URL;
    const env = getEnv();
    expect(env.ngeniusBaseUrl).toBe(NGENIUS_KSA_SANDBOX_BASE_URL);
  });

  it("uses CF-compatible identity body on global hosts", () => {
    expect(buildNGeniusIdentityBody("NIARABIA")).toEqual({
      grant_type: "client_credentials",
      realm: "NIARABIA",
    });
  });

  it("uses CF body for NIARABIA even on KSA production host", () => {
    expect(
      buildNGeniusIdentityBody("NIARABIA", {
        baseUrl: NGENIUS_KSA_PRODUCTION_BASE_URL,
      }),
    ).toEqual({
      grant_type: "client_credentials",
      realm: "NIARABIA",
    });
  });

  it("uses KSA realmName-only body for standard KSA realms", () => {
    expect(
      buildNGeniusIdentityBody("networkinternational", {
        baseUrl: NGENIUS_KSA_PRODUCTION_BASE_URL,
      }),
    ).toEqual({ realmName: "networkinternational" });
    expect(
      buildNGeniusIdentityBody("ni", {
        baseUrl: NGENIUS_KSA_SANDBOX_BASE_URL,
      }),
    ).toEqual({ realmName: "ni" });
  });

  it("builds sandbox identity URL /identity/auth/access-token", () => {
    const env = getEnv();
    const req = buildNGeniusIdentityRequest(env);
    expect(req.url).toBe(
      "https://api-gateway.sandbox.ngenius-payments.com/identity/auth/access-token",
    );
    expect(req.method).toBe("POST");
    expect(req.bodyJson).toEqual({
      grant_type: "client_credentials",
      realm: "ni",
    });
    expect(JSON.parse(req.body)).toEqual({
      grant_type: "client_credentials",
      realm: "ni",
    });
    expect(req.headers.Accept).toBeUndefined();
  });

  it("keeps NIARABIA on global sandbox host when that is the portal URL", () => {
    resetEnvCacheForTests();
    process.env.NGENIUS_REALM = "NIARABIA";
    process.env.NGENIUS_SANDBOX_BASE_URL = NGENIUS_GLOBAL_SANDBOX_BASE_URL;
    const env = getEnv();
    expect(env.ngeniusBaseUrl).toBe(NGENIUS_GLOBAL_SANDBOX_BASE_URL);
    expect(env.ngeniusRealm).toBe("NIARABIA");
    const req = buildNGeniusIdentityRequest(env);
    expect(req.url).toBe(
      `${NGENIUS_GLOBAL_SANDBOX_BASE_URL}/identity/auth/access-token`,
    );
    expect(req.bodyJson).toEqual({
      grant_type: "client_credentials",
      realm: "NIARABIA",
    });
  });

  it("order/create base uses the same sandbox host", () => {
    const env = getEnv();
    const ordersUrl = `${env.ngeniusBaseUrl}/transactions/outlets/${env.NGENIUS_OUTLET_REF}/orders`;
    expect(ordersUrl).toBe(
      "https://api-gateway.sandbox.ngenius-payments.com/transactions/outlets/outlet/orders",
    );
  });

  it("uses ni-identity Content-Type and Basic auth without re-encoding", () => {
    const env = getEnv();
    const req = buildNGeniusIdentityRequest(env);
    expect(req.headers["Content-Type"]).toBe(NGENIUS_IDENTITY_CONTENT_TYPE);
    expect(req.headers.Accept).toBeUndefined();
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

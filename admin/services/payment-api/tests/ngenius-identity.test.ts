import { describe, expect, it, beforeEach } from "vitest";
import {
  buildNGeniusIdentityBody,
  buildNGeniusIdentityRequest,
  normalizeNGeniusApiKeyForBasicAuth,
  NGENIUS_IDENTITY_CONTENT_TYPE,
} from "@/lib/ngenius/client";
import { getEnv, resetEnvCacheForTests } from "@/lib/security/env";

describe("N-Genius sandbox identity request", () => {
  beforeEach(() => {
    resetEnvCacheForTests();
    process.env.NGENIUS_ENV = "sandbox";
    process.env.NGENIUS_API_KEY = "sandbox-api-key-material";
    process.env.NGENIUS_OUTLET_REF = "outlet";
    process.env.NGENIUS_WEBHOOK_SECRET = "webhook-secret-16chars";
    process.env.NGENIUS_REALM = "ni";
    process.env.NGENIUS_SANDBOX_BASE_URL =
      "https://api-gateway.sandbox.ngenius-payments.com";
    process.env.FIREBASE_PROJECT_ID = "demo";
    process.env.FIREBASE_CLIENT_EMAIL = "demo@demo.iam.gserviceaccount.com";
    process.env.FIREBASE_PRIVATE_KEY =
      "-----BEGIN PRIVATE KEY-----\\nABC\\n-----END PRIVATE KEY-----\\n";
  });

  it("uses official realmName body (not grant_type/client_credentials)", () => {
    expect(buildNGeniusIdentityBody("ni")).toEqual({ realmName: "ni" });
    expect(buildNGeniusIdentityBody("ni")).not.toHaveProperty("grant_type");
    expect(buildNGeniusIdentityBody("ni")).not.toHaveProperty("realm");
  });

  it("builds sandbox identity URL /identity/auth/access-token", () => {
    const env = getEnv();
    const req = buildNGeniusIdentityRequest(env);
    expect(req.url).toBe(
      "https://api-gateway.sandbox.ngenius-payments.com/identity/auth/access-token",
    );
    expect(req.method).toBe("POST");
    expect(req.bodyJson).toEqual({ realmName: "ni" });
    expect(JSON.parse(req.body)).toEqual({ realmName: "ni" });
  });

  it("uses ni-identity Content-Type and Basic auth without re-encoding", () => {
    const env = getEnv();
    const req = buildNGeniusIdentityRequest(env);
    expect(req.headers["Content-Type"]).toBe(NGENIUS_IDENTITY_CONTENT_TYPE);
    expect(req.headers.Accept).toBe(NGENIUS_IDENTITY_CONTENT_TYPE);
    expect(req.headers.Authorization).toBe("Basic sandbox-api-key-material");
    // Must not look like we wrapped the key in another Base64 Basic blob.
    expect(req.headers.Authorization).not.toMatch(/^Basic Basic /i);
  });

  it("strips accidental Basic prefix from pasted API keys", () => {
    expect(normalizeNGeniusApiKeyForBasicAuth("Basic abc123")).toBe("abc123");
    expect(normalizeNGeniusApiKeyForBasicAuth("  basic   xyz  ")).toBe("xyz");
  });
});

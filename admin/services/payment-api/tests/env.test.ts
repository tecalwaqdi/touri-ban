import { describe, expect, it, beforeEach } from "vitest";
import { getEnv, resetEnvCacheForTests, envPresence } from "@/lib/security/env";

describe("env", () => {
  beforeEach(() => {
    resetEnvCacheForTests();
    process.env.NGENIUS_ENV = "sandbox";
    process.env.NGENIUS_API_KEY = "test-key";
    process.env.NGENIUS_OUTLET_REF = "outlet";
    process.env.FIREBASE_PROJECT_ID = "demo";
    process.env.FIREBASE_CLIENT_EMAIL = "demo@demo.iam.gserviceaccount.com";
    process.env.FIREBASE_PRIVATE_KEY = "-----BEGIN PRIVATE KEY-----\\nABC\\n-----END PRIVATE KEY-----\\n";
  });

  it("defaults to sandbox", () => {
    const env = getEnv();
    expect(env.NGENIUS_ENV).toBe("sandbox");
    expect(env.isProductionNGenius).toBe(false);
    expect(env.privateKey).toContain("BEGIN PRIVATE KEY");
    expect(env.privateKey).not.toContain("\\n");
  });

  it("reports presence without leaking secrets", () => {
    const p = envPresence();
    expect(p.ngeniusApiKey).toBe(true);
    expect(p.firebase).toBe(true);
  });

  it("requires explicit production env", () => {
    resetEnvCacheForTests();
    process.env.NGENIUS_ENV = "production";
    const env = getEnv();
    expect(env.isProductionNGenius).toBe(true);
    expect(env.ngeniusBaseUrl).toContain("api-gateway.ngenius-payments.com");
  });
});

import { describe, expect, it } from "vitest";
import {
  buildStaticNGeniusDiagnostics,
  probeNGeniusHostedPaymentPage,
} from "@/lib/ngenius/diagnostics";
import { getEnv, resetEnvCacheForTests } from "@/lib/security/env";

describe("ngenius diagnostics", () => {
  it("reports production host/realm without secrets", () => {
    resetEnvCacheForTests();
    process.env.NGENIUS_ENV = "production";
    process.env.NGENIUS_API_KEY = "test-key";
    process.env.NGENIUS_OUTLET_REF = "abcdefghijklmnop";
    process.env.NGENIUS_WEBHOOK_SECRET = "webhook-secret-16chars";
    process.env.NGENIUS_REALM = "NIARABIA";
    process.env.NGENIUS_PRODUCTION_BASE_URL =
      "https://api-gateway.ksa.ngenius-payments.com";
    process.env.FIREBASE_PROJECT_ID = "demo";
    process.env.FIREBASE_CLIENT_EMAIL = "demo@demo.iam.gserviceaccount.com";
    process.env.FIREBASE_PRIVATE_KEY =
      "-----BEGIN PRIVATE KEY-----\\nABC\\n-----END PRIVATE KEY-----\\n";

    const env = getEnv();
    const report = buildStaticNGeniusDiagnostics();
    expect(report.environment).toBe("production");
    expect(report.baseHost).toBe("api-gateway.ksa.ngenius-payments.com");
    expect(report.realm).toBe("NIARABIA");
    expect(report.usesProductionBaseUrl).toBe(true);
    expect(report.usesSandboxHost).toBe(false);
    expect(report.outletRefMasked).toContain("…");
    expect(JSON.stringify(report)).not.toContain(env.NGENIUS_API_KEY);
    expect(JSON.stringify(report)).not.toContain(env.NGENIUS_WEBHOOK_SECRET);
  });

  it("blocks hpp probe unless ALLOW_HPP_PROBE=true", async () => {
    resetEnvCacheForTests();
    process.env.NGENIUS_ENV = "production";
    process.env.NGENIUS_API_KEY = "test-key";
    process.env.NGENIUS_OUTLET_REF = "abcdefghijklmnop";
    process.env.NGENIUS_WEBHOOK_SECRET = "webhook-secret-16chars";
    process.env.NGENIUS_REALM = "NIARABIA";
    process.env.FIREBASE_PROJECT_ID = "demo";
    process.env.FIREBASE_CLIENT_EMAIL = "demo@demo.iam.gserviceaccount.com";
    process.env.FIREBASE_PRIVATE_KEY =
      "-----BEGIN PRIVATE KEY-----\\nABC\\n-----END PRIVATE KEY-----\\n";
    delete process.env.ALLOW_HPP_PROBE;

    const report = await probeNGeniusHostedPaymentPage();
    expect(report.createOrderStatus).toBe("blocked");
    expect(report.readiness).toBe("NOT_READY");
  });
});

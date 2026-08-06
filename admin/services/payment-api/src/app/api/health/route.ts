import { envPresence, getEnv } from "@/lib/security/env";
import { firebaseReady } from "@/lib/firebase/admin";
import { jsonOk } from "@/lib/validation/http";

export const runtime = "nodejs";

export async function GET() {
  const soft = getEnv({ requireSecrets: false });
  const presence = envPresence();
  return jsonOk({
    status: "ok",
    version: soft.SERVICE_VERSION,
    environment: soft.NGENIUS_ENV,
    firebaseInitialized: firebaseReady(),
    ngeniusConfigured: {
      apiKey: presence.ngeniusApiKey,
      outlet: presence.ngeniusOutlet,
      webhookSecret: presence.ngeniusWebhookSecret,
    },
  });
}

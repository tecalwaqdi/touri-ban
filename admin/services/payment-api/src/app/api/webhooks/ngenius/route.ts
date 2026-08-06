import { handleNGeniusWebhook } from "@/lib/payments/webhook";
import { jsonError, jsonOk } from "@/lib/validation/http";

export const runtime = "nodejs";

export async function POST(req: Request) {
  try {
    const result = await handleNGeniusWebhook(req);
    return jsonOk(result);
  } catch (error) {
    return jsonError(error);
  }
}

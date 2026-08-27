import { handleCancelPayment } from "@/lib/payments/cancel";
import { jsonError, jsonOk } from "@/lib/validation/http";

export const runtime = "nodejs";

export async function POST(req: Request) {
  try {
    const result = await handleCancelPayment(req);
    return jsonOk(result);
  } catch (error) {
    return jsonError(error);
  }
}

import { handlePaymentStatus } from "@/lib/payments/status-handler";
import { jsonError, jsonOk } from "@/lib/validation/http";

export const runtime = "nodejs";

export async function GET(
  req: Request,
  ctx: { params: Promise<{ sessionId: string }> },
) {
  try {
    const { sessionId } = await ctx.params;
    const result = await handlePaymentStatus(req, sessionId);
    return jsonOk(result);
  } catch (error) {
    return jsonError(error);
  }
}

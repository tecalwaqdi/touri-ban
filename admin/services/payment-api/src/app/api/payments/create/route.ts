import { handleCreatePayment } from "@/lib/payments/create";
import { jsonError, jsonOk } from "@/lib/validation/http";

export const runtime = "nodejs";

export async function POST(req: Request) {
  try {
    const result = await handleCreatePayment(req);
    return jsonOk(result);
  } catch (error) {
    return jsonError(error);
  }
}

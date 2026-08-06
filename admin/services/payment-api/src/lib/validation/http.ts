import { NextResponse } from "next/server";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { logger } from "@/lib/logging/logger";

export function jsonOk(body: unknown, status = 200) {
  return NextResponse.json(body, { status });
}

export function jsonError(error: unknown) {
  if (error instanceof ApiError) {
    return NextResponse.json(
      { error: { code: error.code, message: error.message } },
      { status: error.status },
    );
  }
  logger.error("unhandled_api_error", {
    name: error instanceof Error ? error.name : "unknown",
  });
  return NextResponse.json(
    {
      error: {
        code: PaymentErrorCode.UNKNOWN_ERROR,
        message: "Unexpected server error",
      },
    },
    { status: 500 },
  );
}

/** Framework-agnostic JSON helpers (Express handlers throw ApiError instead). */

export function jsonBody(status: number, body: unknown): Response {
  return Response.json(body, { status });
}

export function jsonOk(body: unknown, status = 200): Response {
  return jsonBody(status, body);
}

export function jsonError(
  status: number,
  code: string,
  message?: string,
): Response {
  return jsonBody(status, {
    error: { code, message: message || code },
  });
}

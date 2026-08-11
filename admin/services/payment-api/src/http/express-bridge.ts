import type { Request as ExpressRequest, Response as ExpressResponse } from "express";

/** Build a Fetch API Request so existing handlers stay framework-agnostic. */
export function toFetchRequest(req: ExpressRequest): globalThis.Request {
  const proto = String(req.headers["x-forwarded-proto"] || req.protocol || "https");
  const host = String(req.headers["x-forwarded-host"] || req.headers.host || "localhost");
  const url = `${proto}://${host}${req.originalUrl}`;

  const headers = new Headers();
  for (const [key, value] of Object.entries(req.headers)) {
    if (value == null) continue;
    if (Array.isArray(value)) {
      for (const v of value) headers.append(key, v);
    } else {
      headers.set(key, value);
    }
  }

  const method = (req.method || "GET").toUpperCase();
  const init: RequestInit = { method, headers };
  if (method !== "GET" && method !== "HEAD") {
    init.body = JSON.stringify(req.body ?? {});
  }
  return new globalThis.Request(url, init);
}

export function sendJson(res: ExpressResponse, status: number, body: unknown): void {
  res.status(status).json(body);
}

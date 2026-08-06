type LogFields = Record<string, unknown>;

const REDACT_KEYS = [
  "authorization",
  "apiKey",
  "api_key",
  "token",
  "access_token",
  "private_key",
  "privateKey",
  "webhook_secret",
  "webhookSecret",
  "password",
  "card",
  "pan",
  "cvv",
];

function redact(value: unknown, depth = 0): unknown {
  if (depth > 4) return "[truncated]";
  if (value == null) return value;
  if (typeof value === "string") {
    if (value.length > 200) return `${value.slice(0, 40)}…[len=${value.length}]`;
    return value;
  }
  if (Array.isArray(value)) return value.map((v) => redact(v, depth + 1));
  if (typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      if (REDACT_KEYS.some((r) => k.toLowerCase().includes(r.toLowerCase()))) {
        out[k] = "[redacted]";
      } else {
        out[k] = redact(v, depth + 1);
      }
    }
    return out;
  }
  return value;
}

export const logger = {
  info(message: string, fields?: LogFields) {
    console.log(JSON.stringify({ level: "info", message, ...((redact(fields) as object) || {}) }));
  },
  warn(message: string, fields?: LogFields) {
    console.warn(JSON.stringify({ level: "warn", message, ...((redact(fields) as object) || {}) }));
  },
  error(message: string, fields?: LogFields) {
    console.error(JSON.stringify({ level: "error", message, ...((redact(fields) as object) || {}) }));
  },
};

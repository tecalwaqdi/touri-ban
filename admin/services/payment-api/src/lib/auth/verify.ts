import type { DecodedIdToken } from "firebase-admin/auth";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { auth, db, COLLECTIONS } from "@/lib/firebase/admin";
import { logger } from "@/lib/logging/logger";

export type AuthedUser = {
  uid: string;
  email?: string;
  token: DecodedIdToken;
};

/** Global finance/admin vs country-scoped panel access (F07). */
export type FinanceAccess =
  | { kind: "global" }
  | { kind: "country"; countryPath: string }
  | { kind: "denied" };

function peekJwtClaims(token: string): Record<string, unknown> {
  try {
    const part = token.split(".")[1];
    if (!part) return {};
    const json = Buffer.from(part, "base64url").toString("utf8");
    const payload = JSON.parse(json) as Record<string, unknown>;
    return {
      aud: payload.aud,
      iss: payload.iss,
      sub: typeof payload.sub === "string" ? payload.sub.slice(0, 8) : undefined,
      exp: payload.exp,
      auth_time: payload.auth_time,
    };
  } catch {
    return { peek: "failed" };
  }
}

export async function verifyBearerToken(
  authorizationHeader: string | null,
): Promise<AuthedUser> {
  if (!authorizationHeader || !authorizationHeader.startsWith("Bearer ")) {
    throw new ApiError(PaymentErrorCode.AUTH_REQUIRED, 401);
  }
  const token = authorizationHeader.slice("Bearer ".length).trim();
  if (!token) throw new ApiError(PaymentErrorCode.AUTH_REQUIRED, 401);
  const claimsPeek = peekJwtClaims(token);

  // Prefer revocation check; fall back if Identity Toolkit revoke lookup fails (IAM).
  try {
    const decoded = await auth().verifyIdToken(token, true);
    return { uid: decoded.uid, email: decoded.email, token: decoded };
  } catch (revokedErr) {
    try {
      const decoded = await auth().verifyIdToken(token, false);
      logger.warn("verifyIdToken_checkRevoked_failed_using_basic", {
        claimsPeek,
        revokedErr:
          revokedErr instanceof Error ? revokedErr.message : String(revokedErr),
      });
      return { uid: decoded.uid, email: decoded.email, token: decoded };
    } catch (basicErr) {
      logger.error("verifyIdToken_failed", {
        claimsPeek,
        tokenLen: token.length,
        revokedErr:
          revokedErr instanceof Error ? revokedErr.message : String(revokedErr),
        basicErr:
          basicErr instanceof Error ? basicErr.message : String(basicErr),
      });
      throw new ApiError(PaymentErrorCode.AUTH_INVALID, 401);
    }
  }
}

function normalizeCountryPath(raw: unknown): string | null {
  if (raw == null) return null;
  if (typeof raw === "string" && raw.trim()) {
    const s = raw.trim();
    return s.startsWith("countries/") ? s : `countries/${s}`;
  }
  if (typeof raw === "object" && raw && "path" in raw) {
    const p = String((raw as { path: string }).path || "").trim();
    return p || null;
  }
  return null;
}

/**
 * Resolve finance/admin access without treating isAdminRule=2 / country_admin
 * as global. Pure Agents inherit country_admin claim today — they stay
 * country-scoped here.
 */
export async function resolveFinanceAccess(user: AuthedUser): Promise<FinanceAccess> {
  const claims = user.token as DecodedIdToken & {
    super_admin?: boolean;
    finance?: boolean;
    country_admin?: boolean;
    agent?: boolean;
    country_id?: string;
  };

  if (claims.super_admin === true) return { kind: "global" };
  // Global accountant: finance claim without country_admin/agent hybrid.
  if (
    claims.finance === true &&
    claims.country_admin !== true &&
    claims.agent !== true
  ) {
    return { kind: "global" };
  }

  const snap = await db().collection(COLLECTIONS.users).doc(user.uid).get();
  const data = snap.exists ? snap.data() || {} : {};
  const rule = Number(data.isAdminRule ?? data.IsAdminRule ?? 0);

  if (data.isAdmin === true || data.IsAdmin === true || rule === 1) {
    return { kind: "global" };
  }

  // Country-scoped: claims country_id or profile country refs.
  const fromClaim = normalizeCountryPath(claims.country_id);
  const fromProfile =
    normalizeCountryPath(data.Rev_dloh_agent) ||
    normalizeCountryPath(data.Rev_dolh);
  const countryPath = fromClaim || fromProfile;

  if (
    (claims.country_admin === true ||
      claims.agent === true ||
      rule === 2 ||
      data.Isagent === true ||
      data.isagent === true) &&
    countryPath
  ) {
    return { kind: "country", countryPath };
  }

  // Finance + country_admin hybrid: still country-scoped when country present.
  if (claims.finance === true && countryPath) {
    return { kind: "country", countryPath };
  }

  return { kind: "denied" };
}

/**
 * Throws unless caller is global finance/admin OR country-scoped panel role.
 * Callers must still enforce resource country via assertResourceCountryAccess.
 */
export async function requireFinanceOrAdmin(
  user: AuthedUser,
): Promise<Exclude<FinanceAccess, { kind: "denied" }>> {
  const access = await resolveFinanceAccess(user);
  if (access.kind === "denied") {
    throw new ApiError(PaymentErrorCode.FORBIDDEN, 403);
  }
  return access;
}

/** F07 — resource country must match caller country for scoped roles. */
export function assertResourceCountryAccess(
  access: FinanceAccess,
  resourceCountryPath: string | null | undefined,
): void {
  if (access.kind === "global") return;
  if (access.kind === "denied") {
    throw new ApiError(PaymentErrorCode.FORBIDDEN, 403);
  }
  const resource = normalizeCountryPath(resourceCountryPath);
  if (!resource || resource !== access.countryPath) {
    throw new ApiError(PaymentErrorCode.FORBIDDEN, 403);
  }
}

/** Extract country path from payment session / order-like docs. */
export function resourceCountryFromDoc(
  data: Record<string, unknown> | null | undefined,
): string | null {
  if (!data) return null;
  return (
    normalizeCountryPath(data.countryPath) ||
    normalizeCountryPath(data.country_path) ||
    normalizeCountryPath(data.countryId) ||
    normalizeCountryPath(data.country_id) ||
    normalizeCountryPath(data.Rev_dolh) ||
    null
  );
}

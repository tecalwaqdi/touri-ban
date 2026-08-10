import type { DecodedIdToken } from "firebase-admin/auth";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { auth, db, COLLECTIONS } from "@/lib/firebase/admin";
import { logger } from "@/lib/logging/logger";

export type AuthedUser = {
  uid: string;
  email?: string;
  token: DecodedIdToken;
};

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

/**
 * Reuses existing project role model:
 * custom claims super_admin / finance OR Firestore user admin flags.
 */
export async function requireFinanceOrAdmin(user: AuthedUser): Promise<void> {
  const claims = user.token as DecodedIdToken & {
    super_admin?: boolean;
    finance?: boolean;
  };
  if (claims.super_admin === true || claims.finance === true) return;

  const snap = await db().collection(COLLECTIONS.users).doc(user.uid).get();
  if (!snap.exists) throw new ApiError(PaymentErrorCode.FORBIDDEN, 403);
  const data = snap.data() || {};
  const rule = Number(data.isAdminRule ?? data.IsAdminRule ?? 0);
  if (data.isAdmin === true || data.IsAdmin === true || rule === 1 || rule === 2) {
    return;
  }
  throw new ApiError(PaymentErrorCode.FORBIDDEN, 403);
}

import type { DecodedIdToken } from "firebase-admin/auth";
import { ApiError, PaymentErrorCode } from "@/lib/errors/codes";
import { auth, db, COLLECTIONS } from "@/lib/firebase/admin";

export type AuthedUser = {
  uid: string;
  email?: string;
  token: DecodedIdToken;
};

export async function verifyBearerToken(
  authorizationHeader: string | null,
): Promise<AuthedUser> {
  if (!authorizationHeader || !authorizationHeader.startsWith("Bearer ")) {
    throw new ApiError(PaymentErrorCode.AUTH_REQUIRED, 401);
  }
  const token = authorizationHeader.slice("Bearer ".length).trim();
  if (!token) throw new ApiError(PaymentErrorCode.AUTH_REQUIRED, 401);
  try {
    const decoded = await auth().verifyIdToken(token, true);
    return { uid: decoded.uid, email: decoded.email, token: decoded };
  } catch {
    throw new ApiError(PaymentErrorCode.AUTH_INVALID, 401);
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

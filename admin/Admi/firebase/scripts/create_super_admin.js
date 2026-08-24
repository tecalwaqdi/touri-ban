/**
 * Creates or updates a super-admin panel user (Auth + Firestore + custom claims).
 *
 * Usage:
 *   cd firebase/functions
 *   ADMIN_EMAIL=... ADMIN_PASSWORD=... node ../scripts/create_super_admin.js
 *
 * Required env:
 *   ADMIN_EMAIL
 *   ADMIN_PASSWORD
 * Optional:
 *   ADMIN_NAME
 *
 * AUD-B-001: no hardcoded credential defaults — fail closed if env missing.
 */

const path = require("path");
const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));

const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = String(process.env.ADMIN_EMAIL || "").trim();
const PASSWORD = String(process.env.ADMIN_PASSWORD || "");
const DISPLAY_NAME =
  String(process.env.ADMIN_NAME || "").trim() || "Super Admin";

if (!EMAIL || !PASSWORD) {
  console.error(
    "Refusing to run: set ADMIN_EMAIL and ADMIN_PASSWORD in the environment (no defaults).",
  );
  process.exit(1);
}

function initAdmin() {
  if (admin.apps.length) return;
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
    });
  } catch (_) {
    admin.initializeApp({ projectId: PROJECT_ID });
  }
}

function deriveClaims(data) {
  const claims = {};
  const rule = data.isAdminRule ?? data.IsAdminRule ?? 0;
  const ruleNum = typeof rule === "string" ? parseInt(rule, 10) : rule;

  if (data.IsAdmin === true || data.isAdmin === true || ruleNum === 1) {
    claims.super_admin = true;
    claims.finance = true;
    claims.support = true;
  }
  return claims;
}

async function getUserByEmail(auth, email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === "auth/user-not-found") return null;
    throw e;
  }
}

async function main() {
  initAdmin();
  const auth = admin.auth();
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  console.log(`Creating/updating super admin: ${EMAIL}`);

  let existing = await getUserByEmail(auth, EMAIL);
  let uid;

  if (existing) {
    uid = existing.uid;
    await auth.updateUser(uid, {
      password: PASSWORD,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      disabled: false,
    });
    console.log("Updated existing Auth user:", uid);
  } else {
    const created = await auth.createUser({
      email: EMAIL,
      password: PASSWORD,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      disabled: false,
    });
    uid = created.uid;
    console.log("Created Auth user:", uid);
  }

  const userDoc = {
    email: EMAIL,
    display_name: DISPLAY_NAME,
    uid,
    created_time: now,
    actev_user: true,
    IsAdmin: true,
    isAdminRule: 1,
  };

  await db.collection("user").doc(uid).set(userDoc, { merge: true });
  console.log("Firestore user doc written: user/" + uid);

  const claims = deriveClaims(userDoc);
  await auth.setCustomUserClaims(uid, claims);
  console.log("Custom claims set:", JSON.stringify(claims));

  console.log("\n=== Super admin ready ===");
  console.log("Email:   ", EMAIL);
  console.log("Password: [REDACTED]");
  console.log("UID:     ", uid);
}

main().catch((err) => {
  console.error("Failed:", err.message || err);
  if (
    String(err.message || err).includes("Could not load the default credentials")
  ) {
    console.error(
      "\nSet Firebase Admin credentials:\n" +
        "  firebase login\n" +
        "  gcloud auth application-default login\n" +
        "  OR set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON\n",
    );
  }
  process.exit(1);
});

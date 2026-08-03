/**
 * Creates or updates a super-admin panel user (Auth + Firestore + custom claims).
 *
 * Usage:
 *   cd firebase/functions
 *   node ../scripts/create_super_admin.js
 *
 * Optional env:
 *   ADMIN_EMAIL=alwaqdi@gmail.com
 *   ADMIN_PASSWORD=alwaqdi@2026
 *   ADMIN_NAME="الواقدي"
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
const EMAIL = process.env.ADMIN_EMAIL || "alwaqdi@gmail.com";
const PASSWORD = process.env.ADMIN_PASSWORD || "alwaqdi@2026";
const DISPLAY_NAME = process.env.ADMIN_NAME || "الواقدي - سوبر أدمن";

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
  console.log("Password:", PASSWORD);
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

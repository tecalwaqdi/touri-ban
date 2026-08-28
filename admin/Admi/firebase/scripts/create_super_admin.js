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
 * Never logs the password.
 */

const fs = require("fs");
const os = require("os");
const path = require("path");
const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));
const {UserRefreshClient} = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "google-auth-library",
));

const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = String(process.env.ADMIN_EMAIL || "").trim().toLowerCase();
const PASSWORD = String(process.env.ADMIN_PASSWORD || "");
const DISPLAY_NAME =
  String(process.env.ADMIN_NAME || "").trim() || "Super Admin";

// Public OAuth client embedded in firebase-tools (not a secret).
const FIREBASE_TOOLS_CLIENT_ID =
  "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const FIREBASE_TOOLS_CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi";

if (!EMAIL || !PASSWORD) {
  console.error(
    "Refusing to run: set ADMIN_EMAIL and ADMIN_PASSWORD in the environment (no defaults).",
  );
  process.exit(1);
}

if (PASSWORD.length < 8) {
  console.error("Refusing to run: ADMIN_PASSWORD must be at least 8 characters.");
  process.exit(1);
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

async function credentialFromFirebaseTools() {
  const cfgPath = path.join(
    os.homedir(),
    ".config",
    "configstore",
    "firebase-tools.json",
  );
  if (!fs.existsSync(cfgPath)) {
    throw new Error("firebase-tools.json not found — run: firebase login");
  }
  const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
  const refreshToken = cfg.tokens && cfg.tokens.refresh_token;
  if (!refreshToken) {
    throw new Error("No firebase-tools refresh token — run: firebase login");
  }
  const client = new UserRefreshClient(
    FIREBASE_TOOLS_CLIENT_ID,
    FIREBASE_TOOLS_CLIENT_SECRET,
    refreshToken,
  );
  const {credentials} = await client.refreshAccessToken();
  const accessToken = credentials.access_token;
  const expiry = credentials.expiry_date || Date.now() + 3500 * 1000;
  return {
    getAccessToken: async () => ({
      access_token: accessToken,
      expires_in: Math.max(60, Math.floor((expiry - Date.now()) / 1000)),
    }),
  };
}

async function initAdmin() {
  if (admin.apps.length) return;

  // Prefer an explicit service-account JSON (works for Auth + Firestore).
  const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (saPath && fs.existsSync(saPath)) {
    const sa = JSON.parse(fs.readFileSync(saPath, "utf8"));
    if (sa.client_email && sa.private_key) {
      admin.initializeApp({
        credential: admin.credential.cert(sa),
        projectId: PROJECT_ID,
      });
      return;
    }
  }

  const tryAdc = async () => {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
    });
    // Force an Auth round-trip; ADC often 403s Identity Toolkit without quota.
    try {
      await admin.auth().getUser("0000000000000000000000000000");
    } catch (e) {
      if (e.code === "auth/user-not-found") return; // Auth API reachable
      throw e;
    }
  };

  try {
    await tryAdc();
    return;
  } catch (_) {
    if (admin.apps.length) {
      await admin.app().delete().catch(() => {});
    }
  }

  // firebase-tools OAuth works for Auth but NOT Firestore — last resort only.
  const cred = await credentialFromFirebaseTools();
  admin.initializeApp({
    credential: cred,
    projectId: PROJECT_ID,
  });
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
  await initAdmin();
  const auth = admin.auth();
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  console.log(`Creating/updating super admin: ${EMAIL}`);

  let existing = await getUserByEmail(auth, EMAIL);
  let uid;
  let authUserExisted = false;

  if (existing) {
    authUserExisted = true;
    uid = existing.uid;
    await auth.updateUser(uid, {
      password: PASSWORD,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      disabled: false,
    });
    console.log("AUTH_USER_REUSED = true");
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
    console.log("AUTH_USER_CREATED = PASS");
    console.log("Created Auth user:", uid);
  }

  // Canonical Super Admin identity — clear conflicting panel roles.
  const userDoc = {
    email: EMAIL,
    display_name: DISPLAY_NAME,
    uid,
    created_time: now,
    actev_user: true,
    IsAdmin: true,
    isAdmin: true,
    isAdminRule: 1,
    isagent: false,
    isPartner: false,
    Isagent: false,
  };

  await db.collection("user").doc(uid).set(userDoc, {merge: true});
  // Explicitly unset transport / partner linkage if present as null-safe clears.
  await db.collection("user").doc(uid).set(
    {
      transport_company_id: admin.firestore.FieldValue.delete(),
      partner_mkan_id: admin.firestore.FieldValue.delete(),
    },
    {merge: true},
  );
  console.log("SUPER_ADMIN_ROLE_DOC = PASS");
  console.log("Firestore user doc written: user/" + uid);

  const claims = deriveClaims(userDoc);
  await auth.setCustomUserClaims(uid, claims);
  const verified = await auth.getUser(uid);
  const got = verified.customClaims || {};
  if (got.super_admin !== true) {
    throw new Error("CUSTOM_CLAIMS verification failed: super_admin missing");
  }
  console.log("SUPER_ADMIN_CLAIMS = PASS");
  console.log("Custom claims set:", JSON.stringify(claims));

  console.log("\n=== Super admin ready ===");
  console.log("Email:   ", EMAIL);
  console.log("Password: [REDACTED]");
  console.log("UID:     ", uid);
  console.log("Auth existed before:", authUserExisted);
}

main().catch((err) => {
  console.error("Failed:", err.message || err);
  if (
    String(err.message || err).includes("Could not load the default credentials") ||
    String(err.message || err).includes("firebase-tools")
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

#!/usr/bin/env node
/**
 * Seeds / repairs the App Store review driver demo account.
 *
 * Default credentials (App Store Connect):
 *   Email:    info@touri-taxi.com
 *   Password: tourytaxi@2030
 *
 * Prerequisites:
 *   gcloud auth application-default login
 *   cd admin/ara_oatan_app/firebase/functions && npm ci
 *
 * Usage:
 *   node admin/scripts/seed_app_store_driver_review.js
 *   REVIEW_EMAIL=... REVIEW_PASSWORD=... node admin/scripts/seed_app_store_driver_review.js
 */
const path = require("path");
const admin = require(path.join(
  __dirname,
  "../ara_oatan_app/firebase/functions/node_modules",
  "firebase-admin",
));

const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = (process.env.REVIEW_EMAIL || "info@touri-taxi.com")
  .trim()
  .toLowerCase();
const PASSWORD = process.env.REVIEW_PASSWORD || "tourytaxi@2030";
const DISPLAY_NAME = process.env.REVIEW_NAME || "Touri Demo Driver";
const PHONE = process.env.REVIEW_PHONE || "+966500000099";
const WALLET_SAR = Number(process.env.REVIEW_WALLET_SAR || 2000);

async function getUserByEmail(auth, email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === "auth/user-not-found") return null;
    throw e;
  }
}

async function firstRef(db, candidates) {
  for (const name of candidates) {
    const snap = await db.collection(name).limit(1).get();
    if (!snap.empty) {
      const doc = snap.docs[0];
      return { ref: doc.ref, collection: name, data: doc.data() };
    }
  }
  return null;
}

async function ensureWallet(db, uid, userRef, amountSar) {
  const wallets = await db
    .collection("wallets")
    .where("userRef", "==", userRef)
    .limit(1)
    .get();
  const walletRef = wallets.empty
    ? db.collection("wallets").doc(uid)
    : wallets.docs[0].ref;

  await walletRef.set(
    {
      userRef,
      currentBalance: amountSar,
      walletBalance: amountSar,
      currency: "SAR",
      isActive: true,
      walletUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return walletRef.id;
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
    });
  }

  const auth = admin.auth();
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();

  console.log(`Seeding App Store review driver: ${EMAIL}`);

  let authUser = await getUserByEmail(auth, EMAIL);
  if (authUser) {
    await auth.updateUser(authUser.uid, {
      password: PASSWORD,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      disabled: false,
    });
    console.log(`Updated existing Auth user ${authUser.uid}`);
  } else {
    authUser = await auth.createUser({
      email: EMAIL,
      password: PASSWORD,
      displayName: DISPLAY_NAME,
      emailVerified: true,
      disabled: false,
    });
    console.log(`Created Auth user ${authUser.uid}`);
  }

  const uid = authUser.uid;
  const userRef = db.collection("user").doc(uid);

  const city = await firstRef(db, ["mndob_vill", "vill", "city"]);
  const car = await firstRef(db, ["type_car", "typeCar"]);

  if (!city) {
    throw new Error(
      "No city document found (mndob_vill). Seed geography first.",
    );
  }
  if (!car) {
    throw new Error("No vehicle type found (type_car). Seed catalog first.");
  }

  const cityName =
    city.data.naim ||
    city.data.name ||
    city.data.name_ar ||
    city.data.title ||
    "Jeddah";
  const carName =
    car.data.naim ||
    car.data.name ||
    car.data.name_ar ||
    car.data.title ||
    "Economy";

  const profile = {
    uid,
    email: EMAIL,
    display_name: DISPLAY_NAME,
    phone_number: PHONE,
    created_time: now,
    ismndob: true,
    ismndom: true,
    actev_mndob: true,
    ngl: false,
    mndon_newacc: false,
    registration_status: "approved",
    submission_status: "approved",
    account_status: "active",
    operational_status: "offline",
    vehicle_review_status: "approved",
    document_review_status: "approved",
    auto_activated: true,
    approved_at: now,
    reviewed_at: now,
    reviewed_by: "app_store_review_seed",
    mndob_vill: city.ref,
    mndob_vill_text: String(cityName),
    mndob_type_car: car.ref,
    text_type_car_mndob: String(carName),
    number_lohh_car: "ABC 1234",
    sequenceNumber: "1234567890",
    driverId: uid,
    app_store_review_account: true,
    last_seen_at: now,
  };

  await userRef.set(profile, { merge: true });

  const existingClaims = (await auth.getUser(uid)).customClaims || {};
  await auth.setCustomUserClaims(uid, {
    ...existingClaims,
    driver: true,
    driver_active: true,
  });

  const walletId = await ensureWallet(db, uid, userRef, WALLET_SAR);

  console.log(
    JSON.stringify(
      {
        ok: true,
        email: EMAIL,
        password: PASSWORD,
        uid,
        city: { id: city.ref.id, collection: city.collection, name: cityName },
        vehicle: { id: car.ref.id, collection: car.collection, name: carName },
        walletId,
        walletSar: WALLET_SAR,
        message:
          "Demo driver ready. Sign in on device, allow location while using the app, then go online.",
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error("FAILED", e.code || "", e.message || e);
  process.exit(1);
});

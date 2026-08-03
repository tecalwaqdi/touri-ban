/**
 * Seeds 4 demo panel users + supporting Firestore data.
 *
 * Usage (from project root):
 *   cd firebase/functions && node ../scripts/seed_demo_users.js
 *
 * Requires Firebase Admin credentials (one of):
 *   - GOOGLE_APPLICATION_CREDENTIALS pointing to a service account JSON
 *   - gcloud auth application-default login
 *
 * Demo password for all accounts: Demo@2026
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
const DEMO_PASSWORD = "Demo@2026";

const USERS = [
  {
    key: "super_admin",
    email: "demo.super@arawatan.sa",
    displayName: "سوبر أدمن تجريبي",
    phone: "+966500000001",
    firestore: {
      IsAdmin: true,
      isAdminRule: 1,
      actev_user: true,
    },
  },
  {
    key: "country_agent",
    email: "demo.agent@arawatan.sa",
    displayName: "وكيل دولة تجريبي",
    phone: "+966500000002",
    firestore: {
      Isagent: true,
      isAdminRule: 2,
      actev_user: true,
    },
  },
  {
    key: "partner",
    email: "demo.partner@arawatan.sa",
    displayName: "شريك تجريبي",
    phone: "+966500000003",
    firestore: {
      is_partner: true,
      isAdminRule: 3,
      actev_user: true,
    },
  },
  {
    key: "transport_manager",
    email: "demo.transport@arawatan.sa",
    displayName: "مدير شركة نقل تجريبي",
    phone: "+966500000004",
    firestore: {
      isAdminRule: 4,
      actev_user: true,
    },
  },
];

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

async function getUserByEmail(auth, email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === "auth/user-not-found") return null;
    throw e;
  }
}

async function upsertAuthUser(auth, spec) {
  const existing = await getUserByEmail(auth, spec.email);
  if (existing) {
    await auth.updateUser(existing.uid, {
      password: DEMO_PASSWORD,
      displayName: spec.displayName,
      emailVerified: true,
      disabled: false,
    });
    return existing.uid;
  }

  const created = await auth.createUser({
    email: spec.email,
    password: DEMO_PASSWORD,
    displayName: spec.displayName,
    emailVerified: true,
    disabled: false,
  });
  return created.uid;
}

async function seedGeoAndCompanies(db, now) {
  const countryRef = db.collection("countries").doc("demo_saudi");
  await countryRef.set(
    {
      naim: "السعودية (تجريبي)",
      osf: "دولة تجريبية لاختبار لوحة الإدارة",
      acctev: true,
      saudi: true,
      vat_percent: 15,
      app_commission_percent: 12,
      num_trteb: 1,
    },
    { merge: true },
  );

  const regionRef = db.collection("cities").doc("demo_region_riyadh");
  await regionRef.set(
    {
      naim: "منطقة الرياض (تجريبي)",
      dolh: countryRef,
      acctev: true,
    },
    { merge: true },
  );

  const villageRef = db.collection("villages").doc("demo_city_riyadh");
  await villageRef.set(
    {
      naim: "الرياض (تجريبي)",
      cities: regionRef,
      dolh: countryRef,
      acctev: true,
    },
    { merge: true },
  );

  const mkanRef = db.collection("mkan").doc("demo_partner_mkan");
  await mkanRef.set(
    {
      naim: "منتجع الشريك التجريبي",
      osf: "معلم شريك سياحي للاختبار — يشمل إقامة وفعاليات",
      img1:
        "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/tutorial-multi-language-70gx4j/assets/demo/landmark.jpg",
      acctev: true,
      isShrek: true,
      ismzod: true,
      as_ads: true,
      tsnef: "شريك سياحي",
      Rev_dolh: countryRef,
      id_cit: regionRef,
      id_vill: villageRef,
      address: "الرياض، المملكة العربية السعودية",
      mdh: "+966500000003",
      rate: 4.5,
      Location: new admin.firestore.GeoPoint(24.7136, 46.6753),
      dataAdd: now,
      EmailUser: "demo.partner@arawatan.sa",
    },
    { merge: true },
  );

  const companyRef = db.collection("transport_company").doc("demo_transport_co");
  await companyRef.set(
    {
      naim: "شركة النقل التجريبية",
      license_number: "DEMO-LIC-2026-001",
      Rev_dolh: countryRef,
      dolh_text: "السعودية (تجريبي)",
      phone: "+966500000004",
      email: "demo.transport@arawatan.sa",
      actev: true,
      created_time: now,
    },
    { merge: true },
  );

  return { countryRef, regionRef, villageRef, mkanRef, companyRef };
}

async function seedSampleOrder(db, countryRef, mkanRef, now) {
  const orderRef = db.collection("order").doc("demo_order_001");
  await orderRef.set(
    {
      total: 1250,
      ALLNOW: true,
      Rev_dolh: countryRef,
      data_order: now,
      IDorder: "DEMO-001",
      naim_user_text: "عميل تجريبي",
      halh_order: "Pending",
      halh: "pending",
      listAmakn: [
        {
          mkan: mkanRef,
          naim: "منتجع الشريك التجريبي",
          cost: 1250,
        },
      ],
    },
    { merge: true },
  );
}

async function main() {
  initAdmin();
  const auth = admin.auth();
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  console.log("Seeding demo geo data...");
  const geo = await seedGeoAndCompanies(db, now);

  console.log("Seeding demo order...");
  await seedSampleOrder(db, geo.countryRef, geo.mkanRef, now);

  const agentEnd = new Date();
  agentEnd.setFullYear(agentEnd.getFullYear() + 1);
  const agentStart = new Date();

  const results = [];

  for (const spec of USERS) {
    console.log(`Upserting ${spec.key} (${spec.email})...`);
    const uid = await upsertAuthUser(auth, spec);

    const userDoc = {
      email: spec.email,
      display_name: spec.displayName,
      phone_number: spec.phone,
      uid,
      created_time: now,
      ...spec.firestore,
    };

    if (spec.key === "country_agent") {
      userDoc.dolh_agent = "السعودية (تجريبي)";
      userDoc.Rev_dloh_agent = geo.countryRef;
      userDoc.agent_date_reg = admin.firestore.Timestamp.fromDate(agentStart);
      userDoc.agent_date_end = admin.firestore.Timestamp.fromDate(agentEnd);
      userDoc.Agent_total = 10;
      userDoc.Bookings_Agent = 0;
    }

    if (spec.key === "partner") {
      userDoc.partner_mkan = geo.mkanRef;
    }

    if (spec.key === "transport_manager") {
      userDoc.transport_company = geo.companyRef;
      userDoc.transport_company_text = "شركة النقل التجريبية";
      await geo.companyRef.set({ owner_user: db.collection("user").doc(uid) }, {
        merge: true,
      });
    }

    await db.collection("user").doc(uid).set(userDoc, { merge: true });

    results.push({
      role: spec.key,
      email: spec.email,
      password: DEMO_PASSWORD,
      uid,
    });
  }

  console.log("\n=== Demo users ready ===\n");
  console.log("Password for ALL accounts:", DEMO_PASSWORD);
  console.log("");
  for (const r of results) {
    console.log(`- ${r.role}`);
    console.log(`  Email: ${r.email}`);
    console.log(`  UID:   ${r.uid}`);
    console.log("");
  }
  console.log("Supporting docs:");
  console.log("  countries/demo_saudi");
  console.log("  cities/demo_region_riyadh");
  console.log("  villages/demo_city_riyadh");
  console.log("  mkan/demo_partner_mkan");
  console.log("  transport_company/demo_transport_co");
  console.log("  order/demo_order_001");
}

main().catch((err) => {
  console.error("Seed failed:", err.message || err);
  if (
    String(err.message || err).includes("Could not load the default credentials")
  ) {
    console.error(
      "\nSet up Admin SDK credentials, then re-run:\n" +
        "  1. Firebase Console → Project Settings → Service accounts → Generate key\n" +
        "  2. set GOOGLE_APPLICATION_CREDENTIALS=path\\to\\key.json\n" +
        "  3. cd firebase/functions && node ../scripts/seed_demo_users.js\n",
    );
  }
  process.exit(1);
});

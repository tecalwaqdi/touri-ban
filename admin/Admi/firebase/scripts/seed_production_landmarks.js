/**
 * Seeds production Saudi tourism data (50 landmarks, orders, geo).
 *
 * Usage:
 *   cd firebase/functions && node ../scripts/seed_production_landmarks.js
 *
 * Requires Firebase Admin credentials (ADC or GOOGLE_APPLICATION_CREDENTIALS).
 */

const path = require("path");
const fs = require("fs");
const admin = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "firebase-admin",
));

const PROJECT_ID = "tutorial-multi-language-70gx4j";
const DATA = JSON.parse(
  fs.readFileSync(path.join(__dirname, "production_seed_data.json"), "utf8"),
);

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

function geoPoint(lat, lng) {
  return new admin.firestore.GeoPoint(lat, lng);
}

function daysAgoDate(days) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return admin.firestore.Timestamp.fromDate(d);
}

async function commitBatches(db, ops) {
  const chunk = 400;
  for (let i = 0; i < ops.length; i += chunk) {
    const batch = db.batch();
    for (const op of ops.slice(i, i + chunk)) {
      op(batch);
    }
    await batch.commit();
  }
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const countryRef = db.collection("countries").doc(DATA.countryId);
  const regionRefs = {};
  const cityRefs = {};
  const mkanRefs = {};
  const ops = [];

  ops.push((b) =>
    b.set(
      countryRef,
      {
        naim: DATA.countryName,
        osf: DATA.countryDesc,
        acctev: true,
        saudi: true,
        vat_percent: 15,
        app_commission_percent: 12,
        num_trteb: 1,
      },
      { merge: true },
    ),
  );

  for (const region of DATA.regions) {
    const regionRef = db.collection("cities").doc(region.id);
    regionRefs[region.id] = regionRef;
    ops.push((b) =>
      b.set(
        regionRef,
        { naim: region.name, dolh: countryRef, acctev: true },
        { merge: true },
      ),
    );
    for (const city of region.cities) {
      const cityRef = db.collection("villages").doc(city.id);
      cityRefs[city.id] = cityRef;
      ops.push((b) =>
        b.set(
          cityRef,
          {
            naim: city.name,
            cities: regionRef,
            dolh: countryRef,
            acctev: true,
          },
          { merge: true },
        ),
      );
    }
  }

  const vehicleTypes = [
    ["type_sedan", "سيدان", 1],
    ["type_suv", "دفع رباعي", 2],
    ["type_van", "فان عائلي", 3],
    ["type_bus", "حافلة سياحية", 4],
  ];
  for (const [id, name, sr] of vehicleTypes) {
    ops.push((b) =>
      b.set(
        db.collection("type_car").doc(id),
        { naim: name, sr, acctev: true },
        { merge: true },
      ),
    );
  }

  const categories = [
    ["cat_heritage", "تراث وثقافة"],
    ["cat_nature", "طبيعة ومغامرات"],
    ["cat_religious", "مواقع دينية"],
    ["cat_modern", "معالم حديثة"],
  ];
  for (const [id, name] of categories) {
    ops.push((b) =>
      b.set(
        db.collection("Classification").doc(id),
        { naim: name, acctev: true },
        { merge: true },
      ),
    );
  }

  console.log("Writing geo + types...");
  await commitBatches(db, ops);

  const landmarkOps = [];
  for (const lm of DATA.landmarks) {
    const regionRef = regionRefs[lm.regionId];
    const cityRef = cityRefs[lm.cityId];
    if (!regionRef || !cityRef) {
      console.warn("Skip landmark (missing geo):", lm.id);
      continue;
    }
    const ref = db.collection("mkan").doc(lm.id);
    mkanRefs[lm.id] = ref;
    const doc = {
      naim: lm.name,
      osf: lm.description,
      img1: lm.img1,
      img2: lm.img2 || "",
      img3: lm.img3 || "",
      sr: lm.sortOrder,
      ismsgd: !!lm.isMosque,
      isfood: lm.isFood !== false,
      ishmam: lm.isRestroom !== false,
      acctev: true,
      id_cit: regionRef,
      id_vill: cityRef,
      Rev_dolh: countryRef,
      Location: geoPoint(lm.lat, lm.lng),
      address: lm.address,
      mdh: lm.phone || "+966112345678",
      as_ads: true,
      ismzod: true,
      isShrek: !!lm.isPartner,
      tsnef: lm.category || "معلم سياحي",
      rate: lm.rate ?? 4.6,
      add_saat: 2,
      dataAdd: daysAgoDate(lm.daysAgo ?? 180),
    };
    if (lm.isPartner) {
      doc.EmailUser = `partner.${lm.id}@arawatan.sa`;
    }
    landmarkOps.push((b) => b.set(ref, doc, { merge: true }));
  }

  console.log(`Writing ${landmarkOps.length} landmarks...`);
  await commitBatches(db, landmarkOps);

  const orderOps = [];
  const rng = DATA.landmarks.length;
  const customers = DATA.customerNames;
  const baseNow = Date.now();

  for (let monthOffset = 11; monthOffset >= 0; monthOffset--) {
    for (let i = 0; i < 8; i++) {
      const lm = DATA.landmarks[(monthOffset * 3 + i) % rng];
      const mkanRef = mkanRefs[lm.id];
      if (!mkanRef) continue;

      const orderDate = new Date(
        baseNow - (monthOffset * 28 + i * 4 + 3) * 86400000,
      );
      const total = 450 + monthOffset * 37 + i * 125;
      const isPaid = (monthOffset + i) % 4 !== 0;
      const isCanceled = !isPaid && i === 4;
      const halh = isCanceled ? "canceled" : isPaid ? "paid" : "pending";
      const halhOrder = isCanceled ? "Canceled" : isPaid ? "Paid" : "Pending";
      const orderId = `order_${orderDate.getFullYear()}${String(orderDate.getMonth() + 1).padStart(2, "0")}_${String(monthOffset * 8 + i + 1).padStart(3, "0")}`;

      const doc = {
        total,
        total_app: Math.round(total * 0.12),
        total_vat: Math.round(total * 0.15),
        ALLNOW: !isCanceled && !isPaid,
        Rev_dolh: countryRef,
        data_order: admin.firestore.Timestamp.fromDate(orderDate),
        IDorder: `ARW-${orderDate.getFullYear()}${String(orderDate.getMonth() + 1).padStart(2, "0")}-${String(monthOffset * 8 + i + 1).padStart(4, "0")}`,
        naim_user_text: customers[(monthOffset + i) % customers.length],
        halh_order: halhOrder,
        halh,
        cartext: lm.name,
        listAmakn: [
          {
            naim: lm.name,
            mkanRev: [mkanRef],
            sr: total,
          },
        ],
      };
      if (lm.isPartner) {
        doc.partner_mkans = [mkanRef];
      }
      orderOps.push((b) =>
        b.set(db.collection("order").doc(orderId), doc, { merge: true }),
      );
    }
  }

  console.log(`Writing ${orderOps.length} orders...`);
  await commitBatches(db, orderOps);

  const tickets = [
    "استفسار عن حجز معلم",
    "تأخر وصول المندوب",
    "طلب تعديل موعد",
    "مشكلة في الدفع",
    "اقتراح إضافة معلم",
  ];
  const supportOps = tickets.map((subject, t) => (b) =>
    b.set(
      db.collection("support").doc(`support_${t + 1}`),
      {
        id: t + 1,
        naim: subject,
        osf: `تذكرة دعم رقم ${t + 1} — تم فتحها ضمن بيانات النظام التشغيلية.`,
        Rev_dolh: countryRef,
        data: daysAgoDate(30 * (t + 1)),
        halh: t % 2 === 0 ? "Open" : "Closed",
      },
      { merge: true },
    ),
  );
  await commitBatches(db, supportOps);

  console.log("\n=== Production seed complete ===");
  console.log(`Landmarks: ${landmarkOps.length}`);
  console.log(`Orders: ${orderOps.length}`);
  console.log(`Regions: ${DATA.regions.length}`);
  console.log(`Support tickets: ${tickets.length}`);
  console.log(`Country: countries/${DATA.countryId}`);
}

main().catch((err) => {
  console.error("Seed failed:", err.message || err);
  process.exit(1);
});

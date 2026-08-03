const admin = require("firebase-admin");

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "tutorial-multi-language-70gx4j";

admin.initializeApp({projectId});
const db = admin.firestore();
const {GeoPoint} = admin.firestore;

const countries = {
  "saudi-arabia": ["sa", [23.89, 45.08], [16.0, 34.0], [33.5, 55.7]],
  "united-arab-emirates": ["ae", [23.42, 53.85], [22.6, 51.5], [26.1, 56.4]],
  qatar: ["qa", [25.35, 51.18], [24.4, 50.7], [26.2, 51.7]],
  kuwait: ["kw", [29.31, 47.48], [28.4, 46.5], [30.2, 48.5]],
  bahrain: ["bh", [26.07, 50.56], [25.5, 50.3], [26.4, 50.9]],
  oman: ["om", [21.47, 55.98], [16.6, 51.8], [26.4, 59.8]],
};

async function main() {
  const batch = db.batch();
  for (const [id, [isoCode, center, southWest, northEast]] of
    Object.entries(countries)) {
    batch.set(db.collection("countries").doc(id), {
      iso_code: isoCode,
      geo_center: new GeoPoint(center[0], center[1]),
      bounds_sw: new GeoPoint(southWest[0], southWest[1]),
      bounds_ne: new GeoPoint(northEast[0], northEast[1]),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  await batch.commit();
  console.log(`Backfilled geographic metadata for ${Object.keys(countries).length} countries.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

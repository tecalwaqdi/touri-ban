const admin = require("firebase-admin");

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "tutorial-multi-language-70gx4j";

admin.initializeApp({projectId});
const db = admin.firestore();

const requiredCountryIds = [
  "saudi-arabia",
  "united-arab-emirates",
  "qatar",
  "kuwait",
  "bahrain",
  "oman",
  "uzbekistan",
  "kyrgyzstan",
  "egypt",
  "jordan",
  "morocco",
  "turkey",
  "indonesia",
  "malaysia",
  "azerbaijan",
  "georgia",
  "iraq",
  "pakistan",
  "india",
];

function hasGeoPoint(value) {
  return value &&
    Number.isFinite(value.latitude) &&
    Number.isFinite(value.longitude);
}

async function verifyCountries(errors) {
  const snapshots = await Promise.all(
    requiredCountryIds.map((id) => db.collection("countries").doc(id).get()),
  );
  for (const snapshot of snapshots) {
    if (!snapshot.exists) {
      errors.push(`Missing country: ${snapshot.id}`);
      continue;
    }
    const data = snapshot.data() || {};
    if (!data.acctev) errors.push(`Inactive country: ${snapshot.id}`);
    if (!String(data.iso_code || "").trim()) {
      errors.push(`Missing ISO code: ${snapshot.id}`);
    }
    if (!String(data.flagEmoji || data.flagUrl || "").trim()) {
      errors.push(`Missing flag: ${snapshot.id}`);
    }
    if (!hasGeoPoint(data.geo_center) ||
        !hasGeoPoint(data.bounds_sw) ||
        !hasGeoPoint(data.bounds_ne)) {
      errors.push(`Missing geographic bounds: ${snapshot.id}`);
    }
  }
  return snapshots.length;
}

async function verifySaudiRegions(errors) {
  const cities = await db.collection("cities")
    .where("dolh", "==", db.collection("countries").doc("saudi-arabia"))
    .get();
  const expandedCities = cities.docs.filter((doc) => {
    const sorting = Number(doc.data().sorting || 0);
    return sorting >= 10;
  });
  if (expandedCities.length !== 13) {
    errors.push(`Expected 13 Saudi regions, found ${expandedCities.length}`);
  }

  let landmarkTotal = 0;
  for (const city of expandedCities) {
    const villages = await db.collection("villages")
      .where("cities", "==", city.ref)
      .where("no_delete_place", "==", true)
      .get();
    if (villages.size !== 1) {
      errors.push(`Expected one route village for ${city.id}, found ${villages.size}`);
      continue;
    }
    const places = await db.collection("mkan")
      .where("id_vill", "==", villages.docs[0].ref)
      .get();
    landmarkTotal += places.size;
    if (places.size !== 20) {
      errors.push(`Expected 20 landmarks for ${city.id}, found ${places.size}`);
    }
    for (const place of places.docs) {
      const data = place.data();
      if (!hasGeoPoint(data.Location) || !String(data.img1 || "").trim()) {
        errors.push(`Incomplete landmark: ${place.id}`);
      }
    }
  }
  return {regions: expandedCities.length, landmarks: landmarkTotal};
}

async function verifyKyrgyzstanRegions(errors) {
  const cities = await db.collection("cities")
    .where("dolh", "==", db.collection("countries").doc("kyrgyzstan"))
    .get();
  const regions = cities.docs.filter((doc) => doc.id.startsWith("kg-"));
  if (regions.length !== 7) {
    errors.push(`Expected 7 Kyrgyzstan regions, found ${regions.length}`);
  }

  let landmarkTotal = 0;
  for (const city of regions) {
    const cityData = city.data();
    const cityNames = cityData.names_i18n || {};
    for (const locale of ["ar", "en", "ru", "ky"]) {
      if (!String(cityNames[locale] || "").trim()) {
        errors.push(`Missing ${locale} region name: ${city.id}`);
      }
    }
    if (!hasGeoPoint(cityData.geo_center) ||
        !hasGeoPoint(cityData.bounds_sw) ||
        !hasGeoPoint(cityData.bounds_ne)) {
      errors.push(`Missing region map bounds: ${city.id}`);
    }

    const villages = await db.collection("villages")
      .where("cities", "==", city.ref)
      .where("no_delete_place", "==", true)
      .get();
    if (villages.size !== 1) {
      errors.push(`Expected one route village for ${city.id}, found ${villages.size}`);
      continue;
    }

    const places = await db.collection("mkan")
      .where("id_vill", "==", villages.docs[0].ref)
      .get();
    landmarkTotal += places.size;
    if (places.size !== 10) {
      errors.push(`Expected 10 Kyrgyzstan landmarks for ${city.id}, found ${places.size}`);
    }
    for (const place of places.docs) {
      const data = place.data();
      const placeNames = data.names_i18n || {};
      if (!hasGeoPoint(data.Location) || !String(data.img1 || "").trim()) {
        errors.push(`Incomplete Kyrgyzstan landmark: ${place.id}`);
      }
      for (const locale of ["ar", "en", "ru", "ky"]) {
        if (!String(placeNames[locale] || "").trim()) {
          errors.push(`Missing ${locale} landmark name: ${place.id}`);
        }
      }
    }
  }
  return {regions: regions.length, landmarks: landmarkTotal};
}

async function main() {
  const errors = [];
  const [countries, saudi, kyrgyzstan] = await Promise.all([
    verifyCountries(errors),
    verifySaudiRegions(errors),
    verifyKyrgyzstanRegions(errors),
  ]);
  console.log(`Verified countries: ${countries}`);
  console.log(`Verified Saudi regions: ${saudi.regions}`);
  console.log(`Verified Saudi landmarks: ${saudi.landmarks}`);
  console.log(`Verified Kyrgyzstan regions: ${kyrgyzstan.regions}`);
  console.log(`Verified Kyrgyzstan landmarks: ${kyrgyzstan.landmarks}`);
  if (errors.length > 0) {
    for (const error of errors) console.error(`- ${error}`);
    throw new Error(`Content verification failed with ${errors.length} issue(s).`);
  }
  console.log("Toury content verification passed.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

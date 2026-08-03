/** Verifies production countries and the 13 x 20 OSM landmark import. */
const { getIdToken } = require("./seed_production_client");

const PROJECT_ID = "tutorial-multi-language-70gx4j";
const BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
  "/databases/(default)/documents";

function value(raw) {
  if (!raw) return null;
  if ("stringValue" in raw) return raw.stringValue;
  if ("booleanValue" in raw) return raw.booleanValue;
  if ("integerValue" in raw) return Number(raw.integerValue);
  if ("referenceValue" in raw) return raw.referenceValue;
  return null;
}

async function listDocs(idToken, collection) {
  const documents = [];
  let pageToken = "";
  do {
    const url = new URL(`${BASE}/${collection}`);
    url.searchParams.set("pageSize", "1000");
    if (pageToken) url.searchParams.set("pageToken", pageToken);
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    if (!response.ok) {
      throw new Error(`${collection}: ${response.status} ${await response.text()}`);
    }
    const payload = await response.json();
    documents.push(...(payload.documents || []));
    pageToken = payload.nextPageToken || "";
  } while (pageToken);
  return documents;
}

async function main() {
  const { idToken } = await getIdToken();
  const [countries, cities, landmarks] = await Promise.all([
    listDocs(idToken, "countries"),
    listDocs(idToken, "cities"),
    listDocs(idToken, "mkan"),
  ]);

  const activeCountryIso = new Set(
    countries
      .filter((doc) => value(doc.fields?.acctev) === true)
      .map((doc) => value(doc.fields?.iso_code))
      .filter(Boolean),
  );
  const saudiRegions = cities.filter((doc) =>
    String(value(doc.fields?.iso_code) || "").startsWith("SA-"),
  );
  const osm = landmarks.filter(
    (doc) => value(doc.fields?.source_provider) === "OpenStreetMap",
  );
  const perRegion = {};
  for (const doc of osm) {
    const regionRef = String(value(doc.fields?.id_cit) || "");
    const id = regionRef.split("/").pop();
    perRegion[id] = (perRegion[id] || 0) + 1;
  }
  const invalid = Object.entries(perRegion).filter(([, count]) => count < 20);

  console.log(`Active country ISO codes: ${activeCountryIso.size}`);
  console.log(`Saudi ISO regions: ${saudiRegions.length}`);
  console.log(`OpenStreetMap landmarks: ${osm.length}`);
  console.log("Landmarks per region:", perRegion);

  if (activeCountryIso.size < 22) {
    throw new Error("Expected at least 22 active country ISO codes");
  }
  if (saudiRegions.length !== 13) {
    throw new Error(`Expected 13 Saudi regions, found ${saudiRegions.length}`);
  }
  if (osm.length < 260 || invalid.length) {
    throw new Error(
      `Expected 20 landmarks per region; total=${osm.length}, invalid=${JSON.stringify(invalid)}`,
    );
  }
  console.log("Production geography verification passed.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

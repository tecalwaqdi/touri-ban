/**
 * Seed default landmark_categories (customer filter chips).
 *
 * Usage:
 *   cd admin/Admi/firebase/functions
 *   node ../scripts/seed_landmark_categories.js
 *
 * Auth: firebase-tools refresh token (after `firebase login`), or
 * GOOGLE_APPLICATION_CREDENTIALS / ADC when available.
 * Optional: OVERWRITE=1 to replace existing docs.
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const {UserRefreshClient} = require(path.join(
  __dirname,
  "..",
  "functions",
  "node_modules",
  "google-auth-library",
));

const PROJECT_ID = "tutorial-multi-language-70gx4j";
const OVERWRITE = String(process.env.OVERWRITE || "").trim() === "1";
const COLLECTION = "landmark_categories";
const BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const FIREBASE_TOOLS_CLIENT_ID =
  "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const FIREBASE_TOOLS_CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi";

const BUILT_IN = [
  {id: "all", storage: "الكل", labelAr: "الكل", labelEn: "All", icon: "all", trKey: "landmark_cat_all", enabled: true, sort: 0},
  {id: "religious", storage: "معالم دينية", labelAr: "معالم دينية", labelEn: "Religious landmarks", icon: "cloud", trKey: "landmark_cat_religious", enabled: true, sort: 10},
  {id: "historical", storage: "معالم تاريخية", labelAr: "معالم تاريخية", labelEn: "Historical landmarks", icon: "place", trKey: "landmark_cat_historical", enabled: true, sort: 20},
  {id: "tourism", storage: "معالم سياحية", labelAr: "معالم سياحية", labelEn: "Tourist landmarks", icon: "attraction", trKey: "landmark_cat_tourism", enabled: true, sort: 30},
  {id: "entertainment", storage: "أماكن ترفيهية", labelAr: "أماكن ترفيهية", labelEn: "Entertainment", icon: "happy", trKey: "landmark_cat_entertainment", enabled: true, sort: 40},
  {id: "markets", storage: "أسواق", labelAr: "أسواق", labelEn: "Markets", icon: "cart", trKey: "landmark_cat_markets", enabled: true, sort: 50},
  {id: "restaurants", storage: "مطاعم", labelAr: "مطاعم", labelEn: "Restaurants", icon: "food", trKey: "landmark_cat_restaurants", enabled: true, sort: 60},
  {id: "cafe", storage: "مقهى", labelAr: "مقهى", labelEn: "Cafe", icon: "cafe", trKey: "landmark_cat_cafe", enabled: true, sort: 70},
  {id: "hotels", storage: "فنادق", labelAr: "فنادق", labelEn: "Hotels", icon: "hotel", trKey: "landmark_cat_hotels", enabled: true, sort: 80},
  {id: "desert", storage: "جولة برية", labelAr: "جولة برية", labelEn: "Desert tour", icon: "forest", trKey: "landmark_cat_desert", enabled: true, sort: 90},
  {id: "sea", storage: "جولة بحرية", labelAr: "جولة بحرية", labelEn: "Sea tour", icon: "sea", trKey: "landmark_cat_sea", enabled: true, sort: 100},
];

async function accessTokenFromFirebaseTools() {
  const cfgPath = path.join(os.homedir(), ".config", "configstore", "firebase-tools.json");
  if (!fs.existsSync(cfgPath)) throw new Error("firebase-tools.json missing — run: firebase login");
  const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
  const refreshToken = cfg.tokens && cfg.tokens.refresh_token;
  if (!refreshToken) throw new Error("no firebase-tools refresh token — run: firebase login");
  const client = new UserRefreshClient(
    FIREBASE_TOOLS_CLIENT_ID,
    FIREBASE_TOOLS_CLIENT_SECRET,
    refreshToken,
  );
  const {credentials} = await client.refreshAccessToken();
  if (!credentials.access_token) throw new Error("failed to refresh firebase-tools access token");
  return credentials.access_token;
}

function toFirestoreFields(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (typeof v === "string") fields[k] = {stringValue: v};
    else if (typeof v === "boolean") fields[k] = {booleanValue: v};
    else if (typeof v === "number") fields[k] = {integerValue: String(Math.trunc(v))};
    else if (v == null) fields[k] = {nullValue: null};
    else fields[k] = {stringValue: String(v)};
  }
  return fields;
}

async function listDocs(token) {
  const ids = [];
  let pageToken = "";
  do {
    const url = new URL(`${BASE}/${COLLECTION}`);
    url.searchParams.set("pageSize", "100");
    if (pageToken) url.searchParams.set("pageToken", pageToken);
    const res = await fetch(url, {
      headers: {Authorization: `Bearer ${token}`},
    });
    const body = await res.json();
    if (!res.ok) {
      throw new Error(`list failed ${res.status}: ${JSON.stringify(body)}`);
    }
    for (const doc of body.documents || []) {
      const name = String(doc.name || "");
      ids.push(name.split("/").pop());
    }
    pageToken = body.nextPageToken || "";
  } while (pageToken);
  return ids;
}

async function upsertDoc(token, id, data) {
  const fields = toFirestoreFields(data);
  const fieldPaths = Object.keys(data);
  if (OVERWRITE) {
    const res = await fetch(`${BASE}/${COLLECTION}/${encodeURIComponent(id)}`, {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({fields}),
    });
    const body = await res.json();
    if (!res.ok) throw new Error(`upsert ${id} failed ${res.status}: ${JSON.stringify(body)}`);
    return;
  }
  // create-or-merge: PATCH with updateMask
  const url = new URL(`${BASE}/${COLLECTION}/${encodeURIComponent(id)}`);
  for (const fp of fieldPaths) url.searchParams.append("updateMask.fieldPaths", fp);
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({fields}),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`merge ${id} failed ${res.status}: ${JSON.stringify(body)}`);
}

async function main() {
  const token = await accessTokenFromFirebaseTools();
  const existing = OVERWRITE ? new Set() : new Set(await listDocs(token));
  let writes = 0;
  for (const d of BUILT_IN) {
    if (!OVERWRITE && existing.has(d.id)) continue;
    const {id, ...data} = d;
    await upsertDoc(token, id, data);
    writes++;
  }
  const after = await listDocs(token);
  console.log(JSON.stringify({
    project: PROJECT_ID,
    overwrite: OVERWRITE,
    writes,
    totalDocs: after.length,
    ids: after.sort(),
  }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

/**
 * Patch missing Saudi city hero images on villages/* (remote, no app release).
 *
 * Root cause of "Makkah shows Taif": city_sa_makkah.img was empty while
 * IMGVILL cache kept the previous city's URL. Filling img fixes new sessions
 * and devices that load live Firestore; client cache fix still needs IPA.
 *
 * Usage:
 *   node admin/Admi/firebase/scripts/fix_saudi_city_hero_images.js
 *   node admin/Admi/firebase/scripts/fix_saudi_city_hero_images.js --apply
 */
const fs = require("fs");
const path = require("path");

const APPLY = process.argv.includes("--apply");
const PROJECT_ID = "tutorial-multi-language-70gx4j";

/** Stable public Wikimedia heroes (same pattern as city_abha / city_dammam). */
const HERO_BY_CANONICAL = {
  city_sa_makkah:
    "https://upload.wikimedia.org/wikipedia/commons/4/4d/Bab_makkah.jpg",
  city_sa_jeddah:
    "https://upload.wikimedia.org/wikipedia/commons/3/33/Red_Sea_Mall_1_Jeddah.jpg",
  city_sa_taif: null, // already set in prod — keep unless empty
  city_sa_riyadh: null,
  city_sa_tabuk: null,
};

/** Legacy id → canonical (copy img onto both when patching). */
const LEGACY_ALIASES = {
  city_makkah: "city_sa_makkah",
  city_jeddah: "city_sa_jeddah",
  city_taif: "city_sa_taif",
  city_riyadh: "city_sa_riyadh",
  city_tabuk: "city_sa_tabuk",
};

function loadAccessToken() {
  const confPath = path.join(
    process.env.HOME || "",
    ".config/configstore/firebase-tools.json",
  );
  const conf = JSON.parse(fs.readFileSync(confPath, "utf8"));
  const t = conf.tokens;
  if (!t?.access_token) {
    throw new Error("No firebase-tools access_token; run firebase login");
  }
  if (t.expires_at && t.expires_at < Date.now() + 30_000) {
    throw new Error("firebase-tools token expired; run firebase login");
  }
  return t.access_token;
}

function decodeFields(fields) {
  const out = {};
  for (const [k, v] of Object.entries(fields || {})) {
    if (v.stringValue !== undefined) out[k] = v.stringValue;
    else if (v.booleanValue !== undefined) out[k] = v.booleanValue;
    else out[k] = v;
  }
  return out;
}

async function getVillage(token, id) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/villages/${id}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const json = await res.json();
  if (json.error) {
    if (json.error.status === "NOT_FOUND") return null;
    throw new Error(`${id}: ${JSON.stringify(json.error)}`);
  }
  return decodeFields(json.fields);
}

async function patchImg(token, id, img) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/villages/${id}?updateMask.fieldPaths=img`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields: { img: { stringValue: img } } }),
  });
  const json = await res.json();
  if (json.error) throw new Error(`${id} patch: ${JSON.stringify(json.error)}`);
  return json;
}

(async () => {
  const token = loadAccessToken();
  const report = { apply: APPLY, updated: [], skipped: [], missing: [] };

  // Resolve images: prefer configured URL, else copy from canonical if present.
  const resolved = { ...HERO_BY_CANONICAL };
  for (const id of Object.keys(resolved)) {
    const existing = await getVillage(token, id);
    if (!existing) {
      report.missing.push(id);
      continue;
    }
    if (existing.img && existing.img.trim()) {
      resolved[id] = existing.img.trim();
      report.skipped.push({ id, reason: "already_has_img" });
    } else if (!resolved[id]) {
      report.missing.push(`${id}:empty_and_no_default`);
    }
  }

  const targets = new Map();
  for (const [id, img] of Object.entries(resolved)) {
    if (!img) continue;
    const existing = await getVillage(token, id);
    if (!existing) continue;
    if (!(existing.img || "").trim()) {
      targets.set(id, img);
    }
  }
  for (const [legacy, canonical] of Object.entries(LEGACY_ALIASES)) {
    const img = resolved[canonical];
    if (!img) continue;
    const existing = await getVillage(token, legacy);
    if (!existing) {
      report.missing.push(legacy);
      continue;
    }
    if (!(existing.img || "").trim()) {
      targets.set(legacy, img);
    } else {
      report.skipped.push({ id: legacy, reason: "already_has_img" });
    }
  }

  for (const [id, img] of targets) {
    console.log(`${APPLY ? "WRITE" : "WOULD_WRITE"} villages/${id} => ${img.slice(0, 80)}…`);
    if (APPLY) {
      await patchImg(token, id, img);
    }
    report.updated.push({ id, img });
  }

  const out = path.join(__dirname, "fix_saudi_city_hero_images_report.json");
  fs.writeFileSync(out, JSON.stringify(report, null, 2));
  console.log("report", out);
  console.log(JSON.stringify({ updated: report.updated.length, skipped: report.skipped.length, missing: report.missing }, null, 2));
})().catch((e) => {
  console.error(e);
  process.exit(1);
});

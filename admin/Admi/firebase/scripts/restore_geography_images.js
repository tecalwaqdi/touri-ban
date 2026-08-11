/**
 * Restore landmark img1 + soft-disabled docs changed by audit_and_clean_geography --apply.
 * Prefer exact report `from` URLs; fall back to staging/patch map for truncated data URLs.
 *
 * Usage: node restore_geography_images.js
 */
const fs = require("fs");
const path = require("path");

const API_KEY =
  process.env.FIREBASE_WEB_API_KEY ||
  "AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY";
const PROJECT_ID = "tutorial-multi-language-70gx4j";
const EMAIL = process.env.SEED_EMAIL || "demo.super@arawatan.sa";
const PASSWORD = process.env.SEED_PASSWORD || "Demo@2026";
const BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
  "/databases/(default)/documents";

const reportPath = path.join(
  __dirname,
  "audit_and_clean_geography_apply_report.json",
);
const stagingDir = path.resolve(
  __dirname,
  "../../../ara_oatan_app/firebase/tools/geo_import/staging/firestore/mkan",
);
const patchPath = path.resolve(
  __dirname,
  "../../../ara_oatan_app/firebase/tools/geo_import/reports/sa_landmark_images_patch.json",
);
const curatedPath = path.join(__dirname, "curated_landmarks_ready.json");

function firestoreValue(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  throw new Error(`Unsupported value type: ${typeof v}`);
}

async function authRequest(endpoint, body) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
  );
  const json = await res.json();
  if (json.error) throw new Error(json.error.message);
  return json;
}

async function getIdToken() {
  const json = await authRequest("signInWithPassword", {
    email: EMAIL,
    password: PASSWORD,
    returnSecureToken: true,
  });
  return json.idToken;
}

async function patchDoc(idToken, docPath, data) {
  const fields = {};
  const mask = [];
  for (const [k, v] of Object.entries(data)) {
    fields[k] = firestoreValue(v);
    mask.push(`updateMask.fieldPaths=${encodeURIComponent(k)}`);
  }
  const url = `${BASE}/${docPath}?` + mask.join("&");
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${idToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`PATCH ${docPath}: ${res.status} ${text}`);
  }
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function isCompleteReportFrom(from) {
  const s = String(from || "");
  if (!s) return false;
  // Truncated by apply report at 120 chars
  if (s.length >= 120) return false;
  return s.startsWith("http") || s.startsWith("assets/");
}

function loadFallbackMap() {
  const map = new Map();
  try {
    const curated = JSON.parse(fs.readFileSync(curatedPath, "utf8"));
    for (const lm of curated.landmarks || []) {
      if (lm.id && lm.img1) map.set(lm.id, { img1: lm.img1, src: "curated" });
    }
  } catch (_) {}
  try {
    const patch = JSON.parse(fs.readFileSync(patchPath, "utf8"));
    for (const [id, url] of Object.entries(patch.map || {})) {
      if (typeof url === "string" && url.length > 5) {
        map.set(id, { img1: url, src: "sa_landmark_images_patch" });
      }
    }
  } catch (_) {}
  try {
    for (const f of fs.readdirSync(stagingDir)) {
      if (!f.endsWith(".json")) continue;
      const id = f.replace(/\.json$/, "");
      const j = JSON.parse(fs.readFileSync(path.join(stagingDir, f), "utf8"));
      if (j.img1 && String(j.img1).length > 20) {
        map.set(id, { img1: j.img1, src: "staging_mkan" });
      }
    }
  } catch (_) {}
  try {
    const ju = JSON.parse(
      fs.readFileSync(
        path.resolve(
          __dirname,
          "../../../ara_oatan_app/firebase/tools/geo_import/reports/jeddah_user_landmark_images.json",
        ),
        "utf8",
      ),
    );
    for (const row of ju.mapped || []) {
      if (row.id && row.asset) {
        map.set(row.id, { img1: row.asset, src: "jeddah_user_images" });
      }
    }
  } catch (_) {}
  return map;
}

function resolveImage(fix, fallbacks) {
  if (isCompleteReportFrom(fix.from)) {
    return { img1: fix.from, src: "apply_report_from" };
  }
  const fb = fallbacks.get(fix.landmarkId);
  if (fb) return fb;
  return null;
}

async function main() {
  const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
  const fallbacks = loadFallbackMap();
  const idToken = await getIdToken();
  console.log("Auth OK — restoring soft-disabled + original images");

  const reenabled = [];
  const restored = [];
  const skipped = [];
  const errors = [];

  for (const item of report.softDisable || []) {
    try {
      await patchDoc(idToken, `mkan/${item.landmarkId}`, {
        acctev: true,
        deactivated_reason: "",
        geography_restored_at: new Date().toISOString(),
      });
      reenabled.push(item.landmarkId);
      await sleep(70);
    } catch (e) {
      errors.push(`reenable ${item.landmarkId}: ${e.message || e}`);
    }
  }

  for (const fix of report.imageFixes || []) {
    const resolved = resolveImage(fix, fallbacks);
    if (!resolved) {
      skipped.push({
        landmarkId: fix.landmarkId,
        reason: fix.reason,
        note: "no complete original URL available",
      });
      continue;
    }
    try {
      await patchDoc(idToken, `mkan/${fix.landmarkId}`, {
        img1: resolved.img1,
        geography_restored_at: new Date().toISOString(),
      });
      restored.push({
        landmarkId: fix.landmarkId,
        source: resolved.src,
        img1Head: String(resolved.img1).slice(0, 100),
        previousReason: fix.reason,
      });
      await sleep(70);
    } catch (e) {
      errors.push(`img ${fix.landmarkId}: ${e.message || e}`);
    }
  }

  const out = {
    reenabled,
    restoredCount: restored.length,
    skipped,
    errors,
    restored,
    note: "Did not add/remove landmark documents. Soft-disabled were re-enabled. Images restored from report/staging/patch.",
  };
  const outPath = path.join(__dirname, "restore_geography_images_report.json");
  fs.writeFileSync(outPath, JSON.stringify(out, null, 2));
  console.log(
    JSON.stringify(
      {
        reenabled: reenabled.length,
        restored: restored.length,
        skipped: skipped.length,
        errors: errors.length,
        outPath,
        skippedIds: skipped.map((s) => s.landmarkId),
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

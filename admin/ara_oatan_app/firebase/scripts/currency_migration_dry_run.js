#!/usr/bin/env node
/**
 * DRY-RUN ONLY — does not write to Firestore.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./sa.json node currency_migration_dry_run.js
 *
 * Outputs a JSON report of orders missing currency_code and proposed codes.
 */
/* eslint-disable no-console */
const fs = require("fs");
const path = require("path");

const ISO_MAP = { SA: "SAR", KG: "KGS", KGZ: "KGS", RU: "RUB", UZ: "UZS", UZB: "UZS" };
const KNOWN = new Set(["SAR", "KGS", "RUB", "UZS"]);

async function main() {
  let admin;
  try {
    admin = require("firebase-admin");
  } catch {
    console.error("firebase-admin not installed in this folder; run from functions/ or install.");
    process.exit(1);
  }
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  const db = admin.firestore();
  const snap = await db.collection("order").limit(500).get();
  const report = {
    scanned: snap.size,
    alreadyOk: 0,
    proposed: [],
    needsManualReview: [],
    dryRun: true,
    generatedAt: new Date().toISOString(),
  };

  for (const doc of snap.docs) {
    const d = doc.data() || {};
    const existing = String(d.currency_code || "").toUpperCase();
    if (KNOWN.has(existing)) {
      report.alreadyOk += 1;
      continue;
    }
    const legacy = String(d.currency || "").toUpperCase();
    if (KNOWN.has(legacy)) {
      report.proposed.push({ id: doc.id, currency_code: legacy, via: "legacy_currency" });
      continue;
    }
    let countryCode = "";
    try {
      if (d.Rev_dolh) {
        const c = await d.Rev_dolh.get();
        if (c.exists) {
          const cd = c.data() || {};
          countryCode = String(cd.currency_code || cd.currencyCode || "").toUpperCase();
          if (!KNOWN.has(countryCode)) {
            const iso = String(cd.iso_code || cd.isoCode || "").toUpperCase();
            countryCode = ISO_MAP[iso] || "";
          }
        }
      }
    } catch (_) {
      /* ignore */
    }
    if (KNOWN.has(countryCode)) {
      report.proposed.push({ id: doc.id, currency_code: countryCode, via: "country_ref" });
    } else {
      report.needsManualReview.push({
        id: doc.id,
        currency: d.currency || null,
        note: "Could not infer currency_code",
      });
    }
  }

  const out = path.join(__dirname, "currency_migration_dry_run_report.json");
  fs.writeFileSync(out, JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ ...report, proposed: report.proposed.length, needsManualReview: report.needsManualReview.length, out }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

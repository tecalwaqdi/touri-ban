#!/usr/bin/env node
/**
 * Marks existing trial / demo agents so they never enter FIN-9 attribution.
 *
 * Usage:
 *   cd admin/Admi/firebase/functions
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/sa.json \
 *     node ../scripts/flag_demo_agents_exclude_attribution.js [--dry-run]
 */
'use strict';

const path = require('path');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));

const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const DRY_RUN = process.argv.includes('--dry-run');

function initAdmin() {
  if (admin.apps.length) return;
  const sa =
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    path.join(process.env.HOME, 'Downloads/tutorial-multi-language-70gx4j-fb851be1eb3e.json');
  admin.initializeApp({
    credential: admin.credential.cert(require(sa)),
    projectId: PROJECT_ID,
  });
}

function looksLikeTrialOrDemo(data) {
  if (data.trial_agent === true) return true;
  if (data.is_demo_agent === true || data.demo_agent === true) return true;
  if (data.exclude_from_agent_attribution === true) return true;
  const email = String(data.email || '').toLowerCase();
  if (email.includes('trial') || email.includes('demo')) return true;
  const name = String(data.display_name || '').toLowerCase();
  if (name.includes('trial') || name.includes('demo')) return true;
  return false;
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const snap = await db.collection('user').where('Isagent', '==', true).get();

  let matched = 0;
  let updated = 0;
  let already = 0;

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    if (!looksLikeTrialOrDemo(data)) continue;
    matched += 1;

    const needs =
      data.exclude_from_agent_attribution !== true ||
      data.is_demo_agent !== true ||
      data.demo_agent !== true;

    if (!needs) {
      already += 1;
      continue;
    }

    console.log(
      `${DRY_RUN ? '[dry-run] would flag' : 'flagging'} ${doc.id} ${data.email || ''}`,
    );
    if (!DRY_RUN) {
      await doc.ref.set(
        {
          exclude_from_agent_attribution: true,
          is_demo_agent: true,
          demo_agent: true,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      updated += 1;
    } else {
      updated += 1;
    }
  }

  console.log(
    JSON.stringify(
      {
        dryRun: DRY_RUN,
        agentsScanned: snap.size,
        trialOrDemoMatched: matched,
        alreadyFlagged: already,
        updatedOrWouldUpdate: updated,
      },
      null,
      2,
    ),
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

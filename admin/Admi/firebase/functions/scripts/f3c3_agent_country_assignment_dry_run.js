#!/usr/bin/env node
/**
 * F3-C3 dry-run: seed plan for agent_country_assignment locks.
 * READ-ONLY against production unless --apply (disabled by default; C3 does not apply).
 */
'use strict';

const os = require('os');
const path = require('path');

const APPLY = process.argv.includes('--apply');
const project = 'tutorial-multi-language-70gx4j';

function isActive(data) {
  if (!(data.Isagent === true || data.isagent === true)) return false;
  if (data.actev_user === false) return false;
  const now = Date.now();
  const end = data.agent_date_end;
  if (end) {
    const t = end.toDate ? end.toDate().getTime() : Date.parse(end);
    if (!Number.isNaN(t) && t < now) return false;
  }
  const start = data.agent_date_reg;
  if (start) {
    const t = start.toDate ? start.toDate().getTime() : Date.parse(start);
    if (!Number.isNaN(t) && t > now) return false;
  }
  return true;
}

async function main() {
  if (APPLY) {
    console.error('C3 dry-run refuses --apply. Deploy/seed only after F3-C3D approval.');
    process.exit(2);
  }

  const cfg = require(path.join(
    os.homedir(),
    '.config/configstore/firebase-tools.json',
  ));
  const token = (cfg.tokens && cfg.tokens.access_token) || cfg.access_token;

  async function runQuery(structuredQuery) {
    const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents:runQuery`;
    const r = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({structuredQuery}),
    });
    return r.json();
  }

  function fval(fields, k) {
    const v = fields && fields[k];
    if (!v) return null;
    if (v.booleanValue != null) return v.booleanValue;
    if (v.stringValue != null) return v.stringValue;
    if (v.timestampValue) return v.timestampValue;
    if (v.referenceValue) {
      return v.referenceValue.replace(/^.*\/documents\//, '');
    }
    return null;
  }

  const rows = await runQuery({
    from: [{collectionId: 'user'}],
    where: {
      fieldFilter: {
        field: {fieldPath: 'Isagent'},
        op: 'EQUAL',
        value: {booleanValue: true},
      },
    },
  });

  const by = {};
  for (const row of rows) {
    if (!row.document) continue;
    const fields = row.document.fields || {};
    const data = {
      Isagent: fval(fields, 'Isagent'),
      actev_user: fval(fields, 'actev_user'),
      agent_date_reg: fval(fields, 'agent_date_reg'),
      agent_date_end: fval(fields, 'agent_date_end'),
      Rev_dloh_agent: fval(fields, 'Rev_dloh_agent'),
    };
    if (!isActive(data)) continue;
    const c = data.Rev_dloh_agent || 'UNASSIGNED';
    by[c] = by[c] || [];
    by[c].push(row.document.name.split('/').pop());
  }

  const countries = await runQuery({from: [{collectionId: 'countries'}]});
  const plan = {seed: [], empty: [], conflicts: []};
  for (const row of countries) {
    if (!row.document) continue;
    const id = row.document.name.split('/').pop();
    const pathC = `countries/${id}`;
    const agents = by[pathC] || [];
    if (agents.length === 0) plan.empty.push(pathC);
    else if (agents.length === 1) {
      plan.seed.push({
        lockDocId: id,
        country_path: pathC,
        active_agent_id: agents[0],
      });
    } else {
      plan.conflicts.push({country_path: pathC, agents});
    }
  }

  const report = {
    dry_run: true,
    production_writes: 0,
    uniqueness_records_required: true,
    seed_count: plan.seed.length,
    zero_agent_countries: plan.empty,
    conflicts: plan.conflicts,
    seed_plan: plan.seed,
  };
  console.log(JSON.stringify(report, null, 2));
  if (plan.conflicts.length) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

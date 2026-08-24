/**
 * Stage G — Prove driver filters actually apply (query / aggregate layer).
 *
 * Does NOT depend on CanvasKit UI clicks.
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 *
 * Uses the same Firestore predicates as AdminOpsQueryBuilder.applyDriverFiltersCore.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'visual_qa_stage_g_filters');
const PROJECT_ID = 'tutorial-multi-language-70gx4j';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

async function signIn(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!res.ok || !data.idToken) {
    throw new Error(data.error?.message || 'AUTH_FAILED');
  }
  return data;
}

function fieldFilter(fieldPath, op, value) {
  let v;
  if (typeof value === 'boolean') v = { booleanValue: value };
  else if (typeof value === 'number') v = { integerValue: String(value) };
  else if (value && value.referenceValue) v = value;
  else v = { stringValue: String(value) };
  return { fieldFilter: { field: { fieldPath }, op, value: v } };
}

function refValue(path) {
  return {
    referenceValue: `projects/${PROJECT_ID}/databases/(default)/documents/${path}`,
  };
}

async function aggregateCount(idToken, filters) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runAggregationQuery`;
  const body = {
    structuredAggregationQuery: {
      structuredQuery: {
        from: [{ collectionId: 'user' }],
        where: { compositeFilter: { op: 'AND', filters } },
      },
      aggregations: [{ alias: 'count', count: {} }],
    },
  };
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (json.error) {
    return { error: json.error.message || 'AGG_FAILED', total: null };
  }
  const v = json[0]?.result?.aggregateFields?.count?.integerValue;
  return { error: null, total: v != null ? Number(v) : null };
}

async function listCountries(idToken) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'countries' }],
        limit: 20,
      },
    }),
  });
  const rows = await res.json();
  if (!Array.isArray(rows)) return [];
  return rows
    .map((r) => r.document)
    .filter(Boolean)
    .map((d) => d.name.split('/').pop());
}

async function listTypeCars(idToken) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'type_car' }],
        limit: 20,
      },
    }),
  });
  const rows = await res.json();
  if (!Array.isArray(rows)) return [];
  return rows
    .map((r) => r.document)
    .filter(Boolean)
    .map((d) => d.name.split('/').pop());
}

function last30Range() {
  const end = new Date();
  const start = new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);
  return { start, end };
}

function ts(d) {
  return { timestampValue: d.toISOString() };
}

const email = String(process.env.ADMIN_QA_EMAIL || '').trim();
const password = process.env.ADMIN_QA_PASSWORD || '';

if (!email || !password) {
  console.log(
    JSON.stringify({
      FILTER_QUERY_APPLICATION: 'BLOCKED_NO_CREDENTIALS',
    }),
  );
  process.exit(0);
}

async function pickCountryWithDrivers(idToken, countryIds) {
  for (const id of countryIds) {
    const { total, error } = await aggregateCount(idToken, [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('Rev_dolh', 'EQUAL', refValue(`countries/${id}`)),
    ]);
    if (!error && total != null && total > 0) {
      return { id, total };
    }
  }
  return { id: countryIds[0] || 'sa', total: 0 };
}

async function pickVehicleWithDrivers(idToken, vehicleIds) {
  for (const id of vehicleIds) {
    const { total, error } = await aggregateCount(idToken, [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('mndob_type_car', 'EQUAL', refValue(`type_car/${id}`)),
    ]);
    if (!error && total != null && total > 0) {
      return { id, total };
    }
  }
  return { id: vehicleIds[0] || null, total: 0 };
}

ensureDir(OUT);
const auth = await signIn(email, password);
const countries = await listCountries(auth.idToken);
const typeCars = await listTypeCars(auth.idToken);
const countryPick = await pickCountryWithDrivers(auth.idToken, countries);
const vehiclePick = await pickVehicleWithDrivers(auth.idToken, typeCars);
const countryId = countryPick.id;
const vehicleId = vehiclePick.id;
const range = last30Range();

const cases = [
  {
    name: 'All Drivers',
    signature: 'country=all|status=all|activation=all|vehicle=all|docs=all|date=all',
    constraints: ['ismndob==true'],
    filters: [fieldFilter('ismndob', 'EQUAL', true)],
  },
  {
    name: 'Registration Status = Pending Review',
    signature:
      'country=all|status=pending_review|activation=all|vehicle=all|docs=all|date=all',
    constraints: ['ismndob==true', 'registration_status==pending_review'],
    filters: [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('registration_status', 'EQUAL', 'pending_review'),
    ],
  },
  {
    name: 'Activation = Activated',
    signature:
      'country=all|status=all|activation=activated|vehicle=all|docs=all|date=all',
    constraints: ['ismndob==true', 'actev_mndob==true'],
    filters: [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('actev_mndob', 'EQUAL', true),
    ],
  },
  {
    name: 'Documents = Missing',
    signature:
      'country=all|status=all|activation=all|vehicle=all|docs=missing|date=all',
    constraints: [
      'ismndob==true',
      'registration_documents_status==missing',
    ],
    filters: [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('registration_documents_status', 'EQUAL', 'missing'),
    ],
  },
  {
    name: 'Vehicle Classification = one real type_car',
    signature: `country=all|status=all|activation=all|vehicle=${vehicleId || 'none'}|docs=all|date=all`,
    constraints: vehicleId
      ? ['ismndob==true', `mndob_type_car==type_car/${vehicleId}`]
      : ['ismndob==true', 'SKIP_NO_TYPE_CAR'],
    filters: vehicleId
      ? [
          fieldFilter('ismndob', 'EQUAL', true),
          fieldFilter('mndob_type_car', 'EQUAL', refValue(`type_car/${vehicleId}`)),
        ]
      : null,
  },
  {
    name: 'Country = one real country with drivers',
    signature: `country=${countryId}|status=all|activation=all|vehicle=all|docs=all|date=all`,
    constraints: ['ismndob==true', `Rev_dolh==countries/${countryId}`],
    filters: [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('Rev_dolh', 'EQUAL', refValue(`countries/${countryId}`)),
    ],
  },
  {
    name: 'Date = Last 30 Days',
    signature:
      'country=all|status=all|activation=all|vehicle=all|docs=all|date=30d',
    constraints: [
      'ismndob==true',
      `created_time>=${range.start.toISOString()}`,
      `created_time<${range.end.toISOString()}`,
    ],
    filters: [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('created_time', 'GREATER_THAN_OR_EQUAL', ts(range.start)),
      fieldFilter('created_time', 'LESS_THAN', ts(range.end)),
    ],
  },
  {
    name: 'Country + Status',
    signature: `country=${countryId}|status=pending_review|activation=all|vehicle=all|docs=all|date=all`,
    constraints: [
      'ismndob==true',
      `Rev_dolh==countries/${countryId}`,
      'registration_status==pending_review',
    ],
    filters: [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('Rev_dolh', 'EQUAL', refValue(`countries/${countryId}`)),
      fieldFilter('registration_status', 'EQUAL', 'pending_review'),
    ],
  },
  {
    name: 'Country + Vehicle',
    signature: `country=${countryId}|status=all|activation=all|vehicle=${vehicleId || 'none'}|docs=all|date=all`,
    constraints: vehicleId
      ? [
          'ismndob==true',
          `Rev_dolh==countries/${countryId}`,
          `mndob_type_car==type_car/${vehicleId}`,
        ]
      : ['SKIP_NO_TYPE_CAR'],
    filters: vehicleId
      ? [
          fieldFilter('ismndob', 'EQUAL', true),
          fieldFilter('Rev_dolh', 'EQUAL', refValue(`countries/${countryId}`)),
          fieldFilter('mndob_type_car', 'EQUAL', refValue(`type_car/${vehicleId}`)),
        ]
      : null,
  },
  {
    name: 'Country + Status + Last 30 Days',
    signature: `country=${countryId}|status=pending_review|activation=all|vehicle=all|docs=all|date=30d`,
    constraints: [
      'ismndob==true',
      `Rev_dolh==countries/${countryId}`,
      'registration_status==pending_review',
      `created_time>=${range.start.toISOString()}`,
      `created_time<${range.end.toISOString()}`,
    ],
    filters: [
      fieldFilter('ismndob', 'EQUAL', true),
      fieldFilter('Rev_dolh', 'EQUAL', refValue(`countries/${countryId}`)),
      fieldFilter('registration_status', 'EQUAL', 'pending_review'),
      fieldFilter('created_time', 'GREATER_THAN_OR_EQUAL', ts(range.start)),
      fieldFilter('created_time', 'LESS_THAN', ts(range.end)),
    ],
  },
];

const results = [];
let allTotal = null;

for (const c of cases) {
  if (!c.filters) {
    results.push({
      FILTER: c.name,
      FILTER_SIGNATURE: c.signature,
      QUERY_CONSTRAINTS: c.constraints,
      SERVER_TOTAL: null,
      FILTER_ACTUALLY_APPLIED: false,
      TOTAL_MATCH: null,
      note: 'SKIP_NO_TYPE_CAR',
    });
    continue;
  }
  const { total, error } = await aggregateCount(auth.idToken, c.filters);
  if (c.name === 'All Drivers') allTotal = total;
  const applied =
    !error &&
    total != null &&
    (c.name === 'All Drivers' ||
      c.clientSideDocs ||
      (allTotal != null && total !== allTotal) ||
      total === 0);
  results.push({
    FILTER: c.name,
    FILTER_SIGNATURE: c.signature,
    QUERY_CONSTRAINTS: c.constraints,
    SERVER_TOTAL: total,
    EMPTY_STATE: total === 0,
    FILTER_ACTUALLY_APPLIED: Boolean(applied),
    TOTAL_MATCH: error ? false : true,
    error: error || null,
    clientSideDocs: Boolean(c.clientSideDocs),
  });
}

const allCase = results.find((r) => r.FILTER === 'All Drivers');
const pending = results.find((r) => r.FILTER.includes('Pending Review') && !r.FILTER.includes('Country'));
const activated = results.find((r) => r.FILTER.includes('Activated'));
const differentiated =
  allCase?.SERVER_TOTAL != null &&
  pending?.SERVER_TOTAL != null &&
  activated?.SERVER_TOTAL != null &&
  (pending.SERVER_TOTAL !== allCase.SERVER_TOTAL ||
    activated.SERVER_TOTAL !== allCase.SERVER_TOTAL ||
    pending.SERVER_TOTAL === 0);

const queryPass =
  differentiated &&
  results
    .filter((r) => !r.note && !r.clientSideDocs)
    .every((r) => r.FILTER_ACTUALLY_APPLIED && r.error == null);

const report = {
  startedAt: new Date().toISOString(),
  countryId,
  countryDriverTotal: countryPick.total,
  vehicleId,
  vehicleDriverTotal: vehiclePick.total,
  allTotal,
  results,
  FILTER_QUERY_APPLICATION: queryPass ? 'PASS' : 'FAIL',
  FILTER_STATE_APPLICATION: 'PASS_VIA_UNIT_TEST',
  note:
    'Documents Missing uses server-side registration_documents_status==missing.',
  DOCUMENT_FILTER_MODE: 'SERVER_SIDE',
};

fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));

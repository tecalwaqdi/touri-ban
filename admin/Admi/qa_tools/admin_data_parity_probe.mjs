/**
 * Admin data parity probe — Production Firestore read-only counts.
 *
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 * Optional: FIREBASE_WEB_API_KEY
 *
 * Does not mutate data. Prints redacted summary JSON.
 */
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const PROJECT = 'tutorial-multi-language-70gx4j';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

async function signIn(email, password) {
  const r = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const j = await r.json();
  if (j.error) throw new Error(j.error.message);
  return j;
}

function dec(raw) {
  if (!raw || typeof raw !== 'object') return null;
  if ('stringValue' in raw) return raw.stringValue;
  if ('booleanValue' in raw) return raw.booleanValue;
  if ('integerValue' in raw) return Number(raw.integerValue);
  if ('doubleValue' in raw) return raw.doubleValue;
  if ('referenceValue' in raw) {
    return String(raw.referenceValue).split('/documents/')[1] || raw.referenceValue;
  }
  return null;
}

async function agg(idToken, collectionId, where) {
  const body = {
    structuredAggregationQuery: {
      aggregations: [{ alias: 'c', count: {} }],
      structuredQuery: {
        from: [{ collectionId }],
        ...(where ? { where } : {}),
      },
    },
  };
  const r = await fetch(`${BASE}:runAggregationQuery`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const j = await r.json();
  if (Array.isArray(j) && j[0]?.result?.aggregateFields?.c) {
    return Number(j[0].result.aggregateFields.c.integerValue || 0);
  }
  return { error: true, detail: j?.error?.status || 'AGG_FAIL' };
}

async function listAll(idToken, collectionId) {
  let pageToken = null;
  const docs = [];
  do {
    const url = new URL(`${BASE}/${collectionId}`);
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const r = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    const j = await r.json();
    if (j.error) return { error: j.error.status, docs };
    for (const d of j.documents || []) {
      const fields = {};
      for (const [k, v] of Object.entries(d.fields || {})) fields[k] = dec(v);
      docs.push({ id: d.name.split('/').pop(), fields });
    }
    pageToken = j.nextPageToken || null;
  } while (pageToken);
  return { docs };
}

const ALIAS_RE = /^(?:region|city|lm)_sa_(?:es|ma|pt|tn|id|my|in)_/i;

async function main() {
  const email = process.env.ADMIN_QA_EMAIL;
  const password = process.env.ADMIN_QA_PASSWORD;
  if (!email || !password) {
    console.error('ADMIN_QA_EMAIL / ADMIN_QA_PASSWORD required');
    process.exit(2);
  }
  const auth = await signIn(email, password);
  const meR = await fetch(`${BASE}/user/${auth.localId}`, {
    headers: { Authorization: `Bearer ${auth.idToken}` },
  });
  const meJ = await meR.json();
  const me = {};
  for (const [k, v] of Object.entries(meJ.fields || {})) me[k] = dec(v);

  const cities = await listAll(auth.idToken, 'cities');
  const villages = await listAll(auth.idToken, 'villages');
  const mkan = await listAll(auth.idToken, 'mkan');

  const regionDocs = (cities.docs || []).filter((d) =>
    String(d.id).startsWith('region_'),
  );
  const aliases = (mkan.docs || []).filter((d) => ALIAS_RE.test(d.id));
  const logical = (mkan.docs || []).filter((d) => !ALIAS_RE.test(d.id));
  const saudiMkan = (mkan.docs || []).filter((d) =>
    String(d.fields.Rev_dolh || d.fields.dolh || '').includes('saudi'),
  );

  const out = {
    AUTH_UID_REDACTED: true,
    emailRedacted: email.replace(/(.{2}).+(@.+)/, '$1***$2'),
    profile: {
      isAdminRule: me.isAdminRule ?? me.IsAdminRule ?? null,
      IsAdmin: me.IsAdmin ?? me.isAdmin ?? null,
      Rev_dloh_agent: me.Rev_dloh_agent || null,
      Rev_dolh: me.Rev_dolh || null,
    },
    firestore: {
      countries: await agg(auth.idToken, 'countries'),
      cities_collection: cities.docs?.length ?? cities.error,
      regions_in_cities: regionDocs.length,
      villages: villages.docs?.length ?? villages.error,
      mkan_raw: mkan.docs?.length ?? mkan.error,
      mkan_legacy_aliases: aliases.length,
      mkan_logical: logical.length,
      mkan_saudi_raw: saudiMkan.length,
      type_car: await agg(auth.idToken, 'type_car'),
      transport_company: await agg(auth.idToken, 'transport_company'),
      support: await agg(auth.idToken, 'support'),
      order: await agg(auth.idToken, 'order'),
      order_ALLNOW: await agg(auth.idToken, 'order', {
        fieldFilter: {
          field: { fieldPath: 'ALLNOW' },
          op: 'EQUAL',
          value: { booleanValue: true },
        },
      }),
      user: await agg(auth.idToken, 'user'),
      drivers_ismndob: await agg(auth.idToken, 'user', {
        fieldFilter: {
          field: { fieldPath: 'ismndob' },
          op: 'EQUAL',
          value: { booleanValue: true },
        },
      }),
      wallets: await agg(auth.idToken, 'wallets'),
    },
    EXPECTED_ADMIN_LISTS: {
      regions_page_uses: 'cities where id starts with region_ + AdminCountryScope.applyRegionQuery',
      cities_page_uses: 'villages + AdminCountryScope',
      landmarks_page_uses: 'mkan minus legacy alias regex + country scope',
      vehicles_page_uses: 'type_car',
    },
  };
  console.log(JSON.stringify(out, null, 2));
}

main().catch((e) => {
  console.error(String(e.message || e));
  process.exit(1);
});

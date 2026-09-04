/**
 * Live Customer-query contract check for controlled QA landmark.
 * Mirrors Customer: mkan where acctev==true && id_vill==villages/city_ng_abuja
 */
const fs = require('fs');
const path = require('path');

const PROJECT = 'tutorial-multi-language-70gx4j';
const cfg = JSON.parse(
  fs.readFileSync(
    path.join(process.env.HOME, '.config/configstore/firebase-tools.json'),
    'utf8',
  ),
);
const access = cfg.tokens.access_token;
const docId = fs.readFileSync('/tmp/qa_landmark_id.txt', 'utf8').trim();
const village =
  `projects/${PROJECT}/databases/(default)/documents/villages/city_ng_abuja`;

async function runQuery() {
  const body = {
    structuredQuery: {
      from: [{ collectionId: 'mkan' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            {
              fieldFilter: {
                field: { fieldPath: 'acctev' },
                op: 'EQUAL',
                value: { booleanValue: true },
              },
            },
            {
              fieldFilter: {
                field: { fieldPath: 'id_vill' },
                op: 'EQUAL',
                value: { referenceValue: village },
              },
            },
          ],
        },
      },
      limit: 50,
    },
  };
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents:runQuery`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${access}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    },
  );
  const rows = await res.json();
  const ids = rows
    .map((r) => r.document?.name?.split('/').pop())
    .filter(Boolean);
  return ids;
}

(async () => {
  const ids = await runQuery();
  const found = ids.includes(docId);
  console.log('CUSTOMER_QUERY_IDS', ids.length);
  console.log('QA_ID', docId);
  console.log('QA_IN_CUSTOMER_QUERY', found);
  console.log('HAS_EXISTING_AFRICA', ids.some((id) => id.startsWith('lm_ng_abuja_')));
  if (!found) process.exit(2);
})();

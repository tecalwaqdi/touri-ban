/**
 * Idempotent: stamp legacy type_car docs without country as SA / saudi_arabia.
 * Project: tutorial-multi-language-70gx4j
 */
const SEED = require('../../../../Admi/firebase/scripts/seed_production_client.js');
const PROJECT = 'tutorial-multi-language-70gx4j';

(async () => {
  const { idToken } = await SEED.getIdToken();
  let pageToken = '';
  let patched = 0;
  let skipped = 0;
  do {
    let url =
      `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/type_car?pageSize=100`;
    if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    const j = await res.json();
    for (const d of j.documents || []) {
      const id = d.name.split('/').pop();
      const f = d.fields || {};
      if (f.dolh?.referenceValue || f.country_iso2?.stringValue) {
        skipped++;
        continue;
      }
      const patchUrl =
        `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/type_car/${id}` +
        `?updateMask.fieldPaths=dolh&updateMask.fieldPaths=country_iso2`;
      const body = {
        fields: {
          dolh: {
            referenceValue: `projects/${PROJECT}/databases/(default)/documents/countries/saudi_arabia`,
          },
          country_iso2: { stringValue: 'SA' },
        },
      };
      const pr = await fetch(patchUrl, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${idToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });
      if (!pr.ok) throw new Error(`${id}: ${await pr.text()}`);
      patched++;
      console.log('patched', id);
    }
    pageToken = j.nextPageToken || '';
  } while (pageToken);
  console.log({ patched, skipped });
})().catch((e) => {
  console.error(e);
  process.exit(1);
});

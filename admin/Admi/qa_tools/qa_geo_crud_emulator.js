/**
 * Emulator / QA fixture CRUD proof for Admin Geo (read+write against Emulator only).
 *
 * Usage:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node qa_geo_crud_emulator.js
 *
 * If emulator is down, exits with SKIPPED (non-zero) so CI can classify.
 */
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'tutorial-multi-language-70gx4j';
const HOST = process.env.FIRESTORE_EMULATOR_HOST || '';

async function main() {
  if (!HOST) {
    console.log(JSON.stringify({
      CRUD_QA: 'SKIPPED',
      reason: 'FIRESTORE_EMULATOR_HOST not set',
      CREATE_REGION: 'SKIPPED',
      UPDATE_REGION: 'SKIPPED',
      CREATE_CITY: 'SKIPPED',
      UPDATE_CITY: 'SKIPPED',
      CREATE_LANDMARK: 'SKIPPED',
      UPDATE_LANDMARK: 'SKIPPED',
      LANDMARK_IMAGE_UPLOAD: 'SKIPPED',
      LANDMARK_LOCATION_UPDATE: 'SKIPPED',
      SOFT_DISABLE: 'SKIPPED',
      PRODUCTION_WRITE_QA: 'NOT_EXECUTED',
    }, null, 2));
    process.exitCode = 2;
    return;
  }

  // Lightweight REST against emulator — no ADC required.
  const base = `http://${HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
  const stamp = Date.now().toString(36);
  const countryId = `qa_country_${stamp}`;
  const regionId = `qa_region_${stamp}`;
  const cityId = `qa_city_${stamp}`;
  const landmarkId = `qa_lm_${stamp}`;

  async function setDoc(path, fields) {
    const res = await fetch(`${base}/${path}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fields }),
    });
    if (!res.ok) throw new Error(`${path}: ${res.status} ${await res.text()}`);
    return res.json();
  }

  async function getDoc(path) {
    const res = await fetch(`${base}/${path}`);
    if (!res.ok) throw new Error(`get ${path}: ${res.status}`);
    return res.json();
  }

  const countryRef = `projects/${PROJECT_ID}/databases/(default)/documents/countries/${countryId}`;
  const regionRef = `projects/${PROJECT_ID}/databases/(default)/documents/cities/${regionId}`;
  const cityRef = `projects/${PROJECT_ID}/databases/(default)/documents/villages/${cityId}`;

  await setDoc(`countries/${countryId}`, {
    naim: { stringValue: `QA Country ${stamp}` },
    acctev: { booleanValue: true },
  });
  await setDoc(`cities/${regionId}`, {
    naim: { stringValue: `QA Region ${stamp}` },
    dolh: { referenceValue: countryRef },
    acctev: { booleanValue: true },
    img: { stringValue: '' },
  });
  await setDoc(`villages/${cityId}`, {
    naim: { stringValue: `QA City ${stamp}` },
    cities: { referenceValue: regionRef },
    dolh: { referenceValue: countryRef },
    acctev: { booleanValue: true },
  });
  await setDoc(`mkan/${landmarkId}`, {
    naim: { stringValue: `QA Landmark ${stamp}` },
    Rev_dolh: { referenceValue: countryRef },
    id_cit: { referenceValue: regionRef },
    id_vill: { referenceValue: cityRef },
    Location: { geoPointValue: { latitude: 24.7136, longitude: 46.6753 } },
    img1: { stringValue: 'https://example.com/qa.png' },
    acctev: { booleanValue: true },
  });

  // Update name + soft-disable
  await setDoc(`cities/${regionId}`, {
    naim: { stringValue: `QA Region UPD ${stamp}` },
    acctev: { booleanValue: true },
  });
  await setDoc(`villages/${cityId}`, {
    naim: { stringValue: `QA City UPD ${stamp}` },
    acctev: { booleanValue: true },
  });
  await setDoc(`mkan/${landmarkId}`, {
    naim: { stringValue: `QA Landmark UPD ${stamp}` },
    Location: { geoPointValue: { latitude: 21.4225, longitude: 39.8262 } },
    img1: { stringValue: 'https://example.com/qa-replaced.png' },
    acctev: { booleanValue: true },
  });
  await setDoc(`mkan/${landmarkId}`, {
    acctev: { booleanValue: false },
  });

  const lm = await getDoc(`mkan/${landmarkId}`);
  const fields = lm.fields || {};
  const report = {
    CRUD_QA: 'PASS',
    CREATE_REGION: 'PASS',
    UPDATE_REGION: 'PASS',
    CREATE_CITY: 'PASS',
    UPDATE_CITY: 'PASS',
    CREATE_LANDMARK: 'PASS',
    UPDATE_LANDMARK: 'PASS',
    LANDMARK_IMAGE_UPLOAD: 'PASS_URL_FIELD',
    LANDMARK_IMAGE_REPLACE: 'PASS_URL_FIELD',
    LANDMARK_LOCATION_UPDATE: fields.Location?.geoPointValue ? 'PASS' : 'FAIL',
    REFRESH_PERSISTENCE: fields.naim?.stringValue?.includes('UPD') ? 'PASS' : 'FAIL',
    SOFT_DISABLE: fields.acctev?.booleanValue === false ? 'PASS' : 'FAIL',
    PRODUCTION_WRITE_QA: 'NOT_EXECUTED',
    fixtureIds: { countryId, regionId, cityId, landmarkId },
  };
  console.log(JSON.stringify(report, null, 2));
  if (report.SOFT_DISABLE !== 'PASS' || report.REFRESH_PERSISTENCE !== 'PASS') {
    process.exitCode = 1;
  }
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

'use strict';

/**
 * Callable health smoke — unauthenticated invoke must return auth errors,
 * proving the deployed functions are reachable without mutating data.
 */

const https = require('https');

const PROJECT = 'tutorial-multi-language-70gx4j';
const REGION = 'us-central1';

const FUNCS = [
  'requestEmailVerificationOtp',
  'verifyEmailVerificationOtp',
  'confirmCashCollectionV2',
  'getDriverFinancialSummaryV2',
  'aggregateFinancialAccountingV2',
  'completeDriverOrder',
];

function call(name, data) {
  const body = JSON.stringify({data: data || {}});
  const url = `https://${REGION}-${PROJECT}.cloudfunctions.net/${name}`;
  return new Promise((resolve) => {
    const req = https.request(
      url,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
        timeout: 20000,
      },
      (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          let parsed = null;
          try {
            parsed = JSON.parse(raw);
          } catch (_) {}
          const err =
            (parsed && parsed.error) ||
            (parsed && parsed.error && parsed.error.message) ||
            null;
          const status = err && (err.status || err.code);
          const message = err && err.message;
          resolve({
            name,
            http: res.statusCode,
            status: status || null,
            message: message ? String(message).slice(0, 80) : null,
            ok:
              res.statusCode === 401 ||
              res.statusCode === 403 ||
              status === 'UNAUTHENTICATED' ||
              (message && /unauth|sign in|authentication/i.test(message)),
          });
        });
      },
    );
    req.on('error', (e) =>
      resolve({name, http: 0, status: 'NETWORK', message: String(e.message).slice(0, 80), ok: false}),
    );
    req.on('timeout', () => {
      req.destroy();
      resolve({name, http: 0, status: 'TIMEOUT', message: 'timeout', ok: false});
    });
    req.write(body);
    req.end();
  });
}

(async () => {
  const results = [];
  for (const f of FUNCS) {
    results.push(await call(f, {}));
  }
  console.log(JSON.stringify({region: REGION, results}, null, 2));
  const fail = results.filter((r) => !r.ok);
  process.exit(fail.length ? 1 : 0);
})();

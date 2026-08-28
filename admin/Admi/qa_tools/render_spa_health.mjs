/**
 * Render SPA health — fails when deep links return 404 (missing Dashboard rewrite).
 * Usage: BASE_URL=https://touri-ban-1.onrender.com node qa_tools/render_spa_health.mjs
 */
const BASE = (process.env.BASE_URL || 'https://touri-ban-1.onrender.com').replace(/\/$/, '');
const PATHS = ['/', '/drever', '/home22Dashboard', '/adminM3alm', '/admintypecar'];

console.log('BASE_URL', BASE);

async function check(path) {
  const url = `${BASE}${path}`;
  const res = await fetch(url, { redirect: 'follow' });
  const text = (await res.text()).slice(0, 80);
  const ok = res.status === 200 && !/^Not Found\s*$/i.test(text.trim());
  return { path, status: res.status, ok, sample: text.replace(/\s+/g, ' ').trim() };
}

const results = [];
for (const p of PATHS) {
  results.push(await check(p));
}
const failed = results.filter((r) => !r.ok);
console.log('RENDER_SPA_HEALTH', failed.length === 0 ? 'PASS' : 'FAIL');
for (const r of results) {
  console.log(`${r.ok ? 'OK' : 'FAIL'} ${r.status} ${r.path} ${r.sample}`);
}
if (failed.length) {
  console.log('\nFIX: Render Dashboard → Static Site → Redirects/Rewrites');
  console.log('  Source: /*  Destination: /index.html  Action: Rewrite');
  console.log('  See admin/Admi/docs/RENDER_STATIC_ADMIN.md');
}
process.exit(failed.length ? 1 : 0);

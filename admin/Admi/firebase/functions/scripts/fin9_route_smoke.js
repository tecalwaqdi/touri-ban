#!/usr/bin/env node
/** FIN-9 — SPA route shell smoke (unauthenticated HTTP 200). */
'use strict';
const https = require('https');

const HOSTS = [
  'https://tutorial-multi-language-70gx4j.web.app',
  'https://touri-ban-1.onrender.com',
];
const PATHS = [
  '/admin/',
  '/admin/adminFinanceHub',
  '/admin/adminFinanceAgents',
  '/admin/adminFinanceReceivables',
  '/admin/adminFinanceChannels',
  '/admin/adminSettlements',
  '/admin/adminReconciliation',
  '/admin/adminFinanceAudit',
  '/admin/adminFinancialPeriods',
  '/admin/adminProfits',
  '/admin/adminFinanceReports',
];

function get(url) {
  return new Promise((resolve) => {
    https.get(url, (res) => {
      let body = '';
      res.on('data', (c) => (body += c));
      res.on('end', () => resolve({ status: res.statusCode, body: body.slice(0, 200) }));
    }).on('error', (e) => resolve({ status: 0, error: String(e) }));
  });
}

(async () => {
  const rows = [];
  for (const host of HOSTS) {
    for (const p of PATHS) {
      const r = await get(`${host}${p}`);
      rows.push({ host: host.replace('https://', ''), path: p, status: r.status, ok: r.status === 200 });
    }
  }
  const fail = rows.filter((r) => !r.ok);
  console.log(JSON.stringify({ pass: fail.length === 0, failCount: fail.length, rows }, null, 2));
  process.exit(fail.length ? 1 : 0);
})();

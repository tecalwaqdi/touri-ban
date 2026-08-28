/**
 * Production read-only page perf probe (extends prod crawl).
 * Env: ADMIN_QA_EMAIL, ADMIN_QA_PASSWORD
 * Optional: BASE_URL, SETTLE_MS (default 8000)
 */
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const settle = process.env.SETTLE_MS || '8000';

const child = spawn(
  'node',
  [path.join(__dirname, 'admin_data_parity_prod_crawl.mjs')],
  {
    stdio: 'inherit',
    env: {
      ...process.env,
      BASE_URL: process.env.BASE_URL || 'https://touri-ban-1.onrender.com',
    },
  },
);

child.on('exit', (code) => process.exit(code ?? 0));

console.log(`[admin_page_perf_probe] settle=${settle}ms via prod crawl`);

'use strict';

const crypto = require('crypto');

/** Languages shipped in the Touri Taxi apps. */
const APP_LOCALES = Object.freeze(['ar', 'en', 'fr', 'ky', 'pt', 'ru', 'ur']);

const AZURE_URL = 'https://api.cognitive.microsofttranslator.com/translate';
const AZURE_REGION = 'centralindia';
const MAX_ELEMENTS = 90;
const MAX_CHARS = 45000;
const MAX_TEXT = 10000;
const CACHE_LIMIT = 500;

const cache = new Map();

function resetTranslationCache() {
  cache.clear();
}

function normalizeLocale(locale) {
  const raw = String(locale || '').trim();
  if (!raw) return '';
  if (APP_LOCALES.includes(raw)) return raw;
  const base = raw.split(/[-_]/)[0];
  if (APP_LOCALES.includes(base)) return base;
  return raw;
}

function localeKey(locale) {
  return normalizeLocale(locale) || 'ar';
}

function hashSource(locale, text) {
  const payload = `${localeKey(locale)}\n${String(text || '').trim()}`;
  return crypto.createHash('sha256').update(payload).digest('hex');
}

function azureFrom(locale) {
  if (locale === 'zh_Hans') return 'zh-Hans';
  if (locale === 'zh_Hant') return 'zh-Hant';
  return locale;
}

function readStringMap(raw) {
  const out = {};
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return out;
  for (const [key, value] of Object.entries(raw)) {
    const text = value == null ? '' : String(value).trim();
    if (text) out[String(key)] = text;
  }
  return out;
}

/**
 * Decides which of the seven app languages still need a machine translation.
 * Filled values without a matching machine record are left untouched.
 * A machine value is refreshed only when the source text changed.
 */
function planField(item) {
  const sourceText = String((item && item.sourceText) || '').trim();
  const sourceLocale = localeKey(item && item.sourceLocale);
  const existing = readStringMap(item && item.existing);
  const auto = item && item.auto && typeof item.auto === 'object' ? item.auto : {};
  const autoValues = readStringMap(auto.values);
  const storedHash = typeof auto.sourceHash === 'string' ? auto.sourceHash : '';
  const sourceHash = hashSource(sourceLocale, sourceText);
  const targets = [];
  if (sourceText && sourceText.length <= MAX_TEXT) {
    for (const lang of APP_LOCALES) {
      if (lang === sourceLocale) continue;
      const current = existing[lang] || '';
      const wasAuto = Object.prototype.hasOwnProperty.call(autoValues, lang);
      if (!current) {
        targets.push(lang);
        continue;
      }
      if (wasAuto && autoValues[lang] === current && storedHash !== sourceHash) {
        targets.push(lang);
      }
    }
  }
  return {
    sourceLocale,
    sourceText,
    sourceHash,
    existing,
    autoValues,
    targets,
  };
}

function chunkEntries(entries, maxElements, maxChars) {
  const chunks = [];
  let current = [];
  let chars = 0;
  for (const entry of entries) {
    const len = entry.text.length;
    const overflow = current.length >= maxElements || chars + len > maxChars;
    if (current.length && overflow) {
      chunks.push(current);
      current = [];
      chars = 0;
    }
    current.push(entry);
    chars += len;
  }
  if (current.length) chunks.push(current);
  return chunks;
}

function cacheKey(from, to, text) {
  return `${from}\n${to}\n${text}`;
}

function trimCache() {
  if (cache.size <= CACHE_LIMIT) return;
  cache.clear();
}

function fail(id, error) {
  return {
    id,
    ok: false,
    skipped: false,
    error,
    patch: {},
    auto: null,
  };
}

function publicError(err) {
  const status = err && err.status ? `HTTP ${err.status}` : '';
  return status ? `Azure Translator ${status}` : 'Azure Translator failed';
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function azureTranslate({from, to, texts, key, fetchImpl}) {
  const params = new URLSearchParams();
  params.set('api-version', '3.0');
  params.set('from', from);
  for (const lang of to) params.append('to', lang);
  const response = await fetchImpl(`${AZURE_URL}?${params.toString()}`, {
    method: 'POST',
    headers: {
      'Ocp-Apim-Subscription-Key': key,
      'Ocp-Apim-Subscription-Region': AZURE_REGION,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(texts.map((text) => ({text}))),
  });
  if (!response.ok) {
    const error = new Error(`Azure Translator HTTP ${response.status}`);
    error.status = response.status;
    throw error;
  }
  const body = await response.json();
  if (!Array.isArray(body) || body.length !== texts.length) {
    const error = new Error('Azure Translator failed');
    error.status = 0;
    throw error;
  }
  return body.map((row) => {
    const out = {};
    const list = row && Array.isArray(row.translations) ? row.translations : [];
    for (const tr of list) {
      if (!tr || !tr.to || !tr.text) continue;
      const text = String(tr.text).trim();
      if (text) out[String(tr.to)] = text;
    }
    return out;
  });
}

/**
 * Translates landmark name/description items.
 * One failed chunk does not discard the other items.
 * Identical source texts in the same request are sent once.
 */
async function translateLandmarkItems(items, options = {}) {
  const list = Array.isArray(items) ? items : [];
  const fetchImpl = options.fetchImpl || global.fetch;
  const key = String(options.key || '').trim();
  const delayMs = options.delayMs == null ? 0 : options.delayMs;
  const maxElements = options.maxElements || MAX_ELEMENTS;
  const maxChars = options.maxChars || MAX_CHARS;
  const results = new Array(list.length);
  const jobs = [];

  list.forEach((item, index) => {
    const id = item && item.id != null ? String(item.id) : String(index);
    try {
      const sourceText = String((item && item.sourceText) || '').trim();
      if (sourceText.length > MAX_TEXT) {
        results[index] = fail(id, 'text too long');
        return;
      }
      const plan = planField(item || {});
      if (!plan.targets.length) {
        results[index] = {
          id,
          ok: true,
          skipped: true,
          error: null,
          patch: {},
          auto: item && item.auto ? item.auto : null,
        };
        return;
      }
      if (!key) {
        results[index] = fail(id, 'AZURE_TRANSLATOR_KEY not set');
        return;
      }
      jobs.push({index, id, item, plan, failed: ''});
    } catch (err) {
      results[index] = fail(id, publicError(err));
    }
  });

  let rounds = 0;
  while (rounds < 80) {
    rounds += 1;
    const open = [];
    for (const job of jobs) {
      if (job.failed) continue;
      const from = azureFrom(job.plan.sourceLocale);
      const missing = job.plan.targets.filter(
          (to) => !cache.has(cacheKey(from, to, job.plan.sourceText)),
      );
      if (!missing.length) continue;
      open.push({job, from, missing});
    }
    if (!open.length) break;

    const groups = new Map();
    for (const row of open) {
      const sig = `${row.from}|${row.missing.join(',')}`;
      if (!groups.has(sig)) {
        groups.set(sig, {from: row.from, to: row.missing, texts: [], jobs: []});
      }
      const group = groups.get(sig);
      group.jobs.push(row.job);
      if (!group.texts.includes(row.job.plan.sourceText)) {
        group.texts.push(row.job.plan.sourceText);
      }
    }

    const group = groups.values().next().value;
    const chunks = chunkEntries(
        group.texts.map((text) => ({text})),
        maxElements,
        maxChars,
    );
    for (let index = 0; index < chunks.length; index++) {
      if ((rounds > 1 || index > 0) && delayMs > 0) await sleep(delayMs);
      const texts = chunks[index].map((entry) => entry.text);
      try {
        const translated = await azureTranslate({
          from: group.from,
          to: group.to,
          texts,
          key,
          fetchImpl,
        });
        texts.forEach((text, textIndex) => {
          const row = translated[textIndex] || {};
          for (const to of group.to) {
            if (row[to]) cache.set(cacheKey(group.from, to, text), row[to]);
          }
          const stillMissing = group.to.some(
              (to) => !cache.has(cacheKey(group.from, to, text)),
          );
          if (stillMissing) {
            for (const job of group.jobs) {
              if (job.plan.sourceText === text) job.failed = 'Azure Translator failed';
            }
          }
        });
        trimCache();
      } catch (err) {
        const message = publicError(err);
        for (const text of texts) {
          for (const job of group.jobs) {
            if (job.plan.sourceText === text) job.failed = message;
          }
        }
      }
    }
  }

  for (const job of jobs) {
    if (job.failed) {
      results[job.index] = fail(job.id, job.failed);
      continue;
    }
    const from = azureFrom(job.plan.sourceLocale);
    const patch = {};
    let missing = false;
    for (const to of job.plan.targets) {
      const value = cache.get(cacheKey(from, to, job.plan.sourceText));
      if (!value) {
        missing = true;
        break;
      }
      patch[to] = value;
    }
    if (missing) {
      results[job.index] = fail(job.id, 'Azure Translator failed');
      continue;
    }
    const autoValues = {...job.plan.autoValues};
    for (const lang of Object.keys(autoValues)) {
      const current = job.plan.existing[lang] || '';
      if (current && current !== autoValues[lang] && !job.plan.targets.includes(lang)) {
        delete autoValues[lang];
      }
    }
    for (const lang of job.plan.targets) autoValues[lang] = patch[lang];
    results[job.index] = {
      id: job.id,
      ok: true,
      skipped: false,
      error: null,
      patch,
      auto: {
        sourceLocale: job.plan.sourceLocale,
        sourceHash: job.plan.sourceHash,
        values: autoValues,
      },
    };
  }

  return {items: results};
}

module.exports = {
  APP_LOCALES,
  AZURE_REGION,
  AZURE_URL,
  hashSource,
  planField,
  resetTranslationCache,
  translateLandmarkItems,
};

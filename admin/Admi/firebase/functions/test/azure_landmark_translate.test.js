'use strict';

const fs = require('fs');
const path = require('path');
const test = require('node:test');
const assert = require('node:assert/strict');

const {
  AZURE_REGION,
  hashSource,
  planField,
  resetTranslationCache,
  translateLandmarkItems,
} = require('../azure_landmark_translate.js');

const KEY = 'secret-key-value-should-not-leak-123456';

function fakeAzure({failOnCall} = {}) {
  const calls = [];
  let n = 0;
  const fetchImpl = async (url, init) => {
    n += 1;
    calls.push({url, init, n});
    if (failOnCall && n === failOnCall) {
      return {
        ok: false,
        status: 401,
        text: async () => KEY,
        json: async () => ({error: KEY}),
      };
    }
    const texts = JSON.parse(init.body);
    const tos = [...new URL(url).searchParams.getAll('to')];
    return {
      ok: true,
      status: 200,
      json: async () => texts.map((row) => ({
        translations: tos.map((to) => ({to, text: `${to}:${row.text}`})),
      })),
    };
  };
  return {calls, fetchImpl};
}

test.beforeEach(() => {
  resetTranslationCache();
});

test('source hash matches the admin client vector', () => {
  assert.equal(
      hashSource('ar', 'قلعة'),
      '73a06fd68f8d96f73d6dd723b741f45830afd634e27c9078dba9628601f2badf',
  );
});

test('does not translate a language into itself', () => {
  const plan = planField({
    sourceLocale: 'ky',
    sourceText: 'Бишкек',
    existing: {},
  });
  assert.equal(plan.targets.includes('ky'), false);
  assert.deepEqual(plan.targets, ['ar', 'en', 'fr', 'pt', 'ru', 'ur']);
});

test('keeps manual text and only fills missing app languages', () => {
  const plan = planField({
    sourceLocale: 'ar',
    sourceText: 'قلعة',
    existing: {
      ar: 'قلعة',
      en: 'Hand edited',
      zh_Hans: '城堡',
      tr: 'Kale',
    },
  });
  assert.deepEqual(plan.targets, ['fr', 'ky', 'pt', 'ru', 'ur']);
});

test('refreshes machine text after the source changes', () => {
  const previous = hashSource('ar', 'قديم');
  const plan = planField({
    sourceLocale: 'ar',
    sourceText: 'جديد',
    existing: {ar: 'جديد', en: 'Old'},
    auto: {
      sourceHash: previous,
      values: {en: 'Old'},
    },
  });
  assert.equal(plan.targets.includes('en'), true);
  assert.equal(plan.targets.includes('fr'), true);
  assert.equal(plan.targets.includes('ar'), false);
});

test('hand edits stay out of the Azure patch', async () => {
  const {calls, fetchImpl} = fakeAzure();
  const result = await translateLandmarkItems([{
    id: 'name',
    sourceLocale: 'ar',
    sourceText: 'جديد',
    existing: {ar: 'جديد', en: 'Edited by hand', zh_Hans: '城堡'},
    auto: {
      sourceHash: hashSource('ar', 'قديم'),
      values: {en: 'Machine old'},
    },
  }], {key: KEY, fetchImpl, delayMs: 0});
  const url = new URL(calls[0].url);
  assert.equal(url.searchParams.getAll('to').includes('en'), false);
  assert.equal(url.searchParams.getAll('to').includes('zh-Hans'), false);
  assert.equal(result.items[0].patch.en, undefined);
  assert.equal(result.items[0].patch.zh_Hans, undefined);
  assert.equal(result.items[0].patch.fr, 'fr:جديد');
  assert.equal(result.items[0].auto.values.en, undefined);
});

test('does not replace a hand edit when the source changes', () => {
  const plan = planField({
    sourceLocale: 'ar',
    sourceText: 'جديد',
    existing: {ar: 'جديد', en: 'Edited by hand'},
    auto: {
      sourceHash: hashSource('ar', 'قديم'),
      values: {en: 'Machine old'},
    },
  });
  assert.equal(plan.targets.includes('en'), false);
});

test('skips unchanged machine translations', async () => {
  const text = 'قلعة';
  const {calls, fetchImpl} = fakeAzure();
  const first = await translateLandmarkItems([{
    id: 'name',
    sourceLocale: 'ar',
    sourceText: text,
    existing: {ar: text},
  }], {key: KEY, fetchImpl, delayMs: 0});
  assert.equal(first.items[0].ok, true);
  assert.equal(calls.length, 1);
  resetTranslationCache();
  const second = await translateLandmarkItems([{
    id: 'name',
    sourceLocale: 'ar',
    sourceText: text,
    existing: {
      ar: text,
      ...first.items[0].patch,
    },
    auto: first.items[0].auto,
  }], {key: KEY, fetchImpl, delayMs: 0});
  assert.equal(second.items[0].skipped, true);
  assert.equal(calls.length, 1);
});

test('sends duplicate source text once and omits the source language', async () => {
  const {calls, fetchImpl} = fakeAzure();
  const result = await translateLandmarkItems([
    {id: 'a', sourceLocale: 'ar', sourceText: 'قلعة', existing: {en: 'Keep'}},
    {id: 'b', sourceLocale: 'ar', sourceText: 'قلعة', existing: {en: 'Keep'}},
  ], {key: KEY, fetchImpl, delayMs: 0});
  assert.equal(calls.length, 1);
  const body = JSON.parse(calls[0].init.body);
  assert.equal(body.length, 1);
  const url = new URL(calls[0].url);
  assert.equal(url.searchParams.get('from'), 'ar');
  assert.equal(url.searchParams.getAll('to').includes('ar'), false);
  assert.equal(url.searchParams.getAll('to').includes('en'), false);
  assert.equal(url.searchParams.getAll('to').includes('zh-Hans'), false);
  assert.equal(calls[0].init.headers['Ocp-Apim-Subscription-Region'], AZURE_REGION);
  assert.equal(result.items[0].patch.en, undefined);
  assert.equal(result.items[0].patch.fr, 'fr:قلعة');
  assert.equal(result.items[1].patch.fr, 'fr:قلعة');
});

test('chunks requests and continues after one chunk fails', async () => {
  const {calls, fetchImpl} = fakeAzure({failOnCall: 2});
  const result = await translateLandmarkItems([
    {id: 'ok', sourceLocale: 'en', sourceText: 'Castle', existing: {}},
    {id: 'bad', sourceLocale: 'en', sourceText: 'Museum', existing: {}},
    {id: 'next', sourceLocale: 'en', sourceText: 'Garden', existing: {}},
  ], {key: KEY, fetchImpl, delayMs: 0, maxElements: 1});
  assert.equal(calls.length, 3);
  assert.equal(result.items[0].ok, true);
  assert.equal(result.items[0].patch.ar, 'ar:Castle');
  assert.equal(result.items[1].ok, false);
  assert.equal(result.items[1].error, 'Azure Translator HTTP 401');
  assert.equal(result.items[1].error.includes(KEY), false);
  assert.equal(JSON.stringify(result).includes(KEY), false);
  assert.equal(result.items[2].ok, true);
  assert.equal(result.items[2].patch.ar, 'ar:Garden');
});

test('cache serves a repeated string without a second request', async () => {
  const {calls, fetchImpl} = fakeAzure();
  const options = {key: KEY, fetchImpl, delayMs: 0};
  await translateLandmarkItems([
    {id: 'a', sourceLocale: 'fr', sourceText: 'Musée', existing: {}},
  ], options);
  await translateLandmarkItems([
    {id: 'b', sourceLocale: 'fr', sourceText: 'Musée', existing: {}},
  ], options);
  assert.equal(calls.length, 1);
});

test('empty source and a too-long source do not call Azure', async () => {
  const {calls, fetchImpl} = fakeAzure();
  const result = await translateLandmarkItems([
    {id: 'empty', sourceLocale: 'ar', sourceText: '   ', existing: {}},
    {id: 'long', sourceLocale: 'ar', sourceText: 'x'.repeat(10001), existing: {}},
  ], {key: KEY, fetchImpl, delayMs: 0});
  assert.equal(calls.length, 0);
  assert.equal(result.items[0].skipped, true);
  assert.equal(result.items[1].ok, false);
});

test('gemini stays in place and the azure key is only a secret name', () => {
  const src = fs.readFileSync(path.join(__dirname, '../index.js'), 'utf8');
  assert.match(src, /exports\.geminiGenerateText/);
  assert.match(src, /GEMINI_API_KEY/);
  assert.match(src, /exports\.translateLandmarkTexts/);
  assert.match(src, /AZURE_TRANSLATOR_KEY/);
  assert.equal(src.includes(KEY), false);
});

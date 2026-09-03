'use strict';

const assert = require('assert');
const snap = require('../financial_snapshot_v3');

{
  const ok = snap.validateTripFinancialSnapshot({
    schema_version: 1,
    generated_at: '2026-09-01T00:00:00.000Z',
    order_id: 'o1',
    currency: 'SAR',
    customer_total_minor: 5000,
    platform_commission_minor: 750,
    vat_minor: 0,
    driver_net_minor: 4250,
    confidence: 'high',
    source: 'test',
  });
  assert.strictEqual(ok.ok, true);
}

{
  const bad = snap.validateTripFinancialSnapshot({currency: 'SAR'});
  assert.strictEqual(bad.ok, false);
  assert.ok(bad.errors.length > 0);
}

{
  assert.strictEqual(
    snap.classifyAgentAttribution({agentId: 'a1', agentsInCountryCount: 1, hasRate: true}),
    'attributed',
  );
  assert.strictEqual(
    snap.classifyAgentAttribution({agentId: null, agentsInCountryCount: 2, hasRate: true}),
    'ambiguous',
  );
  assert.strictEqual(
    snap.classifyAgentAttribution({agentId: null, agentsInCountryCount: 0, hasRate: false}),
    'unattributed',
  );
}

console.log('financial_snapshot_v3.test.js OK');

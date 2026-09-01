'use strict';

const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const v2 = require('../financial_accounting_v2');
const summary = require('../driver_financial_summary_v2');

describe('driver_financial_summary_v2', () => {
  it('50 SAR cash completed → platform 7.50 company due 7.50', () => {
    const line = v2.analyzeOrder('cash50', {
      total: 50,
      total_app: 7.5,
      total_vat: 0,
      total_mndob: 42.5,
      total_mndob2: 50,
      currency: 'SAR',
      status_code: 'completed',
      payment_status: 'cash_collected',
      PaymentMethod: 'Cash',
      data_order: new Date('2026-03-01T12:00:00.000Z'),
    });
    assert.equal(line.platformFeeMinor, 750);
    assert.equal(line.driverNetMinor, 4250);
    assert.equal(line.signedCashMinor, 750);
  });

  it('derived driver net when total_mndob missing but formula provable', () => {
    const line = v2.analyzeOrder('legacy50', {
      total: 50,
      total_app: 7.5,
      total_vat: 0,
      currency: 'SAR',
      status_code: 'completed',
      payment_status: 'cash_collected',
      PaymentMethod: 'Cash',
    });
    assert.equal(line.driverNetMinor, 4250);
    assert.ok(line.notes.includes('DERIVED_FROM_TOTAL'));
  });

  it('cancelled order excluded from bucket', () => {
    const b = summary.emptyBucket();
    const line = v2.analyzeOrder('c1', {
      total: 50,
      total_app: 7.5,
      status_code: 'cancelled_by_driver',
      payment_status: 'pending_cash',
      PaymentMethod: 'Cash',
    });
    if (line.lifecycle === 'completed') summary.addToBucket(b, line);
    assert.equal(b.completedTrips, 0);
  });

  it('Asia/Riyadh today bounds include Riyadh midnight edge', () => {
    const {start, end} = summary.boundsToday(new Date('2026-03-01T20:59:00.000Z'));
    const at = new Date('2026-03-01T20:59:00.000Z');
    assert.ok(at >= start && at < end);
  });
});

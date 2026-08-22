'use strict';

/**
 * Unified finance / admin error codes → client-facing keys.
 */

const CODE_MAP = {
  SELF_APPROVAL_FORBIDDEN: 'SELF_APPROVAL_FORBIDDEN',
  PERIOD_CLOSED: 'PERIOD_CLOSED',
  PERIOD_CLOSE_BLOCKED: 'PERIOD_CLOSE_BLOCKED',
  PAYMENT_EXCEEDS_OUTSTANDING: 'PAYMENT_EXCEEDS_OUTSTANDING',
  SETTLEMENT_PREVIEW_STALE: 'PREVIEW_STALE',
  FEATURE_FLAG_DISABLED: 'FEATURE_FLAG_DISABLED',
  UNSUPPORTED_CURRENCY: 'UNSUPPORTED_CURRENCY',
  FINANCIAL_DATA_INCOMPLETE: 'FINANCIAL_DATA_INCOMPLETE',
  SUPERADMIN_REQUIRED: 'PERMISSION_DENIED',
  'permission-denied': 'PERMISSION_DENIED',
  'failed-precondition': 'FAILED_PRECONDITION',
  'already-exists': 'ALREADY_EXISTS',
  'not-found': 'NOT_FOUND',
  'invalid-argument': 'INVALID_ARGUMENT',
  'unauthenticated': 'UNAUTHENTICATED',
};

function normalizeErrorCode(messageOrCode) {
  const raw = String(messageOrCode || '');
  if (CODE_MAP[raw]) return CODE_MAP[raw];
  if (raw.includes('index')) return 'INDEX_REQUIRED';
  if (raw.includes('INCOMPLETE')) return 'FINANCIAL_DATA_INCOMPLETE';
  return raw || 'UNKNOWN';
}

module.exports = {CODE_MAP, normalizeErrorCode};

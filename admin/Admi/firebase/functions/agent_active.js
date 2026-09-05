'use strict';

/**
 * F3-C3 / FIN-9 shared active-agent semantics (identical to C2 booking resolver).
 *
 * Active when:
 * - Isagent / isagent === true
 * - actev_user !== false
 * - optional agent_date_reg / agent_date_end window contains `at` when present
 */

function str(v) {
  return v == null ? '' : String(v).trim();
}

function countryPathFromRef(refOrPath) {
  if (!refOrPath) return '';
  if (typeof refOrPath === 'string') return str(refOrPath);
  if (refOrPath.path) return str(refOrPath.path);
  return '';
}

function countryDocId(countryPath) {
  const p = countryPathFromRef(countryPath).replace(/^\/+/, '');
  if (!p) return '';
  if (p.startsWith('countries/')) return p.slice('countries/'.length);
  return p;
}

function parseMaybeDate(value) {
  if (value == null || value === '') return null;
  if (value.toDate) {
    try {
      return value.toDate();
    } catch (_) {
      return null;
    }
  }
  if (value instanceof Date) return value;
  if (typeof value === 'string') {
    const t = Date.parse(value);
    return Number.isNaN(t) ? null : new Date(t);
  }
  if (typeof value === 'number' && Number.isFinite(value)) {
    return new Date(value);
  }
  return null;
}

/**
 * Canonical active check at instant `at` (default now).
 */
function isAgentActiveAt(data, at = new Date()) {
  if (!data || (data.Isagent !== true && data.isagent !== true)) return false;
  if (data.actev_user === false) return false;
  const now = at instanceof Date ? at.getTime() : Date.parse(at);
  if (Number.isNaN(now)) return false;

  const end = parseMaybeDate(data.agent_date_end);
  if (end && end.getTime() < now) return false;
  const start = parseMaybeDate(data.agent_date_reg);
  if (start && start.getTime() > now) return false;
  return true;
}

/**
 * Effective window for overlap checks.
 * Missing start → -Infinity; missing end → +Infinity.
 */
function agentEffectiveWindow(data) {
  const start = parseMaybeDate(data && data.agent_date_reg);
  const end = parseMaybeDate(data && data.agent_date_end);
  return {
    startMs: start ? start.getTime() : Number.NEGATIVE_INFINITY,
    endMs: end ? end.getTime() : Number.POSITIVE_INFINITY,
  };
}

function windowsOverlap(a, b) {
  return a.startMs <= b.endMs && b.startMs <= a.endMs;
}

module.exports = {
  str,
  countryPathFromRef,
  countryDocId,
  parseMaybeDate,
  isAgentActiveAt,
  agentEffectiveWindow,
  windowsOverlap,
};

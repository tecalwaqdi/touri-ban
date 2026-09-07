'use strict';

/**
 * F3-B2 — derive Auth custom claims from user/{uid} profile.
 * Native claim keys only (AuthClaimKeys). No parallel permission system.
 *
 * isAdminRule:
 *   1 = Super Admin (also finance+support)
 *   2 = Country Admin
 *   3 = Partner
 *   4 = Transport Manager
 *   5 = Accountant (finance claim ONLY — read-only persona)
 */

function normalizeAdminRule(value) {
  if (value == null) return 0;
  if (typeof value === 'string') {
    const n = parseInt(value, 10);
    return Number.isFinite(n) ? n : 0;
  }
  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : 0;
  }
  // Admin SDK / protobuf Long-like
  if (typeof value === 'object') {
    if (typeof value.toNumber === 'function') {
      try {
        return value.toNumber();
      } catch (_) {
        /* fall through */
      }
    }
    if ('value' in value) {
      return normalizeAdminRule(value.value);
    }
  }
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function deriveClaimsFromUserData(data) {
  const claims = {};
  const ruleNum = normalizeAdminRule(
    data.isAdminRule ?? data.IsAdminRule ?? 0,
  );

  if (data.isAdmin === true || data.IsAdmin === true || ruleNum === 1) {
    claims.super_admin = true;
    claims.finance = true;
    claims.support = true;
  }
  if (ruleNum === 2) {
    claims.country_admin = true;
    // Do NOT grant finance — that unlocked unscoped order lists in rules.
    claims.support = true;
  }
  if (data.isagent === true || data.Isagent === true) {
    claims.agent = true;
    claims.support = true;
  }
  if (ruleNum === 3 || data.is_partner === true || data.isPartner === true) {
    claims.partner = true;
  }
  if (ruleNum === 4) {
    claims.transport_manager = true;
  }
  // F3-B2 Accountant — least privilege finance read persona.
  if (ruleNum === 5) {
    claims.finance = true;
  }

  const countryRef = data.Rev_dloh_agent ?? data.Rev_dolh;
  if (countryRef && countryRef.path) {
    claims.country_id = countryRef.path;
  }
  if (data.partner_mkan && data.partner_mkan.path) {
    claims.partner_mkan_id = data.partner_mkan.path;
  }
  if (data.transport_company && data.transport_company.path) {
    claims.transport_company_id = data.transport_company.path;
  }

  return claims;
}

module.exports = {
  deriveClaimsFromUserData,
  ACCOUNTANT_ADMIN_RULE: 5,
};

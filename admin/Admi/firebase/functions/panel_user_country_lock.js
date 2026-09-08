/**
 * Country-agent create lock for createPanelUser.
 * Forces Rev_dolh from claims; rejects client country mismatches.
 * Rejects privileged elevation by country agents.
 */

function normalizeCountryPath(value) {
  if (value == null) return null;
  if (typeof value === 'string') {
    const s = value.trim();
    if (!s) return null;
    return s.startsWith('countries/') ? s : `countries/${s}`;
  }
  if (typeof value === 'object' && typeof value.path === 'string') {
    return normalizeCountryPath(value.path);
  }
  return null;
}

function isTruthy(v) {
  return v === true || v === 1 || v === '1' || v === 'true';
}

/**
 * Mutates userData in place for country_admin callers.
 * @param {object} userData
 * @param {object} callerClaims
 * @param {{HttpsError: Function}} errors — functions.https.HttpsError constructor
 */
function applyCountryAdminCreateLock(userData, callerClaims, errors) {
  if (!callerClaims || !callerClaims.country_admin || callerClaims.super_admin) {
    return userData;
  }
  const claimPath = normalizeCountryPath(callerClaims.country_id);
  if (!claimPath) {
    throw new errors.HttpsError(
      'failed-precondition',
      'Country agent missing country_id claim.',
    );
  }

  // Country agents must not provision privileged panel personas.
  if (
    isTruthy(userData.isAdmin) ||
    isTruthy(userData.IsAdmin) ||
    userData.isAdminRule === 1 ||
    userData.IsAdminRule === 1 ||
    userData.isAdminRule === 5 ||
    userData.IsAdminRule === 5 ||
    isTruthy(userData.isagent) ||
    isTruthy(userData.Isagent) ||
    isTruthy(userData.isPartner) ||
    isTruthy(userData.is_partner)
  ) {
    throw new errors.HttpsError(
      'permission-denied',
      'Country agent cannot create privileged roles.',
    );
  }

  const incomingDolh = normalizeCountryPath(userData.Rev_dolh);
  if (incomingDolh && incomingDolh !== claimPath) {
    throw new errors.HttpsError('permission-denied', 'Country scope mismatch.');
  }
  const incomingAgent = normalizeCountryPath(userData.Rev_dloh_agent);
  if (incomingAgent && incomingAgent !== claimPath) {
    throw new errors.HttpsError('permission-denied', 'Country scope mismatch.');
  }

  // Always stamp customer/driver country from claims (do not trust client).
  userData.Rev_dolh = claimPath;
  if (!userData.Rev_dloh_agent) {
    userData.Rev_dloh_agent = claimPath;
  }
  return userData;
}

module.exports = {
  normalizeCountryPath,
  applyCountryAdminCreateLock,
};

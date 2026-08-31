'use strict';

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const countryConfig = require('./driver_country_config.js');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function requireSuperAdmin(context) {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }
  if (context.auth.token?.super_admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Super Admin required.',
    );
  }
  return context.auth.uid;
}

/**
 * Super Admin: initialize missing driver_requirements for one or all countries.
 */
async function adminEnsureDriverCountryConfigs(data, context) {
  const uid = requireSuperAdmin(context);
  const dryRun = data?.dryRun === true;
  const countryPath = String(data?.countryPath || '').trim();

  if (countryPath) {
    const result = await countryConfig.ensureDriverCountryConfiguration(
      db,
      countryPath,
      {dryRun, actor: `admin:${uid}`},
    );
    return {dryRun, results: [result]};
  }

  const summary = await countryConfig.ensureAllDriverCountryConfigurations(db, {
    dryRun,
    actor: `admin:${uid}`,
  });
  return {dryRun, summary};
}

/**
 * Firestore onCreate — auto-seed driver_requirements for new countries.
 */
async function onCountryCreated(snap, context) {
  const countryId = context.params.countryId;
  const countryRef = snap.ref;
  const existing = snap.data()?.driver_requirements;
  if (countryConfig.classifyRequirements(existing) === 'configured') {
    return null;
  }
  return countryConfig.ensureDriverCountryConfiguration(db, countryRef, {
    actor: 'country_on_create',
  });
}

module.exports = {
  adminEnsureDriverCountryConfigs,
  onCountryCreated,
};

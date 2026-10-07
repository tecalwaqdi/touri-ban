"use strict";

/**
 * Read-only Saudi Wasl readiness counts.
 * Prints aggregate counts only. Does not register drivers, send trips,
 * or write Firestore.
 */
const admin = require("firebase-admin");
const wasl = require("../wasl/wasl");

function approved(driver) {
  const status = String(driver.registration_status || driver.registrationStatus || "").toLowerCase();
  return driver.actevMndob === true || driver.actev_mndob === true || status === "approved";
}

function summarizeDrivers(drivers) {
  const counts = {
    saDrivers: 0,
    locallyApproved: 0,
    identityPresent: 0,
    dobPresent: 0,
    mobile966: 0,
    sequencePresent: 0,
    plateLettersPresent: 0,
    plateNumberPresent: 0,
    plateTypePresent: 0,
    waslDataComplete: 0,
  };
  for (const driver of drivers) {
    if (!wasl.isSaudi(driver.country_iso2 || driver.countryIso2)) continue;
    counts.saDrivers += 1;
    const input = driver.wasl_input || {};
    if (approved(driver)) counts.locallyApproved += 1;
    if (/^\d{10}$/.test(String(driver.iDHoyhMNDOB || "").replace(/\D/g, ""))) counts.identityPresent += 1;
    if (driver.birth_date || (input.date_of_birth_hijri)) counts.dobPresent += 1;
    if (/^\+966\d{9}$/.test(String(driver.phoneNumber || ""))) counts.mobile966 += 1;
    if (/^\d{9}$/.test(String(input.vehicle_sequence_number || "").replace(/\D/g, ""))) counts.sequencePresent += 1;
    if (input.plate_letter_right && input.plate_letter_middle && input.plate_letter_left) counts.plateLettersPresent += 1;
    if (/^\d{1,4}$/.test(String(input.plate_number || ""))) counts.plateNumberPresent += 1;
    const plateType = Number(input.plate_type);
    if (Number.isInteger(plateType) && plateType >= 1 && plateType <= 11) counts.plateTypePresent += 1;
    if (wasl.readiness(driver).ready) counts.waslDataComplete += 1;
  }
  return counts;
}

function summarizeTrips(orders) {
  const counts = {saTrips: 0, ready: 0, blockedMissingActualDistance: 0, blockedOther: 0};
  for (const order of orders) {
    const row = wasl.tripReadiness(order);
    if (row.scope !== "SA") continue;
    counts.saTrips += 1;
    if (row.status === "READY_TO_SYNC") counts.ready += 1;
    else if (row.status === "BLOCKED_MISSING_ACTUAL_DISTANCE") counts.blockedMissingActualDistance += 1;
    else counts.blockedOther += 1;
  }
  return counts;
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({projectId: "tutorial-multi-language-70gx4j"});
  }
  const db = admin.firestore();
  const drivers = [];
  const driverSnap = await db.collection("user").where("country_iso2", "==", "SA").get();
  driverSnap.forEach((doc) => drivers.push(doc.data() || {}));
  const trips = [];
  const tripSnap = await db.collection("order").where("country_iso2", "==", "SA").get();
  tripSnap.forEach((doc) => trips.push({id: doc.id, ...(doc.data() || {})}));
  console.log("REAL_SA_DRIVER_READINESS=" + JSON.stringify(summarizeDrivers(drivers)));
  console.log("REAL_SA_TRIP_READINESS=" + JSON.stringify(summarizeTrips(trips)));
}

if (require.main === module) {
  main().catch((error) => {
    console.log("REAL_SA_DRIVER_READINESS=NOT_EXECUTED");
    console.log("REAL_SA_TRIP_READINESS=NOT_EXECUTED");
    console.log("READINESS_ERROR_CLASS=" + (error.code || error.message || "FAILED").toString().split("\n")[0].slice(0, 180));
    process.exitCode = 1;
  });
}

module.exports = {summarizeDrivers, summarizeTrips};

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

const ngeniusPayments = require("./ngenius_payments.js");
const secureIntegrations = require("./secure_integrations.js");
const driverApproval = require("./driver_registration_approval.js");
const driverRegistrationV2 = require("./driver_registration_v2.js");
const driverProfileChangeRequest = require("./driver_profile_change_request.js");
exports.createNGeniusPayment = ngeniusPayments.createNGeniusPayment;
exports.getNGeniusPayment = ngeniusPayments.getNGeniusPayment;
exports.finalizeNGeniusBooking = ngeniusPayments.finalizeNGeniusBooking;
exports.createCashBooking = ngeniusPayments.createCashBooking;
exports.getExtraHoursQuote = ngeniusPayments.getExtraHoursQuote;
exports.addCashExtraHours = ngeniusPayments.addCashExtraHours;
const cashBookingCompatibility = require("./cash_booking_compatibility.js");
exports.normalizeCashBookingCompatibility =
  cashBookingCompatibility.normalizeCashBookingCompatibility;
exports.finalizeNGeniusWalletTopUp =
  ngeniusPayments.finalizeNGeniusWalletTopUp;
exports.createWalletWithdrawalRequest =
  ngeniusPayments.createWalletWithdrawalRequest;
exports.finalizeNGeniusExtraHours =
  ngeniusPayments.finalizeNGeniusExtraHours;
exports.refundNGeniusPayment = ngeniusPayments.refundNGeniusPayment;
exports.ngeniusWebhook = ngeniusPayments.ngeniusWebhook;
exports.sendWhatsAppMessage = secureIntegrations.sendWhatsAppMessage;
exports.reverseGeocode = secureIntegrations.reverseGeocode;
exports.getRoadRoute = secureIntegrations.getRoadRoute;
exports.waslRequest = secureIntegrations.waslRequest;
const waslCallables = require("./wasl/callables.js");
exports.waslOnlineGate = waslCallables.waslOnlineGate;
exports.waslRefreshDriverEligibility = waslCallables.waslRefreshDriverEligibility;
exports.waslRefreshEligibilityBulk = waslCallables.waslRefreshEligibilityBulk;
exports.waslRegisterSaudiDriver = waslCallables.waslRegisterSaudiDriver;
exports.waslSubmitLocationSample = waslCallables.waslSubmitLocationSample;
exports.waslRetryTripSync = waslCallables.waslRetryTripSync;
exports.waslOnOrderUpdated = functions.region("us-central1")
  .firestore.document("order/{orderId}")
  .onUpdate(waslCallables.onOrderUpdated);
exports.waslOnUserUpdated = functions.region("us-central1")
  .firestore.document("user/{userId}")
  .onUpdate(waslCallables.onUserUpdated);
exports.waslTripOutbox = functions.region("us-central1")
  .pubsub.schedule("every 5 minutes")
  .onRun(waslCallables.waslTripOutbox);
exports.approveDriverRegistration = functions.region("us-central1")
  .https.onCall(driverApproval.approveDriverRegistration);
exports.rejectDriverRegistration = functions.region("us-central1")
  .https.onCall(driverApproval.rejectDriverRegistration);
exports.requestDriverChanges = functions.region("us-central1")
  .https.onCall(driverApproval.requestDriverChanges);
exports.autoActivateDriver = functions.region("us-central1")
  .https.onCall(driverApproval.autoActivateDriver);
exports.submitDriverApplicationV2 = functions.region("us-central1")
  .https.onCall(driverRegistrationV2.submitDriverApplicationV2);
exports.reviewDriverApplicationV2 = functions.region("us-central1")
  .https.onCall(driverRegistrationV2.reviewDriverApplicationV2);
exports.submitDriverProfileChangeRequest = functions.region("us-central1")
  .https.onCall(driverProfileChangeRequest.submitDriverProfileChangeRequest);
exports.reviewDriverProfileChangeRequest = functions.region("us-central1")
  .https.onCall(driverProfileChangeRequest.reviewDriverProfileChangeRequest);
const driverDocumentReview = require('./driver_document_review.js');
const driverCountryConfigAdmin = require('./driver_country_config_admin.js');
exports.reviewDriverDocument = functions
  .region('us-central1')
  .https.onCall(driverDocumentReview.reviewDriverDocument);
exports.adminEnsureDriverCountryConfigs = functions
  .region('us-central1')
  .https.onCall(driverCountryConfigAdmin.adminEnsureDriverCountryConfigs);
exports.onCountryCreatedDriverConfig = functions
  .region('us-central1')
  .firestore.document('countries/{countryId}')
  .onCreate(driverCountryConfigAdmin.onCountryCreated);
const driverDocumentExpiryNotify = require('./driver_document_expiry_notify.js');
exports.scanDriverDocumentExpiry = driverDocumentExpiryNotify.scanDriverDocumentExpiry;


const emailVerificationOtp = require("./email_verification_otp.js");
// Always bind Secret Manager secrets for OTP — required for production send/verify.
exports.requestEmailVerificationOtp = functions
  .region("us-central1")
  .runWith({
    timeoutSeconds: 60,
    secrets: ["EMAIL_OTP_HMAC_SECRET", "BREVO_API_KEY"],
  })
  .https.onCall(emailVerificationOtp.requestEmailVerificationOtp);
exports.verifyEmailVerificationOtp = functions
  .region("us-central1")
  .runWith({
    timeoutSeconds: 60,
    secrets: ["EMAIL_OTP_HMAC_SECRET"],
  })
  .https.onCall(emailVerificationOtp.verifyEmailVerificationOtp);
exports.getEmailVerificationOtpStatus = functions
  .region("us-central1")
  .https.onCall(emailVerificationOtp.getEmailVerificationOtpStatus);
exports.probeBrevoOtpDeliveryEvents = functions
  .region("us-central1")
  .runWith({
    timeoutSeconds: 30,
    secrets: ["BREVO_API_KEY"],
  })
  .https.onCall(emailVerificationOtp.probeBrevoOtpDeliveryEvents);

const driverWalletOps = require("./driver_wallet_ops.js");
exports.acceptDriverOrder = driverWalletOps.acceptDriverOrder;
exports.payCompanyFromWallet = driverWalletOps.payCompanyFromWallet;

const orderOfferWaves = require("./order_offer_waves.js");
exports.onOrderCreatedOfferWave = orderOfferWaves.onOrderCreatedOfferWave;
exports.expandOrderOfferWaves = orderOfferWaves.expandOrderOfferWaves;
exports.refreshOrderOfferWave = orderOfferWaves.refreshOrderOfferWave;

const pushEnqueue = require("./push_enqueue.js");
exports.enqueueUserPushNotification = pushEnqueue.enqueueUserPushNotification;

const kFcmTokensCollection = "fcm_tokens";
const kPushNotificationsCollection = "ff_push_notifications";
const kUserPushNotificationsCollection = "ff_user_push_notifications";
const firestore = admin.firestore();

const kPushNotificationRuntimeOpts = {
  timeoutSeconds: 540,
  memory: "2GB",
};

exports.addFcmToken = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in required.",
      );
    }
    const userDocPath = data.userDocPath;
    const fcmToken = data.fcmToken;
    const deviceType = data.deviceType;
    if (
      typeof userDocPath === "undefined" ||
      typeof fcmToken === "undefined" ||
      typeof deviceType === "undefined" ||
      userDocPath.split("/").length <= 1 ||
      fcmToken.length === 0 ||
      deviceType.length === 0
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid FCM token arguments.",
      );
    }
    if (context.auth.uid != userDocPath.split("/")[1]) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Authenticated user doesn't match user provided.",
      );
    }
    const existingTokens = await firestore
      .collectionGroup(kFcmTokensCollection)
      .where("fcm_token", "==", fcmToken)
      .get();
    var userAlreadyHasToken = false;
    for (var doc of existingTokens.docs) {
      const user = doc.ref.parent.parent;
      if (user.path != userDocPath) {
        // Should never have the same FCM token associated with multiple users.
        await doc.ref.delete();
      } else {
        userAlreadyHasToken = true;
      }
    }
    if (userAlreadyHasToken) {
      return { ok: true, alreadyExists: true };
    }
    await getUserFcmTokensCollection(userDocPath).doc().set({
      fcm_token: fcmToken,
      device_type: deviceType,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true };
  });

exports.sendPushNotificationsTrigger = functions
  .region("us-central1")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document(`${kPushNotificationsCollection}/{id}`)
  .onCreate(async (snapshot) => {
    try {
      // Ignore scheduled push notifications on create
      const scheduledTime = snapshot.data().scheduled_time || "";
      if (scheduledTime) {
        return;
      }

      await sendPushNotifications(snapshot);
    } catch (e) {
      console.log(`Error: ${e}`);
      await snapshot.ref.update({ status: "failed", error: `${e}` });
    }
  });

exports.sendUserPushNotificationsTrigger = functions
  .region("us-central1")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document(`${kUserPushNotificationsCollection}/{id}`)
  .onCreate(async (snapshot) => {
    try {
      // Ignore scheduled push notifications on create
      const scheduledTime = snapshot.data().scheduled_time || "";
      if (scheduledTime) {
        return;
      }

      // Don't let user-triggered notifications to be sent to all users.
      const userRefs = normalizePushUserRefs(snapshot.data().user_refs);
      if (userRefs.length) {
        await sendPushNotifications(snapshot);
      }
    } catch (e) {
      console.log(`Error: ${e}`);
      await snapshot.ref.update({ status: "failed", error: `${e}` });
    }
  });

/** Normalize user_refs stored as comma-string or DocumentReference[]. */
function normalizePushUserRefs(raw) {
  if (Array.isArray(raw)) {
    return raw
      .map((v) => {
        if (typeof v === "string") return v.trim();
        if (v && typeof v.path === "string") return v.path.trim();
        return "";
      })
      .filter((p) => p.length > 0);
  }
  if (typeof raw === "string") {
    return raw
      .split(",")
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  }
  return [];
}

/** FCM data payloads require string values. */
function normalizePushParameterData(raw) {
  if (raw == null || raw === "") return "";
  if (typeof raw === "string") return raw;
  try {
    return JSON.stringify(raw);
  } catch (_) {
    return "";
  }
}

function isValidFcmToken(token) {
  return typeof token === "string" && token.trim().length > 0;
}

async function sendPushNotifications(snapshot) {
  const notificationData = snapshot.data();
  const title = notificationData.notification_title || "";
  const body = notificationData.notification_text || "";
  const imageUrl = notificationData.notification_image_url || "";
  const sound = notificationData.notification_sound || "";
  const parameterData = normalizePushParameterData(
    notificationData.parameter_data,
  );
  const targetAudience = notificationData.target_audience || "";
  const initialPageName = String(
    notificationData.initial_page_name || "",
  );
  const userRefs = normalizePushUserRefs(notificationData.user_refs);
  const batchIndex = notificationData.batch_index || 0;
  const numBatches = notificationData.num_batches || 0;
  const status = notificationData.status || "";

  if (status !== "" && status !== "started") {
    console.log(`Already processed ${snapshot.ref.path}. Skipping...`);
    return;
  }

  if (title === "" || body === "") {
    await snapshot.ref.update({ status: "failed", error: "empty_title_or_body" });
    return;
  }

  var tokens = new Set();
  if (userRefs.length) {
    for (var userRef of userRefs) {
      const userTokens = await firestore
        .doc(userRef)
        .collection(kFcmTokensCollection)
        .get();
      userTokens.docs.forEach((token) => {
        const fcm = token.data().fcm_token;
        if (isValidFcmToken(fcm)) {
          tokens.add(fcm.trim());
        }
      });
    }
  } else {
    var userTokensQuery = firestore.collectionGroup(kFcmTokensCollection);
    // Handle batched push notifications by splitting tokens up by document
    // id.
    if (numBatches > 0) {
      userTokensQuery = userTokensQuery
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAt(getDocIdBound(batchIndex, numBatches))
        .endBefore(getDocIdBound(batchIndex + 1, numBatches));
    }
    const userTokens = await userTokensQuery.get();
    userTokens.docs.forEach((token) => {
      const data = token.data();
      const audienceMatches =
        targetAudience === "All" || data.device_type === targetAudience;
      if (audienceMatches && isValidFcmToken(data.fcm_token)) {
        tokens.add(data.fcm_token.trim());
      }
    });
  }

  const tokensArr = Array.from(tokens);
  if (!tokensArr.length) {
    await snapshot.ref.update({
      status: "succeeded",
      num_sent: 0,
      note: "no_fcm_tokens",
    });
    return;
  }

  var messageBatches = [];
  for (let i = 0; i < tokensArr.length; i += 500) {
    const tokensBatch = tokensArr.slice(i, Math.min(i + 500, tokensArr.length));
    const messages = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl: imageUrl }),
      },
      data: {
        initialPageName,
        parameterData,
      },
      android: {
        priority: "high",
        notification: {
          ...(sound && { sound: sound }),
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            sound: sound || "default",
            // Do NOT set content-available for alert pushes — it can suppress
            // banners on iOS when the app is backgrounded.
          },
        },
      },
      tokens: tokensBatch,
    };
    messageBatches.push(messages);
  }

  var numSent = 0;
  var numFail = 0;
  const sampleErrors = [];
  await Promise.all(
    messageBatches.map(async (messages) => {
      const response = await admin.messaging().sendEachForMulticast(messages);
      numSent += response.successCount;
      numFail += response.failureCount;
      if (response.responses) {
        for (const r of response.responses) {
          if (!r.success && sampleErrors.length < 5) {
            sampleErrors.push(String((r.error && r.error.code) || r.error || "unknown"));
          }
        }
      }
    }),
  );

  const patch = {
    status: numSent > 0 || tokensArr.length === 0 ? "succeeded" : "failed",
    num_sent: numSent,
    num_fail: numFail,
    token_count: tokensArr.length,
  };
  if (tokensArr.length && numSent === 0) {
    patch.error = sampleErrors.join(",") || "all_fcm_sends_failed";
  }
  if (sampleErrors.length) {
    patch.fcm_error_samples = sampleErrors;
  }
  await snapshot.ref.update(patch);
}

function getUserFcmTokensCollection(userDocPath) {
  return firestore.doc(userDocPath).collection(kFcmTokensCollection);
}

function getDocIdBound(index, numBatches) {
  if (index <= 0) {
    return "user/(";
  }
  if (index >= numBatches) {
    return "user/}";
  }
  const numUidChars = 62;
  const twoCharOptions = Math.pow(numUidChars, 2);

  var twoCharIdx = (index * twoCharOptions) / numBatches;
  var firstCharIdx = Math.floor(twoCharIdx / numUidChars);
  var secondCharIdx = Math.floor(twoCharIdx % numUidChars);
  const firstChar = getCharForIndex(firstCharIdx);
  const secondChar = getCharForIndex(secondCharIdx);
  return "user/" + firstChar + secondChar;
}

function getCharForIndex(charIdx) {
  if (charIdx < 10) {
    return String.fromCharCode(charIdx + "0".charCodeAt(0));
  } else if (charIdx < 36) {
    return String.fromCharCode("A".charCodeAt(0) + charIdx - 10);
  } else {
    return String.fromCharCode("a".charCodeAt(0) + charIdx - 36);
  }
}
exports.onUserDeleted = functions
  .region("us-central1")
  .auth.user()
  .onDelete(async (user) => {
    await admin.firestore().doc("user/" + user.uid).delete();
  });

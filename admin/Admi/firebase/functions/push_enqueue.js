"use strict";

/**
 * Trusted client → server enqueue for ff_user_push_notifications.
 * Firestore rules deny client creates on that collection; this callable
 * validates the caller and writes via Admin SDK so sendUserPushNotificationsTrigger runs.
 */
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const pushLocale = require("../../../shared/push_locale");

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required");
  }
  return context.auth.uid;
}

function normalizeUserRefs(raw) {
  if (Array.isArray(raw)) {
    return raw
      .map((v) => {
        if (typeof v === "string") return v.trim();
        if (v && typeof v.path === "string") return v.path.trim();
        return "";
      })
      .filter((p) => /^user\/[^/]+$/.test(p));
  }
  if (typeof raw === "string") {
    return raw
      .split(",")
      .map((s) => s.trim())
      .filter((p) => /^user\/[^/]+$/.test(p));
  }
  return [];
}

function stringifyParameterData(raw) {
  if (raw == null || raw === "") return "";
  if (typeof raw === "string") return raw;
  try {
    return JSON.stringify(raw);
  } catch (_) {
    return "";
  }
}

exports.enqueueUserPushNotification = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const notificationType = String(
      data.notificationType || data.notification_type || "",
    ).trim();
    const title = String(data.notificationTitle || data.notification_title || "").trim();
    const text = String(data.notificationText || data.notification_text || "").trim();
    if (!notificationType && (!title || !text)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "notificationTitle and notificationText required",
      );
    }
    const userRefs = normalizeUserRefs(data.userRefs || data.user_refs);
    if (!userRefs.length) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userRefs required",
      );
    }
    // Cap fan-out from clients (chat / trip events are 1 recipient typically).
    if (userRefs.length > 20) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "too many recipients",
      );
    }

    const initialPageName = String(
      data.initialPageName || data.initial_page_name || "",
    ).trim();
    const parameterData = stringifyParameterData(
      data.parameterData ?? data.parameter_data,
    );
    const imageUrl = String(
      data.notificationImageUrl || data.notification_image_url || "",
    ).trim();
    const sound = String(
      data.notificationSound || data.notification_sound || "",
    ).trim();

    const payload = {
      notification_title: title.slice(0, 180),
      notification_text: text.slice(0, 500),
      user_refs: userRefs.join(","),
      initial_page_name: initialPageName.slice(0, 80),
      parameter_data: parameterData.slice(0, 4000),
      sender: admin.firestore().doc(`user/${uid}`),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "",
      source: "enqueueUserPushNotification",
    };
    if (imageUrl) payload.notification_image_url = imageUrl.slice(0, 500);
    if (sound) payload.notification_sound = sound.slice(0, 80);

    const orderPath = String(data.orderPath || data.order_path || "").trim();
    if (/^order\/[^/]+$/.test(orderPath)) {
      payload.order_ref = admin.firestore().doc(orderPath);
    }

    const notificationPayload =
      data.notificationPayload || data.notification_payload || data.payload || {};
    if (notificationType) {
      const ids = [];
      for (const userRef of userRefs) {
        const snap = await admin.firestore().doc(userRef).get();
        const locale = pushLocale.normalizeLocale(
          snap.exists ? snap.data().preferred_locale : "en",
        );
        const copy = pushLocale.resolvePair(
          notificationType,
          locale,
          notificationPayload,
        );
        if (!copy) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "UNKNOWN_NOTIFICATION_TYPE",
          );
        }
        const ref = await admin
          .firestore()
          .collection("ff_user_push_notifications")
          .add({
            ...payload,
            notification_title: copy.title,
            notification_text: copy.body,
            notification_type: notificationType,
            preferred_locale: locale,
            user_refs: userRef,
          });
        ids.push(ref.id);
      }
      return { ok: true, id: ids[0], ids };
    }

    const ref = await admin
      .firestore()
      .collection("ff_user_push_notifications")
      .add(payload);
    return { ok: true, id: ref.id };
  });

exports.normalizeUserRefs = normalizeUserRefs;
exports.stringifyParameterData = stringifyParameterData;

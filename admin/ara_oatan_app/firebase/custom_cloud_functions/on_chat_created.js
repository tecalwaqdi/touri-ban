const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

async function collectFcmTokens(userRef) {
  const tokens = new Set();
  if (!userRef || !userRef.path) {
    return [];
  }

  const userDoc = await admin.firestore().doc(userRef.path).get();
  if (!userDoc.exists) {
    return [];
  }

  const userData = userDoc.data() || {};
  const topLevel = userData.fcm_token || userData.fcmToken;
  if (typeof topLevel === "string" && topLevel.trim()) {
    tokens.add(topLevel.trim());
  }
  if (Array.isArray(userData.fcm_tokens)) {
    for (const item of userData.fcm_tokens) {
      if (typeof item === "string" && item.trim()) {
        tokens.add(item.trim());
      } else if (item && typeof item.fcm_token === "string" && item.fcm_token.trim()) {
        tokens.add(item.fcm_token.trim());
      }
    }
  }

  try {
    const sub = await userRef.collection("fcm_tokens").limit(25).get();
    for (const doc of sub.docs) {
      const token = (doc.data() || {}).fcm_token;
      if (typeof token === "string" && token.trim()) {
        tokens.add(token.trim());
      }
    }
  } catch (err) {
    console.error("Failed reading fcm_tokens subcollection:", err);
  }

  return Array.from(tokens);
}

exports.onChatCreated = functions.firestore
  .document("chat/{chatId}")
  .onCreate(async (snapshot) => {
    try {
      const chatData = snapshot.data();
      if (!chatData) return null;

      const receiverRef = chatData.user1;
      if (!receiverRef || !receiverRef.path) {
        console.error("user1 reference missing or invalid");
        return null;
      }

      const tokens = await collectFcmTokens(receiverRef);
      if (!tokens.length) {
        console.error("FCM token not found for user", receiverRef.path);
        return null;
      }

      const body =
        (typeof chatData.msg === "string" && chatData.msg.trim()) ||
        (typeof chatData.text === "string" && chatData.text.trim()) ||
        "لديك رسالة جديدة";

      const results = [];
      for (const token of tokens) {
        const message = {
          notification: {
            title: "رسالة جديدة",
            body,
          },
          android: {
            priority: "high",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
          token,
        };
        try {
          results.push(await admin.messaging().send(message));
        } catch (sendErr) {
          console.error("FCM send failed for token:", sendErr);
        }
      }

      console.log("Chat notifications sent:", results.length);
      return results;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  });

const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.notifyOnNewChat = functions.firestore
  .document("chat/{chatDocId}")
  .onCreate(async (snap, context) => {
    const chatData = snap.data();
    console.log("New Chat Created:", context.params.chatDocId);

    if (!chatData.user1) {
      console.error("Field user1 is missing!");
      return null;
    }

    // استخراج ID المستخدم من الـ Reference
    const userId = chatData.user1.id;
    console.log("Extracted User ID:", userId);

    try {
      const userDoc = await admin
        .firestore()
        .collection("user")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.error(`User ${userId} not found in 'user' collection`);
        return null;
      }

      // جرب الحقلين الشائعين في FlutterFlow
      const fcmToken = userDoc.data().fcm_token || userDoc.data().fcmToken;
      console.log("FCM Token found:", fcmToken ? "Yes" : "No");

      if (!fcmToken) return null;

      const message = {
        notification: { title: "رسالة جديدة", body: "لديك رسالة بخصوص طلبك" },
        token: fcmToken,
      };

      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
    } catch (error) {
      console.error("Detailed Error:", error);
    }
    return null;
  });

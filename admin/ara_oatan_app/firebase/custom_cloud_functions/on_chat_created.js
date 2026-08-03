const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.onChatCreated = functions.firestore
  .document("chat/{chatId}")
  .onCreate(async (snapshot) => {
    try {
      const chatData = snapshot.data();
      if (!chatData) return null;

      // المستلم (user1)
      const receiverRef = chatData.user1;

      if (!receiverRef || !receiverRef.path) {
        console.error("user1 reference missing or invalid");
        return null;
      }

      // جلب بيانات المستخدم من جدول user
      const userDoc = await admin.firestore().doc(receiverRef.path).get();

      if (!userDoc.exists) {
        console.error("User document not found");
        return null;
      }

      const userData = userDoc.data();
      const token = userData.fcm_token;

      if (!token) {
        console.error("FCM token not found for user");
        return null;
      }

      // إعداد الإشعار
      const message = {
        notification: {
          title: "رسالة جديدة",
          body: chatData.text || "لديك رسالة جديدة",
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
        token: token,
      };

      const response = await admin.messaging().send(message);
      console.log("Notification sent successfully:", response);
      return response;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  });

const { initializeApp, getApps } = require("firebase-admin/app");

if (!getApps().length) {
  initializeApp();
}

const autoCancelOrders = require("./auto_cancel_orders.js");
exports.autoCancelOrders = autoCancelOrders.autoCancelOrders;
const newCloudFunction = require("./new_cloud_function.js");
exports.newCloudFunction = newCloudFunction.newCloudFunction;
// notifyOnNewChat removed — superseded by onChatCreated (msg + fcm_tokens).
const onChatCreated = require("./on_chat_created.js");
exports.onChatCreated = onChatCreated.onChatCreated;

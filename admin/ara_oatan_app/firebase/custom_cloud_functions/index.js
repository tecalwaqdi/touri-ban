const { initializeApp, getApps } = require("firebase-admin/app");

if (!getApps().length) {
  initializeApp();
}

const autoCancelOrders = require("./auto_cancel_orders.js");
exports.autoCancelOrders = autoCancelOrders.autoCancelOrders;
const newCloudFunction = require("./new_cloud_function.js");
exports.newCloudFunction = newCloudFunction.newCloudFunction;
const notifyOnNewChat = require("./notify_on_new_chat.js");
exports.notifyOnNewChat = notifyOnNewChat.notifyOnNewChat;
const onChatCreated = require("./on_chat_created.js");
exports.onChatCreated = onChatCreated.onChatCreated;

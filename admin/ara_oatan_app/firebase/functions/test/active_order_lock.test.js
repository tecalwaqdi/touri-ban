const {
  isCustomerActiveStatusCode,
} = require("../active_order_lock.js");

function assert(cond, msg) {
  if (!cond) throw new Error(msg || "assert failed");
}

assert(isCustomerActiveStatusCode("payment_pending") === true);
assert(isCustomerActiveStatusCode("pending_driver") === true);
assert(isCustomerActiveStatusCode("driver_assigned") === true);
assert(isCustomerActiveStatusCode("completed") === false);
assert(isCustomerActiveStatusCode("expired") === false);
assert(isCustomerActiveStatusCode("cancelled_by_customer") === false);
assert(isCustomerActiveStatusCode("") === false);

console.log("active_order_lock status checks OK");

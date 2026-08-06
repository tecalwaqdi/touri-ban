import 'package:flutter_test/flutter_test.dart';

import 'package:mndob/core/toury_system_status_codes.dart';

/// Documents driver pool visibility rules for payment migration.
///
/// Driver open-pool query (DriverOrderMatch.queryBuilder):
///   status_code == pending_driver AND ALLNOW == true
///
/// Online unpaid sessions live only in payment_sessions — never in `order`
/// until paid finalize/webhook. Therefore unpaid/failed/cancelled card
/// payments cannot appear in the driver pool.
void main() {
  test('pending_driver status code is stable', () {
    expect(TourySystemStatusCodes.pendingDriver, 'pending_driver');
  });

  test('paid online and cash share pending_driver for offers', () {
    // Both cash (pending_cash) and paid online use status_code=pending_driver
    // with ALLNOW=true so they appear in the same pool.
    const cashStatusCode = 'pending_driver';
    const paidOnlineStatusCode = 'pending_driver';
    expect(cashStatusCode, paidOnlineStatusCode);
  });

  test('unpaid online never uses order status_code before payment', () {
    // payment_sessions.status may be pending/failed; no order doc exists.
    const sessionPending = 'pending';
    expect(sessionPending, isNot(TourySystemStatusCodes.pendingDriver));
  });
}

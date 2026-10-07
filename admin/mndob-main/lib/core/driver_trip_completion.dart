import '/backend/schema/order_record.dart';
import '/core/driver_lifecycle_state.dart';
import '/core/driver_trip_constants.dart';
import '/core/toury_system_status_codes.dart';

/// Trip completion helpers for cash / post-trip panels.
abstract final class DriverTripCompletion {
  DriverTripCompletion._();

  static bool isCompleted(OrderRecord order) {
    final code = (order.snapshotData['status_code'] ?? '').toString();
    if (DriverTripActionGates.isCompletedListItem(code, order.halhText)) {
      return true;
    }
    final c = code.trim().toLowerCase();
    if (c == TourySystemStatusCodes.completed ||
        c == TourySystemStatusCodes.legacyTripCompleted) {
      return true;
    }
    return DriverTripHalh.isCompleted(order.halhText);
  }
}

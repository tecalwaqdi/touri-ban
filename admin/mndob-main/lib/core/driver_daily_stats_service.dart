import '/backend/backend.dart';
import '/core/driver_order_match.dart';

/// إحصائيات يومية للمندوب.
class DriverDailyStats {
  const DriverDailyStats({
    required this.tripCount,
    required this.earningsToday,
    required this.hoursWorkedMinutes,
    required this.availableOrdersNearby,
  });

  final int tripCount;
  final int earningsToday;
  final int hoursWorkedMinutes;
  final int availableOrdersNearby;

  static const empty = DriverDailyStats(
    tripCount: 0,
    earningsToday: 0,
    hoursWorkedMinutes: 0,
    availableOrdersNearby: 0,
  );

  String get hoursWorkedLabel {
    if (hoursWorkedMinutes <= 0) return '0 د';
    final h = hoursWorkedMinutes ~/ 60;
    final m = hoursWorkedMinutes % 60;
    if (h == 0) return '$m د';
    if (m == 0) return '$h س';
    return '$h س $m د';
  }
}

abstract final class DriverDailyStatsService {
  DriverDailyStatsService._();

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool _isToday(DateTime? value) {
    if (value == null) return false;
    final start = _startOfToday();
    final end = start.add(const Duration(days: 1));
    return !value.isBefore(start) && value.isBefore(end);
  }

  static DateTime? _completionTime(OrderRecord order) {
    return order.dateend ?? order.endTime ?? order.timestamp ?? order.dataOrder;
  }

  static Future<DriverDailyStats> fetch({
    DocumentReference? driverRef,
    DocumentReference? villRef,
    DocumentReference? carTypeRef,
  }) async {
    if (driverRef == null) return DriverDailyStats.empty;

    final completed = await queryOrderRecordOnce(
      queryBuilder: (order) => order
          .where('mndob_user', isEqualTo: driverRef)
          .where('halh_text', isEqualTo: 'مكتمل'),
    );

    var tripCount = 0;
    var earningsToday = 0;
    var minutesWorked = 0;

    for (final order in completed) {
      final doneAt = _completionTime(order);
      if (!_isToday(doneAt)) continue;

      tripCount++;
      earningsToday += order.totalMndob > 0 ? order.totalMndob : order.total;

      final start = order.start;
      final end = order.dateend ?? order.endTime;
      if (start != null && end != null && end.isAfter(start)) {
        minutesWorked += end.difference(start).inMinutes;
      }
    }

    var availableCount = 0;
    if (carTypeRef != null) {
      availableCount = await queryOrderRecordCount(
        queryBuilder: DriverOrderMatch.queryBuilder(typeCarRef: carTypeRef),
      );
    }

    return DriverDailyStats(
      tripCount: tripCount,
      earningsToday: earningsToday,
      hoursWorkedMinutes: minutesWorked,
      availableOrdersNearby: availableCount,
    );
  }
}

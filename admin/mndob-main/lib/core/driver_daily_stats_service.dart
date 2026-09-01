import '/backend/backend.dart';
import '/core/driver_financial_summary_service.dart';
import '/core/driver_order_match.dart';

/// إحصائيات يومية للمندوب — earnings from server Summary V2.
class DriverDailyStats {
  const DriverDailyStats({
    required this.tripCount,
    required this.earningsToday,
    required this.driverNetToday,
    required this.hoursWorkedMinutes,
    required this.availableOrdersNearby,
    this.financeLoaded = false,
    this.financeError,
  });

  final int tripCount;
  /// Legacy int display fallback — prefer [driverNetToday].
  final int earningsToday;
  final double driverNetToday;
  final int hoursWorkedMinutes;
  final int availableOrdersNearby;
  final bool financeLoaded;
  final String? financeError;

  static const empty = DriverDailyStats(
    tripCount: 0,
    earningsToday: 0,
    driverNetToday: 0,
    hoursWorkedMinutes: 0,
    availableOrdersNearby: 0,
  );

  String get earningsTodayLabel => driverNetToday.toStringAsFixed(2);

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

  static DateTime _startOfTodayRiyadh() {
    const offset = Duration(hours: 3);
    final now = DateTime.now().toUtc().add(offset);
    final startLocal = DateTime.utc(now.year, now.month, now.day);
    return startLocal.subtract(offset);
  }

  static DateTime _endOfTodayRiyadh() =>
      _startOfTodayRiyadh().add(const Duration(days: 1));

  static bool _isTodayRiyadh(DateTime? value) {
    if (value == null) return false;
    final start = _startOfTodayRiyadh();
    final end = _endOfTodayRiyadh();
    final utc = value.toUtc();
    return !utc.isBefore(start) && utc.isBefore(end);
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

    final finance = await DriverFinancialSummaryService.load(
      driverId: driverRef.id,
    );

    var tripCount = 0;
    var minutesWorked = 0;
    double driverNetToday = 0;
    var financeLoaded = false;
    String? financeError;

    if (finance.ok && finance.summary != null) {
      financeLoaded = true;
      tripCount = finance.summary!.today.completedTrips;
      driverNetToday = finance.summary!.today.driverNet;
    } else {
      financeError = finance.error;
    }

    // Hours worked still derived locally from completed orders today.
    final completed = await queryOrderRecordOnce(
      queryBuilder: (order) => order
          .where('mndob_user', isEqualTo: driverRef)
          .where('halh_text', isEqualTo: 'مكتمل'),
    );

    if (!financeLoaded) {
      for (final order in completed) {
        final doneAt = _completionTime(order);
        if (!_isTodayRiyadh(doneAt)) continue;
        tripCount++;
        driverNetToday += order.hasTotalMndob()
            ? order.totalMndob
            : (order.total > 0 ? order.total : order.totalMndob2);
      }
    }

    for (final order in completed) {
      final doneAt = _completionTime(order);
      if (!_isTodayRiyadh(doneAt)) continue;
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
      earningsToday: driverNetToday.round(),
      driverNetToday: driverNetToday,
      hoursWorkedMinutes: minutesWorked,
      availableOrdersNearby: availableCount,
      financeLoaded: financeLoaded,
      financeError: financeError,
    );
  }
}

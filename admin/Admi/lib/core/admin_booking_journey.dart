import '/backend/schema/order_record.dart';
import '/core/admin_booking_status_label.dart';
import '/core/toury_system_status_codes.dart';

/// Per-stop presentation state for Admin booking journey (read-only).
enum AdminBookingJourneyStopState {
  upcoming,
  current,
  arrived,
  visited,
  returnLeg,
  unknown,
}

/// One stop on a tourist / multi-stop booking route.
class AdminBookingJourneyStop {
  const AdminBookingJourneyStop({
    required this.index,
    required this.name,
    required this.state,
    required this.okdoneKnown,
    required this.isReturnDestination,
    this.arrivedAt,
    this.visitedAt,
  });

  final int index;
  final String name;
  final AdminBookingJourneyStopState state;
  final bool okdoneKnown;
  final bool isReturnDestination;
  final DateTime? arrivedAt;
  final DateTime? visitedAt;

  bool get isCurrent =>
      state == AdminBookingJourneyStopState.current ||
      state == AdminBookingJourneyStopState.returnLeg;

  bool get isCompleted => state == AdminBookingJourneyStopState.visited;
}

/// Read-only journey derived from persisted order fields (`listAmakn[].okdone`).
class AdminBookingJourneyView {
  const AdminBookingJourneyView({
    required this.stops,
    required this.onReturnLeg,
    required this.tripInProgress,
    required this.hasStopMetadata,
  });

  final List<AdminBookingJourneyStop> stops;
  final bool onReturnLeg;
  final bool tripInProgress;
  final bool hasStopMetadata;

  bool get isEmpty => stops.isEmpty;

  static AdminBookingJourneyView fromOrder(OrderRecord order) {
    final rawStops = order.snapshotData['listAmakn'];
    if (rawStops is! List || rawStops.isEmpty) {
      return const AdminBookingJourneyView(
        stops: [],
        onReturnLeg: false,
        tripInProgress: false,
        hasStopMetadata: false,
      );
    }

    final statusCode = AdminBookingStatusLabel.codeOf(order);
    final tripInProgress = _tripInProgress(statusCode);
    final parsed = <({String name, bool? okdone, DateTime? visitedAt})>[];

    for (final item in rawStops) {
      if (item is! Map) {
        parsed.add((name: '', okdone: null, visitedAt: null));
        continue;
      }
      final map = Map<String, dynamic>.from(item);
      parsed.add((
        name: _stopName(map),
        okdone: _readOkdone(map),
        visitedAt: _readTimestamp(map, const [
          'visited_at',
          'visitedAt',
          'okdone_at',
          'okdoneAt',
        ]),
      ));
    }

    final hasStopMetadata =
        parsed.any((s) => s.okdone != null) || parsed.length > 1;

    // Mirror customer contract: landmarks = all but last when length > 1.
    final landmarkCount =
        parsed.length <= 1 ? parsed.length : parsed.length - 1;

    var visitedLandmarks = 0;
    int? activeLandmarkIndex;
    for (var i = 0; i < landmarkCount; i++) {
      if (parsed[i].okdone == true) {
        visitedLandmarks++;
      } else if (activeLandmarkIndex == null && parsed[i].okdone != null) {
        activeLandmarkIndex = i;
      }
    }

    final onReturnLeg = tripInProgress &&
        landmarkCount > 0 &&
        visitedLandmarks >= landmarkCount;

    int? activeIndex;
    if (onReturnLeg && parsed.isNotEmpty) {
      activeIndex = parsed.length - 1;
    } else {
      activeIndex = activeLandmarkIndex;
    }

    final stops = <AdminBookingJourneyStop>[];
    for (var i = 0; i < parsed.length; i++) {
      final p = parsed[i];
      final isReturn = parsed.length > 1 && i == parsed.length - 1;
      final okdoneKnown = p.okdone != null;
      final state = _resolveState(
        index: i,
        okdone: p.okdone,
        okdoneKnown: okdoneKnown,
        activeIndex: activeIndex,
        onReturnLeg: onReturnLeg,
        isReturnDestination: isReturn,
        tripInProgress: tripInProgress,
      );
      stops.add(
        AdminBookingJourneyStop(
          index: i,
          name: p.name.isNotEmpty ? p.name : '—',
          state: state,
          okdoneKnown: okdoneKnown,
          isReturnDestination: isReturn,
          visitedAt: p.visitedAt,
        ),
      );
    }

    return AdminBookingJourneyView(
      stops: stops,
      onReturnLeg: onReturnLeg,
      tripInProgress: tripInProgress,
      hasStopMetadata: hasStopMetadata,
    );
  }

  static bool _tripInProgress(String statusCode) {
    const active = {
      TourySystemStatusCodes.tripStarted,
      TourySystemStatusCodes.tripInProgress,
      TourySystemStatusCodes.driverArrived,
    };
    return active.contains(statusCode);
  }

  static String _stopName(Map<String, dynamic> map) {
    for (final key in const ['address', 'naim', 'textivill']) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static bool? _readOkdone(Map<String, dynamic> map) {
    if (!map.containsKey('okdone')) return null;
    final v = map['okdone'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    return null;
  }

  static DateTime? _readTimestamp(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final v = map[key];
      if (v == null) continue;
      if (v is DateTime) return v;
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
      }
      if (v is Map) {
        final sec = v['seconds'] ?? v['_seconds'];
        if (sec is num) {
          return DateTime.fromMillisecondsSinceEpoch(sec.toInt() * 1000,
              isUtc: true);
        }
      }
    }
    return null;
  }

  static AdminBookingJourneyStopState _resolveState({
    required int index,
    required bool? okdone,
    required bool okdoneKnown,
    required int? activeIndex,
    required bool onReturnLeg,
    required bool isReturnDestination,
    required bool tripInProgress,
  }) {
    if (!okdoneKnown) {
      return AdminBookingJourneyStopState.unknown;
    }
    if (okdone == true) {
      return AdminBookingJourneyStopState.visited;
    }
    if (activeIndex != null && index == activeIndex && tripInProgress) {
      return AdminBookingJourneyStopState.current;
    }
    if (onReturnLeg && isReturnDestination && tripInProgress) {
      return AdminBookingJourneyStopState.returnLeg;
    }
    return AdminBookingJourneyStopState.upcoming;
  }

  /// Localized Arabic label for [state] (presentation only).
  static String stateLabelArabic(AdminBookingJourneyStopState state) {
    return switch (state) {
      AdminBookingJourneyStopState.upcoming => 'قادم',
      AdminBookingJourneyStopState.current => 'الحالي',
      AdminBookingJourneyStopState.arrived => 'تم الوصول',
      AdminBookingJourneyStopState.visited => 'تمت الزيارة',
      AdminBookingJourneyStopState.returnLeg => 'العودة',
      AdminBookingJourneyStopState.unknown => 'غير متوفر',
    };
  }
}

/// Canonical hourly booking billable-hours rule.
///
/// Service minutes =
///   outboundTravelMinutes
///   + (landmarkCount × [minLandmarkVisitMinutes])
///   + returnTravelMinutes (0 when return-to-pickup is off)
///
/// billableHours = max(
///   userSelectedHours,
///   vehicleMinimumHours,
///   ceil(serviceMinutes / 60),
/// )
///
/// Example: 50 min travel + 1 landmark (15) = 65 min → 2h.
/// With return 50 min → 115 min → still 2h.
/// At 135 min → 3h.
///
/// Does not compute commission, VAT, or fee — only the hours input that feeds
/// [touryCalculatePriceQuote].
abstract final class TouryBillableHours {
  TouryBillableHours._();

  /// Minimum on-site visit time per landmark after arrival (minutes).
  static const int minLandmarkVisitMinutes = 15;

  /// Ceil route/service minutes to whole billable hours (0 when non-positive).
  static int hoursFromRouteMinutes(int estimatedRouteDurationMinutes) {
    if (estimatedRouteDurationMinutes <= 0) return 0;
    return (estimatedRouteDurationMinutes / 60).ceil();
  }

  /// Total service minutes: travel + per-landmark visit floor + optional return.
  static int serviceMinutes({
    required int outboundTravelMinutes,
    required int landmarkCount,
    int returnTravelMinutes = 0,
  }) {
    final travel = outboundTravelMinutes < 0 ? 0 : outboundTravelMinutes;
    final landmarks = landmarkCount < 0 ? 0 : landmarkCount;
    final ret = returnTravelMinutes < 0 ? 0 : returnTravelMinutes;
    return travel + (landmarks * minLandmarkVisitMinutes) + ret;
  }

  /// Canonical billable hours for an hourly booking.
  ///
  /// [estimatedRouteDurationMinutes] should already include visit floors and
  /// return travel when applicable (see [serviceMinutes]).
  static int compute({
    required int userSelectedHours,
    required int vehicleMinimumHours,
    required int estimatedRouteDurationMinutes,
  }) {
    final selected = userSelectedHours.clamp(0, 24 * 30).toInt();
    final vehicleMin = vehicleMinimumHours.clamp(0, 24 * 30).toInt();
    final routeHours = hoursFromRouteMinutes(estimatedRouteDurationMinutes)
        .clamp(0, 24 * 30)
        .toInt();
    var billable = selected;
    if (vehicleMin > billable) billable = vehicleMin;
    if (routeHours > billable) billable = routeHours;
    return billable;
  }

  /// Convenience: compute from travel legs + landmark count.
  static int computeFromLegs({
    required int userSelectedHours,
    required int vehicleMinimumHours,
    required int outboundTravelMinutes,
    required int landmarkCount,
    int returnTravelMinutes = 0,
  }) {
    return compute(
      userSelectedHours: userSelectedHours,
      vehicleMinimumHours: vehicleMinimumHours,
      estimatedRouteDurationMinutes: serviceMinutes(
        outboundTravelMinutes: outboundTravelMinutes,
        landmarkCount: landmarkCount,
        returnTravelMinutes: returnTravelMinutes,
      ),
    );
  }

  /// True when route/service ETA forced billable hours above the user's
  /// selection (and above vehicle minimum when that already exceeded selection).
  static bool routeForcedIncrease({
    required int userSelectedHours,
    required int vehicleMinimumHours,
    required int estimatedRouteDurationMinutes,
    required int billableHours,
  }) {
    final routeHours = hoursFromRouteMinutes(estimatedRouteDurationMinutes);
    if (routeHours <= 0) return false;
    final floorWithoutRoute = [
      userSelectedHours.clamp(0, 24 * 30),
      vehicleMinimumHours.clamp(0, 24 * 30),
    ].reduce((a, b) => a > b ? a : b);
    return billableHours > floorWithoutRoute && billableHours == routeHours;
  }

  /// Human-readable duration for localized explanation copy.
  /// Returns (hoursPart, minutesPart) of the ETA (e.g. 70 → (1, 10)).
  static (int hours, int minutes) splitDurationMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return (0, 0);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return (h, m);
  }
}

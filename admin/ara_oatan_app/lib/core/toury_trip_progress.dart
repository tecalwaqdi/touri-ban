import '/core/toury_booking_status_localizer.dart';

/// Ordered milestones shown on the live tracking timeline.
enum TouryTripStage {
  /// Waiting for a driver to accept.
  searching,

  /// Driver accepted and is heading to the pickup point.
  enRoute,

  /// Driver reached the pickup point.
  arrived,

  /// Trip is running.
  started,

  /// Trip finished.
  completed,
}

/// Stages rendered in the timeline (terminal `completed` included).
const List<TouryTripStage> touryTripTimeline = <TouryTripStage>[
  TouryTripStage.searching,
  TouryTripStage.enRoute,
  TouryTripStage.arrived,
  TouryTripStage.started,
  TouryTripStage.completed,
];

/// Maps a canonical/legacy booking status onto a timeline stage.
TouryTripStage touryResolveTripStage({
  String? statusCode,
  String? halhText,
  String? driverOrderStatus,
}) {
  if (BookingStatusLocalizer.isTripCompleted(
    statusCode: statusCode,
    halhText: halhText,
    driverOrderStatus: driverOrderStatus,
  )) {
    return TouryTripStage.completed;
  }

  final code = BookingStatusLocalizer.resolveCode(
    statusCode: statusCode,
    halhText: halhText,
  );

  switch (code) {
    case TouryBookingStatusCodes.tripInProgress:
      return TouryTripStage.started;
    case TouryBookingStatusCodes.driverArrived:
      return TouryTripStage.arrived;
    case TouryBookingStatusCodes.driverAssigned:
      return TouryTripStage.enRoute;
    default:
      return TouryTripStage.searching;
  }
}

/// Zero-based index inside [touryTripTimeline]; -1 when not applicable.
int touryTripStageIndex(TouryTripStage stage) =>
    touryTripTimeline.indexOf(stage);

/// Localization key for the headline shown above the map.
String touryTripStageTitleKey(TouryTripStage stage) {
  switch (stage) {
    case TouryTripStage.searching:
      return 'track_stage_searching';
    case TouryTripStage.enRoute:
      return 'track_stage_en_route';
    case TouryTripStage.arrived:
      return 'track_stage_arrived';
    case TouryTripStage.started:
      return 'track_stage_started';
    case TouryTripStage.completed:
      return 'track_stage_completed';
  }
}

/// True while the driver marker/ETA are meaningful on the map.
bool touryTripStageIsLive(TouryTripStage stage) =>
    stage == TouryTripStage.enRoute ||
    stage == TouryTripStage.arrived ||
    stage == TouryTripStage.started;

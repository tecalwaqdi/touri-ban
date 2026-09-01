/// Central TTL / freshness policy for admin ops data (Phase 4).
///
/// Do not hard-code durations inside widgets — import from here.
abstract final class AdminCachePolicy {
  AdminCachePolicy._();

  /// Active bookings / open support — prefer fresher numbers.
  static const Duration realtimeTtl = Duration(seconds: 45);

  /// Users, drivers totals, landmarks, bookings lifecycle aggregates.
  static const Duration nearRealtimeTtl = Duration(minutes: 2);

  /// Countries, regions, cities, master geo.
  static const Duration onDemandTtl = Duration(minutes: 15);

  /// Default dashboard bundle (mixed metrics).
  static const Duration dashboardBundleTtl = nearRealtimeTtl;

  /// Debounce for order snapshot → invalidate.
  static const Duration liveInvalidateDebounce = Duration(milliseconds: 1200);

  /// Max docs scanned when listing unknown-activation drivers.
  static const int unknownDriverScanCap = 800;
}

/// Classification for ops surfaces (documentation + coordinator).
enum AdminDataFreshness {
  realtime,
  nearRealtime,
  onDemand,
}

abstract final class AdminDataClassification {
  AdminDataClassification._();

  static const Map<String, AdminDataFreshness> byKey = {
    'activeBookings': AdminDataFreshness.realtime,
    'supportOpenTickets': AdminDataFreshness.realtime,
    'bookingsTotal': AdminDataFreshness.nearRealtime,
    'bookingsCompleted': AdminDataFreshness.nearRealtime,
    'bookingsCancelled': AdminDataFreshness.nearRealtime,
    'bookingsExpired': AdminDataFreshness.nearRealtime,
    'appUsers': AdminDataFreshness.nearRealtime,
    'representatives': AdminDataFreshness.nearRealtime,
    'driversActive': AdminDataFreshness.nearRealtime,
    'driversInactive': AdminDataFreshness.nearRealtime,
    'driversUnknown': AdminDataFreshness.nearRealtime,
    'attractions': AdminDataFreshness.nearRealtime,
    'partners': AdminDataFreshness.nearRealtime,
    'agents': AdminDataFreshness.nearRealtime,
    'tourGuides': AdminDataFreshness.nearRealtime,
    'transportCompanies': AdminDataFreshness.nearRealtime,
    'supportTickets': AdminDataFreshness.nearRealtime,
    'countries': AdminDataFreshness.onDemand,
    'regions': AdminDataFreshness.onDemand,
    'cities': AdminDataFreshness.onDemand,
  };
}

/// Accounting date policy for Admin presets.
///
/// Finance Hub / Profits / Finance Reports / Ops date chips all use
/// **Asia/Riyadh** (UTC+03, no DST) via [AdminFinanceDateRangeResolver].
/// Booking financial country SoT remains `order.Rev_dolh` (not driver/customer).
abstract final class AdminTimezonePolicy {
  AdminTimezonePolicy._();

  static const String policyId = 'ASIA_RIYADH_ACCOUNTING';
  static const String note =
      'Date presets use Asia/Riyadh calendar days (UTC+03, no DST).';
}

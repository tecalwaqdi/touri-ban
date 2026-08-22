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

/// Timezone policy (Phase 3.1) — no country.timezone field in schema today.
///
/// TIMEZONE_POLICY:
/// - countries collection has: naim, iso_code, currency_*, bounds, vat/commission
///   rates — **no timezone / utc_offset field**.
/// - Do **not** invent TZ from country name.
/// - **SuperAdmin (global date presets):** use **UTC** calendar day for
///   Today/Yesterday/Month until a trusted per-country TZ exists.
/// - **Country Agent:** same as SuperAdmin for now (UTC), ready to switch to
///   `countries.timezone` when added and verified.
/// - **Custom range:** calendar dates chosen in the picker are interpreted as
///   whole UTC days (start inclusive / end exclusive next day).
/// - Display timestamps in the admin UI may still follow device locale.
abstract final class AdminTimezonePolicy {
  AdminTimezonePolicy._();

  static const String policyId = 'UTC_UNTIL_COUNTRY_TZ';
  static const String note =
      'No countries.timezone in Firestore SoT — date presets use UTC days.';
}

/// Stable ids for dashboard KPI reliability tracking.
abstract final class DashboardMetricKeys {
  DashboardMetricKeys._();

  static const attractions = 'attractions';
  static const partners = 'partners';
  static const countries = 'countries';
  static const regions = 'regions';
  static const cities = 'cities';
  static const agents = 'agents';
  static const representatives = 'representatives';
  static const appUsers = 'appUsers';
  static const transportCompanies = 'transportCompanies';
  static const activeBookings = 'activeBookings';
  static const supportTickets = 'supportTickets';
  static const driversActive = 'driversActive';
  static const driversInactive = 'driversInactive';
  static const driversUnknown = 'driversUnknown';
  static const tourGuides = 'tourGuides';
  static const bookingsTotal = 'bookingsTotal';
  static const bookingsCompleted = 'bookingsCompleted';
  static const bookingsCancelled = 'bookingsCancelled';
  static const bookingsExpired = 'bookingsExpired';
  static const supportOpenTickets = 'supportOpenTickets';

  static const all = {
    attractions,
    partners,
    countries,
    regions,
    cities,
    agents,
    representatives,
    appUsers,
    transportCompanies,
    activeBookings,
    supportTickets,
    driversActive,
    driversInactive,
    driversUnknown,
    tourGuides,
    bookingsTotal,
    bookingsCompleted,
    bookingsCancelled,
    bookingsExpired,
    supportOpenTickets,
  };
}

/// Per-metric load outcome for dashboard aggregates.
class DashboardMetricResult {
  const DashboardMetricResult({
    required this.value,
    required this.reliable,
  });

  final int value;
  final bool reliable;

  static DashboardMetricResult fromRaw(int raw) => DashboardMetricResult(
        value: raw < 0 ? 0 : raw,
        reliable: raw >= 0,
      );
}

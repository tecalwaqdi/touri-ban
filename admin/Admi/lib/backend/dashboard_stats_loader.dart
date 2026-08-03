
import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_landmark_count.dart';
import '/backend/admin_panel_data_bootstrap.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_partner_orders.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';
import '/backend/admin_performance.dart';
import '/backend/schema/enums/enums.dart';

/// Aggregated dashboard metrics aligned with admin list pages.
class DashboardStats {
  const DashboardStats({
    required this.attractions,
    required this.partners,
    required this.countries,
    required this.regions,
    required this.cities,
    required this.appUsers,
    required this.agents,
    required this.representatives,
    required this.transportCompanies,
    required this.activeBookings,
    required this.supportTickets,
    required this.loadedAt,
    this.loadComplete = true,
  });

  final int attractions;
  final int partners;
  final int countries;
  final int regions;
  final int cities;
  final int appUsers;
  final int agents;
  final int representatives;
  final int transportCompanies;
  final int activeBookings;
  final int supportTickets;
  final DateTime loadedAt;
  final bool loadComplete;

  bool get isExpired =>
      DateTime.now().difference(loadedAt) > kAdminStatsTtl;

  static DashboardStats empty() => DashboardStats(
        attractions: 0,
        partners: 0,
        countries: 0,
        regions: 0,
        cities: 0,
        appUsers: 0,
        agents: 0,
        representatives: 0,
        transportCompanies: 0,
        activeBookings: 0,
        supportTickets: 0,
        loadedAt: DateTime.now(),
        loadComplete: false,
      );

  bool get hasLoadedData => loadComplete;
}

final Map<String, DashboardStats> _dashboardStatsCacheByScope = {};
String? _activeStatsScopeKey;
Future<DashboardStats>? _statsLoadInFlight;
String? _statsLoadInFlightKey;
bool _forceServerCounts = false;
bool dashboardStatsNeedRefresh = false;

/// Set when a delete happens off-dashboard so home reloads on next open.
void markDashboardStatsStale() {
  dashboardStatsNeedRefresh = true;
}

bool consumeDashboardStatsStaleFlag() {
  if (!dashboardStatsNeedRefresh) return false;
  dashboardStatsNeedRefresh = false;
  return true;
}

/// Cancels an in-flight stats load (e.g. before delete refresh).
void cancelDashboardStatsLoadInFlight() {
  _statsLoadInFlight = null;
  _statsLoadInFlightKey = null;
}

/// Clears cached dashboard numbers (call on login / logout / role change).
void clearDashboardStatsCache() {
  _dashboardStatsCacheByScope.clear();
  _activeStatsScopeKey = null;
  _statsLoadInFlight = null;
  _statsLoadInFlightKey = null;
}

int _clampStat(int value) => value.clamp(0, 1 << 30);

/// Instant −1 (or more) on visible dashboard cards after a confirmed delete.
void patchDashboardStatsCache({
  int landmarksDelta = 0,
  int partnersDelta = 0,
  int countriesDelta = 0,
  int regionsDelta = 0,
  int citiesDelta = 0,
  int appUsersDelta = 0,
  int agentsDelta = 0,
  int representativesDelta = 0,
  int transportCompaniesDelta = 0,
  int activeBookingsDelta = 0,
  int supportTicketsDelta = 0,
}) {
  final scopeKey = dashboardStatsScopeKey();
  if (scopeKey.startsWith('none:') || scopeKey.contains(':no-country')) {
    return;
  }
  final cached = _dashboardStatsCacheByScope[scopeKey];
  if (cached == null || !cached.loadComplete) return;

  _dashboardStatsCacheByScope[scopeKey] = DashboardStats(
    attractions: _clampStat(cached.attractions + landmarksDelta),
    partners: _clampStat(cached.partners + partnersDelta),
    countries: _clampStat(cached.countries + countriesDelta),
    regions: _clampStat(cached.regions + regionsDelta),
    cities: _clampStat(cached.cities + citiesDelta),
    appUsers: _clampStat(cached.appUsers + appUsersDelta),
    agents: _clampStat(cached.agents + agentsDelta),
    representatives: _clampStat(cached.representatives + representativesDelta),
    transportCompanies:
        _clampStat(cached.transportCompanies + transportCompaniesDelta),
    activeBookings: _clampStat(cached.activeBookings + activeBookingsDelta),
    supportTickets: _clampStat(cached.supportTickets + supportTicketsDelta),
    loadedAt: DateTime.now(),
    loadComplete: true,
  );
}

/// Instant read for UI while a background refresh runs.
DashboardStats? peekDashboardStats() {
  final scopeKey = dashboardStatsScopeKey();
  if (scopeKey.startsWith('none:') || scopeKey.contains(':no-country')) {
    return null;
  }
  final cached = _dashboardStatsCacheByScope[scopeKey];
  if (cached == null || cached.isExpired) {
    return null;
  }
  if (!cached.loadComplete) {
    return cached;
  }
  return cached;
}

String dashboardStatsScopeKey() {
  final uid = currentUserUid;
  if (uid.isEmpty) return 'guest';

  final role = AdminRoleService.currentRole;
  switch (role) {
    case AdminRole.superAdmin:
      return 'super:$uid';
    case AdminRole.countryAgent:
      final country = _resolvedCountryRef()?.path ?? 'no-country';
      return 'agent:$uid:$country';
    case AdminRole.partner:
      final mkan = AdminRoleService.partnerMkanRef?.path ?? 'no-mkan';
      return 'partner:$uid:$mkan';
    case AdminRole.transportCompany:
      final company = AdminRoleService.transportCompanyRef?.path ?? 'no-co';
      return 'transport:$uid:$company';
    case AdminRole.none:
      return 'none:$uid';
  }
}

/// Loads dashboard counts scoped to the current panel user.
Future<DashboardStats> loadDashboardStats({
  bool forceRefresh = false,
  bool quickLandmarks = false,
  bool priorityOnly = false,
}) async {
  await _ensureRoleReady();
  if (AdminRoleService.hasPanelAccess) {
    await AdminPanelDataBootstrap.ensureReady();
    if (AdminRoleService.isCountryAgent) {
      AdminAgentCountryLock.applyToAppState();
    }
  }

  var scopeKey = dashboardStatsScopeKey();
  if (scopeKey.startsWith('none:')) {
    return DashboardStats.empty();
  }
  if (scopeKey.contains(':no-country') && AdminRoleService.isCountryAgent) {
    await AdminAgentCountryLock.ensureCountryResolved();
    AdminAgentCountryLock.applyToAppState();
    await AdminPanelDataBootstrap.ensureReady(force: true);
    scopeKey = dashboardStatsScopeKey();
  }
  if (scopeKey.contains(':no-country') &&
      !AdminCountryScope.isSaudiCountryAgent) {
    return DashboardStats.empty();
  }

  if (_activeStatsScopeKey != scopeKey) {
    forceRefresh = true;
    _activeStatsScopeKey = scopeKey;
  }

  if (forceRefresh) {
    _statsLoadInFlight = null;
    _statsLoadInFlightKey = null;
    _forceServerCounts = true;
  }

  final cached = _dashboardStatsCacheByScope[scopeKey];
  if (!forceRefresh &&
      cached != null &&
      !cached.isExpired &&
      cached.loadComplete) {
    return cached;
  }

  if (_statsLoadInFlight != null &&
      _statsLoadInFlightKey ==
          _loadKey(scopeKey, quickLandmarks, priorityOnly)) {
    try {
      return await _statsLoadInFlight!.timeout(const Duration(seconds: 60));
    } catch (_) {
      return cached ?? DashboardStats.empty();
    }
  }

  final useQuickLandmarks = quickLandmarks;
  final load = _fetchDashboardStats(
    quickLandmarks: useQuickLandmarks,
    priorityOnly: priorityOnly,
  )
      .timeout(
        const Duration(seconds: 60),
        onTimeout: () => cached ?? DashboardStats.empty(),
      )
      .then((stats) {
        final prior = _dashboardStatsCacheByScope[scopeKey];
        final merged = prior != null && !stats.loadComplete
            ? _mergeStats(prior, stats)
            : stats;
        _dashboardStatsCacheByScope[scopeKey] = merged;
        return merged;
      })
      .whenComplete(() {
        _forceServerCounts = false;
        if (_statsLoadInFlightKey ==
            _loadKey(scopeKey, useQuickLandmarks, priorityOnly)) {
          _statsLoadInFlight = null;
          _statsLoadInFlightKey = null;
        }
      });

  _statsLoadInFlight = load;
  _statsLoadInFlightKey = _loadKey(scopeKey, useQuickLandmarks, priorityOnly);
  return load;
}

String _loadKey(String scopeKey, bool quickLandmarks, bool priorityOnly) =>
    '$scopeKey|${quickLandmarks ? 'q' : 'f'}|${priorityOnly ? 'p' : 'a'}';

DashboardStats _mergeStats(DashboardStats prior, DashboardStats incoming) {
  if (incoming.loadComplete) return incoming;

  // Priority-only refresh (landmarks + partners for country agents).
  final isLandmarkPartial = incoming.regions == 0 &&
      incoming.cities == 0 &&
      incoming.appUsers == 0 &&
      incoming.agents == 0 &&
      incoming.representatives == 0 &&
      incoming.transportCompanies == 0 &&
      incoming.activeBookings == 0 &&
      incoming.supportTickets == 0;

  if (isLandmarkPartial) {
    return DashboardStats(
      attractions: incoming.attractions,
      partners: incoming.partners,
      countries: incoming.countries != 0 ? incoming.countries : prior.countries,
      regions: prior.regions,
      cities: prior.cities,
      appUsers: prior.appUsers,
      agents: prior.agents,
      representatives: prior.representatives,
      transportCompanies: prior.transportCompanies,
      activeBookings: prior.activeBookings,
      supportTickets: prior.supportTickets,
      loadedAt: incoming.loadedAt,
      loadComplete: false,
    );
  }

  return incoming;
}

DocumentReference? _resolvedCountryRef() {
  final fromUser = AdminRoleService.scopedCountryRef;
  if (fromUser != null) return fromUser;

  if (AdminRoleService.isCountryAgent) {
    return FFAppState().RevDolh ?? FFAppState().dolh;
  }
  return null;
}

Future<void> _ensureRoleReady() async {
  if (!loggedIn) return;
  if (AdminRoleService.currentRole != AdminRole.none) return;
  try {
    await ensureCurrentUserDocument().timeout(const Duration(seconds: 8));
  } catch (_) {}
}

Future<DashboardStats> _fetchDashboardStats({
  bool quickLandmarks = false,
  bool priorityOnly = false,
}) async {
  switch (AdminRoleService.currentRole) {
    case AdminRole.superAdmin:
      return _fetchSuperAdminStats();
    case AdminRole.countryAgent:
      return _fetchCountryAgentStats(
        quickLandmarks: quickLandmarks,
        priorityOnly: priorityOnly,
      );
    case AdminRole.partner:
      return _fetchPartnerStats();
    case AdminRole.transportCompany:
      return _fetchTransportCompanyStats();
    case AdminRole.none:
      return DashboardStats.empty();
  }
}

Future<int> _count(Future<int> Function() load) async {
  try {
    return await load().timeout(const Duration(seconds: 18));
  } catch (_) {
    return 0;
  }
}

Future<int> _recordCount(
  Query collection, {
  Query Function(Query)? queryBuilder,
}) =>
    queryCollectionCount(
      collection,
      queryBuilder: queryBuilder,
      forceServer: _forceServerCounts,
    );

Future<int> _countHeavy(Future<int> Function() load) async {
  try {
    return await load().timeout(const Duration(seconds: 18));
  } catch (_) {
    return 0;
  }
}

Future<List<T>> _parallelCounts<T>(
  List<Future<T> Function()> tasks, {
  int batchSize = 2,
}) async {
  final results = <T>[];
  for (var i = 0; i < tasks.length; i += batchSize) {
    final end = i + batchSize > tasks.length ? tasks.length : i + batchSize;
    final batch = tasks.sublist(i, end);
    results.addAll(await Future.wait(batch.map((task) => task())));
  }
  return results;
}

Future<int> _representativeCount(DocumentReference? country) async {
  if (country == null) {
    return _count(
      () => queryUserRecordCount(
        queryBuilder: (q) => q.where('ismndob', isEqualTo: true),
      ),
    );
  }

  return _count(
    () => queryUserRecordCount(
      queryBuilder: (q) => q
          .where('ismndob', isEqualTo: true)
          .where('Rev_dolh', isEqualTo: country),
    ),
  );
}

Future<int> _scopedAppUserCount(DocumentReference? country) async {
  if (country == null) {
    return queryAppUserCount();
  }

  final results = await _parallelCounts<int>([
    () => _count(
      () => queryUserRecordCount(
        queryBuilder: (q) => q.where('Rev_dolh', isEqualTo: country),
      ),
    ),
    () => _count(
      () => queryUserRecordCount(
        queryBuilder: (q) => q
            .where('Rev_dolh', isEqualTo: country)
            .where('Isagent', isEqualTo: true),
      ),
    ),
    () => _count(
      () => queryUserRecordCount(
        queryBuilder: (q) => q
            .where('Rev_dolh', isEqualTo: country)
            .where('ismndob', isEqualTo: true),
      ),
    ),
    () => _count(
      () => queryUserRecordCount(
        queryBuilder: (q) => q
            .where('Rev_dolh', isEqualTo: country)
            .where('Isagent', isEqualTo: true)
            .where('ismndob', isEqualTo: true),
      ),
    ),
  ], batchSize: 4);

  final total = results[0];
  final agents = results[1];
  final reps = results[2];
  final both = results[3];
  return (total - agents - reps + both).clamp(0, 1 << 30);
}

Future<int> _scopedSupportCount(DocumentReference? country) async {
  if (country == null) {
    return _count(() => querySupportRecordCount());
  }

  return _count(
    () => querySupportRecordCount(
      queryBuilder: (q) => q.where('Rev_dolh', isEqualTo: country),
    ),
  );
}

Future<int> _partnerBookingCount(DocumentReference partnerMkan) async {
  try {
    return await AdminPartnerOrders.countActiveBookings(partnerMkan)
        .timeout(const Duration(seconds: 15));
  } catch (_) {
    return 0;
  }
}

Future<DashboardStats> _fetchSuperAdminStats() async {
  final results = await _parallelCounts<dynamic>([
    () => _count(() => _recordCount(MkanRecord.collection)),
    () => _count(
      () => _recordCount(
        MkanRecord.collection,
        queryBuilder: (q) => q.where('isShrek', isEqualTo: true),
      ),
    ),
    () => _count(() => _recordCount(CountriesRecord.collection)),
    () => _count(() => _recordCount(CitiesRecord.collection)),
    () => _count(() => _recordCount(VillagesRecord.collection)),
    () => _count(
      () => _recordCount(
        UserRecord.collection,
        queryBuilder: (q) => q.where('Isagent', isEqualTo: true),
      ),
    ),
    () => _representativeCount(null),
    () => queryAppUserCount(forceServer: _forceServerCounts),
    () => _count(() => _recordCount(TransportCompanyRecord.collection)),
    () => _count(
      () => _recordCount(
        OrderRecord.collection,
        queryBuilder: (q) => q.where('ALLNOW', isEqualTo: true),
      ),
    ),
    () => _count(() => _recordCount(SupportRecord.collection)),
  ], batchSize: 3);

  return _buildStatsFromResults(results);
}

Future<DashboardStats> _fetchCountryAgentStats({
  bool quickLandmarks = false,
  bool priorityOnly = false,
}) async {
  final country = _resolvedCountryRef();
  final isSaudi = AdminCountryScope.isSaudiCountryAgent;
  if (country == null && !isSaudi) {
    return DashboardStats.empty();
  }

  if (isSaudi) {
    await AdminSaudiCountry.ensureQueryRefsLoaded();
  }

  final countryRefs = isSaudi
      ? AdminSaudiCountry.countryRefsForQuery()
      : (country != null ? [country] : <DocumentReference>[]);

  // Fast Firestore counts first (super-admin pattern); heavy geo merge on manual refresh only.
  final landmarkCount = quickLandmarks
      ? () => _count(() => _fastLandmarkCount(partnersOnly: false))
      : () => _countHeavy(
          () => AdminLandmarkCount.countForAgent(partnersOnly: false),
        );
  final partnerCount = quickLandmarks
      ? () => _count(() => _fastLandmarkCount(partnersOnly: true))
      : () => _countHeavy(
          () => AdminLandmarkCount.countForAgent(partnersOnly: true),
        );

  if (priorityOnly) {
    final results = await Future.wait<int>([
      landmarkCount(),
      partnerCount(),
    ]);
    return DashboardStats(
      attractions: results[0],
      partners: results[1],
      countries: countryRefs.length.clamp(1, 99),
      regions: 0,
      cities: 0,
      appUsers: 0,
      agents: 0,
      representatives: 0,
      transportCompanies: 0,
      activeBookings: 0,
      supportTickets: 0,
      loadedAt: DateTime.now(),
      loadComplete: false,
    );
  }

  final results = await _parallelCounts<dynamic>([
    landmarkCount,
    partnerCount,
    () => Future.value(countryRefs.isEmpty ? 0 : countryRefs.length),
    () => _countRegionsForAgent(countryRefs, isSaudi: isSaudi),
    () => _countCitiesForAgent(countryRefs, isSaudi: isSaudi),
    () => _countAgentsForAgent(countryRefs),
    () => _countRepresentativesForAgent(countryRefs),
    () => _countAppUsersForAgent(countryRefs),
    () => _countTransportCompaniesForAgent(countryRefs),
    () => _countActiveBookingsForAgent(countryRefs),
    () => _countSupportTicketsForAgent(countryRefs),
  ], batchSize: 3);

  return _buildStatsFromResults(results);
}

Future<int> _countRegionsForAgent(
  List<DocumentReference> countryRefs, {
  required bool isSaudi,
}) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _count(
      () => queryCitiesRecordCount(
        queryBuilder: (q) => q.where('dolh', isEqualTo: countryRefs.first),
      ),
    );
  }
  return _count(
    () => queryCitiesRecordCount(
      queryBuilder: (q) => q.where(
        'dolh',
        whereIn: countryRefs.take(30).toList(growable: false),
      ),
    ),
  );
}

Future<int> _countCitiesForAgent(
  List<DocumentReference> countryRefs, {
  required bool isSaudi,
}) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _count(
      () => queryVillagesRecordCount(
        queryBuilder: (q) => q.where('dolh', isEqualTo: countryRefs.first),
      ),
    );
  }
  return _count(
    () => queryVillagesRecordCount(
      queryBuilder: (q) => q.where(
        'dolh',
        whereIn: countryRefs.take(30).toList(growable: false),
      ),
    ),
  );
}

Future<int> _fastLandmarkCount({required bool partnersOnly}) async {
  return queryMkanRecordCount(
    queryBuilder: (collection) {
      var q = collection as Query<Map<String, dynamic>>;
      if (partnersOnly) {
        q = q.where('isShrek', isEqualTo: true);
      }
      return AdminCountryScope.applyLandmarkCountryFilter(q);
    },
  ).timeout(const Duration(seconds: 12));
}

Future<int> _countAgentsForAgent(List<DocumentReference> countryRefs) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _count(
      () => queryUserRecordCount(
        queryBuilder: (q) => q
            .where('Isagent', isEqualTo: true)
            .where('Rev_dloh_agent', isEqualTo: countryRefs.first),
      ),
    );
  }
  return _count(
    () => queryUserRecordCount(
      queryBuilder: (q) => q
          .where('Isagent', isEqualTo: true)
          .where(
            'Rev_dloh_agent',
            whereIn: countryRefs.take(30).toList(growable: false),
          ),
    ),
  );
}

Future<int> _countRepresentativesForAgent(
  List<DocumentReference> countryRefs,
) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _representativeCount(countryRefs.first);
  }
  return _count(
    () => queryUserRecordCount(
      queryBuilder: (q) => q
          .where('ismndob', isEqualTo: true)
          .where(
            'Rev_dolh',
            whereIn: countryRefs.take(30).toList(growable: false),
          ),
    ),
  );
}

Future<int> _countAppUsersForAgent(List<DocumentReference> countryRefs) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _scopedAppUserCount(countryRefs.first);
  }
  var total = 0;
  for (final ref in countryRefs) {
    total += await _scopedAppUserCount(ref);
  }
  return total;
}

Future<int> _countTransportCompaniesForAgent(
  List<DocumentReference> countryRefs,
) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _count(
      () => queryTransportCompanyRecordCount(
        queryBuilder: (q) => q.where('Rev_dolh', isEqualTo: countryRefs.first),
      ),
    );
  }
  return _count(
    () => queryTransportCompanyRecordCount(
      queryBuilder: (q) => q.where(
        'Rev_dolh',
        whereIn: countryRefs.take(30).toList(growable: false),
      ),
    ),
  );
}

Future<int> _countActiveBookingsForAgent(
  List<DocumentReference> countryRefs,
) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _count(
      () => queryOrderRecordCount(
        queryBuilder: (q) => q
            .where('ALLNOW', isEqualTo: true)
            .where('Rev_dolh', isEqualTo: countryRefs.first),
      ),
    );
  }
  return _count(
    () => queryOrderRecordCount(
      queryBuilder: (q) => q
          .where('ALLNOW', isEqualTo: true)
          .where(
            'Rev_dolh',
            whereIn: countryRefs.take(30).toList(growable: false),
          ),
    ),
  );
}

Future<int> _countSupportTicketsForAgent(
  List<DocumentReference> countryRefs,
) async {
  if (countryRefs.isEmpty) return 0;
  if (countryRefs.length == 1) {
    return _scopedSupportCount(countryRefs.first);
  }
  return _count(
    () => querySupportRecordCount(
      queryBuilder: (q) => q.where(
        'Rev_dolh',
        whereIn: countryRefs.take(30).toList(growable: false),
      ),
    ),
  );
}

Future<DashboardStats> _fetchPartnerStats() async {
  final partnerMkan = AdminRoleService.partnerMkanRef;
  if (partnerMkan == null) {
    return DashboardStats.empty();
  }

  final bookings = await _partnerBookingCount(partnerMkan);

  return DashboardStats(
    attractions: 1,
    partners: 1,
    countries: 0,
    regions: 0,
    cities: 0,
    appUsers: 0,
    agents: 0,
    representatives: 0,
    transportCompanies: 0,
    activeBookings: bookings,
    supportTickets: 0,
    loadedAt: DateTime.now(),
  );
}

Future<DashboardStats> _fetchTransportCompanyStats() async {
  final company = AdminRoleService.transportCompanyRef;
  if (company == null) {
    return DashboardStats.empty();
  }

  final drivers = await _count(
    () => queryUserRecordCount(
      queryBuilder: (q) => q
          .where('ismndob', isEqualTo: true)
          .where('transport_company', isEqualTo: company),
    ),
  );

  return DashboardStats(
    attractions: 0,
    partners: 0,
    countries: 0,
    regions: 0,
    cities: 0,
    appUsers: 0,
    agents: 0,
    representatives: drivers,
    transportCompanies: 1,
    activeBookings: 0,
    supportTickets: 0,
    loadedAt: DateTime.now(),
  );
}

DashboardStats _buildStatsFromResults(List<dynamic> results) {
  return DashboardStats(
    attractions: results[0] as int,
    partners: results[1] as int,
    countries: results[2] as int,
    regions: results[3] as int,
    cities: results[4] as int,
    agents: results[5] as int,
    representatives: results[6] as int,
    appUsers: results[7] as int,
    transportCompanies: results[8] as int,
    activeBookings: results[9] as int,
    supportTickets: results[10] as int,
    loadedAt: DateTime.now(),
  );
}

Future<int> queryAppUserCount({bool forceServer = false}) async {
  final results = await Future.wait<int>([
    _count(
      () => queryCollectionCount(
        UserRecord.collection,
        forceServer: forceServer,
      ),
    ),
    _count(
      () => queryCollectionCount(
        UserRecord.collection,
        forceServer: forceServer,
        queryBuilder: (q) => q.where('Isagent', isEqualTo: true),
      ),
    ),
    _count(
      () => queryCollectionCount(
        UserRecord.collection,
        forceServer: forceServer,
        queryBuilder: (q) => q.where('ismndob', isEqualTo: true),
      ),
    ),
    _count(
      () => queryCollectionCount(
        UserRecord.collection,
        forceServer: forceServer,
        queryBuilder: (q) => q
            .where('Isagent', isEqualTo: true)
            .where('ismndob', isEqualTo: true),
      ),
    ),
  ]);

  final total = results[0];
  final agents = results[1];
  final reps = results[2];
  final both = results[3];
  return (total - agents - reps + both).clamp(0, 1 << 30);
}

/// App users excluding agents/reps; [country] null = all countries.
Future<int> queryScopedAppUserCount(DocumentReference? country) =>
    _scopedAppUserCount(country);

int countAppUsers(List<UserRecord> users) =>
    users.where((u) => !u.isagent && !u.ismndob).length;

int countOpenSupportTickets(List<SupportRecord> tickets) => tickets
    .where(
      (t) => t.halh == null || t.halh == HalhSupport.Open,
    )
    .length;

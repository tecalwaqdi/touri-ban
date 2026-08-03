import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_reports_country_scope.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';
import '/core/country/country_resolver.dart';

/// Applies country / partner filters to Firestore queries and in-memory lists.
class AdminCountryScope {
  AdminCountryScope._();

  static DocumentReference? get activeCountryRef {
    if (AdminReportsCountryScope.isActive) {
      return AdminReportsCountryScope.countryRef;
    }

    final fromUser = AdminRoleService.scopedCountryRef;
    if (fromUser != null) return fromUser;

    if (AdminRoleService.isCountryAgent) {
      final fromState = FFAppState().RevDolh ?? FFAppState().dolh;
      if (fromState != null) return fromState;

      final user = currentUserDocument;
      if (user != null && AdminSaudiCountry.isSaudiAgent(user)) {
        final refs = AdminSaudiCountry.countryRefsForQuery();
        if (refs.isNotEmpty) return refs.first;
      }
    }
    return null;
  }

  static String get activeCountryLabel {
    if (AdminReportsCountryScope.isActive) {
      return AdminReportsCountryScope.countryLabel;
    }
    if (AdminRoleService.isCountryAgent) {
      return AdminRoleService.scopedCountryName;
    }
    return '';
  }

  static bool get hasActiveCountryScope => activeCountryRef != null;

  /// Country ref to persist on landmark create/update (agents + super admin).
  static DocumentReference? mkanCountryRefForSave() {
    return activeCountryRef ?? FFAppState().RevDolh ?? FFAppState().dolh;
  }

  static Query<Map<String, dynamic>> applyToQuery(
    Query<Map<String, dynamic>> query, {
    required String countryField,
  }) {
    final country = activeCountryRef;
    if (country == null) return query;
    return query.where(countryField, isEqualTo: country);
  }

  static bool get isSaudiCountryAgent {
    if (AdminRoleService.isCountryAgent) {
      final user = currentUserDocument;
      if (user != null && AdminSaudiCountry.isSaudiAgent(user)) return true;
      return AdminSaudiCountry.isSaudiRef(activeCountryRef);
    }
    if (AdminReportsCountryScope.isActive) {
      return AdminSaudiCountry.isSaudiRef(AdminReportsCountryScope.countryRef);
    }
    return false;
  }

  /// Filters landmark queries for country agents (canonical country ref).
  static Query<Map<String, dynamic>> applyLandmarkCountryFilter(
    Query<Map<String, dynamic>> q,
  ) {
    if (AdminRoleService.isCountryAgent || AdminReportsCountryScope.isActive) {
      final country = activeCountryRef;
      if (country != null) {
        return q.where('Rev_dolh', isEqualTo: country);
      }
    }
    return q;
  }

  static Query applyMkanQuery(Query collection) {
    var q = collection as Query<Map<String, dynamic>>;
    q = applyLandmarkCountryFilter(q);
    return q.orderBy(FieldPath.documentId);
  }

  /// Country agents only see landmarks in their country scope.
  static bool isLandmarkInAgentCountry(MkanRecord mkan) {
    if (!AdminRoleService.isCountryAgent &&
        !AdminReportsCountryScope.isActive) {
      return true;
    }

    if (isSaudiCountryAgent) {
      return AdminSaudiCountry.belongsToSaudiSync(mkan);
    }

    final country = activeCountryRef;
    if (country == null) return false;

    if (mkan.hasRevDolh() && mkan.revDolh!.path == country.path) {
      return true;
    }

    if (mkan.hasIdCit() &&
        _geoRegionPaths != null &&
        _geoRegionPaths!.contains(mkan.idCit!.path)) {
      return true;
    }

    if (mkan.hasIdVill() &&
        _geoVillagePaths != null &&
        _geoVillagePaths!.contains(mkan.idVill!.path)) {
      return true;
    }

    return false;
  }

  /// Async geo fallback for Saudi agents (landmarks missing `Rev_dolh`).
  static Future<bool> isLandmarkInAgentCountryAsync(MkanRecord mkan) async {
    if (!AdminRoleService.isCountryAgent) return true;
    if (isLandmarkInAgentCountry(mkan)) return true;
    if (!isSaudiCountryAgent) return false;
    return AdminSaudiCountry.landmarkBelongsToSaudi(mkan);
  }

  static Query applyOrderQuery(Query collection) {
    var q = collection as Query<Map<String, dynamic>>;
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q;
  }

  static Future<Query<Map<String, dynamic>>> applyOrderQueryResolved(
    Query<Map<String, dynamic>> collection,
  ) async {
    final country = activeCountryRef;
    if (country == null) return collection;
    final refs = await CountryResolver.queryRefsForPath(country);
    if (refs.isEmpty) return collection;
    return collection.where('Rev_dolh', isEqualTo: refs.first);
  }

  static Query applyRegionQuery(Query collection) {
    var q = collection as Query<Map<String, dynamic>>;
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('dolh', isEqualTo: country);
    }
    return q;
  }

  static Query applyVillageQuery(Query collection) {
    return applyRegionQuery(collection);
  }

  /// Villages list for pickers — by region when set, otherwise by agent country.
  static Query<Map<String, dynamic>> applyVillagePickerQuery(
    Query<Map<String, dynamic>> collection, {
    DocumentReference? regionRef,
    DocumentReference? countryRef,
  }) {
    var q = collection.where('acctev', isEqualTo: true);
    if (regionRef != null) {
      return q.where('cities', isEqualTo: regionRef);
    }

    final country = countryRef ?? activeCountryRef ?? FFAppState().RevDolh;
    final scopeActive = AdminRoleService.isCountryAgent ||
        AdminReportsCountryScope.isActive ||
        country != null;

    if (!scopeActive) return q;

    if (isSaudiCountryAgent) {
      final refs = <DocumentReference>[
        ...AdminSaudiCountry.countryRefsForQuery(),
      ];
      if (country != null && !refs.any((r) => r.path == country.path)) {
        refs.add(country);
      }
      if (refs.isNotEmpty) {
        return q.where(
          'dolh',
          whereIn: refs.take(30).toList(growable: false),
        );
      }
    }

    final scoped = country ?? activeCountryRef;
    if (scoped != null) {
      return q.where('dolh', isEqualTo: scoped);
    }

    return q;
  }

  static Query applyAgentUserQuery(Query collection) {
    var q = (collection as Query<Map<String, dynamic>>)
        .where('Isagent', isEqualTo: true);
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('Rev_dloh_agent', isEqualTo: country);
    }
    return q;
  }

  static Query applySuperAdminUserQuery(Query collection) {
    return (collection as Query<Map<String, dynamic>>).where(
      'isAdminRule',
      isEqualTo: AdminRoleService.ruleSuperAdmin,
    );
  }

  static Query applyAppUserQuery(Query collection) {
    var q = collection as Query<Map<String, dynamic>>;
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q.orderBy(FieldPath.documentId);
  }

  static Query applyRepresentativeQuery(Query collection) {
    var q = (collection as Query<Map<String, dynamic>>)
        .where('ismndob', isEqualTo: true);
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q.orderBy(FieldPath.documentId);
  }

  /// Representatives awaiting activation.
  ///
  /// Older registrations used `ismndom`, while the current driver flow uses
  /// `registration_status/submission_status` and `ismndob`. Requiring the
  /// legacy flag made valid new applications disappear from the review list.
  static Query applyPendingDriverActivationQuery(Query collection) {
    var q = (collection as Query<Map<String, dynamic>>)
        .where('ismndob', isEqualTo: true)
        .where('actev_mndob', isEqualTo: false);
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q.orderBy(FieldPath.documentId);
  }

  /// All users in scope (no role filter — legacy user-management screen).
  static Query applyAllUsersQuery(Query collection) =>
      applyAppUserQuery(collection);

  static Query applySupportQuery(Query collection) {
    var q = collection as Query<Map<String, dynamic>>;
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q;
  }

  static List<UserRecord> filterAppUsers(List<UserRecord> users) {
    return users.where((u) => !u.isagent && !u.ismndob).toList();
  }

  static Set<String>? _villagePathCache;
  static String? _villageCacheCountryPath;
  static Set<String>? _geoRegionPaths;
  static Set<String>? _geoVillagePaths;
  static String? _geoCacheCountryPath;

  static void clearVillageCache() {
    _villagePathCache = null;
    _villageCacheCountryPath = null;
    _geoRegionPaths = null;
    _geoVillagePaths = null;
    _geoCacheCountryPath = null;
  }

  /// Preloads region/village paths for the active country agent.
  static Future<void> ensureGeoCacheReady() async {
    if (!AdminRoleService.isCountryAgent &&
        !AdminReportsCountryScope.isActive) {
      return;
    }

    if (isSaudiCountryAgent) {
      await AdminSaudiCountry.ensureQueryRefsLoaded();
      await AdminSaudiCountry.regionPaths();
      await AdminSaudiCountry.villagePaths();
      return;
    }

    final country = activeCountryRef;
    if (country == null) return;
    if (_geoCacheCountryPath == country.path &&
        _geoRegionPaths != null &&
        _geoVillagePaths != null) {
      return;
    }

    _geoRegionPaths = await _loadRegionPathsForCountry(country);
    _geoVillagePaths = await villagePathsForCountry(country);
    _geoCacheCountryPath = country.path;
  }

  static Future<List<DocumentReference>> regionRefsForActiveCountry() async {
    if (isSaudiCountryAgent) {
      final paths = await AdminSaudiCountry.regionPaths();
      return paths
          .map((path) => FirebaseFirestore.instance.doc(path))
          .toList(growable: false);
    }

    await ensureGeoCacheReady();
    return (_geoRegionPaths ?? const <String>{})
        .map((path) => FirebaseFirestore.instance.doc(path))
        .toList(growable: false);
  }

  static Future<List<DocumentReference>> villageRefsForActiveCountry() async {
    if (isSaudiCountryAgent) {
      final paths = await AdminSaudiCountry.villagePaths();
      return paths
          .map((path) => FirebaseFirestore.instance.doc(path))
          .toList(growable: false);
    }

    await ensureGeoCacheReady();
    return (_geoVillagePaths ?? const <String>{})
        .map((path) => FirebaseFirestore.instance.doc(path))
        .toList(growable: false);
  }

  static Future<Set<String>> _loadRegionPathsForCountry(
    DocumentReference country,
  ) async {
    final paths = <String>{};
    DocumentSnapshot? last;

    while (true) {
      final batch = await queryCitiesRecordOnce(
        queryBuilder: (q) {
          var query = q.where('dolh', isEqualTo: country);
          if (last != null) query = query.startAfterDocument(last);
          return query;
        },
        limit: 200,
      );
      if (batch.isEmpty) break;
      paths.addAll(batch.map((r) => r.reference.path));
      last = await batch.last.reference.get();
      if (batch.length < 200) break;
    }

    return paths;
  }

  /// Village document paths inside the active country (for rep filtering).
  static Future<Set<String>> villagePathsInCountry() async {
    final country = activeCountryRef;
    if (country == null) {
      return const {};
    }
    return villagePathsForCountry(country);
  }

  /// Village paths for an explicit country (stats loader — no role side-effects).
  static Future<Set<String>> villagePathsForCountry(
    DocumentReference country,
  ) async {
    if (_villageCacheCountryPath == country.path && _villagePathCache != null) {
      return _villagePathCache!;
    }

    const pageSize = 500;
    final paths = <String>{};
    DocumentSnapshot? last;

    while (true) {
      final villages = await queryVillagesRecordOnce(
        queryBuilder: (q) {
          var query =
              q.where('dolh', isEqualTo: country).orderBy(FieldPath.documentId);
          if (last != null) {
            query = query.startAfterDocument(last);
          }
          return query;
        },
        limit: pageSize,
      );
      if (villages.isEmpty) break;
      paths.addAll(villages.map((v) => v.reference.path));
      last = await villages.last.reference.get();
      if (villages.length < pageSize) break;
    }

    _villagePathCache = paths;
    _villageCacheCountryPath = country.path;
    return _villagePathCache!;
  }

  static Query applyTransportCompanyQuery(Query collection) {
    var q = collection as Query<Map<String, dynamic>>;
    final country = activeCountryRef;
    if (country != null) {
      q = q.where('Rev_dolh', isEqualTo: country);
    }
    return q;
  }

  static List<UserRecord> filterRepresentatives(
    List<UserRecord> reps,
    Set<String> villagePaths, {
    DocumentReference? country,
  }) {
    final scopedCountry = country ?? activeCountryRef;
    if (scopedCountry == null) return reps;
    if (villagePaths.isEmpty) return const [];

    return reps
        .where(
          (u) =>
              u.mndobVill != null && villagePaths.contains(u.mndobVill!.path),
        )
        .toList();
  }

  static List<MkanRecord> filterLandmarks(List<MkanRecord> items) {
    if (!AdminRoleService.isCountryAgent &&
        !AdminReportsCountryScope.isActive) {
      return items;
    }
    return items.where(isLandmarkInAgentCountry).toList();
  }

  static List<OrderRecord> filterOrders(List<OrderRecord> items) {
    final country = activeCountryRef;
    if (country != null) {
      return items.where((o) {
        if (o.revDolh?.path == country.path) return true;
        return AdminSaudiCountry.sameCountryScope(o.revDolh, country);
      }).toList();
    }

    final partnerMkan = AdminRoleService.partnerMkanRef;
    if (partnerMkan != null) {
      return items.where((o) => orderIncludesMkan(o, partnerMkan)).toList();
    }

    return items;
  }

  static bool orderIncludesMkan(OrderRecord order, DocumentReference mkanRef) {
    for (final ref in order.partnerMkans) {
      if (ref.path == mkanRef.path) return true;
    }
    for (final item in order.listAmakn) {
      for (final ref in item.mkanRev) {
        if (ref.path == mkanRef.path) return true;
      }
    }
    return false;
  }

  static List<UserRecord> filterUsers(List<UserRecord> users) {
    return filterAppUsers(users);
  }
}

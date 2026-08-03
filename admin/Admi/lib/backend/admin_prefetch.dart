
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_landmark_search.dart';
import '/backend/admin_performance.dart';
import '/backend/admin_partner_orders.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';

/// Warms Firestore local cache after login — scoped per role.
class AdminPrefetch {
  AdminPrefetch._();

  static bool _listenerAttached = false;
  static String? _warmedForUid;

  /// Clears dedup so post-login warmup can run after [completePanelSignIn].
  static void resetForLogin() {
    _warmedForUid = null;
  }

  /// Warms first list page only (stats warmed by [AdminPanelSession]).
  static Future<void> warmAfterLogin() async {
    if (!loggedIn || !AdminRoleService.hasPanelAccess) return;
    _warmedForUid = currentUserUid;
    await _warmListCache();
  }

  /// Non-blocking: prefetch after auth when user profile is available.
  static void warmCache() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    authenticatedUserStream.listen((user) {
      if (user == null) {
        _warmedForUid = null;
        return;
      }
      if (_warmedForUid == user.uid) return;
      if (!AdminRoleService.hasPanelAccess) return;

      _warmedForUid = user.uid;
      Future<void>(() async {
        try {
          await _warmListCache();
        } catch (_) {}
      });
    });
  }

  /// First paginated list page — cache-first for instant screens.
  static Future<void> _warmListCache() async {
    final tasks = <Future<void>>[];

    if (AdminRoleService.isSuperAdmin || AdminRoleService.isCountryAgent) {
      tasks.add(_prefetchLandmarksScoped());
    }
    if (AdminRoleService.isCountryAgent) {
      tasks.add(_prefetchRepresentatives());
    }
    if (AdminRoleService.isPartner) {
      tasks.add(_prefetchPartnerBookings());
    }
    if (AdminRoleService.isTransportCompany) {
      tasks.add(_prefetchCompanyDrivers());
    }

    if (tasks.isEmpty) return;

    // Parallel cache warm — same pattern as super-admin dashboard counts.
    await Future.wait(tasks);
  }

  static Future<void> _prefetchLandmarksScoped() async {
    if (AdminCountryScope.isSaudiCountryAgent) {
      await AdminSaudiCountry.ensureQueryRefsLoaded();
    }
    final items = await queryListCacheFirst(
      MkanRecord.collection,
      MkanRecord.fromSnapshot,
      queryBuilder: (q) => AdminCountryScope.applyMkanQuery(q),
      limit: kAdminPageSize,
    );
    AdminLandmarkIndex.ingest(items);
  }

  static Future<void> _prefetchRepresentatives() => queryListCacheFirst(
        UserRecord.collection,
        UserRecord.fromSnapshot,
        queryBuilder: (q) => AdminCountryScope.applyRepresentativeQuery(q),
        limit: kAdminPageSize,
      ).then((_) {});

  static Future<void> _prefetchPartnerBookings() {
    final mkan = AdminRoleService.partnerMkanRef;
    if (mkan == null) return Future.value();
    return queryListCacheFirst(
      OrderRecord.collection,
      OrderRecord.fromSnapshot,
      queryBuilder: (q) => AdminPartnerOrders.applyPartnerOrderQuery(q, mkan),
      limit: kAdminPageSize,
    ).then((_) {});
  }

  static Future<void> _prefetchCompanyDrivers() {
    final company = AdminRoleService.transportCompanyRef;
    if (company == null) return Future.value();
    return queryListCacheFirst(
      UserRecord.collection,
      UserRecord.fromSnapshot,
      queryBuilder: (q) => q
          .where('ismndob', isEqualTo: true)
          .where('transport_company', isEqualTo: company)
          .orderBy(FieldPath.documentId),
      limit: kAdminPageSize,
    ).then((_) {});
  }
}

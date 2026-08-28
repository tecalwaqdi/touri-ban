import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/admin_country_scope.dart';
import '/backend/admin_reports_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';

/// Aligns ops list/aggregate queries with dashboard country scoping.
///
/// Saudi agents may have drivers/users/orders spread across canonical + legacy
/// country document refs (`saudi_arabia`, `demo_saudi`). Dashboard counts use
/// `whereIn`; lists must match.
abstract final class AdminOpsCountryScope {
  AdminOpsCountryScope._();

  static Query applyCountryFieldFilter(
    Query query, {
    required String field,
    DocumentReference? explicitCountry,
  }) {
    if (AdminCountryScope.isSaudiCountryAgent ||
        (AdminReportsCountryScope.isActive &&
            AdminSaudiCountry.isSaudiRef(AdminReportsCountryScope.countryRef))) {
      final refs = AdminSaudiCountry.countryRefsForQuery();
      if (refs.isEmpty) return query;
      if (refs.length == 1) {
        return query.where(field, isEqualTo: refs.first);
      }
      return query.where(
        field,
        whereIn: refs.take(30).toList(growable: false),
      );
    }

    final country = explicitCountry ??
        (AdminRoleService.isCountryAgent || AdminReportsCountryScope.isActive
            ? (AdminReportsCountryScope.isActive
                ? AdminReportsCountryScope.countryRef
                : AdminRoleService.scopedCountryRef)
            : null);

    if (country != null) {
      return query.where(field, isEqualTo: country);
    }
    return query;
  }

  /// Country refs for manual multi-query counts (non-Saudi agents: single ref).
  static List<DocumentReference> countryRefsForCounts({
    DocumentReference? explicitCountry,
  }) {
    if (AdminCountryScope.isSaudiCountryAgent) {
      return AdminSaudiCountry.countryRefsForQuery();
    }
    final country = explicitCountry ??
        (AdminRoleService.isCountryAgent
            ? AdminRoleService.scopedCountryRef
            : null);
    if (country != null) return [country];
    return const [];
  }
}

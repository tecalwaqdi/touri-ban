import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';

/// Document-level access checks (route guard alone is not enough).
class AdminResourceGuard {
  AdminResourceGuard._();

  static bool canViewOrder(OrderRecord order) {
    switch (AdminRoleService.currentRole) {
      case AdminRole.superAdmin:
        return true;
      case AdminRole.countryAgent:
        final country = AdminCountryScope.activeCountryRef;
        if (country == null) return false;
        if (order.revDolh?.path == country.path) return true;
        return AdminSaudiCountry.sameCountryScope(order.revDolh, country);
      case AdminRole.partner:
        final mkan = AdminRoleService.partnerMkanRef;
        if (mkan == null) return false;
        return AdminCountryScope.orderIncludesMkan(order, mkan);
      case AdminRole.transportCompany:
        return false;
      case AdminRole.none:
        return false;
    }
  }

  /// Full access check including transport-company driver ownership.
  static Future<bool> canViewOrderAsync(OrderRecord order) async {
    if (AdminRoleService.currentRole != AdminRole.transportCompany) {
      return canViewOrder(order);
    }

    final company = AdminRoleService.transportCompanyRef;
    if (company == null || !order.hasMndobUser()) return false;

    try {
      final driver = await UserRecord.getDocumentOnce(order.mndobUser!);
      return driver.hasTransportCompany() &&
          driver.transportCompany!.path == company.path;
    } catch (_) {
      return false;
    }
  }

  static bool canEditMkan(MkanRecord record) {
    if (AdminRoleService.isSuperAdmin) return true;
    if (!AdminRoleService.isCountryAgent) return false;
    return AdminCountryScope.isLandmarkInAgentCountry(record);
  }

  static Future<bool> canEditDriver(UserRecord user) async {
    if (AdminRoleService.isSuperAdmin) return true;

    if (AdminRoleService.isTransportCompany) {
      final company = AdminRoleService.transportCompanyRef;
      return company != null &&
          user.hasTransportCompany() &&
          user.transportCompany!.path == company.path;
    }

    if (AdminRoleService.isCountryAgent) {
      final country = AdminCountryScope.activeCountryRef;
      if (country == null || user.mndobVill == null) return false;
      final villages = await AdminCountryScope.villagePathsInCountry();
      return villages.contains(user.mndobVill!.path);
    }

    return false;
  }

  static bool canEditTransportCompany(TransportCompanyRecord company) {
    if (AdminRoleService.isSuperAdmin) return true;
    if (!AdminRoleService.isCountryAgent) return false;
    final country = AdminCountryScope.activeCountryRef;
    if (country == null) return false;
    return company.revDolh?.path == country.path;
  }
}

import '/auth/firebase_auth/auth_util.dart';

import '/backend/admin_role_service.dart';

import '/index.dart';



/// Returns a redirect path when the signed-in user may not access [routeName].

String? adminRouteRedirect(String? routeName) {

  if (routeName == null || routeName.isEmpty) {
    return null;
  }

  if (routeName == '_initialize') {
    if (loggedIn &&
        currentUserDocument != null &&
        AdminRoleService.hasPanelAccess) {
      return homePathForCurrentUser();
    }
    return null;
  }



  const publicRoutes = {

    'HomePage',

  };

  if (publicRoutes.contains(routeName)) {
    // After sign-in the router may still be on the login route until a redirect
    // runs — send panel users to their home dashboard.
    if (routeName == 'HomePage' &&
        loggedIn &&
        currentUserDocument != null &&
        AdminRoleService.hasPanelAccess) {
      return homePathForCurrentUser();
    }
    return null;
  }



  // Block public super-admin registration (route name is lowercase in nav).

  if (routeName == 'adminRegesr') {

    return HomePageWidget.routePath;

  }



  if (!loggedIn) {

    return null;

  }



  // Profile may still be loading from Firestore — do not bounce to login.
  if (currentUserDocument == null) {

    return null;

  }



  if (!AdminRoleService.hasPanelAccess) {

    return HomePageWidget.routePath;

  }



  if (!AdminRoleService.canAccessRoute(routeName)) {

    return _homePathFor(AdminRoleService.currentRole);

  }



  return null;

}



String _homePathFor(AdminRole role) {

  switch (role) {

    case AdminRole.partner:

      return PartnerBookingsWidget.routePath;

    case AdminRole.transportCompany:

      return CompanyDriversWidget.routePath;

    case AdminRole.countryAgent:

    case AdminRole.superAdmin:

      return Home22DashboardWidget.routePath;

    case AdminRole.none:

      return HomePageWidget.routePath;

  }

}



String homePathForCurrentUser() =>

    _homePathFor(AdminRoleService.currentRole);


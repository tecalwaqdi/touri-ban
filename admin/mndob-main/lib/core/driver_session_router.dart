import '/core/driver_account_state_resolver.dart';

/// Maps [DriverLifecycle] → GoRouter named routes / AuthGate destinations.
abstract final class DriverSessionRouter {
  DriverSessionRouter._();

  static const String loginRoute = 'Login1';
  static const String homeRoute = 'home';
  static const String pendingRoute = 'DriverPendingApproval';
  static const String registerRoute = 'regdrever';
  static const String tripRoute = 'TfaselOrser';
  static const String acceptedRoute = 'Accepted';

  static String namedRouteForLifecycle(DriverLifecycle life) {
    switch (life) {
      case DriverLifecycle.loggedOut:
      case DriverLifecycle.loading:
        return loginRoute;
      case DriverLifecycle.incompleteProfile:
        return registerRoute;
      case DriverLifecycle.pendingApproval:
      case DriverLifecycle.changesRequested:
      case DriverLifecycle.rejected:
      case DriverLifecycle.suspended:
        return pendingRoute;
      case DriverLifecycle.onTrip:
        return acceptedRoute;
      case DriverLifecycle.activeOffline:
      case DriverLifecycle.activeOnline:
        return homeRoute;
    }
  }

  static bool opensRegistration(DriverLifecycle life) =>
      life == DriverLifecycle.incompleteProfile;

  static bool opensPendingShell(DriverLifecycle life) =>
      life == DriverLifecycle.pendingApproval ||
      life == DriverLifecycle.changesRequested ||
      life == DriverLifecycle.rejected ||
      life == DriverLifecycle.suspended;

  static bool opensHomeShell(DriverLifecycle life) =>
      life == DriverLifecycle.activeOffline ||
      life == DriverLifecycle.activeOnline ||
      life == DriverLifecycle.onTrip;
}

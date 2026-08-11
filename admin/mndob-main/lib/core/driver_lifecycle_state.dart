import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_account_state_resolver.dart';
import '/core/driver_trip_constants.dart';
import '/core/toury_system_status_codes.dart';
import '/flutter_flow/flutter_flow_util.dart';

export '/core/driver_account_state_resolver.dart'
    show DriverLifecycle, DriverAccountStateResolver;

/// Facade kept for existing imports — delegates to [DriverAccountStateResolver].
abstract final class DriverLifecycleState {
  DriverLifecycleState._();

  static DriverLifecycle resolve({
    bool? hasActiveTrip,
    UserRecord? document,
  }) {
    final authUser = currentUser;
    if (authUser == null || !loggedIn) {
      return DriverLifecycle.loggedOut;
    }

    final doc = document ?? currentUserDocument;
    if (doc == null) {
      // Auth present, doc not loaded yet — bootstrap distinguishes missing doc.
      return DriverLifecycle.loading;
    }

    return DriverAccountStateResolver.resolve(
      hasAuthUser: true,
      isAnonymous: false,
      driverDocumentExists: true,
      doc: doc,
      hasActiveTrip: hasActiveTrip ?? (FFAppState().revOrder != null),
    );
  }

  static DriverLifecycle resolveFromDocument(
    UserRecord doc, {
    bool? hasActiveTrip,
  }) =>
      DriverAccountStateResolver.resolveFromDocument(
        doc,
        hasActiveTrip: hasActiveTrip ?? (FFAppState().revOrder != null),
      );

  static bool canGoOnline(DriverLifecycle state) =>
      state == DriverLifecycle.activeOffline;

  static bool canGoOffline(DriverLifecycle state) =>
      state == DriverLifecycle.activeOnline;

  static bool canReceiveOrders(DriverLifecycle state) =>
      state == DriverLifecycle.activeOnline;

  static bool canOpenOrderIntake(DriverLifecycle state) =>
      state == DriverLifecycle.activeOnline ||
      state == DriverLifecycle.activeOffline ||
      state == DriverLifecycle.onTrip;
}

/// UI action matrix for an assigned order (status_code first, Arabic fallback).
abstract final class DriverTripActionGates {
  DriverTripActionGates._();

  static String codeOf(Map<String, dynamic> snapshot, String halhText) {
    final code = (snapshot['status_code'] ?? '').toString().trim();
    if (code.isNotEmpty) return code;
    return TourySystemStatusCodes.fromHalhText(halhText) ?? '';
  }

  static bool isAssignedToCurrentDriver(DocumentReference? mndobUser) =>
      mndobUser?.path == currentUserReference?.path;

  static bool canCancel(String statusCode, String halhText) {
    final c = statusCode.trim().toLowerCase();
    if (c == TourySystemStatusCodes.driverAssigned ||
        c == TourySystemStatusCodes.driverArriving ||
        c == TourySystemStatusCodes.driverArrived ||
        c == TourySystemStatusCodes.tripStarted ||
        c == TourySystemStatusCodes.tripInProgress) {
      return true;
    }
    return DriverTripHalh.isActiveTrip(halhText);
  }

  static bool canStart(String statusCode, String halhText) {
    final c = statusCode.trim().toLowerCase();
    // Require arrive first — do not allow start from assigned/arriving.
    if (c == TourySystemStatusCodes.driverArrived) {
      return true;
    }
    return halhText == DriverTripHalh.driverArrived;
  }

  static bool canCompleteByStatus(String statusCode, String halhText) {
    final c = statusCode.trim().toLowerCase();
    if (c == TourySystemStatusCodes.tripInProgress ||
        c == TourySystemStatusCodes.tripStarted) {
      return true;
    }
    return halhText == DriverTripHalh.inProgress;
  }

  static bool isActiveListItem(String statusCode, String halhText) {
    final c = statusCode.trim().toLowerCase();
    if (c == TourySystemStatusCodes.driverAssigned ||
        c == TourySystemStatusCodes.driverArriving ||
        c == TourySystemStatusCodes.driverArrived ||
        c == TourySystemStatusCodes.tripStarted ||
        c == TourySystemStatusCodes.tripInProgress) {
      return true;
    }
    return DriverTripHalh.isActiveTrip(halhText);
  }

  static bool isCompletedListItem(String statusCode, String halhText) {
    final c = statusCode.trim().toLowerCase();
    if (c == TourySystemStatusCodes.completed ||
        c == TourySystemStatusCodes.legacyTripCompleted) {
      return true;
    }
    return DriverTripHalh.isCompleted(halhText);
  }

  static bool isCancelledListItem(String statusCode, String halhText) {
    final c = statusCode.trim().toLowerCase();
    if (c == TourySystemStatusCodes.cancelledByDriver ||
        c == TourySystemStatusCodes.cancelledByCustomer ||
        c == TourySystemStatusCodes.cancelledByAdmin ||
        c == TourySystemStatusCodes.legacyCancelled ||
        c == TourySystemStatusCodes.legacyCanceled) {
      return true;
    }
    return halhText == DriverTripHalh.cancelled;
  }
}

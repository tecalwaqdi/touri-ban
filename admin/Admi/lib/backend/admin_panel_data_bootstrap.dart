import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_agent_session_ready.dart';
import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_country_scope.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';
import 'dart:async';

/// Prepares scoped data for any panel role before paginated list loads.
class AdminPanelDataBootstrap {
  AdminPanelDataBootstrap._();

  static Future<void>? _inFlight;
  static String? _readyForUid;
  static DocumentReference? _partnerCountryRef;
  static int _generation = 0;

  static bool get isReady =>
      _readyForUid != null && _readyForUid == currentUserUid;

  /// Country agent has a resolvable country (or Saudi catalog refs).
  static bool get isAgentScopeReady {
    if (!AdminRoleService.isCountryAgent) return true;
    if (AdminCountryScope.isSaudiCountryAgent) {
      return AdminSaudiCountry.countryRefsForQuery().isNotEmpty;
    }
    return AdminCountryScope.activeCountryRef != null;
  }

  /// Country ref from partner's linked landmark (after bootstrap).
  static DocumentReference? get partnerCountryRef => _partnerCountryRef;

  static void reset() {
    _generation++;
    _inFlight = null;
    _readyForUid = null;
    _partnerCountryRef = null;
  }

  static Future<void> ensureReady({bool force = false}) async {
    if (!AdminRoleService.hasPanelAccess) return;

    final uid = currentUserUid;
    if (uid.isEmpty) return;

    if (!force && isReady) {
      if (!AdminRoleService.isCountryAgent || isAgentScopeReady) {
        return;
      }
    }

    if (!force && _inFlight != null) {
      await _inFlight;
      return;
    }

    _inFlight = _bootstrap(uid, force: force);
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
    }
  }

  static Future<void> _bootstrap(String uid, {required bool force}) async {
    final generation = _generation;
    await ensureCurrentUserDocument(forceRefresh: force);

    switch (AdminRoleService.currentRole) {
      case AdminRole.countryAgent:
        await AdminAgentCountryLock.ensureCountryResolved();
        await AdminSaudiCountry.ensureQueryRefsLoaded();
        AdminAgentCountryLock.applyToAppState();
        if (!isAgentScopeReady) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          await AdminAgentCountryLock.ensureCountryResolved();
          AdminAgentCountryLock.applyToAppState();
        }
        // Geo paths load in background — do not block first screen like super admin.
        unawaited(AdminCountryScope.ensureGeoCacheReady());
        break;
      case AdminRole.partner:
        final partnerMkan = AdminRoleService.partnerMkanRef;
        if (partnerMkan != null) {
          try {
            final mkan = await MkanRecord.getDocumentOnce(partnerMkan);
            _partnerCountryRef = mkan.revDolh;
          } catch (_) {
            _partnerCountryRef = null;
          }
        } else {
          _partnerCountryRef = null;
        }
        break;
      case AdminRole.transportCompany:
        AdminAgentCountryLock.applyToAppState();
        break;
      case AdminRole.superAdmin:
        break;
      case AdminRole.none:
        return;
    }

    if (generation != _generation) return;

    if (AdminRoleService.isCountryAgent && !isAgentScopeReady) {
      return;
    }

    _readyForUid = uid;

    if (AdminRoleService.isCountryAgent) {
      AdminAgentSessionReady.notify();
    }
  }
}

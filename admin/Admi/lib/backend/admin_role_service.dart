import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/schema/user_record.dart';
import '/core/auth/auth_claims.dart';
import '/flutter_flow/internationalization.dart';
/// Panel roles derived from Firebase Auth custom claims (with Firestore bootstrap).
enum AdminRole {
  superAdmin,
  countryAgent,
  partner,
  transportCompany,
  none,
}

class AdminRoleService {
  AdminRoleService._();

  static AuthClaims _claims = AuthClaims.fromToken(null);
  static UserRecord? _boundProfile;

  static void bindProfile(UserRecord? user) {
    _boundProfile = user;
  }

  static const int ruleSuperAdmin = 1;
  static const int ruleCountryAgent = 2;
  static const int rulePartner = 3;
  static const int ruleTransportCompany = 4;

  /// Legacy shim for callers comparing an already-loaded profile.
  static AdminRole roleFrom(UserRecord? user) => _roleFromUserDoc(user);

  static String roleLabel(AdminRole role) => role.name;

  static Future<void> refreshClaims({bool forceRefresh = false}) async {
    _claims = await AuthClaims.current(forceRefresh: forceRefresh);
  }

  static void bindClaims(AuthClaims claims) {
    _claims = claims;
  }

  static AdminRole get currentRole {
    if (_claims.isSuperAdmin) return AdminRole.superAdmin;
    if (_claims.isCountryAdmin || _claims.isAgent || _claims.isSupport) {
      return AdminRole.countryAgent;
    }
    if (_claims.isPartner) return AdminRole.partner;
    if (_claims.isTransportManager) return AdminRole.transportCompany;
    if (_claims.isFinance) return AdminRole.countryAgent;

    // Bootstrap: claims may be stale until Cloud Function sync runs.
    return _roleFromUserDoc(_boundProfile);
  }

  static AdminRole _roleFromUserDoc(UserRecord? user) {
    if (user == null) return AdminRole.none;
    if (user.isAdmin || user.isAdminRule == ruleSuperAdmin) {
      return AdminRole.superAdmin;
    }
    if (user.isAdminRule == ruleCountryAgent || user.isagent) {
      return AdminRole.countryAgent;
    }
    if (user.isAdminRule == rulePartner || user.isPartner) {
      return AdminRole.partner;
    }
    if (user.isAdminRule == ruleTransportCompany) {
      return AdminRole.transportCompany;
    }
    return AdminRole.none;
  }

  static bool get hasPanelAccess =>
      _claims.hasPanelAccess ||
      _roleFromUserDoc(_boundProfile) != AdminRole.none;

  static bool get isSuperAdmin =>
      _claims.isSuperAdmin ||
      _roleFromUserDoc(_boundProfile) == AdminRole.superAdmin;

  /// Firestore user doc check (editing/viewing another account).
  static bool isSuperAdminUser(UserRecord? user) {
    if (user == null) return false;
    return user.isAdmin || user.isAdminRule == ruleSuperAdmin;
  }

  static bool get isCountryAgent =>
      _claims.isCountryAdmin ||
      _claims.isAgent ||
      _claims.isSupport ||
      _roleFromUserDoc(_boundProfile) == AdminRole.countryAgent;

  static bool get isPartner =>
      _claims.isPartner || _roleFromUserDoc(_boundProfile) == AdminRole.partner;

  static bool get isTransportCompany =>
      _claims.isTransportManager ||
      _roleFromUserDoc(_boundProfile) == AdminRole.transportCompany;

  static bool get isFinance => _claims.isFinance || isSuperAdmin;

  static DocumentReference? get scopedCountryRef {
    final path = _claims.countryId;
    if (path != null && path.isNotEmpty) {
      return FirebaseFirestore.instance.doc(path);
    }
    return _boundProfile?.revDlohAgent;
  }

  static String get scopedCountryName => _boundProfile?.dolhAgent ?? '';

  static DocumentReference? get partnerMkanRef {
    final path = _claims.partnerMkanId;
    if (path != null && path.isNotEmpty) {
      return FirebaseFirestore.instance.doc(path);
    }
    return _boundProfile?.partnerMkanRef;
  }

  static DocumentReference? get transportCompanyRef {
    final path = _claims.transportCompanyId;
    if (path != null && path.isNotEmpty) {
      return FirebaseFirestore.instance.doc(path);
    }
    return _boundProfile?.transportCompany;
  }

  static const _superAdminOnlyRoutes = {
    'AdminAddAgent',
    'EdetAgent',
    'AdminAddSuperAdmin',
    'EdetSuperAdmin',
    'AdminSuperAdmins',
    'AddDolh',
    'AdminDol',
    'AdminAgent',
    'AdminAgentReport',
    'AdminAuditLog',
    'AdminReportsHub',
    'adminRegesr',
  };

  static const _financeRoutes = {
    'AdminProfits',
    'AdminReportsHub',
  };

  static bool canAccessRoute(String routeName) {
    if (_claims.isFinance && !_claims.isSuperAdmin && !_claims.isCountryAdmin) {
      return _financeRoutes.contains(routeName) || routeName == 'Settings';
    }

    switch (currentRole) {
      case AdminRole.superAdmin:
        return routeName != 'adminRegesr';
      case AdminRole.countryAgent:
        if (_superAdminOnlyRoutes.contains(routeName)) {
          if (_claims.isFinance && _financeRoutes.contains(routeName)) {
            return true;
          }
          return false;
        }
        return _agentRoutes.contains(routeName);
      case AdminRole.partner:
        return _partnerRoutes.contains(routeName);
      case AdminRole.transportCompany:
        return _transportCompanyRoutes.contains(routeName);
      case AdminRole.none:
        return false;
    }
  }

  static const _agentRoutes = {
    'Home22Dashboard',
    'AdminM3alm',
    'AdminPartners',
    'AdminAddPartner',
    'Adminregion',
    'Adminvill',
    'AddReg',
    'edetReg',
    'addVill',
    'edetVill',
    'Adminuser',
    'Admindrever',
    'AdminDrivers',
    'DriverActivation',
    'addDrev',
    'AdminTransportCompanies',
    'AddTransportCompany',
    'EdetTransportCompany',
    'AdminALLhgZ',
    'AdminBookingDetails',
    'AdminProfits',
    'AdminSuport',
    'Settings',
    'DriverProfile',
    'AdminaddMkan',
    'AdminaddMkanCopy',
  };

  static const _partnerRoutes = {
    'PartnerBookings',
    'AdminBookingDetails',
    'Settings',
  };

  static const _transportCompanyRoutes = {
    'CompanyDrivers',
    'addDrev',
    'Settings',
    'DriverProfile',
  };

  static String homeRouteFor(AdminRole role) {
    switch (role) {
      case AdminRole.partner:
        return 'PartnerBookings';
      case AdminRole.transportCompany:
        return 'CompanyDrivers';
      case AdminRole.countryAgent:
      case AdminRole.superAdmin:
        return 'Home22Dashboard';
      case AdminRole.none:
        return 'HomePage';
    }
  }

  static String roleLabelL10n(BuildContext context, AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return FFLocalizations.of(context).getText('role_super_admin');
      case AdminRole.countryAgent:
        return FFLocalizations.of(context).getText('role_country_agent');
      case AdminRole.partner:
        return FFLocalizations.of(context).getText('role_partner');
      case AdminRole.transportCompany:
        return FFLocalizations.of(context).getText('role_transport_manager');
      case AdminRole.none:
        return FFLocalizations.of(context).getText('role_unauthorized');
    }
  }
}

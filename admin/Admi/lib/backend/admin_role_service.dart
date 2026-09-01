import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/admin_rbac_phase.dart';
import '/backend/schema/user_record.dart';
import '/core/auth/auth_claims.dart';
import '/flutter_flow/internationalization.dart';

/// Panel roles derived from Firebase Auth custom claims (bounded profile bootstrap).
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
  static AdminRbacPhase _phase = AdminRbacPhase.loading;

  static AdminRbacPhase get rbacPhase => _phase;

  static void resetSession() {
    _claims = AuthClaims.fromToken(null);
    _boundProfile = null;
    _phase = AdminRbacPhase.loading;
  }

  static void bindProfile(UserRecord? user) {
    _boundProfile = user;
    if (user == null) return;
    if (_phase == AdminRbacPhase.loading &&
        _roleFromUserDoc(user) != AdminRole.none) {
      _phase = AdminRbacPhase.bootstrap;
    }
  }

  /// Call after [refreshMyClaims] + token refresh completes.
  static void markClaimsAuthoritative() {
    _phase = AdminRbacPhase.authoritative;
  }

  static const int ruleSuperAdmin = 1;
  static const int ruleCountryAgent = 2;
  static const int rulePartner = 3;
  static const int ruleTransportCompany = 4;

  /// Legacy shim for callers comparing an already-loaded profile.
  static AdminRole roleFrom(UserRecord? user) => _roleFromUserDoc(user);

  /// Testable role matrix from raw profile fields (no Firebase required).
  static AdminRole roleFromFields({
    required bool isAdmin,
    required int isAdminRule,
    required bool hasIsAdminRule,
    bool isagent = false,
    bool isPartner = false,
  }) {
    if (hasIsAdminRule) {
      if (isAdminRule == ruleSuperAdmin) {
        return AdminRole.superAdmin;
      }
      if (isAdminRule == ruleCountryAgent) {
        return AdminRole.countryAgent;
      }
      if (isAdminRule == rulePartner) {
        return AdminRole.partner;
      }
      if (isAdminRule == ruleTransportCompany) {
        return AdminRole.transportCompany;
      }
    }
    if (isAdmin) {
      return AdminRole.superAdmin;
    }
    if (isagent) {
      return AdminRole.countryAgent;
    }
    if (isPartner) {
      return AdminRole.partner;
    }
    return AdminRole.none;
  }

  static String roleLabel(AdminRole role) => role.name;

  static Future<void> refreshClaims({bool forceRefresh = false}) async {
    _claims = await AuthClaims.current(forceRefresh: forceRefresh);
    if (_claims.hasPanelAccess) {
      _phase = AdminRbacPhase.authoritative;
    }
  }

  static void bindClaims(AuthClaims claims) {
    _claims = claims;
    if (_claims.hasPanelAccess) {
      _phase = AdminRbacPhase.authoritative;
    }
  }

  static AdminRole get currentRole {
    if (_claims.isSuperAdmin) return AdminRole.superAdmin;
    if (_claims.isCountryAdmin || _claims.isAgent || _claims.isSupport) {
      return AdminRole.countryAgent;
    }
    if (_claims.isPartner) return AdminRole.partner;
    if (_claims.isTransportManager) return AdminRole.transportCompany;
    if (_claims.isFinance) return AdminRole.countryAgent;

    if (_phase != AdminRbacPhase.authoritative) {
      return _roleFromUserDoc(_boundProfile);
    }
    return AdminRole.none;
  }

  static AdminRole _roleFromUserDoc(UserRecord? user) {
    if (user == null) return AdminRole.none;
    return roleFromFields(
      isAdmin: user.isAdmin,
      isAdminRule: user.isAdminRule,
      hasIsAdminRule: user.hasIsAdminRule(),
      isagent: user.isagent,
      isPartner: user.isPartner,
    );
  }

  static bool get hasPanelAccess {
    if (_claims.hasPanelAccess) return true;
    if (_phase == AdminRbacPhase.authoritative) return false;
    return _roleFromUserDoc(_boundProfile) != AdminRole.none;
  }

  /// True while signed-in but profile/claims have not arrived yet.
  /// UI must not show "Unauthorized" during this window.
  static bool get isRoleResolving {
    if (_claims.hasPanelAccess) return false;
    if (_boundProfile != null) return false;
    return _phase == AdminRbacPhase.loading;
  }

  static bool get hasClaimsPanelAccess => _claims.hasPanelAccess;

  /// Profile-doc role without considering claims (for claims-sync decisions).
  static AdminRole get profileRole => _roleFromUserDoc(_boundProfile);

  static bool get isSuperAdmin => currentRole == AdminRole.superAdmin;

  /// Country-agent list/dashboard scoping. Super admins always use global scope
  /// even when legacy claims also include country_admin/agent (production QA account).
  static bool get isCountryAgent {
    if (isSuperAdmin) return false;
    return currentRole == AdminRole.countryAgent;
  }

  /// Firestore user doc check (editing/viewing another account).
  static bool isSuperAdminUser(UserRecord? user) {
    if (user == null) return false;
    if (user.hasIsAdminRule()) {
      return user.isAdminRule == ruleSuperAdmin;
    }
    return user.isAdmin;
  }

  static bool get isPartner => currentRole == AdminRole.partner;

  static bool get isTransportCompany =>
      currentRole == AdminRole.transportCompany;

  static bool get isFinance => _claims.isFinance || isSuperAdmin;

  /// SuperAdmin / Finance-only writers. Country agents are read-only in Phase 6A.
  static bool get canWriteSettlements =>
      isSuperAdmin ||
      (_claims.isFinance && !_claims.isCountryAdmin && !_claims.isAgent);

  static DocumentReference? get scopedCountryRef {
    if (isSuperAdmin) return null;
    final path = _claims.countryId;
    if (path != null && path.isNotEmpty) {
      return FirebaseFirestore.instance.doc(path);
    }
    if (_phase != AdminRbacPhase.authoritative) {
      return _boundProfile?.revDlohAgent;
    }
    return null;
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
    'AdminFinanceHub',
    // AdminDriverWallets is LEGACY_WALLET_TOOL — SuperAdmin only (not settlement V2).
    'AdminSettlements',
    'AdminSettlementDetails',
    'AdminSettlementReceipt',
    'AdminReconciliation',
    'AdminFinancialPeriods',
    'AdminFinanceReports',
    'AdminFinanceAudit',
    'AdminDiagnostics',
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
        // Hard deny cross-country admin surfaces even if allowlist drifts.
        if (routeName == 'AdminDol' ||
            routeName == 'AdminAgent' ||
            routeName == 'AdminSuperAdmins' ||
            routeName == 'AdminAuditLog' ||
            routeName == 'AdminReportsHub' ||
            routeName == 'AdminAgentReport') {
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
    'AdminDriverExpiryQueue',
    'DriverActivation',
    'addDrev',
    'AdminTransportCompanies',
    'AddTransportCompany',
    'EdetTransportCompany',
    'AdminALLhgZ',
    'AdminBookingDetails',
    'AdminProfits',
    'AdminFinanceHub',
    'AdminSettlements',
    'AdminSettlementDetails',
    'AdminSettlementReceipt',
    'AdminReconciliation',
    'AdminFinancialPeriods',
    'AdminFinanceReports',
    'AdminFinanceAudit',
    'AdminDiagnostics',
    'AdminTourGuides',
    'AdminSuport',
    'Settings',
    'DriverProfile',
    'AdminaddMkan',
    'AdminaddMkanCopy',
    'Admintypecar',
    'CarTypeAddition',
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

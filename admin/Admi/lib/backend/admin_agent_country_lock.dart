import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';
import '/backend/admin_saudi_country.dart';
import '/backend/backend.dart';

/// Locks geo pickers to the country agent's assigned country.
class AdminAgentCountryLock {
  AdminAgentCountryLock._();

  /// Ensures [FFAppState] and reads have a country ref for the signed-in agent.
  static Future<DocumentReference?> ensureCountryResolved() async {
    if (!AdminRoleService.isCountryAgent) return null;

    final existing = _activeCountryRef();
    if (existing != null) {
      applyToAppState();
      await _persistCountryOnProfile(
        existing,
        AdminRoleService.scopedCountryName,
      );
      return existing;
    }

    await ensureCurrentUserDocument();
    final user = currentUserDocument;
    if (user == null) return null;

    DocumentReference? resolved = user.revDlohAgent;
    if (resolved == null && AdminSaudiCountry.isSaudiAgent(user)) {
      await AdminSaudiCountry.ensureQueryRefsLoaded();
      resolved = await AdminSaudiCountry.resolveRef();
    }

    if (resolved != null) {
      FFAppState().update(() {
        FFAppState().RevDolh = resolved;
        FFAppState().RevdolhTEXT = user.dolhAgent;
        FFAppState().dolh = resolved;
        FFAppState().naimdolh = user.dolhAgent;
      });
      await _persistCountryOnProfile(resolved, user.dolhAgent);
    }

    return resolved;
  }

  static DocumentReference? _activeCountryRef() {
    final fromUser = AdminRoleService.scopedCountryRef;
    if (fromUser != null) return fromUser;
    return FFAppState().RevDolh ?? FFAppState().dolh;
  }

  static void applyToAppState() {
    if (!AdminRoleService.isCountryAgent) {
      return;
    }
    final countryRef = _activeCountryRef();
    final countryName = AdminRoleService.scopedCountryName;
    if (countryRef == null) {
      return;
    }
    FFAppState().update(() {
      FFAppState().RevDolh = countryRef;
      FFAppState().RevdolhTEXT = countryName;
      FFAppState().dolh = countryRef;
      FFAppState().naimdolh = countryName;
    });
  }

  /// Firestore rules read `Rev_dloh_agent` on the server — sync when missing locally.
  static Future<void> _persistCountryOnProfile(
    DocumentReference countryRef,
    String countryName,
  ) async {
    final userRef = currentUserReference;
    if (userRef == null) return;

    final user = currentUserDocument;
    if (user != null &&
        user.hasRevDlohAgent() &&
        user.revDlohAgent!.path == countryRef.path) {
      return;
    }

    try {
      await userRef.set(
        createUserRecordData(
          revDlohAgent: countryRef,
          dolhAgent: countryName.isNotEmpty ? countryName : user?.dolhAgent,
          isagent: true,
          isAdminRule: AdminRoleService.ruleCountryAgent,
        ),
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}

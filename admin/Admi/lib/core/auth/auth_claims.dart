import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth custom claim keys (set server-side only).
abstract final class AuthClaimKeys {
  static const superAdmin = 'super_admin';
  static const countryAdmin = 'country_admin';
  static const agent = 'agent';
  static const support = 'support';
  static const finance = 'finance';
  static const partner = 'partner';
  static const transportManager = 'transport_manager';
  static const countryId = 'country_id';
  static const partnerMkanId = 'partner_mkan_id';
  static const transportCompanyId = 'transport_company_id';
}

/// Reads RBAC state from Firebase Auth custom claims (single source of truth).
class AuthClaims {
  AuthClaims._(this._claims);

  final Map<String, dynamic> _claims;

  static AuthClaims? _cached;
  static DateTime? _cachedAt;

  static Future<AuthClaims> current({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _cached = AuthClaims._({});
      return _cached!;
    }
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 5)) {
      return _cached!;
    }
    final result = await user.getIdTokenResult(forceRefresh);
    _cached = AuthClaims._(Map<String, dynamic>.from(result.claims ?? {}));
    _cachedAt = DateTime.now();
    return _cached!;
  }

  static void clearCache() {
    _cached = null;
    _cachedAt = null;
  }

  static AuthClaims fromToken(Map<String, dynamic>? claims) =>
      AuthClaims._(Map<String, dynamic>.from(claims ?? {}));

  bool _bool(String key) => _claims[key] == true;

  bool get isSuperAdmin => _bool(AuthClaimKeys.superAdmin);

  bool get isCountryAdmin => _bool(AuthClaimKeys.countryAdmin);

  bool get isAgent => _bool(AuthClaimKeys.agent);

  bool get isSupport => _bool(AuthClaimKeys.support);

  bool get isFinance => _bool(AuthClaimKeys.finance);

  bool get isPartner => _bool(AuthClaimKeys.partner);

  bool get isTransportManager => _bool(AuthClaimKeys.transportManager);

  bool get hasPanelAccess =>
      isSuperAdmin ||
      isCountryAdmin ||
      isAgent ||
      isSupport ||
      isFinance ||
      isPartner ||
      isTransportManager;

  String? get countryId => _claims[AuthClaimKeys.countryId] as String?;

  String? get partnerMkanId => _claims[AuthClaimKeys.partnerMkanId] as String?;

  String? get transportCompanyId =>
      _claims[AuthClaimKeys.transportCompanyId] as String?;
}

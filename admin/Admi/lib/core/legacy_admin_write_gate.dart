/// Legacy Admin cutover write policy — config-gated, fail closed.
///
/// Source of truth: `financial_config/runtime` (Admin SDK only; clients cannot
/// override via browser). Customer / driver apps do not read this gate.
///
/// Modes:
/// - unrestricted
/// - read_only
/// - super_admin_emergency_only
library;

/// Parsed write mode for Legacy Admin (financial + panel mutation UX).
enum LegacyAdminWriteMode {
  unrestricted,
  readOnly,
  superAdminEmergencyOnly,
}

/// Result of evaluating whether a Legacy Admin write may proceed.
class LegacyAdminWriteDecision {
  const LegacyAdminWriteDecision.allow()
      : allowed = true,
        code = null;

  const LegacyAdminWriteDecision.deny(this.code) : allowed = false;

  final bool allowed;
  final String? code;
}

/// Pure policy evaluator (unit-testable; no Firebase).
abstract final class LegacyAdminWriteGate {
  LegacyAdminWriteGate._();

  static const runtimeDocPath = 'financial_config/runtime';

  static LegacyAdminWriteMode parseMode(
    Object? raw, {
    bool cutoverRestricted = false,
  }) {
    final mode = (raw ?? '').toString().trim().toLowerCase();
    switch (mode) {
      case 'unrestricted':
        return LegacyAdminWriteMode.unrestricted;
      case 'read_only':
        return LegacyAdminWriteMode.readOnly;
      case 'super_admin_emergency_only':
        return LegacyAdminWriteMode.superAdminEmergencyOnly;
      default:
        // Fail closed when cutover restriction is armed.
        if (cutoverRestricted) return LegacyAdminWriteMode.readOnly;
        return LegacyAdminWriteMode.unrestricted;
    }
  }

  /// Financial / admin write evaluation. Browser cannot override [mode].
  static LegacyAdminWriteDecision evaluate({
    required LegacyAdminWriteMode mode,
    required bool isSuperAdmin,
    bool domainFlagEnabled = true,
  }) {
    switch (mode) {
      case LegacyAdminWriteMode.readOnly:
        return const LegacyAdminWriteDecision.deny('LEGACY_ADMIN_READ_ONLY');
      case LegacyAdminWriteMode.superAdminEmergencyOnly:
        if (!isSuperAdmin) {
          return const LegacyAdminWriteDecision.deny(
            'LEGACY_ADMIN_SUPER_ADMIN_EMERGENCY_ONLY',
          );
        }
        return const LegacyAdminWriteDecision.allow();
      case LegacyAdminWriteMode.unrestricted:
        if (!domainFlagEnabled) {
          return const LegacyAdminWriteDecision.deny('FEATURE_FLAG_DISABLED');
        }
        return const LegacyAdminWriteDecision.allow();
    }
  }
}

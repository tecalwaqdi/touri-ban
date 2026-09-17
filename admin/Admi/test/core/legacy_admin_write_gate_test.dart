import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/legacy_admin_write_gate.dart';

void main() {
  group('LegacyAdminWriteGate', () {
    test('read_only blocks even Super Admin (no browser override)', () {
      final decision = LegacyAdminWriteGate.evaluate(
        mode: LegacyAdminWriteMode.readOnly,
        isSuperAdmin: true,
        domainFlagEnabled: true,
      );
      expect(decision.allowed, isFalse);
      expect(decision.code, 'LEGACY_ADMIN_READ_ONLY');
    });

    test('super_admin_emergency_only allows Super Admin only', () {
      final denied = LegacyAdminWriteGate.evaluate(
        mode: LegacyAdminWriteMode.superAdminEmergencyOnly,
        isSuperAdmin: false,
      );
      expect(denied.allowed, isFalse);
      expect(denied.code, 'LEGACY_ADMIN_SUPER_ADMIN_EMERGENCY_ONLY');

      final allowed = LegacyAdminWriteGate.evaluate(
        mode: LegacyAdminWriteMode.superAdminEmergencyOnly,
        isSuperAdmin: true,
        domainFlagEnabled: false,
      );
      expect(allowed.allowed, isTrue);
    });

    test('unrestricted still requires domain flag', () {
      final blocked = LegacyAdminWriteGate.evaluate(
        mode: LegacyAdminWriteMode.unrestricted,
        isSuperAdmin: true,
        domainFlagEnabled: false,
      );
      expect(blocked.allowed, isFalse);
      expect(blocked.code, 'FEATURE_FLAG_DISABLED');
    });

    test('unknown mode fails closed when cutover restricted', () {
      expect(
        LegacyAdminWriteGate.parseMode('nope', cutoverRestricted: true),
        LegacyAdminWriteMode.readOnly,
      );
      expect(
        LegacyAdminWriteGate.parseMode('', cutoverRestricted: false),
        LegacyAdminWriteMode.unrestricted,
      );
    });
  });
}

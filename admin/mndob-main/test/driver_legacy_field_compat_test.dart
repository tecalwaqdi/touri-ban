import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_account_state_resolver.dart';
import 'package:mndob/core/driver_legacy_field_compat.dart';

void main() {
  group('DriverLegacyFieldCompat', () {
    test('operational approval covers offline online trip', () {
      expect(
        DriverLegacyFieldCompat.isOperationallyApproved(
          DriverLifecycle.activeOffline,
        ),
        isTrue,
      );
      expect(
        DriverLegacyFieldCompat.isOperationallyApproved(
          DriverLifecycle.pendingApproval,
        ),
        isFalse,
      );
    });

    test('isOnline true for activeOnline and onTrip', () {
      expect(
        DriverLegacyFieldCompat.isOnline(DriverLifecycle.activeOnline),
        isTrue,
      );
      expect(
        DriverLegacyFieldCompat.isOnline(DriverLifecycle.onTrip),
        isTrue,
      );
      expect(
        DriverLegacyFieldCompat.isOnline(DriverLifecycle.activeOffline),
        isFalse,
      );
    });

    test('admin approve patch keeps legacy + status', () {
      final patch = DriverLegacyFieldCompat.adminApprovePatch(adminUid: 'a1');
      expect(patch['actev_mndob'], isTrue);
      expect(patch['ismndob'], isTrue);
      expect(patch['registration_status'], 'approved');
    });

    test('admin reject clears activation', () {
      final patch = DriverLegacyFieldCompat.adminRejectPatch(
        reason: 'docs',
        adminUid: 'a1',
      );
      expect(patch['actev_mndob'], isFalse);
      expect(patch['registration_status'], 'rejected');
      expect(patch['rejection_reason'], 'docs');
    });

    test('status message keys are non-empty', () {
      for (final life in DriverLifecycle.values) {
        expect(
          DriverLegacyFieldCompat.statusMessageKey(life),
          isNotEmpty,
        );
      }
    });

    test('field meanings document all legacy keys', () {
      for (final key in [
        'ismndob',
        'ismndom',
        'actev_mndob',
        'ngl',
        'mndon_newacc',
        'registration_status',
        'rejection_reason',
      ]) {
        expect(DriverLegacyFieldCompat.fieldMeanings.containsKey(key), isTrue);
      }
    });
  });
}

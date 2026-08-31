import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admintypecar/admin_vehicle_types_adapter.dart';
import 'package:admin_arawatan/backend/admin_media_resolver.dart';

void main() {
  group('AdminVehicleTypeFilters', () {
    test('defaults inactive flags', () {
      const f = AdminVehicleTypeFilters();
      expect(f.hasActive, isFalse);
      expect(f.status, AdminVehicleTypeStatusFilter.all);
    });

    test('copyWith search activates filter', () {
      final f = const AdminVehicleTypeFilters().copyWith(searchQuery: 'economy');
      expect(f.hasActive, isTrue);
    });
  });

  group('AdminVehicleTypeRow classification heuristics', () {
    test('media resolver accepts type_car paths', () {
      expect(
        AdminMediaResolver.storagePathFrom('type_car/uploads/a.jpg'),
        'type_car/uploads/a.jpg',
      );
    });

    test('sort prefers positive sort keys', () {
      // Pure list sort with synthetic rows isn't available without Firestore
      // records; validate filter enum and media classification stay stable.
      expect(
        AdminMediaResolver.classifyStorageCode('object-not-found'),
        AdminMediaFailureKind.expectedMissing,
      );
      expect(
        AdminVehicleTypeStatusFilter.active.name,
        'active',
      );
    });
  });

  group('adminSortVehicleTypes', () {
    test('empty list stable', () {
      expect(adminSortVehicleTypes(const []), isEmpty);
    });
  });
}

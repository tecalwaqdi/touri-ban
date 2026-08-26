import 'package:ara_oatan_app/core/toury_car_i18n.dart';
import 'package:ara_oatan_app/core/toury_vehicle_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin-controlled vehicle catalog SOT', () {
    test('Firestore names override hardcoded catalog', () {
      final merged = touryMergeVehicleNames(
        firestoreNames: {
          'ar': 'اسم مخصص من الأدمن',
          'en': 'Admin Custom Economy',
        },
        codeCar: 'economy',
        naim: 'اسم مخصص',
      );
      expect(merged['en'], 'Admin Custom Economy');
      expect(merged['ar'], 'اسم مخصص من الأدمن');
      // Hardcoded catalog fills missing locales only.
      expect(merged['ru'], isNotEmpty);
    });

    test('admin sort key prefers explicit sort_order', () {
      expect(
        touryAdminVehicleSortKey(sortOrder: 9, numTrteb: 0, categorySort: 1),
        9,
      );
      expect(
        touryAdminVehicleSortKey(sortOrder: 0, numTrteb: 3, categorySort: 1),
        3,
      );
      expect(
        touryAdminVehicleSortKey(sortOrder: 0, numTrteb: 0, categorySort: 4),
        4,
      );
    });

    test('usable http image means no local asset forced', () {
      expect(
        touryShouldPreferRemoteVehicleImage(
          'https://cdn.example/car.jpg?v=2',
        ),
        isTrue,
      );
      expect(touryShouldPreferRemoteVehicleImage('data:image/jpeg;base64,xx'), isFalse);
      expect(touryShouldPreferRemoteVehicleImage(''), isFalse);
    });
  });
}

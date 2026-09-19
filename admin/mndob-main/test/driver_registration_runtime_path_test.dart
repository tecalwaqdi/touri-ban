import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mndob/core/driver_document_expiry_resolver.dart';
import 'package:mndob/core/driver_registration_profile_loader.dart';
import 'package:mndob/core/driver_registration_update_payload.dart';
import 'package:mndob/regdrever/regdrever_widget.dart';

void main() {
  group('DriverRegistrationNavMode runtime path', () {
    test('query mode=update resolves update mode', () {
      expect(
        DriverRegistrationNavMode.isUpdateMode(queryMode: 'update'),
        isTrue,
      );
      expect(
        DriverRegistrationNavMode.isUpdateMode(queryMode: 'UPDATE'),
        isTrue,
      );
    });

    test('extra mode=update resolves without query', () {
      expect(
        DriverRegistrationNavMode.isUpdateMode(
          extra: const {'mode': 'update'},
        ),
        isTrue,
      );
    });

    test('missing mode stays register', () {
      expect(DriverRegistrationNavMode.isUpdateMode(), isFalse);
      expect(
        DriverRegistrationNavMode.isUpdateMode(queryMode: 'register'),
        isFalse,
      );
    });

    testWidgets('GoRouter /regdrever?mode=update builds updateExisting widget',
        (tester) async {
      RegdreverMode? seen;
      final router = GoRouter(
        initialLocation: '/regdrever?mode=update',
        routes: [
          GoRoute(
            name: RegdreverWidget.routeName,
            path: RegdreverWidget.routePath,
            builder: (context, state) {
              final update = DriverRegistrationNavMode.isUpdateMode(
                queryMode: state.uri.queryParameters['mode'],
                extra: state.extra,
              );
              seen = update
                  ? RegdreverMode.updateExisting
                  : RegdreverMode.register;
              return Text(update ? 'UPDATE_MODE' : 'REGISTER_MODE');
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('UPDATE_MODE'), findsOneWidget);
      expect(seen, RegdreverMode.updateExisting);
    });

    testWidgets('pushNamed with query+extra reaches update mode', (tester) async {
      RegdreverMode? seen;
      String? seenUri;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.pushNamed(
                  RegdreverWidget.routeName,
                  queryParameters: const {'mode': 'update'},
                  extra: const {'mode': 'update'},
                ),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            name: RegdreverWidget.routeName,
            path: RegdreverWidget.routePath,
            builder: (context, state) {
              seenUri = state.uri.toString();
              final update = DriverRegistrationNavMode.isUpdateMode(
                queryMode: state.uri.queryParameters['mode'],
                extra: state.extra,
              );
              seen = update
                  ? RegdreverMode.updateExisting
                  : RegdreverMode.register;
              return Text(update ? 'UPDATE_MODE' : 'REGISTER_MODE');
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('UPDATE_MODE'), findsOneWidget);
      expect(seen, RegdreverMode.updateExisting);
      expect(seenUri, contains('mode=update'));
    });
  });

  group('existing-driver prefill → edit → save → reload', () {
    test('expiry persists through payload and loader round-trip', () {
      final before = {
        'display_name': 'Driver One',
        'ID_hoyh_MNDOB': '111',
        'email': 'd1@test.com',
        'phone_number': '+966500000001',
        'NameCar': 'Hilux',
        'ModelCar': '2021',
        'number_lohh_car': 'XYZ999',
        'vehicle_color': 'Black',
        'seat_count': 4,
        'registration_status': 'approved',
        'actev_mndob': true,
        'ismndob': true,
        'wallet': {'balance': 50},
        'doc_national_id': {
          'documentType': 'national_id',
          'storagePath': 'users/u1/id.jpg',
        },
        'doc_vehicle_registration': {
          'documentType': 'vehicle_registration',
          'storagePath': 'users/u1/reg.jpg',
        },
        'doc_driver_license': {
          'documentType': 'driver_license',
          'storagePath': 'users/u1/license.jpg',
        },
        'doc_driver_license_front': {
          'documentType': 'driver_license',
          'side': 'front',
          'storagePath': 'users/u1/license-front.jpg',
        },
        'doc_driver_license_back': {
          'documentType': 'driver_license',
          'side': 'back',
          'storagePath': 'users/u1/license-back.jpg',
        },
        'photo_storage_path': 'users/u1/photo.jpg',
      };

      final snap = DriverRegistrationProfileLoader.fromUserData(before);
      expect(snap.displayName, 'Driver One');
      expect(snap.licenseExpiry, isNull);
      expect(snap.licenseFrontStoragePath, 'users/u1/license-front.jpg');
      expect(snap.licenseBackStoragePath, 'users/u1/license-back.jpg');

      final licenseExpiry = DateTime(2028, 6, 15);
      final vehicleExpiry = DateTime(2027, 3, 1);
      final payload = DriverRegistrationUpdatePayload.build(
        uid: 'u1',
        displayName: snap.displayName,
        email: snap.email,
        phoneE164: snap.phone,
        idNumber: snap.idNumber,
        vehicleName: snap.vehicleName,
        modelYear: snap.modelYear,
        plate: snap.plate,
        color: snap.color,
        seats: 4,
        vehicleMake: snap.make,
        vehicleTypeText: 'SUV',
        licenseExpiry: licenseExpiry,
        vehicleRegExpiry: vehicleExpiry,
        photoStoragePath: snap.photoStoragePath,
        nationalIdStoragePath: snap.nationalIdStoragePath,
        vehicleRegStoragePath: snap.vehicleRegStoragePath,
        licenseFrontStoragePath: snap.licenseFrontStoragePath,
        licenseBackStoragePath: snap.licenseBackStoragePath,
        existingNationalId:
            Map<String, dynamic>.from(before['doc_national_id'] as Map),
        existingVehicleReg:
            Map<String, dynamic>.from(before['doc_vehicle_registration'] as Map),
        existingLicenseFront:
            Map<String, dynamic>.from(before['doc_driver_license_front'] as Map),
        existingLicenseBack:
            Map<String, dynamic>.from(before['doc_driver_license_back'] as Map),
      );

      // Simulate merge into existing doc without touching protected fields.
      final after = Map<String, dynamic>.from(before)..addAll(payload);

      expect(after['registration_status'], 'approved');
      expect(after['actev_mndob'], true);
      expect(after['ismndob'], true);
      expect(after['wallet'], {'balance': 50});
      expect(payload.containsKey('registration_status'), isFalse);
      expect(payload.containsKey('actev_mndob'), isFalse);
      expect(payload.containsKey('wallet'), isFalse);
      expect(payload.containsKey('photo_url'), isFalse); // keep existing

      final licenseFront = after['doc_driver_license_front'] as Map;
      final licenseBack = after['doc_driver_license_back'] as Map;
      final licenseLegacy = after['doc_driver_license'] as Map;
      final vehicle = after['doc_vehicle_registration'] as Map;
      expect(licenseFront.containsKey('expiry_date'), isFalse);
      expect(vehicle.containsKey('expiry_date'), isFalse);
      expect(
        licenseFront[DriverRegistrationUpdatePayload.expiryField],
        isA<Timestamp>(),
      );
      expect(
        vehicle[DriverRegistrationUpdatePayload.expiryField],
        isA<Timestamp>(),
      );
      expect(licenseBack['storagePath'], 'users/u1/license-back.jpg');
      expect(licenseLegacy['storagePath'], 'users/u1/license-front.jpg');

      final reloaded = DriverRegistrationProfileLoader.fromUserData(after);
      expect(reloaded.licenseExpiry?.year, 2028);
      expect(reloaded.licenseExpiry?.month, 6);
      expect(reloaded.vehicleRegExpiry?.year, 2027);
      expect(reloaded.vehicleName, 'Hilux');
      expect(reloaded.licenseFrontStoragePath, 'users/u1/license-front.jpg');
      expect(reloaded.licenseBackStoragePath, 'users/u1/license-back.jpg');
    });
  });

  group('new-driver expiry validation → submit gate', () {
    test('missing dates block with localized keys', () {
      expect(
        DriverRegistrationExpiryValidator.blockingKeys(
          licenseExpiry: null,
          vehicleRegExpiry: null,
        ),
        [
          'Please enter the driver license expiry date',
          'Please enter the vehicle registration expiry date',
        ],
      );
    });

    test('both dates present allow continue', () {
      expect(
        DriverRegistrationExpiryValidator.blockingKeys(
          licenseExpiry: DateTime(2028, 1, 1),
          vehicleRegExpiry: DateTime(2027, 1, 1),
        ),
        isEmpty,
      );
    });

    test('new registration doc slots require canonical expiryDate', () {
      final license = DriverRegistrationUpdatePayload.mergeDocSlot(
        documentType: 'driver_license',
        storagePath: 'users/new/license.jpg',
        expiryDate: DateTime(2029, 4, 20),
      );
      expect(license['documentType'], 'driver_license');
      expect(license['storagePath'], 'users/new/license.jpg');
      expect(license[DriverRegistrationUpdatePayload.expiryField], isA<Timestamp>());
      expect(license.containsKey('expiry_date'), isFalse);

      final parsed = DriverDocumentExpiryResolver.parseExpiry(
        license[DriverRegistrationUpdatePayload.expiryField],
      );
      expect(parsed?.year, 2029);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mndob/core/driver_registration_draft.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DriverRegistrationDraft', () {
    test('guest save and load round-trip', () async {
      const draft = DriverRegistrationDraft(
        step: 1,
        name: 'Ali',
        email: 'ali@example.com',
        mobile: '0512345678',
      );
      await draft.save();
      final loaded = await DriverRegistrationDraft.load();
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Ali');
      expect(loaded.step, 1);
      expect(loaded.email, 'ali@example.com');
    });

    test('uid draft does not leak to guest load', () async {
      await const DriverRegistrationDraft(
        step: 2,
        name: 'UidUser',
        email: 'u@example.com',
        uid: 'uid-a',
      ).save(forUid: 'uid-a');

      final guest = await DriverRegistrationDraft.load();
      expect(guest, isNull);

      final forA = await DriverRegistrationDraft.load(uid: 'uid-a');
      expect(forA?.name, 'UidUser');

      final forB = await DriverRegistrationDraft.load(uid: 'uid-b');
      expect(forB, isNull);
    });

    test('migrateGuestToUid moves and clears guest', () async {
      await const DriverRegistrationDraft(
        step: 1,
        name: 'Guest',
        email: 'g@example.com',
      ).save();
      await DriverRegistrationDraft.migrateGuestToUid('uid-x');

      expect(await DriverRegistrationDraft.load(), isNull);
      final uidDraft = await DriverRegistrationDraft.load(uid: 'uid-x');
      expect(uidDraft?.name, 'Guest');
      expect(uidDraft?.uid, 'uid-x');
    });

    test('clearForUid does not clear guest', () async {
      await const DriverRegistrationDraft(
        step: 0,
        name: 'GuestKeep',
        email: 'gk@example.com',
      ).save();
      await const DriverRegistrationDraft(
        step: 1,
        name: 'UidClear',
        email: 'uc@example.com',
        uid: 'uid-z',
      ).save(forUid: 'uid-z');

      await DriverRegistrationDraft.clearForUid('uid-z');
      expect(await DriverRegistrationDraft.load(uid: 'uid-z'), isNull);
      expect((await DriverRegistrationDraft.load())?.name, 'GuestKeep');
    });

    test('mismatched draft.uid rejected for load', () async {
      SharedPreferences.setMockInitialValues({
        'driver_registration_draft_v1_u_uid-a':
            '{"step":1,"name":"X","email":"x@e.com","mobile":"1","uid":"other"}',
      });
      final loaded = await DriverRegistrationDraft.load(uid: 'uid-a');
      expect(loaded, isNull);
    });

    test('lat lng round-trip survives draft save', () async {
      const draft = DriverRegistrationDraft(
        step: 1,
        lat: 42.8746,
        lng: 74.5698,
      );
      await draft.save();
      final loaded = await DriverRegistrationDraft.load();
      expect(loaded?.lat, 42.8746);
      expect(loaded?.lng, 74.5698);
    });

    test('hasContinuableDraft', () async {
      expect(await DriverRegistrationDraft.hasContinuableDraft(), isFalse);
      await const DriverRegistrationDraft(step: 2, name: 'A').save();
      expect(await DriverRegistrationDraft.hasContinuableDraft(), isTrue);
    });

    test('region and village paths round-trip', () async {
      const draft = DriverRegistrationDraft(
        step: 1,
        name: 'Loc',
        email: 'l@example.com',
        regionPath: 'cities/r1',
        regionName: 'Region1',
        villagePath: 'villages/v1',
        villageName: 'City1',
      );
      await draft.save();
      final loaded = await DriverRegistrationDraft.load();
      expect(loaded?.regionPath, 'cities/r1');
      expect(loaded?.villageName, 'City1');
    });

    test('vehicle type path and text round-trip', () async {
      const draft = DriverRegistrationDraft(
        step: 2,
        vehicleTypePath: 'type_car/kg_economy',
        vehicleTypeText: 'Economy Car',
      );
      await draft.save();
      final loaded = await DriverRegistrationDraft.load();
      expect(loaded?.vehicleTypePath, 'type_car/kg_economy');
      expect(loaded?.vehicleTypeText, 'Economy Car');
    });

    test('document expiry dates round-trip', () async {
      const draft = DriverRegistrationDraft(
        step: 2,
        licenseExpiryIso: '2028-08-15T00:00:00.000',
        vehicleRegExpiryIso: '2027-01-01T00:00:00.000',
        licenseImageUrl: 'https://example.com/license.jpg',
      );
      await draft.save();
      final loaded = await DriverRegistrationDraft.load();
      expect(loaded?.licenseExpiryIso, '2028-08-15T00:00:00.000');
      expect(loaded?.vehicleRegExpiryIso, '2027-01-01T00:00:00.000');
      expect(loaded?.licenseImageUrl, 'https://example.com/license.jpg');
    });
  });
}

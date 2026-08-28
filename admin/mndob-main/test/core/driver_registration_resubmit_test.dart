import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_registration_submission_service.dart';

void main() {
  group('DriverRegistrationSubmissionService resubmit', () {
    test('isResubmitAfterChangesRequested detects admin return states', () {
      expect(
        DriverRegistrationSubmissionService.isResubmitAfterChangesRequested(
          'changes_requested',
        ),
        isTrue,
      );
      expect(
        DriverRegistrationSubmissionService.isResubmitAfterChangesRequested(
          'needs_changes',
        ),
        isTrue,
      );
      expect(
        DriverRegistrationSubmissionService.isResubmitAfterChangesRequested(
          'rejected',
        ),
        isTrue,
      );
      expect(
        DriverRegistrationSubmissionService.isResubmitAfterChangesRequested(
          'draft',
        ),
        isFalse,
      );
      expect(
        DriverRegistrationSubmissionService.isResubmitAfterChangesRequested(
          'pending_review',
        ),
        isFalse,
      );
    });

    test('buildResubmitProfilePayload excludes review metadata keys', () {
      const model = DriverRegistrationReviewModel(
        uid: 'u1',
        displayName: 'Ali',
        email: 'a@b.com',
        phoneE164: '+966512345678',
        idNumber: '1234567890',
        birthDate: null,
        countryRef: null,
        regionRef: null,
        villageRef: null,
        regionName: '',
        villageName: '',
        vehicleTypeRef: null,
        vehicleTypeText: '',
        vehicleName: 'Camry',
        modelYear: '2020',
        plate: 'ABC1234',
        color: 'white',
        seats: 4,
        photoUrl: 'https://example.com/p.jpg',
        idImageUrl: 'https://example.com/id.jpg',
        carImageUrl: 'https://example.com/car.jpg',
        licenseImageUrl: 'https://example.com/lic.jpg',
        location: null,
        isResubmit: true,
        uploadInFlight: false,
      );

      final payload = DriverRegistrationSubmissionService.buildResubmitProfilePayload(
        cleanedProfile: {
          'display_name': 'Ali',
          'registration_status': 'draft',
          'submission_status': 'draft',
          'requested_changes': [
            {'resolved': true},
          ],
          'actev_mndob': true,
        },
        uid: 'u1',
        submissionId: 'sub_u1_123',
        model: model,
      );

      expect(payload['submission_id'], 'sub_u1_123');
      expect(payload['display_name'], 'Ali');
      expect(payload.containsKey('registration_status'), isFalse);
      expect(payload.containsKey('submission_status'), isFalse);
      expect(payload.containsKey('requested_changes'), isFalse);
      expect(payload.containsKey('actev_mndob'), isFalse);
      expect(payload.containsKey('ismndob'), isFalse);
    });
  });
}

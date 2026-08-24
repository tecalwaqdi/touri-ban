/// Local-only driver review fixtures for Admin visual QA (Stage F).
/// Never written to Firestore.
abstract final class DriverReviewVisualFixture {
  DriverReviewVisualFixture._();

  static const supportedStates = [
    'pending_review',
    'approved',
    'rejected',
    'needs_changes',
  ];

  static bool isFixtureState(String? state) =>
      state != null && supportedStates.contains(_canonical(state));

  static String _canonical(String state) {
    switch (state) {
      case 'pending_review':
      case 'pending':
        return 'pending_review';
      case 'needs_changes':
      case 'changes_requested':
        return 'needs_changes';
      default:
        return state;
    }
  }

  static Map<String, dynamic> dataFor(String state) {
    switch (_canonical(state)) {
      case 'pending_review':
        return _base(
          registrationStatus: 'pending_review',
          actevMndob: false,
          reason: '',
          fieldsToFix: const <String>[],
          history: const [
            'Submitted',
          ],
        );
      case 'approved':
        return _base(
          registrationStatus: 'approved',
          actevMndob: true,
          reason: '',
          fieldsToFix: const <String>[],
          history: const [
            'Submitted',
            'Approved',
          ],
        );
      case 'rejected':
        return _base(
          registrationStatus: 'rejected',
          actevMndob: false,
          reason: 'National ID photo is unreadable',
          fieldsToFix: const ['national_id'],
          history: const [
            'Submitted',
            'Rejected',
          ],
        );
      case 'needs_changes':
        return _base(
          registrationStatus: 'needs_changes',
          actevMndob: false,
          reason: 'Vehicle registration year does not match the plate photo',
          fieldsToFix: const ['vehicle_registration', 'plate'],
          history: const [
            'Submitted',
            'Changes requested',
          ],
        );
      default:
        return _base(
          registrationStatus: 'pending_review',
          actevMndob: false,
          reason: '',
          fieldsToFix: const <String>[],
          history: const ['Submitted'],
        );
    }
  }

  static Map<String, dynamic> _base({
    required String registrationStatus,
    required bool actevMndob,
    required String reason,
    required List<String> fieldsToFix,
    required List<String> history,
  }) {
    return {
      'displayName': 'QA Fixture Driver',
      'email': 'fixture.driver@qa.local',
      'phoneNumber': '+966500000000',
      'registration_status': registrationStatus,
      'registration_flow_version': 2,
      'actev_mndob': actevMndob,
      'ismndob': true,
      'mndob_vill_text': 'Riyadh',
      'text_type_car_mndob': 'Sedan',
      'vehicle_make': 'Toyota',
      'vehicle_model': 'Camry',
      'vehicle_year': '2022',
      'plate': 'QA 1234',
      'email_verified': true,
      'phone_present': true,
      'documents': const [
        'National ID',
        'Vehicle registration',
        'Driver license',
      ],
      'reason': reason,
      'fieldsToFix': fieldsToFix,
      'review_history': history,
      'fixture': true,
    };
  }
}

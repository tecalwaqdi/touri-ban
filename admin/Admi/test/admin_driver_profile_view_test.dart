import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_ops_counters.dart';
import 'package:admin_arawatan/core/admin_driver_profile_view.dart';

void main() {
  test('driversUnknown identity never negative', () {
    expect(
      AdminOpsCounters.driversUnknown(
        totalDrivers: 100,
        active: 40,
        inactive: 50,
      ),
      10,
    );
    expect(
      AdminOpsCounters.driversUnknown(
        totalDrivers: 10,
        active: 7,
        inactive: 7,
      ),
      0,
    );
  });

  test('reviewBucketFromRaw maps statuses', () {
    expect(
      AdminDriverProfileView.reviewBucketFromRaw('pending_review'),
      AdminDriverReviewBucket.pendingReview,
    );
    expect(
      AdminDriverProfileView.reviewBucketFromRaw('changes_requested'),
      AdminDriverReviewBucket.needsChanges,
    );
    expect(
      AdminDriverProfileView.reviewBucketFromRaw('approved'),
      AdminDriverReviewBucket.approved,
    );
    expect(
      AdminDriverProfileView.reviewBucketFromRaw(''),
      AdminDriverReviewBucket.unknownLegacy,
    );
  });

  test('rawRegistrationStatus prefers registration_status', () {
    expect(
      AdminDriverProfileView.rawRegistrationStatusFromMap({
        'registration_status': 'rejected',
        'submission_status': 'pending_review',
      }),
      'rejected',
    );
    expect(
      AdminDriverProfileView.rawRegistrationStatusFromMap({
        'submission_status': 'pending_review',
      }),
      'pending_review',
    );
  });

  test('parseDocExpiry supports DateTime and ISO string', () {
    final d = DateTime.utc(2026, 9, 1);
    expect(AdminDriverProfileView.parseDocExpiry(d), d);
    expect(
      AdminDriverProfileView.parseDocExpiry('2026-09-01T00:00:00Z')?.toUtc(),
      DateTime.utc(2026, 9, 1),
    );
    expect(AdminDriverProfileView.parseDocExpiry(null), isNull);
  });
}

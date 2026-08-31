import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/admin/admindrever/admin_drivers_adapter.dart';
import 'package:admin_arawatan/core/admin_driver_profile_view.dart';

void main() {
  group('AdminDriverStatusLabels / vehicle display', () {
    test('vehicle missing label prefers Arabic outside debug contract', () {
      const v = AdminDriverVehicleSummary(
        classificationLabel: '',
        name: '',
        modelYear: '',
        plate: '',
        color: '',
        typeCarRef: null,
        isLegacyIncomplete: true,
      );
      expect(v.titleLine, isEmpty);
      expect(v.isLegacyIncomplete, isTrue);
    });

    test('vehicle title/plate lines format', () {
      const v = AdminDriverVehicleSummary(
        classificationLabel: 'اقتصادية',
        name: 'اكسنت',
        modelYear: '2026',
        plate: '9614',
        color: '',
        typeCarRef: null,
        isLegacyIncomplete: false,
      );
      expect(v.titleLine, 'اكسنت 2026');
      expect(v.classLine, 'اقتصادية');
      expect(v.plate, '9614');
    });

    test('review bucket mapping', () {
      expect(
        AdminDriverProfileView.reviewBucketFromRaw('pending_review'),
        AdminDriverReviewBucket.pendingReview,
      );
      expect(
        AdminDriverProfileView.reviewBucketFromRaw('approved'),
        AdminDriverReviewBucket.approved,
      );
      expect(
        AdminDriverProfileView.reviewBucketFromRaw('needs_changes'),
        AdminDriverReviewBucket.needsChanges,
      );
      expect(
        AdminDriverProfileView.reviewBucketFromRaw(''),
        AdminDriverReviewBucket.unknownLegacy,
      );
    });
  });
}

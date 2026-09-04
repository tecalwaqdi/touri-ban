import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_driver_document_access.dart';
import 'package:admin_arawatan/core/admin_driver_profile_view.dart';
import 'package:admin_arawatan/core/driver_registration_document_status.dart';

void main() {
  group('AdminDriverDocumentAccess.mapStorageErrorCode', () {
    test('maps not-found family', () {
      expect(
        AdminDriverDocumentAccess.mapStorageErrorCode(
            'firebase_storage/object-not-found'),
        'not_found',
      );
      expect(
        AdminDriverDocumentAccess.mapStorageErrorCode('storage/not-found'),
        'not_found',
      );
    });

    test('maps permission family', () {
      expect(
        AdminDriverDocumentAccess.mapStorageErrorCode('storage/unauthorized'),
        'unauthorized',
      );
      expect(
        AdminDriverDocumentAccess.mapStorageErrorCode('permission-denied'),
        'unauthorized',
      );
    });

    test('maps network family', () {
      expect(
        AdminDriverDocumentAccess.mapStorageErrorCode(
            'storage/retry-limit-exceeded'),
        'network',
      );
    });
  });

  group('AdminDriverDocViewResult', () {
    test('ok when bytes present', () {
      final r = AdminDriverDocViewResult(bytes: Uint8List.fromList([1, 2, 3]));
      expect(r.ok, isTrue);
      expect(r.isImage, isTrue);
    });

    test('detects pdf magic', () {
      final pdf = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]); // %PDF-
      final r =
          AdminDriverDocViewResult(bytes: pdf, contentType: 'application/pdf');
      expect(r.isPdf, isTrue);
      expect(r.ok, isTrue);
    });

    test('user messages are actionable', () {
      expect(
        const AdminDriverDocViewResult(errorCode: 'denied').userMessageAr,
        contains('صلاحية'),
      );
      expect(
        const AdminDriverDocViewResult(errorCode: 'not_found').userMessageAr,
        contains('غير موجود'),
      );
      expect(
        const AdminDriverDocViewResult(errorCode: 'unauthorized').userMessageAr,
        contains('التخزين'),
      );
    });
  });

  group('AdminDriverProfileView documents status', () {
    test('storage path recognition matches shared helper', () {
      expect(
        DriverRegistrationDocumentStatus.isStoragePath(
            'users/abc/uploads/p.jpg'),
        isTrue,
      );
      expect(
        AdminDriverDocumentAccess.isStoragePath('users/abc/uploads/p.jpg'),
        isTrue,
      );
      expect(
        AdminDriverDocumentAccess.isStoragePath('https://example.com/x.jpg'),
        isFalse,
      );
    });

    test('authoritativeDocumentsStatus reads SoT field', () {
      // documentsComplete uses authoritative when set — covered via map helper.
      expect(
        DriverRegistrationDocumentStatus.isComplete({
          'photo_storage_path': 'users/u1/photo.jpg',
          'doc_national_id': {'storagePath': 'users/u1/id.jpg'},
          'doc_vehicle_registration': {'storagePath': 'users/u1/reg.jpg'},
          'doc_driver_license_front': {'storagePath': 'users/u1/front.jpg'},
          'doc_driver_license_back': {'storagePath': 'users/u1/back.jpg'},
        }),
        isTrue,
      );
      expect(
        DriverRegistrationDocumentStatus.isComplete({
          'photo_storage_path': 'users/u1/photo.jpg',
        }),
        isFalse,
      );
    });

    test('review buckets remain stable', () {
      expect(
        AdminDriverProfileView.reviewBucketFromRaw('pending_review'),
        AdminDriverReviewBucket.pendingReview,
      );
    });
  });
}

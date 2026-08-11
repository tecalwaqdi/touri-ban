import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ara_oatan_app/backend/firebase_storage/storage.dart';
import 'package:ara_oatan_app/backend/profile_photo_service.dart';

Uint8List _makePng({int w = 1200, int h = 800}) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(80, 140, 200));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('compresses oversized images for storage upload', () {
    final raw = _makePng();
    expect(raw.length, greaterThan(1000));

    final compressed = compressImageBytes(
      raw,
      maxEdge: kUserProfileMaxEdge,
      quality: kUserProfileJpegQuality,
    );
    expect(compressed.length, lessThan(raw.length));

    final decoded = img.decodeImage(compressed)!;
    expect(decoded.width <= kUserProfileMaxEdge, isTrue);
    expect(decoded.height <= kUserProfileMaxEdge, isTrue);
  });

  test('stable profile path overwrites same object', () {
    expect(
      userProfilePhotoStoragePath('uid123'),
      'users/uid123/profile.jpg',
    );
  });

  test('jpegStoragePath normalizes extension once', () {
    expect(
      jpegStoragePath('users/u1/uploads/123.png'),
      'users/u1/uploads/123.jpg',
    );
    expect(
      jpegStoragePath('users/u1/profile.jpg'),
      'users/u1/profile.jpg',
    );
  });

  test('quota errors are detected for fallback', () {
    expect(
      isStorageBillingOrUnavailable(
        'Firebase Storage: Quota for bucket exceeded',
      ),
      isTrue,
    );
    expect(
      shouldFallbackToEmbeddedImage(
        'Firebase Storage: Quota for bucket exceeded',
      ),
      isTrue,
    );
  });

  test('uploadErrorMessage never returns raw exception text', () {
    final mapped = uploadErrorMessage(
      Exception('Firebase Storage: Quota for bucket exceeded'),
    );
    expect(mapped.toLowerCase(), contains('حصة'));
    expect(mapped.toLowerCase(), isNot(contains('exception:')));
  });

  test('firestore embed stays under user profile cap', () {
    final raw = _makePng(w: 2000, h: 1500);
    final out = compressImageBytesForFirestore(
      raw,
      maxEdge: kUserProfileMaxEdge,
      quality: kUserProfileJpegQuality,
      maxBytes: kUserProfileMaxEmbeddedBytes,
    );
    expect(out.length, lessThanOrEqualTo(kUserProfileMaxEmbeddedBytes));
  });
}

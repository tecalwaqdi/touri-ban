import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/backend/admin_media_resolver.dart';

void main() {
  group('AdminMediaResolver.storagePathFrom', () {
    test('parses firebasestorage.googleapis.com download URLs', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/tutorial-multi-language-70gx4j.appspot.com/o/users%2Fabc%2Fuploads%2Fphoto.jpg?alt=media&token=xyz';
      expect(
        AdminMediaResolver.storagePathFrom(url),
        'users/abc/uploads/photo.jpg',
      );
    });

    test('parses gs:// paths', () {
      expect(
        AdminMediaResolver.storagePathFrom(
          'gs://tutorial-multi-language-70gx4j.appspot.com/users/u1/profile.jpg',
        ),
        'users/u1/profile.jpg',
      );
    });

    test('parses bare legacy storage paths', () {
      expect(
        AdminMediaResolver.storagePathFrom('users/u1/uploads/a.jpg'),
        'users/u1/uploads/a.jpg',
      );
      expect(
        AdminMediaResolver.storagePathFrom('landmarks/x/img.png'),
        'landmarks/x/img.png',
      );
    });

    test('returns null for empty / non-storage https', () {
      expect(AdminMediaResolver.storagePathFrom(''), isNull);
      expect(AdminMediaResolver.storagePathFrom('https://cdn.example.com/a.jpg'),
          isNull);
      expect(AdminMediaResolver.storagePathFrom('not-a-path'), isNull);
    });

    test('resolve empty / blank → none', () async {
      final a = await AdminMediaResolver.resolve(null);
      final b = await AdminMediaResolver.resolve('   ');
      expect(a.empty, isTrue);
      expect(b.empty, isTrue);
      expect(a.ok, isFalse);
    });

    test('resolve data-URL → memory bytes', () async {
      // 1x1 PNG
      const dataUrl =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      final r = await AdminMediaResolver.resolve(dataUrl);
      expect(r.hasBytes, isTrue);
      expect(r.bytes!.length, greaterThan(10));
    });

    test('resolve non-storage https → network', () async {
      final r = await AdminMediaResolver.resolve('https://cdn.example.com/x.jpg');
      expect(r.hasNetwork, isTrue);
      expect(r.networkUrl, 'https://cdn.example.com/x.jpg');
    });
  });
}

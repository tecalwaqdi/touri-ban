// ignore_for_file: avoid_print
import 'dart:io';

const _key = 'AIzaSyD0eS7iNUBMP4LYm53TiKzwx1j1Vm_mBdw';

final _tests = [
  ('مطعم القلعة', 21.4225, 39.8262),
  ('حديقة البحيرات', 21.3891, 39.8579),
  ('سوق العزيزية', 21.4312, 39.8277),
];

Future<void> main() async {
  final client = HttpClient();
  for (final (name, lat, lng) in _tests) {
    print('=== $name ===');
    for (final api in ['streetview', 'staticmap']) {
      final uri = api == 'streetview'
          ? Uri.https('maps.googleapis.com', '/maps/api/streetview', {
              'size': '600x400',
              'location': '$lat,$lng',
              'key': _key,
            })
          : Uri.https('maps.googleapis.com', '/maps/api/staticmap', {
              'center': '$lat,$lng',
              'zoom': '16',
              'size': '600x400',
              'maptype': 'satellite',
              'key': _key,
            });
      final req = await client.getUrl(uri);
      final res = await req.close();
      print('$api: ${res.statusCode} ${res.headers.contentType}');
      await res.drain();
    }
    print('');
  }
  client.close();
}

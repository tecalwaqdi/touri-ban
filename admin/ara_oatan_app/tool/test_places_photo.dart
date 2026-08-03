// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const _key = 'AIzaSyD0eS7iNUBMP4LYm53TiKzwx1j1Vm_mBdw';

final _tests = [
  ('مطعم القلعة للشوربة والتقاطيع', 21.4225, 39.8262),
  ('حديقة البحيرات', 21.3891, 39.8579),
  ('سوق العزيزية التجاري', 21.4312, 39.8277),
];

Future<void> main() async {
  final client = HttpClient();
  for (final (name, lat, lng) in _tests) {
    print('=== $name ===');
    final findUri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/findplacefromtext/json',
      {
        'input': name,
        'inputtype': 'textquery',
        'fields': 'photos,place_id,name,formatted_address',
        'locationbias': 'circle:5000@$lat,$lng',
        'key': _key,
      },
    );
    final findRes = await (await client.getUrl(findUri)).close();
    final findBody = await findRes.transform(utf8.decoder).join();
    print('find status: ${findRes.statusCode}');
    final findJson = jsonDecode(findBody) as Map<String, dynamic>;
    print('find api status: ${findJson['status']}');
    if (findJson['candidates'] != null) {
      print('candidates: ${jsonEncode(findJson['candidates'])}');
    }
    final candidates = findJson['candidates'] as List? ?? [];
    if (candidates.isEmpty) {
      print('NO CANDIDATES\n');
      continue;
    }
    final photos = (candidates.first as Map)['photos'] as List?;
    if (photos == null || photos.isEmpty) {
      print('NO PHOTOS\n');
      continue;
    }
    final ref = (photos.first as Map)['photo_reference'];
    final photoUri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/photo',
      {'maxwidth': '800', 'photo_reference': ref, 'key': _key},
    );
    final photoReq = await client.getUrl(photoUri);
    photoReq.followRedirects = false;
    final photoRes = await photoReq.close();
    print('photo status: ${photoRes.statusCode}');
    print('photo location: ${photoRes.headers.value('location')}');
    await photoRes.drain();
    print('');
  }
  client.close();
}

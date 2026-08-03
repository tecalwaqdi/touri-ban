// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const _apiKey = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const _project = 'tutorial-multi-language-70gx4j';

Future<void> main() async {
  final client = HttpClient();
  var pageToken = '';
  var googleCount = 0;
  var jetadminCount = 0;
  var okCount = 0;

  do {
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_project/databases/(default)/documents/mkan?pageSize=300${pageToken.isEmpty ? '' : '&pageToken=$pageToken'}',
    );
    final req = await client.getUrl(uri);
    req.headers.set('X-Goog-Api-Key', _apiKey);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final docs = (json['documents'] as List?) ?? [];

    for (final doc in docs) {
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      final name = _str(fields['naim']);
      final img1 = _str(fields['img1']);
      final docId = (doc['name'] as String).split('/').last;
      if (img1.isEmpty) continue;

      if (img1.contains('googleusercontent.com/gps')) {
        googleCount++;
        print('GOOGLE|$docId|$name|$img1');
      } else if (img1.contains('cdn-api.jetadmin.app')) {
        jetadminCount++;
        print('JETADMIN|$docId|$name|$img1');
      } else {
        final ok = await _probe(client, img1);
        if (!ok) {
          print('OTHER_FAIL|$docId|$name|$img1');
        } else {
          okCount++;
        }
      }
    }
    pageToken = json['nextPageToken'] as String? ?? '';
  } while (pageToken.isNotEmpty);

  print('\nSUMMARY google=$googleCount jetadmin=$jetadminCount ok=$okCount');
  client.close();
}

String _str(dynamic field) {
  if (field is! Map) return '';
  return field['stringValue'] as String? ?? '';
}

Future<bool> _probe(HttpClient client, String url) async {
  try {
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('Accept', 'image/*');
    final res = await req.close();
    await res.drain();
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

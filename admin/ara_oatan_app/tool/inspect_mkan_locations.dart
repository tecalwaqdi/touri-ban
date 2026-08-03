// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const _apiKey = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const _project = 'tutorial-multi-language-70gx4j';

final _targets = [
  'مطعم القلعة',
  'حديقة البحيرات',
  'سوق العزيزية',
  'مكتبة مكة',
];

Future<void> main() async {
  final client = HttpClient();
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_project/databases/(default)/documents/mkan?pageSize=300',
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
    if (!_targets.any((t) => name.contains(t))) continue;

    final loc = fields['Location'] as Map<String, dynamic>?;
    final geo = loc?['geoPointValue'] as Map<String, dynamic>?;
    print('=== $name ===');
    print('img1 host: ${_host(_str(fields['img1']))}');
    print('location: ${geo?['latitude']}, ${geo?['longitude']}');
    print('');
  }
  client.close();
}

String _str(dynamic field) {
  if (field is! Map) return '';
  return field['stringValue'] as String? ?? '';
}

String _host(String url) {
  if (url.isEmpty) return '<empty>';
  try {
    return Uri.parse(url).host;
  } catch (_) {
    return url.substring(0, 40);
  }
}

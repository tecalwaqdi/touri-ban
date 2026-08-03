// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const _apiKey = 'AIzaSyBvPtNGHDZcK6QpxZom1pOrtq0g21MloQY';
const _project = 'tutorial-multi-language-70gx4j';

final _targets = [
  'قلعة',
  'القلعة',
  'بحيرات',
  'عزيزية',
  'مكتبة',
  'عرفة',
  'منى',
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
  if (res.statusCode != 200) {
    print('HTTP ${res.statusCode}');
    exit(1);
  }
  final json = jsonDecode(body) as Map<String, dynamic>;
  final docs = (json['documents'] as List?) ?? [];

  for (final doc in docs) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = _str(fields['naim']);
    if (!_targets.any((t) => name.contains(t))) continue;

    print('=== $name ===');
    for (final key in ['img', 'img1', 'img2', 'img3']) {
      final v = _str(fields[key]);
      if (v.isEmpty) {
        print('$key: <empty>');
      } else {
        print('$key: ${_short(v)}');
        await _probe(client, v);
      }
    }
    print('');
  }
  client.close();
}

String _str(dynamic field) {
  if (field is! Map) return '';
  return field['stringValue'] as String? ?? '';
}

String _short(String s) =>
    s.length <= 120 ? s : '${s.substring(0, 120)}...';

Future<void> _probe(HttpClient client, String raw) async {
  final urls = _candidates(raw);
  for (final url in urls.take(3)) {
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('Accept', 'image/*');
      final res = await req.close();
      final ok = res.statusCode == 200;
      print('  -> ${ok ? "OK" : "FAIL"} ${res.statusCode} $url');
      await res.drain();
      if (ok) return;
    } catch (e) {
      print('  -> ERR $e');
    }
  }
}

List<String> _candidates(String raw) {
  final out = <String>{raw.trim()};
  final u = raw.trim();
  if (u.startsWith('projects/')) {
    out.add(
      'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/$u',
    );
  }
  if (u.startsWith('assets/')) {
    out.add(
      'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/tutorial-multi-language-app-aavlbx/$u',
    );
  }
  if (!u.startsWith('http') && u.contains('/')) {
    out.add(
      'https://firebasestorage.googleapis.com/v0/b/tutorial-multi-language-70gx4j.firebasestorage.app/o/${Uri.encodeComponent(u)}?alt=media',
    );
  }
  if (u.startsWith('http://')) {
    out.add('https://${u.substring(7)}');
  }
  return out.toList();
}

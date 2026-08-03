// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

final _places = [
  'مطعم القلعة للشوربة والتقاطيع مكة',
  'حديقة البحيرات مكة',
  'سوق العزيزية التجاري مكة',
  'قلعة عسفان',
];

Future<void> main() async {
  final client = HttpClient();
  for (final name in _places) {
    print('=== $name ===');
    await _wikiTitle(client, 'ar.wikipedia.org', name);
    await _wikiOpenSearch(client, 'ar.wikipedia.org', name);
    await _commonsSearch(client, name);
    print('');
  }
  client.close();
}

Future<void> _wikiTitle(HttpClient client, String host, String title) async {
  final uri = Uri.https(host, '/w/api.php', {
    'action': 'query',
    'format': 'json',
    'prop': 'pageimages',
    'piprop': 'thumbnail',
    'pithumbsize': '800',
    'titles': title,
  });
  final res = await (await client.getUrl(uri)).close();
  final body = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) {
    print('wiki title FAIL ${res.statusCode}');
    return;
  }
  final json = jsonDecode(body) as Map<String, dynamic>;
  final pages = (json['query'] as Map?)?['pages'] as Map?;
  for (final p in pages?.values ?? []) {
    final page = p as Map<String, dynamic>;
    final thumb = page['thumbnail'] as Map?;
    final missing = page['missing'] != null;
    print('wiki title: missing=$missing thumb=${thumb?['source']}');
  }
}

Future<void> _wikiOpenSearch(HttpClient client, String host, String q) async {
  final uri = Uri.https(host, '/w/api.php', {
    'action': 'opensearch',
    'format': 'json',
    'search': q,
    'limit': '3',
  });
  final res = await (await client.getUrl(uri)).close();
  final body = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) return;
  final json = jsonDecode(body) as List;
  print('opensearch titles: ${json[1]}');
  final titles = (json[1] as List).cast<String>();
  for (final t in titles.take(2)) {
    await _wikiTitle(client, host, t);
  }
}

Future<void> _commonsSearch(HttpClient client, String q) async {
  final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
    'action': 'query',
    'format': 'json',
    'generator': 'search',
    'gsrsearch': q,
    'gsrlimit': '3',
    'prop': 'imageinfo',
    'iiprop': 'url',
    'iiurlwidth': '800',
  });
  final res = await (await client.getUrl(uri)).close();
  final body = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) {
    print('commons FAIL ${res.statusCode}');
    return;
  }
  final json = jsonDecode(body) as Map<String, dynamic>;
  final pages = (json['query'] as Map?)?['pages'] as Map?;
  if (pages == null || pages.isEmpty) {
    print('commons: no results');
    return;
  }
  for (final p in pages.values) {
    final page = p as Map<String, dynamic>;
    final info = (page['imageinfo'] as List?)?.first as Map?;
    print('commons: ${page['title']} -> ${info?['thumburl'] ?? info?['url']}');
  }
}

// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const _ua = 'TouryTaxiApp/1.0 (image-fallback; contact@toury.app)';

Future<void> main() async {
  final client = HttpClient();
  client.userAgent = _ua;
  for (final q in [
    'حديقة البحيرات مكة',
    'سوق العزيزية مكة',
    'مطعم القلعة مكة',
    'قلعة عسفان',
  ]) {
    print('=== $q ===');
    await _nominatim(client, q);
    await _wikiOpenSearch(client, q);
    print('');
  }
  client.close();
}

Future<void> _nominatim(HttpClient client, String q) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': q,
    'format': 'jsonv2',
    'limit': '3',
    'addressdetails': '0',
  });
  final req = await client.getUrl(uri);
  req.headers.set('User-Agent', _ua);
  req.headers.set('Accept-Language', 'ar,en');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  print('nominatim ${res.statusCode}');
  if (res.statusCode != 200) return;
  final list = jsonDecode(body) as List;
  for (final item in list.take(2)) {
    final m = item as Map<String, dynamic>;
    print('  ${m['display_name']}');
    print('  extratags: ${m['extratags']}');
    final wiki = m['extratags']?['wikipedia'] ?? m['extratags']?['wikidata'];
    print('  wiki ref: $wiki');
  }
}

Future<void> _wikiOpenSearch(HttpClient client, String q) async {
  for (final host in ['ar.wikipedia.org', 'en.wikipedia.org']) {
    final uri = Uri.https(host, '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'list': 'search',
      'srsearch': q,
      'srlimit': '2',
    });
    final req = await client.getUrl(uri);
    req.headers.set('User-Agent', _ua);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) continue;
    final json = jsonDecode(body) as Map<String, dynamic>;
    final hits = (json['query'] as Map?)?['search'] as List? ?? [];
    for (final hit in hits) {
      final title = (hit as Map)['title'];
      print('  $host search: $title');
      await _wikiThumb(client, host, title as String);
    }
  }
}

Future<void> _wikiThumb(HttpClient client, String host, String title) async {
  final uri = Uri.https(host, '/w/api.php', {
    'action': 'query',
    'format': 'json',
    'prop': 'pageimages',
    'piprop': 'thumbnail',
    'pithumbsize': '800',
    'titles': title,
  });
  final req = await client.getUrl(uri);
  req.headers.set('User-Agent', _ua);
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body) as Map<String, dynamic>;
  final pages = (json['query'] as Map?)?['pages'] as Map?;
  for (final p in pages?.values ?? []) {
    final thumb = (p as Map)['thumbnail'] as Map?;
    if (thumb?['source'] != null) print('    thumb: ${thumb!['source']}');
  }
}

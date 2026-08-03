import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const kTouryHttpUserAgent =
    'TouryTaxiApp/9.1.8 (Flutter; image-resolver; +https://toury.app)';

final _photoCache = <String, String?>{};
final _inflightResolves = <String, Future<String?>>{};

/// حد أقصى لطلبات ويكيبيديا المتوازية — يمنع عاصفة الشبكة عند تمرير القائمة.
const _maxConcurrentPhotoFetches = 2;
int _activePhotoFetches = 0;
final _photoFetchWaiters = <Completer<void>>[];

Future<T> _withPhotoFetchSlot<T>(Future<T> Function() run) async {
  while (_activePhotoFetches >= _maxConcurrentPhotoFetches) {
    final gate = Completer<void>();
    _photoFetchWaiters.add(gate);
    await gate.future;
  }
  _activePhotoFetches++;
  try {
    return await run();
  } finally {
    _activePhotoFetches--;
    if (_photoFetchWaiters.isNotEmpty) {
      _photoFetchWaiters.removeAt(0).complete();
    }
  }
}

/// روابط لا تعمل داخل التطبيق — تُستبدل أو تُؤجَّل بعد فشل التحميل.
bool touryIsUnreliableHotlinkUrl(String url) {
  final u = url.toLowerCase();
  return u.contains('googleusercontent.com') ||
      u.contains('cdn-api.jetadmin.app') ||
      u.contains('jetadmin.app/');
}

bool touryHasUnreliableImageSources(
  String? primary, [
  List<String?> alternates = const [],
]) {
  for (final raw in [primary, ...alternates]) {
    if (raw == null || raw.trim().isEmpty) continue;
    if (touryIsUnreliableHotlinkUrl(raw.trim())) return true;
  }
  return false;
}

/// هل يوجد رابط صورة موثوق من Firestore (ليس رابط Google/JetAdmin الميت).
bool touryHasReliableImageSources(
  String? primary, [
  List<String?> alternates = const [],
]) {
  for (final raw in [primary, ...alternates]) {
    if (raw == null || raw.trim().isEmpty) continue;
    if (raw.trim().startsWith('data:image/')) return true;
    if (!touryIsUnreliableHotlinkUrl(raw.trim())) return true;
  }
  return false;
}

/// بدائل ثابتة — مُعطَّلة لصالح صور Firestore من تطبيق الأدمن.
String? touryLookupMkanImageOverride({
  String? documentId,
  String? placeName,
}) =>
    null;

/// يجلب صورة بديلة من ويكيبيديا/ويكيداتا عند غياب رابط Firestore.
Future<String?> touryResolvePlacePhotoUrl({
  String? documentId,
  required String placeName,
  double? latitude,
  double? longitude,
}) async {
  final name = placeName.trim();
  if (name.isEmpty) return null;

  final cacheKey = '${documentId ?? ''}|$name@${latitude ?? 0},${longitude ?? 0}';
  if (_photoCache.containsKey(cacheKey)) {
    return _photoCache[cacheKey];
  }

  final existing = _inflightResolves[cacheKey];
  if (existing != null) return existing;

  final future = _withPhotoFetchSlot(() => _resolvePlacePhotoUrlUncached(
        cacheKey: cacheKey,
        name: name,
        latitude: latitude,
        longitude: longitude,
      ));
  _inflightResolves[cacheKey] = future;
  try {
    return await future;
  } finally {
    _inflightResolves.remove(cacheKey);
  }
}

Future<String?> _resolvePlacePhotoUrlUncached({
  required String cacheKey,
  required String name,
  double? latitude,
  double? longitude,
}) async {
  for (final query in _searchQueries(name)) {
    final wiki = await _wikipediaThumbnail(query);
    if (wiki != null) {
      _photoCache[cacheKey] = wiki;
      return wiki;
    }
    final commons = await _commonsThumbnail(query);
    if (commons != null) {
      _photoCache[cacheKey] = commons;
      return commons;
    }
  }

  if (latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite) {
    final wikidata = await _wikidataImageNear(latitude, longitude);
    if (wikidata != null) {
      _photoCache[cacheKey] = wikidata;
      return wikidata;
    }
  }

  _photoCache[cacheKey] = null;
  return null;
}

/// يُمسح عند تغيير صورة المعلم من الأدمن.
void touryInvalidatePlacePhotoCache({String? documentId}) {
  if (documentId == null || documentId.trim().isEmpty) {
    _photoCache.clear();
    return;
  }
  final prefix = '${documentId.trim()}|';
  _photoCache.removeWhere((key, _) => key.startsWith(prefix));
}

bool _looksArabic(String name) => RegExp(r'[\u0600-\u06FF]').hasMatch(name);

List<String> _searchQueries(String name) {
  final out = <String>{name};
  final noParens = name.replaceAll(RegExp(r'[()（）]'), ' ').trim();
  if (noParens.isNotEmpty) out.add(noParens);

  // لا تُلحق «مكة» لكل المعالم — كان يسبب طلبات ويكيبيديا فاشلة لـ KG/UZ/RU.
  if (_looksArabic(name) &&
      (name.contains('مكة') || name.contains('الحرم') || name.contains('كعبة'))) {
    if (!name.contains('مكة المكرمة')) out.add('$noParens مكة المكرمة');
  }

  final words = name.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
  if (words.length > 3) {
    out.add(words.take(3).join(' '));
  }
  return out.where((q) => q.trim().length > 2).take(3).toList();
}

Future<http.Response> _get(Uri uri) => http.get(
      uri,
      headers: const {
        'User-Agent': kTouryHttpUserAgent,
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 8));

Future<String?> _wikipediaThumbnail(String query) async {
  // لغة واحدة أولاً حسب النص — أقل طلبات فاشلة.
  final hosts = _looksArabic(query)
      ? ['ar.wikipedia.org', 'en.wikipedia.org']
      : ['en.wikipedia.org', 'ru.wikipedia.org'];
  for (final host in hosts) {
    try {
      final searchUri = Uri.https(host, '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'list': 'search',
        'srsearch': query,
        'srlimit': '2',
      });
      final searchRes = await _get(searchUri);
      if (searchRes.statusCode != 200) continue;
      final searchJson = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final hits =
          (searchJson['query'] as Map<String, dynamic>?)?['search'] as List? ??
              [];
      for (final hit in hits.take(2)) {
        final title = (hit as Map<String, dynamic>)['title'] as String?;
        final thumb = await _wikipediaTitleThumb(host, title);
        if (thumb != null) return thumb;
      }
    } catch (_) {}
  }
  return null;
}

Future<String?> _wikipediaTitleThumb(String host, String? title) async {
  if (title == null || title.trim().isEmpty) return null;
  try {
    final uri = Uri.https(host, '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'prop': 'pageimages',
      'piprop': 'thumbnail',
      'pithumbsize': '480',
      'titles': title.trim(),
    });
    final res = await _get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final pages =
        (json['query'] as Map<String, dynamic>?)?['pages'] as Map<String, dynamic>?;
    if (pages == null) return null;
    for (final page in pages.values) {
      final p = page as Map<String, dynamic>;
      if (p['missing'] != null) continue;
      final thumb = p['thumbnail'] as Map<String, dynamic>?;
      final src = thumb?['source'] as String?;
      if (src != null && src.isNotEmpty) return src;
    }
  } catch (_) {}
  return null;
}

Future<String?> _commonsThumbnail(String query) async {
  try {
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'generator': 'search',
      'gsrsearch': query,
      'gsrlimit': '3',
      'gsrnamespace': '6',
      'prop': 'imageinfo',
      'iiprop': 'url',
      'iiurlwidth': '480',
    });
    final res = await _get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final pages =
        (json['query'] as Map<String, dynamic>?)?['pages'] as Map<String, dynamic>?;
    if (pages == null || pages.isEmpty) return null;
    for (final page in pages.values) {
      final info = ((page as Map<String, dynamic>)['imageinfo'] as List?)
          ?.cast<Map<String, dynamic>>()
          .firstOrNull;
      final url = info?['thumburl'] as String? ?? info?['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }
  } catch (_) {}
  return null;
}

Future<String?> _wikidataImageNear(double lat, double lng) async {
  try {
    final sparql = '''
SELECT ?image WHERE {
  SERVICE wikibase:around {
    ?place wdt:P625 ?loc .
    bd:serviceParam wikibase:center "Point($lng $lat)"^^geo:wktLiteral .
    bd:serviceParam wikibase:radius "0.8" .
  }
  ?place wdt:P18 ?image .
}
LIMIT 4
''';
    final uri = Uri.https('query.wikidata.org', '/sparql', {
      'query': sparql,
      'format': 'json',
    });
    final res = await _get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final bindings = (json['results'] as Map<String, dynamic>?)?['bindings']
        as List<dynamic>?;
    if (bindings == null) return null;
    for (final row in bindings) {
      final image = (row as Map<String, dynamic>)['image']?['value'] as String?;
      final direct = _wikidataImageToDirectUrl(image);
      if (direct != null) return direct;
    }
  } catch (_) {}
  return null;
}

String? _wikidataImageToDirectUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  if (uri.host.contains('wikimedia.org')) {
    if (uri.path.contains('Special:FilePath/')) {
      return uri.replace(queryParameters: {'width': '480'}).toString();
    }
    return raw;
  }
  return null;
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

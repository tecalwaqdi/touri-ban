import 'package:map_launcher/map_launcher.dart' as ml;

import '/core/toury_content_locale.dart';
import '/flutter_flow/flutter_flow_util.dart';

abstract final class TouryNavigationService {
  TouryNavigationService._();

  static Future<void> openGoogleMapsNavigation({
    required LatLng destination,
    LatLng? origin,
    List<LatLng> waypoints = const [],
    String? localeKey,
    String? destinationTitle,
  }) async {
    final lang = _googleMapsLanguage(localeKey);
    final dest = '${destination.latitude},${destination.longitude}';
    final originPart = origin != null
        ? '&origin=${origin.latitude},${origin.longitude}'
        : '';
    final wp = waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
    final waypointsPart = wp.isNotEmpty ? '&waypoints=$wp' : '';
    final directionsUrl =
        'https://www.google.com/maps/dir/?api=1$originPart&destination=$dest'
        '$waypointsPart&travelmode=driving&hl=$lang&language=$lang';

    try {
      await launchURL(directionsUrl);
      return;
    } catch (_) {}

    await launchMap(
      mapType: ml.MapType.google,
      location: destination,
      title: destinationTitle?.trim().isNotEmpty == true
          ? destinationTitle!.trim()
          : _fallbackDestinationTitle(lang),
    );
  }

  static String localeForContext(dynamic context) {
    try {
      return touryContentLocaleFromContext(context).replaceAll('_', '-');
    } catch (_) {
      return 'en';
    }
  }

  static String _googleMapsLanguage(String? localeKey) {
    final normalized = (localeKey ?? 'en').replaceAll('_', '-').toLowerCase();
    if (normalized.startsWith('zh')) return 'zh-CN';
    if (normalized.startsWith('ar')) return 'ar';
    if (normalized.startsWith('ur')) return 'ur';
    if (normalized.startsWith('fr')) return 'fr';
    if (normalized.startsWith('ru')) return 'ru';
    if (normalized.startsWith('tr')) return 'tr';
    if (normalized.startsWith('id')) return 'id';
    if (normalized.startsWith('az')) return 'az';
    if (normalized.startsWith('ka')) return 'ka';
    if (normalized.startsWith('ky')) return 'ky';
    return 'en';
  }

  static String _fallbackDestinationTitle(String lang) {
    if (lang == 'ar') return 'وجهة الرحلة';
    if (lang == 'ur') return 'سفر کی منزل';
    if (lang == 'fr') return 'Destination du voyage';
    if (lang == 'ru') return 'Пункт назначения';
    if (lang == 'tr') return 'Seyahat hedefi';
    if (lang == 'id') return 'Tujuan perjalanan';
    if (lang == 'az') return 'Səyahət təyinatı';
    if (lang == 'ka') return 'მოგზაურობის დანიშნულება';
    if (lang == 'ky') return 'Сапардын багыты';
    if (lang == 'zh-CN') return '行程目的地';
    return 'Trip destination';
  }
}

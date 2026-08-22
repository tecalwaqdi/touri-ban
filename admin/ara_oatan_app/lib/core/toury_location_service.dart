import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';

import '/app_state.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/core/toury_country_registry.dart';
import '/core/toury_firestore_cache.dart';
import '/core/toury_geo_display.dart';
import '/core/toury_i18n_text.dart';
import '/core/toury_route_metrics.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/internationalization.dart';
import '/flutter_flow/lat_lng.dart';
import 'saudi_city_registry.dart';

/// نتيجة تحديد الموقع الجغرافي والمدينة.
class TouryResolvedLocation {
  const TouryResolvedLocation({
    required this.success,
    this.position,
    this.fullAddress,
    this.countryName,
    this.cityName,
    this.village,
    this.country,
    this.geocodeResponse,
    this.errorMessage,
    this.failure,
    this.resolutionMethod,
    this.countryIso2,
    this.isOutsideCoverage = false,
    this.selectionSource = 'automaticGps',
  });

  final bool success;
  final LatLng? position;
  final String? fullAddress;
  final String? countryName;
  final String? cityName;
  final VillagesRecord? village;
  final CountriesRecord? country;
  final dynamic geocodeResponse;
  final String? errorMessage;
  final TouryLocationFailure? failure;
  final String? resolutionMethod;
  final String? countryIso2;

  /// الموقع خارج الدول المفعّلة في النظام.
  final bool isOutsideCoverage;

  /// automaticGps | lastKnownLocation | mapSelection | manualCountry | …
  final String selectionSource;

  String get coordinatesString => position == null
      ? ''
      : '${functions.latitudeFromLocation(position)},${functions.longFromLocation(position)}';

  String get villageName => village?.naim ?? cityName ?? '';

  bool get hasVillage => village != null;
}

/// نتيجة مزامنة الدولة مع موقع GPS.
class TouryCountrySyncResult {
  const TouryCountrySyncResult({
    required this.gpsResolved,
    this.resolved,
    this.wasCorrected = false,
    this.wasCityCorrected = false,
    this.needsManualSelection = false,
    this.isOutsideCoverage = false,
  });

  final bool gpsResolved;
  final TouryResolvedLocation? resolved;
  final bool wasCorrected;

  /// المدينة المخزّنة لا تطابق موقع GPS الحالي.
  final bool wasCityCorrected;
  final bool needsManualSelection;
  final bool isOutsideCoverage;
}

/// خدمة موحّدة لتحديد الموقع الفعلي وربطه بمدن التطبيق.
abstract final class TouryLocationService {
  static List<VillagesRecord>? _villagesCache;
  static List<CountriesRecord>? _countriesCache;

  static TouryLocationFailure classifyException(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('disabled') || text.contains('location services')) {
      return TouryLocationFailure.serviceDisabled;
    }
    if (text.contains('permanently denied') ||
        text.contains('deniedforever')) {
      return TouryLocationFailure.permissionDeniedForever;
    }
    if (text.contains('denied')) {
      return TouryLocationFailure.permissionDenied;
    }
    if (text.contains('timeout') || text.contains('time limit')) {
      return TouryLocationFailure.timeout;
    }
    if (text.contains('network') || text.contains('socket')) {
      return TouryLocationFailure.networkError;
    }
    return TouryLocationFailure.unknown;
  }

  static String messageForFailure(TouryLocationFailure failure) {
    return failure.l10nKey.tr();
  }

  /// الحصول على موقع GPS بدقة عالية.
  static Future<LatLng?> getHighAccuracyPosition({
    Duration timeout = const Duration(seconds: 25),
    Duration maxLastKnownAge = const Duration(minutes: 5),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    Position? current;
    try {
      current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: timeout,
      );
    } catch (_) {
      // جرّب مصادر أخرى أدناه.
    }

    if (current != null &&
        _isUsableGpsPair(current.latitude, current.longitude) &&
        _positionAccuracyMeters(current) > 200) {
      try {
        final refined = await Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
          ),
        ).first.timeout(const Duration(seconds: 12));
        if (_positionAccuracyMeters(refined) <
            _positionAccuracyMeters(current)) {
          current = refined;
        }
      } catch (_) {}
    }

    if (current != null &&
        _isUsableGpsPair(current.latitude, current.longitude) &&
        _positionAccuracyMeters(current) <= 3000) {
      return LatLng(current.latitude, current.longitude);
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null &&
        _isUsableGpsPair(lastKnown.latitude, lastKnown.longitude) &&
        _isRecentPosition(lastKnown, maxLastKnownAge) &&
        _positionAccuracyMeters(lastKnown) <= 1000) {
      return LatLng(lastKnown.latitude, lastKnown.longitude);
    }

    try {
      final coarse = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );
      if (_isUsableGpsPair(coarse.latitude, coarse.longitude)) {
        return LatLng(coarse.latitude, coarse.longitude);
      }
    } catch (e) {
      final failure = classifyException(e);
      if (failure == TouryLocationFailure.timeout) {
        throw Exception('Location request timeout');
      }
      rethrow;
    }

    return null;
  }

  /// Reject null-island (0,0) only — a single axis of 0 can be valid.
  static bool _isUsableGpsPair(double latitude, double longitude) {
    if (latitude.isNaN ||
        longitude.isNaN ||
        latitude.isInfinite ||
        longitude.isInfinite) {
      return false;
    }
    if (latitude == 0 && longitude == 0) return false;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static double _positionAccuracyMeters(Position position) {
    final accuracy = position.accuracy;
    if (accuracy.isNaN || accuracy < 0) return double.infinity;
    return accuracy;
  }

  static bool _isRecentPosition(Position position, Duration maxAge) {
    final age = DateTime.now().difference(position.timestamp);
    return age >= Duration.zero && age <= maxAge;
  }

  /// إحداثيات GPS فعلية أو null — بدون إحداثيات افتراضية.
  static Future<LatLng?> getUserPositionOrNull() async {
    try {
      return await getHighAccuracyPosition();
    } catch (_) {
      return null;
    }
  }

  /// تحديد الموقع الحالي كاملاً: GPS + Geocoding + مطابقة المدينة.
  static Future<TouryResolvedLocation> resolveCurrentLocation() async {
    try {
      final position = await getHighAccuracyPosition();
      if (position == null) {
        return TouryResolvedLocation(
          success: false,
          failure: TouryLocationFailure.timeout,
          errorMessage: messageForFailure(TouryLocationFailure.timeout),
        );
      }
      return resolveFromCoordinates(position);
    } catch (e) {
      final failure = classifyException(e);
      return TouryResolvedLocation(
        success: false,
        failure: failure,
        errorMessage: messageForFailure(failure),
      );
    }
  }

  /// تحليل إحداثيات معيّنة وربطها بمدينة التطبيق.
  static Future<TouryResolvedLocation> resolveFromCoordinates(
    LatLng position, {
    String selectionSource = 'automaticGps',
  }) async {
    final bboxIso = TouryCountryRegistry.isoFromCoordinates(position);
    final inSaudi = bboxIso == 'SA' ||
        SaudiCityRegistry.isWithinSaudiArabia(position);
    final bboxCity =
        inSaudi ? SaudiCityRegistry.cityFromCoordinates(position) : null;

    final geocode = await _reverseGeocode(
      position,
      countryCode: bboxIso?.toLowerCase(),
    );

    if (!geocode.succeeded) {
      return _resolveWithoutGeocode(
        position,
        bboxCity,
        bboxIso: bboxIso,
        selectionSource: selectionSource,
      );
    }

    final iso = TouryCountryRegistry.normalizeIso(geocode.countryCode) ??
        TouryCountryRegistry.normalizeIso(geocode.countryName) ??
        bboxIso;

    // Never invent Saudi Arabia when geocode omitted the country.
    final countryName = geocode.countryName;

    final villageResult = await _matchVillage(
      position: position,
      candidates: [
        if (geocode.cityName != null) geocode.cityName!,
        ...geocode.candidates,
        if (bboxCity != null) bboxCity.displayNameAr,
        ...?bboxCity?.aliases,
      ],
      bboxCity: bboxCity,
      countryIso2: iso,
    );

    final country = await _matchCountry(
      countryName,
      position,
      bboxCity,
      countryCode: iso ?? geocode.countryCode,
    );
    final outsideCoverage = country == null && iso == null;

    return TouryResolvedLocation(
      success: !outsideCoverage &&
          (villageResult.village != null ||
              geocode.cityName != null ||
              country != null),
      position: position,
      fullAddress: geocode.fullAddress,
      countryName:
          outsideCoverage ? null : (country?.naim ?? countryName),
      cityName: outsideCoverage
          ? null
          : (villageResult.village?.naim ??
              geocode.cityName ??
              bboxCity?.displayNameAr),
      village: outsideCoverage ? null : villageResult.village,
      country: country,
      countryIso2: iso ??
          TouryCountryRegistry.normalizeIso(country?.isoCode) ??
          TouryCountryRegistry.normalizeIso(country?.reference.id),
      geocodeResponse: geocode.raw,
      resolutionMethod: villageResult.method,
      isOutsideCoverage: outsideCoverage,
      selectionSource: selectionSource,
      failure: outsideCoverage
          ? TouryLocationFailure.unsupportedCountry
          : (villageResult.village == null && geocode.cityName == null
              ? TouryLocationFailure.noMatchingCity
              : null),
      errorMessage: outsideCoverage
          ? messageForFailure(TouryLocationFailure.unsupportedCountry)
          : (villageResult.village == null && geocode.cityName == null
              ? messageForFailure(TouryLocationFailure.noMatchingCity)
              : null),
    );
  }

  static Future<
      ({
        bool succeeded,
        dynamic raw,
        String? cityName,
        String? countryName,
        String? countryCode,
        String? fullAddress,
        List<String> candidates,
      })> _reverseGeocode(
    LatLng position, {
    String? countryCode,
  }) async {
    final lat = functions.latitudeFromLocation(position) ??
        position.latitude.toString();
    final lng =
        functions.longFromLocation(position) ?? position.longitude.toString();

    final openCage = await PENmdenhCall.call(
      io: '$lat,$lng',
      countryCode: countryCode,
      language: _geocodingLanguage(),
    );
    if (!openCage.succeeded) {
      return (
        succeeded: false,
        raw: null,
        cityName: null,
        countryName: null,
        countryCode: null,
        fullAddress: null,
        candidates: <String>[],
      );
    }

    final json = openCage.jsonBody;
    return (
      succeeded: true,
      raw: json,
      cityName: PENmdenhCall.resolveCityName(json),
      countryName: PENmdenhCall.dolh(json),
      countryCode: PENmdenhCall.countryCode(json),
      fullAddress: PENmdenhCall.fullAdress(json),
      candidates: PENmdenhCall.placeNameCandidates(json),
    );
  }

  static String _geocodingLanguage() {
    final locale = FFLocalizations.getStoredLocale();
    final code = locale?.languageCode ?? 'en';
    if (code == 'ar') return 'ar';
    if (code == 'ru') return 'ru';
    if (code == 'ky') return 'ky';
    return code == 'zh' ? 'zh-CN' : 'en';
  }

  static Future<TouryResolvedLocation> _resolveWithoutGeocode(
    LatLng position,
    SaudiCityDefinition? bboxCity, {
    String? bboxIso,
    String selectionSource = 'automaticGps',
  }) async {
    final iso = bboxIso ?? TouryCountryRegistry.isoFromCoordinates(position);
    final inSaudi =
        iso == 'SA' || SaudiCityRegistry.isWithinSaudiArabia(position);

    if (!inSaudi && iso == null) {
      return TouryResolvedLocation(
        success: false,
        position: position,
        resolutionMethod: 'geocode_unavailable',
        isOutsideCoverage: false,
        selectionSource: selectionSource,
        failure: TouryLocationFailure.geocodingFailure,
        errorMessage:
            messageForFailure(TouryLocationFailure.geocodingFailure),
      );
    }

    final villageResult = await _matchVillage(
      position: position,
      candidates: bboxCity == null
          ? const []
          : SaudiCityRegistry.allSearchTermsFor(bboxCity),
      bboxCity: bboxCity,
      countryIso2: iso,
    );

    final country = await _matchCountry(
      null,
      position,
      bboxCity,
      countryCode: iso,
    );
    final outsideCoverage = country == null && iso == null;

    return TouryResolvedLocation(
      success: !outsideCoverage &&
          (villageResult.village != null ||
              bboxCity != null ||
              country != null),
      position: position,
      countryName: outsideCoverage ? null : country?.naim,
      cityName: outsideCoverage
          ? null
          : (villageResult.village?.naim ?? bboxCity?.displayNameAr),
      village: outsideCoverage ? null : villageResult.village,
      country: country,
      countryIso2: iso,
      resolutionMethod: villageResult.method ?? 'bbox_fallback',
      isOutsideCoverage: outsideCoverage,
      selectionSource: selectionSource,
      failure: outsideCoverage
          ? TouryLocationFailure.unsupportedCountry
          : (villageResult.village == null && bboxCity == null
              ? TouryLocationFailure.noMatchingCity
              : null),
      errorMessage: outsideCoverage
          ? messageForFailure(TouryLocationFailure.unsupportedCountry)
          : (villageResult.village == null && bboxCity == null
              ? messageForFailure(TouryLocationFailure.noMatchingCity)
              : null),
    );
  }

  static Future<({VillagesRecord? village, String? method})> _matchVillage({
    required LatLng position,
    required List<String> candidates,
    SaudiCityDefinition? bboxCity,
    String? countryIso2,
  }) async {
    final villages = await _loadActiveVillages();
    final scoped = _filterVillagesByCountryIso(villages, countryIso2);
    final normalizedCandidates = candidates
        .map(SaudiCityRegistry.normalizePlaceName)
        .where((s) => s.isNotEmpty)
        .toSet();

    for (final candidate in normalizedCandidates) {
      final match = _findByNormalizedName(scoped, candidate);
      if (match != null) {
        return (village: match, method: 'name_match');
      }
    }

    if (countryIso2 == null || countryIso2.toUpperCase() == 'SA') {
      SaudiCityDefinition? cityDef = bboxCity;
      cityDef ??= SaudiCityRegistry.cityFromName(candidates.firstOrNull);
      if (cityDef != null) {
        for (final term in SaudiCityRegistry.allSearchTermsFor(cityDef)) {
          final norm = SaudiCityRegistry.normalizePlaceName(term);
          final match = _findByNormalizedName(scoped, norm);
          if (match != null) {
            return (village: match, method: 'registry_${cityDef.key.name}');
          }
        }
      }
    }

    final nearest = _findNearestVillage(
      scoped,
      position,
      maxKm: bboxCity != null ? 35 : 45,
      bboxCity: bboxCity,
    );
    if (nearest != null) {
      return (
        village: nearest.record,
        method: 'nearest_${nearest.km.toStringAsFixed(1)}km'
      );
    }

    return (village: null, method: null);
  }

  static List<VillagesRecord> _filterVillagesByCountryIso(
    List<VillagesRecord> villages,
    String? countryIso2,
  ) {
    if (countryIso2 == null || countryIso2.isEmpty) return villages;
    final iso = countryIso2.toUpperCase();
    final aliasIds = TouryCountryRegistry.aliasDocIdsForIso(iso);
    final filtered = villages.where((v) {
      final dolhId = v.dolh?.id;
      if (dolhId != null && aliasIds.contains(dolhId)) return true;
      final id = v.reference.id.toLowerCase();
      if (iso == 'SA' &&
          (id.contains('_sa_') ||
              id.startsWith('city_makkah') ||
              id.startsWith('city_jeddah') ||
              id.startsWith('city_riyadh'))) {
        return true;
      }
      if (iso == 'KG' &&
          (id.contains('_kg_') ||
              id.contains('bishkek') ||
              id.contains('osh'))) {
        return true;
      }
      if (iso == 'RU' && id.contains('_ru_')) return true;
      if (iso == 'UZ' && id.contains('_uz_')) return true;
      return false;
    }).toList();
    return filtered.isNotEmpty ? filtered : villages;
  }

  static VillagesRecord? _findByNormalizedName(
    List<VillagesRecord> villages,
    String normalizedCandidate,
  ) {
    if (normalizedCandidate.isEmpty) return null;
    VillagesRecord? best;
    var bestScore = 0;
    for (final village in villages) {
      final fields = [
        village.naim,
        village.naimciteText,
        village.naimViilMap,
        village.osf,
      ];
      for (final field in fields) {
        final norm = SaudiCityRegistry.normalizePlaceName(field);
        if (norm.isEmpty) continue;
        final score =
            SaudiCityRegistry.nameMatchScore(norm, normalizedCandidate);
        if (score > bestScore) {
          bestScore = score;
          best = village;
        }
      }
    }
    return bestScore > 0 ? best : null;
  }

  static ({VillagesRecord record, double km})? _findNearestVillage(
    List<VillagesRecord> villages,
    LatLng position, {
    required double maxKm,
    SaudiCityDefinition? bboxCity,
  }) {
    Iterable<VillagesRecord> pool = villages;
    if (bboxCity != null) {
      final terms = SaudiCityRegistry.allSearchTermsFor(bboxCity)
          .map(SaudiCityRegistry.normalizePlaceName)
          .where((s) => s.isNotEmpty)
          .toSet();
      final inCity = villages.where((village) {
        final names = [
          village.naim,
          village.naimciteText,
          village.naimViilMap,
          village.osf,
        ].map(SaudiCityRegistry.normalizePlaceName);
        return names.any(
          (name) => terms.any(
            (term) => SaudiCityRegistry.nameMatchScore(name, term) > 0,
          ),
        );
      }).toList();
      if (inCity.isNotEmpty) {
        pool = inCity;
      }
    }

    VillagesRecord? best;
    double bestKm = double.infinity;
    for (final village in pool) {
      final coords = village.latLing;
      if (coords == null) continue;
      final km = functions.geoDistance(position, coords) ?? double.infinity;
      if (km <= maxKm && km < bestKm) {
        bestKm = km;
        best = village;
      }
    }
    if (best == null) return null;
    return (record: best, km: bestKm);
  }

  static Future<CountriesRecord?> _matchCountry(
    String? countryName,
    LatLng position,
    SaudiCityDefinition? bboxCity, {
    String? countryCode,
  }) async {
    final countries = await _loadCountries();
    final iso = TouryCountryRegistry.normalizeIso(countryCode) ??
        TouryCountryRegistry.normalizeIso(countryName) ??
        TouryCountryRegistry.isoFromCoordinates(position);

    if (iso != null) {
      final preferred = TouryCountryRegistry.preferCanonicalCountry(
        countries: countries,
        idOf: (c) => c.reference.id,
        isoOf: (c) => c.isoCode,
        iso: iso,
      );
      if (preferred != null) return preferred;

      final aliases = TouryCountryRegistry.aliasDocIdsForIso(iso);
      final byId =
          countries.where((c) => aliases.contains(c.reference.id)).toList();
      if (byId.isNotEmpty) {
        final preferredId = TouryCountryRegistry.preferredCountryDocId(iso);
        return byId.firstWhere(
          (c) => c.reference.id == preferredId,
          orElse: () => byId.first,
        );
      }
    }

    if (bboxCity != null || SaudiCityRegistry.isWithinSaudiArabia(position)) {
      return _findSaudiCountry(countries);
    }

    for (final country in countries) {
      final sw = country.boundsSw;
      final ne = country.boundsNe;
      if (sw == null || ne == null) continue;
      if (position.latitude >= sw.latitude &&
          position.latitude <= ne.latitude &&
          position.longitude >= sw.longitude &&
          position.longitude <= ne.longitude) {
        return country;
      }
    }

    if (countryName == null || countryName.isEmpty) return null;
    final norm = SaudiCityRegistry.normalizePlaceName(countryName);
    for (final country in countries) {
      final names = [
        country.naim,
        country.naimEnglesh,
        country.osf,
        ...country.namesI18n.values,
      ];
      for (final name in names) {
        final n = SaudiCityRegistry.normalizePlaceName(name);
        if (SaudiCityRegistry.namesMatch(n, norm)) {
          return country;
        }
      }
    }
    return null;
  }

  static CountriesRecord? _findSaudiCountry(List<CountriesRecord> countries) {
    return TouryCountryRegistry.preferCanonicalCountry(
          countries: countries.where((c) => c.saudi),
          idOf: (c) => c.reference.id,
          isoOf: (c) => c.isoCode.isNotEmpty ? c.isoCode : 'SA',
          iso: 'SA',
        ) ??
        TouryCountryRegistry.preferCanonicalCountry(
          countries: countries,
          idOf: (c) => c.reference.id,
          isoOf: (c) => c.isoCode,
          iso: 'SA',
        );
  }

  /// هل اسمَي الدولة يشيران لنفس الدولة؟
  static bool countryNamesMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    final isoA = TouryCountryRegistry.normalizeIso(a);
    final isoB = TouryCountryRegistry.normalizeIso(b);
    if (isoA != null && isoB != null && isoA == isoB) return true;
    final na = SaudiCityRegistry.normalizePlaceName(a);
    final nb = SaudiCityRegistry.normalizePlaceName(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  /// هل اسمَي المدينة يشيران لنفس المدينة؟
  static bool cityNamesMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    if (SaudiCityRegistry.namesMatch(a, b)) return true;
    final na = SaudiCityRegistry.normalizePlaceName(a);
    final nb = SaudiCityRegistry.normalizePlaceName(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  static bool _locationFarFromStored(LatLng gps, LatLng? stored,
      {double maxKm = 35}) {
    if (stored == null) return false;
    final km = functions.geoDistance(gps, stored) ?? 0;
    return km > maxKm;
  }

  /// When true, GPS sync must not overwrite or clear the user's manual country.
  static bool manualCountryLock = false;

  /// Clear dependent geo state when the user switches country manually.
  static void clearDependentGeoState() {
    final app = FFAppState();
    app.update(() {
      app.villa = null;
      app.villnow = null;
      app.vil = null;
      app.mdenh = null;
      app.naimvillatext = '';
      app.villtextnow = '';
      app.naimmdenh = '';
      app.latlngvill = null;
      app.mapNEW = null;
      app.ismapview = false;
      app.addcart = 0;
      app.cartmkss = [];
      app.cartPriceSummary = [];
      app.saatcar = 0;
      app.addhors = 0;
      app.totalsaat = 0;
      app.totalsaatandcar = 0;
      app.srtypecar = 0;
      app.typecarRev = null;
      app.tebycar = '';
      app.notcar = '';
      app.msegAi = '';
      app.textallAlmdn = '';
      app.totalApp = 0.0;
      app.TOTALmndob = 0.0;
      app.vat = 0.0;
      app.totalAllNew = 0.0;
      app.totalapp2 = 0;
      app.totalAllNow2 = 0;
      app.vat2 = 0;
      app.TOTALmndob2 = 0;
      app.AllowBooking = false;
    });
  }

  /// Apply a manually chosen country and wipe previous country data.
  static void applyManualCountry(CountriesRecord country) {
    clearDependentGeoState();
    manualCountryLock = true;
    final localeKey = touryActiveContentLocaleKey();
    final app = FFAppState();
    app.update(() {
      app.dolh = country.reference;
      app.naimdolh = touryLocalizedCountryLabel(country, localeKey);
      app.imgDolh = country.img;
      app.VatDolh = country.vat;
      app.isVat = country.isvat;
      app.RMZCurrency = country.currencySymbol;
      app.AllowBooking = false;
    });
    clearCache();
  }

  /// تحديث المدينة/الدولة المحفوظة من GPS.
  static void applyResolvedToAppState(TouryResolvedLocation resolved) {
    if (resolved.isOutsideCoverage) return;

    final localeKey = touryActiveContentLocaleKey();
    final app = FFAppState();
    app.update(() {
      if (resolved.country != null) {
        final country = resolved.country!;
        app.dolh = country.reference;
        app.naimdolh = touryLocalizedCountryLabel(country, localeKey);
        // GPS path previously skipped tax flags → checkout showed VAT 0%.
        app.VatDolh = country.vat;
        app.isVat = country.isvat;
        if (country.currencySymbol.isNotEmpty) {
          app.RMZCurrency = country.currencySymbol;
        }
      } else if (resolved.countryName != null &&
          resolved.countryName!.isNotEmpty) {
        final name = resolved.countryName!;
        if (localeKey == 'ar' || !touryLooksArabic(name)) {
          app.naimdolh = name;
        }
      }

      if (resolved.village != null) {
        final village = resolved.village!;
        app.villa = village.reference;
        app.villnow = village.reference;
        app.vil = village.reference;
        app.naimvillatext = touryLocalizedVillageLabel(village, localeKey);
        app.villtextnow = app.naimvillatext;
        app.naimmdenh = touryLocalizedCityCiteLabel(village, localeKey);
        app.mdenh = village.cities;
      } else if (resolved.cityName != null && resolved.cityName!.isNotEmpty) {
        final city = resolved.cityName!;
        if (localeKey == 'ar' || !touryLooksArabic(city)) {
          app.naimvillatext = city;
          app.villtextnow = city;
        }
      }

      if (resolved.position != null) {
        app.latlngvill = resolved.position;
        app.mkanuserorder = resolved.position;
        app.akrLoceshn = resolved.position;
        app.LOceshtoaddAdress = resolved.coordinatesString;
      }

      if (resolved.fullAddress != null && resolved.fullAddress!.isNotEmpty) {
        app.fullAdress = resolved.fullAddress!;
      }
      app.AllowBooking = true;
      app.IsLnstantAddress = true;
    });

    if (resolved.village != null) {
      TouryFirestoreCache.prefetchMkanFirstPage(resolved.village!.reference);
    }
  }

  /// Re-resolve stored country/city display names after a language change.
  /// Also refreshes VAT / currency from the country doc (Admin vat_percent).
  static Future<void> refreshStoredGeoLabels() async {
    final app = FFAppState();
    final localeKey = touryActiveContentLocaleKey();
    try {
      final countryRef = app.dolh;
      if (countryRef != null) {
        final country = await CountriesRecord.getDocumentOnce(countryRef);
        app.naimdolh = touryLocalizedCountryLabel(country, localeKey);
        applyCountryTaxFlags(country, notify: false);
      }
      final villageRef = app.villnow ?? app.villa ?? app.vil;
      if (villageRef != null) {
        final village = await VillagesRecord.getDocumentOnce(villageRef);
        app.naimvillatext = touryLocalizedVillageLabel(village, localeKey);
        app.villtextnow = app.naimvillatext;
        app.naimmdenh = touryLocalizedCityCiteLabel(village, localeKey);
        // Keep map camera aligned with the village label (avoids Makkah text
        // while camera sits on stale GPS / ocean fallback).
        if (touryIsValidCoordinate(village.latLing)) {
          app.latlngvill = village.latLing;
        }
      }
      app.update(() {});
    } catch (e) {
      // ignore: avoid_print
      print('refreshStoredGeoLabels failed: $e');
    }
  }

  /// Sync FFAppState VAT flags from a countries doc (supports vat + vat_percent).
  static void applyCountryTaxFlags(
    CountriesRecord country, {
    bool notify = true,
  }) {
    void write() {
      final app = FFAppState();
      app.VatDolh = country.vat;
      app.isVat = country.isvat;
      if (country.currencySymbol.isNotEmpty) {
        app.RMZCurrency = country.currencySymbol;
      }
    }

    if (notify) {
      FFAppState().update(write);
    } else {
      write();
    }
  }

  /// Reload active country from Firestore and refresh tax/pricing flags.
  static Future<void> refreshActiveCountryTaxFlags() async {
    final countryRef = FFAppState().dolh;
    if (countryRef == null) return;
    try {
      final country = await CountriesRecord.getDocumentOnce(countryRef);
      applyCountryTaxFlags(country);
    } catch (e) {
      // ignore: avoid_print
      print('refreshActiveCountryTaxFlags failed: $e');
    }
  }

  static Future<bool> syncPersistedLocationFromGps() async {
    try {
      final resolved = await resolveCurrentLocation();
      if (resolved.position == null || resolved.isOutsideCoverage) {
        return false;
      }
      applyResolvedToAppState(resolved);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// مزامنة الدولة المخزّنة مع موقع GPS الحالي.
  static Future<TouryCountrySyncResult> syncCountryFromGps({
    String? storedCountryName,
    DocumentReference? storedCountryRef,
    String? storedCityName,
    LatLng? storedCityCoords,
  }) async {
    final resolved = await resolveCurrentLocation();
    if (resolved.position == null) {
      return const TouryCountrySyncResult(gpsResolved: false);
    }

    if (resolved.isOutsideCoverage) {
      return TouryCountrySyncResult(
        gpsResolved: true,
        resolved: resolved,
        isOutsideCoverage: true,
      );
    }

    final detected = resolved.country;
    final detectedName = detected?.naim ?? resolved.countryName ?? '';
    final detectedCity = resolved.village?.naim ?? resolved.cityName ?? '';
    final hasStored =
        storedCountryName != null && storedCountryName.trim().isNotEmpty;
    final hasStoredCity =
        storedCityName != null && storedCityName.trim().isNotEmpty;

    final cityMismatch = hasStoredCity &&
        detectedCity.isNotEmpty &&
        !cityNamesMatch(storedCityName, detectedCity);
    final distanceMismatch = _locationFarFromStored(
      resolved.position!,
      storedCityCoords,
    );
    final wasCityCorrected = cityMismatch || distanceMismatch;

    if (!hasStored) {
      return TouryCountrySyncResult(
        gpsResolved: true,
        resolved: resolved,
        wasCorrected: detectedName.isNotEmpty,
        wasCityCorrected: detectedCity.isNotEmpty,
      );
    }

    final storedIso = TouryCountryRegistry.normalizeIso(storedCountryRef?.id) ??
        TouryCountryRegistry.normalizeIso(storedCountryName);
    final detectedIso = resolved.countryIso2 ??
        TouryCountryRegistry.normalizeIso(detected?.isoCode) ??
        TouryCountryRegistry.normalizeIso(detected?.reference.id) ??
        TouryCountryRegistry.normalizeIso(detectedName);

    final refMatches = detected != null &&
        storedCountryRef != null &&
        (storedCountryRef.path == detected.reference.path ||
            (storedIso != null &&
                detectedIso != null &&
                storedIso == detectedIso));

    if (refMatches ||
        countryNamesMatch(storedCountryName, detectedName) ||
        (storedIso != null &&
            detectedIso != null &&
            storedIso == detectedIso)) {
      if (wasCityCorrected) {
        return TouryCountrySyncResult(
          gpsResolved: true,
          resolved: resolved,
          wasCityCorrected: true,
        );
      }
      return TouryCountrySyncResult(
        gpsResolved: true,
        resolved: resolved,
      );
    }

    return TouryCountrySyncResult(
      gpsResolved: true,
      resolved: resolved,
      wasCorrected: true,
      wasCityCorrected: wasCityCorrected,
      needsManualSelection: detected == null,
    );
  }

  static Future<List<VillagesRecord>> _loadActiveVillages() async {
    if (_villagesCache != null) return _villagesCache!;
    _villagesCache = await queryVillagesRecordOnce(
      queryBuilder: (q) => q.where('acctev', isEqualTo: true),
    );
    return _villagesCache!;
  }

  static Future<List<CountriesRecord>> _loadCountries() async {
    if (_countriesCache != null) return _countriesCache!;
    _countriesCache = await queryCountriesRecordOnce(
      queryBuilder: (q) => q.where('acctev', isEqualTo: true),
    );
    return _countriesCache!;
  }

  static void clearCache() {
    _villagesCache = null;
    _countriesCache = null;
  }

  static Future<void> refreshCache() async {
    clearCache();
    await warmCache();
  }

  static Future<void> warmCache() async {
    try {
      await Future.wait([
        _loadActiveVillages(),
        _loadCountries(),
      ]);
    } catch (_) {}
  }
}

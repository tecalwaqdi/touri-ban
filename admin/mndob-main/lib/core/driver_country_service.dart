
import 'package:flutter/foundation.dart';

import '/backend/schema/countries_record.dart';
import '/core/toury_country_registry.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// تحديد دولة المندوب من لغة/منطقة الجهاز، مع تفضيل المستند الكانوني.
abstract final class DriverCountryService {
  DriverCountryService._();

  static List<CountriesRecord>? _cache;

  static Future<List<CountriesRecord>> _activeCountries({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) return _cache!;
    try {
      final list = await CountriesRecord.collection
          .where('acctev', isEqualTo: true)
          .get()
          .then((s) => s.docs.map(CountriesRecord.fromSnapshot).toList());
      _cache = list;
      return list;
    } catch (e) {
      debugPrint('DriverCountryService._activeCountries failed: $e');
      // Do not cache failures — auth/rules may become available a moment later.
      rethrow;
    }
  }

  static void clearCache() => _cache = null;

  /// ISO من مرجع/معرّف الدولة.
  static String? isoOfCountry(CountriesRecord c) {
    final fromId = TouryCountryRegistry.normalizeIso(c.reference.id);
    if (fromId != null) return fromId;
    final fromOsf = TouryCountryRegistry.normalizeIso(c.osf);
    if (fromOsf != null) return fromOsf;
    return TouryCountryRegistry.normalizeIso(c.naim);
  }

  /// يحوّل أي مرجع دولة إلى المستند المفضّل الذي ترتبط به المدن
  /// (مثل kyrgyzstan بدل country_kg، و saudi_arabia بدل saudi-arabia).
  static Future<CountriesRecord?> canonicalize(CountriesRecord? country) async {
    if (country == null) return null;
    final iso = isoOfCountry(country);
    if (iso == null) return country;

    final preferredId = TouryCountryRegistry.preferredCountryDocId(iso);
    if (preferredId == null || preferredId == country.reference.id) {
      return country;
    }

    List<CountriesRecord> countries;
    try {
      countries = await _activeCountries();
    } catch (_) {
      return country;
    }
    final preferred = countries
        .where((c) => c.reference.id == preferredId)
        .firstOrNull;
    if (preferred != null) return preferred;

    // المستند المفضّل قد يكون موجوداً دون acctev — نجرب الجلب المباشر.
    try {
      final snap = await FirebaseFirestore.instance
          .collection('countries')
          .doc(preferredId)
          .get();
      if (snap.exists) return CountriesRecord.fromSnapshot(snap);
    } catch (_) {}
    return country;
  }

  static Future<CountriesRecord?> resolveFromDevice() async {
    List<CountriesRecord> countries;
    try {
      countries = await _activeCountries();
    } catch (e) {
      debugPrint('DriverCountryService.resolveFromDevice failed: $e');
      return null;
    }
    if (countries.isEmpty) return null;

    final locale = PlatformDispatcher.instance.locale;
    final cc = locale.countryCode?.toUpperCase();

    CountriesRecord? picked;

    if (cc != null && cc.isNotEmpty) {
      picked = TouryCountryRegistry.preferCanonicalCountry<CountriesRecord>(
        countries: countries,
        iso: cc,
        isoOf: (c) => isoOfCountry(c) ?? '',
        idOf: (c) => c.reference.id,
      );
      if (picked == null) {
        for (final c in countries) {
          if (isoOfCountry(c) == cc) {
            picked = c;
            break;
          }
        }
      }
    }

    if (picked == null &&
        locale.languageCode.toLowerCase() == 'ar' &&
        (cc == null || cc.isEmpty)) {
      picked = TouryCountryRegistry.preferCanonicalCountry<CountriesRecord>(
            countries: countries,
            iso: 'SA',
            isoOf: (c) => isoOfCountry(c) ?? '',
            idOf: (c) => c.reference.id,
          ) ??
          countries.where((c) => c.saudi).firstOrNull;
    }

    if (picked == null) {
      final langIso = TouryCountryRegistry.normalizeIso(locale.languageCode);
      if (langIso != null) {
        picked = TouryCountryRegistry.preferCanonicalCountry<CountriesRecord>(
          countries: countries,
          iso: langIso,
          isoOf: (c) => isoOfCountry(c) ?? '',
          idOf: (c) => c.reference.id,
        );
      }
    }

    picked ??= countries.first;
    return canonicalize(picked);
  }

  static Future<void> primeRegistrationCountry(FFAppState app) async {
    // حتى لو كان dolh قديماً (country_kg / saudi-arabia) نُصحّحه للمستند الكانوني.
    if (app.dolh != null) {
      final countries = await _activeCountries();
      final current = countries
          .where((c) => c.reference.path == app.dolh!.path)
          .firstOrNull;
      final fixed = await canonicalize(current);
      if (fixed != null) {
        app.dolh = fixed.reference;
        app.naimdolh = fixed.naim;
      }
      return;
    }

    final country = await resolveFromDevice();
    if (country == null) return;
    app.dolh = country.reference;
    app.naimdolh = country.naim;
  }

  static Future<void> applyCountry(
    FFAppState app,
    CountriesRecord country,
  ) async {
    final fixed = await canonicalize(country) ?? country;
    app.dolh = fixed.reference;
    app.naimdolh = fixed.naim;
    app.mdenh = null;
    app.naimmdenh = '';
    app.villmndoBREV = null;
    app.textvill = '';
  }

  static Future<List<CountriesRecord>> listActiveCountries({
    bool forceRefresh = false,
  }) async {
    final list = await _activeCountries(forceRefresh: forceRefresh);
    final byIso = <String, CountriesRecord>{};
    for (final c in list) {
      final iso = isoOfCountry(c);
      if (iso == null) {
        byIso.putIfAbsent(c.reference.id, () => c);
        continue;
      }
      final preferredId = TouryCountryRegistry.preferredCountryDocId(iso);
      final existing = byIso[iso];
      if (existing == null) {
        byIso[iso] = c;
      } else if (preferredId != null && c.reference.id == preferredId) {
        byIso[iso] = c;
      }
    }
    final out = byIso.values.toList()
      ..sort((a, b) => a.naim.compareTo(b.naim));
    return out;
  }

  static String? currentIso2() {
    final ref = FFAppState().dolh;
    if (ref == null) return null;
    return TouryCountryRegistry.normalizeIso(ref.id);
  }
}

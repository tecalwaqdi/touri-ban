import '/backend/schema/countries_record.dart';
import '/backend/schema/type_car_record.dart';

enum AdminDriverMarketStatus {
  ready,
  missingDriverRequirements,
  missingVehicleCatalog,
  incomplete,
}

class AdminDriverMarketReadiness {
  const AdminDriverMarketReadiness({
    required this.status,
    required this.enabledRequirements,
    required this.activeVehicles,
  });

  final AdminDriverMarketStatus status;
  final int enabledRequirements;
  final int activeVehicles;

  bool get isReady => status == AdminDriverMarketStatus.ready;
}

abstract final class AdminDriverMarketReadinessResolver {
  AdminDriverMarketReadinessResolver._();

  static int _enabledRequirements(CountriesRecord country) {
    final raw = country.driverRequirements;
    if (raw.isEmpty) return 0;
    return raw.values.where((v) {
      if (v is! Map) return false;
      return v['enabled'] == true;
    }).length;
  }

  static bool _isActiveType(TypeCarRecord car) => car.actev;

  static String? _normalizeIso(String? raw) {
    final t = (raw ?? '').trim().toUpperCase();
    if (t.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(t)) return t;
    final lower = (raw ?? '').trim().toLowerCase();
    if (lower.contains('saudi')) return 'SA';
    if (lower.contains('kyrgyz') || lower == 'kg') return 'KG';
    if (lower.contains('russia') || lower == 'ru') return 'RU';
    if (lower.contains('uzbek') || lower == 'uz') return 'UZ';
    return null;
  }

  static bool _matchesCountry(
    TypeCarRecord car,
    CountriesRecord country,
    String? iso,
  ) {
    final myIso = car.countryIso2.trim().toUpperCase();
    if (myIso.isNotEmpty && iso != null && iso.isNotEmpty && myIso == iso) {
      return true;
    }
    if (car.dolh != null && car.dolh!.path == country.reference.path) {
      return true;
    }
    if (car.dolh != null && iso != null) {
      final dolhIso = _normalizeIso(car.dolh!.id);
      if (dolhIso != null && dolhIso == iso) return true;
    }
    return false;
  }

  static String? _isoOf(CountriesRecord country) {
    return _normalizeIso(country.isoCode) ??
        _normalizeIso(country.reference.id) ??
        _normalizeIso(country.osf);
  }

  static Map<String, int> vehicleCountsByCountryPath(
    List<TypeCarRecord> cars,
    List<CountriesRecord> countries,
  ) {
    final out = <String, int>{};
    for (final country in countries) {
      final iso = _isoOf(country);
      var count = 0;
      for (final car in cars) {
        if (!_isActiveType(car)) continue;
        if (_matchesCountry(car, country, iso)) count++;
      }
      out[country.reference.path] = count;
    }
    return out;
  }

  static AdminDriverMarketReadiness forCountry({
    required CountriesRecord country,
    required int activeVehicles,
  }) {
    final enabled = _enabledRequirements(country);
    if (!country.acctev) {
      return AdminDriverMarketReadiness(
        status: AdminDriverMarketStatus.incomplete,
        enabledRequirements: enabled,
        activeVehicles: activeVehicles,
      );
    }
    if (enabled <= 0) {
      return AdminDriverMarketReadiness(
        status: AdminDriverMarketStatus.missingDriverRequirements,
        enabledRequirements: enabled,
        activeVehicles: activeVehicles,
      );
    }
    if (activeVehicles <= 0) {
      return AdminDriverMarketReadiness(
        status: AdminDriverMarketStatus.missingVehicleCatalog,
        enabledRequirements: enabled,
        activeVehicles: activeVehicles,
      );
    }
    return AdminDriverMarketReadiness(
      status: AdminDriverMarketStatus.ready,
      enabledRequirements: enabled,
      activeVehicles: activeVehicles,
    );
  }
}

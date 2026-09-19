/// Shared vehicle category matching for driver ↔ order dispatch.
///
/// Country-scoped `type_car` docs often share the same category (e.g. luxury)
/// under different document IDs — exact ref equality alone is not enough.
enum DriverVehicleCategory {
  economy,
  family,
  suv,
  luxury,
  miniBus,
  mediumBus,
  largeBus,
  accessibleBus,
  vipBus,
}

abstract final class DriverVehicleCategoryMatch {
  DriverVehicleCategoryMatch._();

  static const _codeToCategory = <String, DriverVehicleCategory>{
    'economy': DriverVehicleCategory.economy,
    'compact': DriverVehicleCategory.economy,
    'sedan': DriverVehicleCategory.economy,
    'sedan_standard': DriverVehicleCategory.economy,
    'comfort': DriverVehicleCategory.economy,
    'airport_transfer': DriverVehicleCategory.economy,
    'electric': DriverVehicleCategory.economy,
    'hybrid': DriverVehicleCategory.economy,
    'suv_family': DriverVehicleCategory.family,
    'van_family': DriverVehicleCategory.family,
    'suv': DriverVehicleCategory.family,
    'suv_standard': DriverVehicleCategory.family,
    'suv_compact': DriverVehicleCategory.family,
    'offroad_4x4': DriverVehicleCategory.suv,
    'pickup_4x4': DriverVehicleCategory.suv,
    'suv_large': DriverVehicleCategory.suv,
    'luxury': DriverVehicleCategory.luxury,
    'premium': DriverVehicleCategory.luxury,
    'premium_sedan': DriverVehicleCategory.luxury,
    'business': DriverVehicleCategory.luxury,
    'sedan_business': DriverVehicleCategory.luxury,
    'luxury_suv': DriverVehicleCategory.luxury,
    'coach_mini': DriverVehicleCategory.miniBus,
    'minivan': DriverVehicleCategory.miniBus,
    'tour_van': DriverVehicleCategory.miniBus,
    'van': DriverVehicleCategory.miniBus,
    'tourist_vehicle': DriverVehicleCategory.miniBus,
    'executive_shuttle': DriverVehicleCategory.miniBus,
    'coach_medium': DriverVehicleCategory.mediumBus,
    'bus_medium': DriverVehicleCategory.mediumBus,
    'medium_bus': DriverVehicleCategory.mediumBus,
    'coach_tour': DriverVehicleCategory.largeBus,
    'bus': DriverVehicleCategory.largeBus,
    'large_bus': DriverVehicleCategory.largeBus,
    'coach_large': DriverVehicleCategory.largeBus,
    'wheelchair': DriverVehicleCategory.accessibleBus,
    'accessible': DriverVehicleCategory.accessibleBus,
    'accessible_bus': DriverVehicleCategory.accessibleBus,
    'van_vip': DriverVehicleCategory.vipBus,
    'vip': DriverVehicleCategory.vipBus,
    'vip_bus': DriverVehicleCategory.vipBus,
    'bus_vip': DriverVehicleCategory.vipBus,
  };

  static DriverVehicleCategory? fromCodeOrId(String? raw) {
    final key = (raw ?? '').trim().toLowerCase();
    if (key.isEmpty) return null;
    return _codeToCategory[key];
  }

  /// Best-effort from display labels (ar/en) when codes are missing.
  static DriverVehicleCategory? fromLabel(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t.isEmpty) return null;

    if (t.contains('vip')) return DriverVehicleCategory.vipBus;
    if (t.contains('wheelchair') ||
        t.contains('احتياج') ||
        t.contains('accessible')) {
      return DriverVehicleCategory.accessibleBus;
    }
    if (t.contains('49') || t.contains('كبيرة') || t.contains('large bus')) {
      return DriverVehicleCategory.largeBus;
    }
    if (t.contains('25') || t.contains('متوسطة') || t.contains('medium bus')) {
      return DriverVehicleCategory.mediumBus;
    }
    if (t.contains('حافلة صغيرة') ||
        t.contains('mini bus') ||
        t.contains('minibus') ||
        t.contains('minivan')) {
      return DriverVehicleCategory.miniBus;
    }
    if (t.contains('فاره') ||
        t.contains('luxury') ||
        t.contains('premium') ||
        t.contains('business')) {
      return DriverVehicleCategory.luxury;
    }
    if (t.contains('رباعي') ||
        t.contains('4x4') ||
        t.contains('offroad') ||
        t.contains('دفع')) {
      return DriverVehicleCategory.suv;
    }
    if (t.contains('عائلي') || t.contains('family')) {
      return DriverVehicleCategory.family;
    }
    if (t.contains('اقتصاد') ||
        t.contains('economy') ||
        t.contains('صغبر') ||
        t.contains('صغير')) {
      return DriverVehicleCategory.economy;
    }
    return null;
  }

  static DriverVehicleCategory? resolve({
    String? codeCar,
    String? documentId,
    String? displayName,
  }) {
    return fromCodeOrId(codeCar) ??
        fromCodeOrId(documentId) ??
        fromLabel(displayName);
  }

  /// True when driver and order refer to the same vehicle class.
  static bool matches({
    required String? driverTypePath,
    required String? orderTypePath,
    String? driverLabel,
    String? orderLabel,
  }) {
    final dPath = (driverTypePath ?? '').trim();
    final oPath = (orderTypePath ?? '').trim();
    if (dPath.isNotEmpty && oPath.isNotEmpty && dPath == oPath) {
      return true;
    }

    final driverCat = resolve(
      documentId: dPath.contains('/') ? dPath.split('/').last : dPath,
      displayName: driverLabel,
    );
    final orderCat = resolve(
      documentId: oPath.contains('/') ? oPath.split('/').last : oPath,
      displayName: orderLabel,
    );
    if (driverCat != null && orderCat != null) {
      return driverCat == orderCat;
    }

    // Last resort: normalized label equality.
    final dl = _norm(driverLabel);
    final ol = _norm(orderLabel);
    if (dl.isNotEmpty && ol.isNotEmpty && dl == ol) return true;

    // No shared signal → do not match different typed vehicles.
    if (dPath.isNotEmpty && oPath.isNotEmpty) return false;
    return false;
  }

  static String _norm(String? raw) =>
      (raw ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

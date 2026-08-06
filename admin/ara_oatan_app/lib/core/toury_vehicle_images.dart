/// صور المركبات المحلية لشاشة قائمة السيارات — مطابقة للاسم/الكود.
abstract final class TouryVehicleImages {
  TouryVehicleImages._();

  static const economy = 'assets/images/vehicles/economy_car.jpg';
  static const family = 'assets/images/vehicles/family_car.jpg';
  static const suv = 'assets/images/vehicles/suv_car.jpg';
  static const luxury = 'assets/images/vehicles/luxury_car.jpg';
  static const miniBus = 'assets/images/vehicles/mini_bus.jpg';
  static const mediumBus = 'assets/images/vehicles/medium_bus.jpg';
  static const largeBus = 'assets/images/vehicles/large_bus.jpg';
  static const accessibleBus = 'assets/images/vehicles/accessible_bus.jpg';
  static const vipBus = 'assets/images/vehicles/vip_bus.jpg';

  /// مطابقة صريحة بـ `codeCar` / معرّف المستند.
  static const Map<String, String> byCode = {
    'economy': economy,
    'compact': economy,
    'sedan': economy,
    'sedan_standard': economy,
    'comfort': economy,
    'airport_transfer': economy,
    'electric': economy,
    'hybrid': economy,
    'suv_family': family,
    'van_family': family,
    'suv': family,
    'suv_standard': family,
    'suv_compact': family,
    'offroad_4x4': suv,
    'pickup_4x4': suv,
    'suv_large': suv,
    'luxury': luxury,
    'premium': luxury,
    'premium_sedan': luxury,
    'business': luxury,
    'sedan_business': luxury,
    'luxury_suv': luxury,
    'coach_mini': miniBus,
    'minivan': miniBus,
    'tour_van': miniBus,
    'van': miniBus,
    'tourist_vehicle': miniBus,
    'executive_shuttle': miniBus,
    'coach_medium': mediumBus,
    'bus_medium': mediumBus,
    'medium_bus': mediumBus,
    'coach_tour': largeBus,
    'bus': largeBus,
    'large_bus': largeBus,
    'coach_large': largeBus,
    'wheelchair': accessibleBus,
    'accessible': accessibleBus,
    'accessible_bus': accessibleBus,
    'van_vip': vipBus,
    'vip': vipBus,
    'vip_bus': vipBus,
    'bus_vip': vipBus,
  };
}

/// يعيد مسار الأصل المحلي المطابق لنوع المركبة، أو null إن لم يوجد.
String? touryVehicleLocalAsset({
  String? codeCar,
  String? documentId,
  String? displayName,
  String? note,
}) {
  final code = (codeCar ?? '').trim().toLowerCase();
  if (code.isNotEmpty) {
    final byCode = TouryVehicleImages.byCode[code];
    if (byCode != null) return byCode;
  }

  final id = (documentId ?? '').trim().toLowerCase();
  if (id.isNotEmpty) {
    final byId = TouryVehicleImages.byCode[id];
    if (byId != null) return byId;
  }

  final haystack = [
    displayName ?? '',
    note ?? '',
    codeCar ?? '',
    documentId ?? '',
  ].join(' ').toLowerCase();

  if (haystack.isEmpty) return null;

  // ترتيب الأخصّ أولاً لتجنّب التداخل بين أنواع الحافلات.
  if (_hasAny(haystack, const [
        'ذوي الاحتياجات',
        'احتياجات خاصة',
        'كرسي متحرك',
        'wheelchair',
        'accessible',
      ])) {
    return TouryVehicleImages.accessibleBus;
  }
  if (_hasAny(haystack, const [
        'vip',
        'حافلة vip',
        'باص vip',
        'فان vip',
      ])) {
    return TouryVehicleImages.vipBus;
  }
  if (_hasAny(haystack, const [
        '49',
        'حافلة كبيرة',
        'باص كبير',
        'large bus',
        'coach large',
      ])) {
    return TouryVehicleImages.largeBus;
  }
  if (_hasAny(haystack, const [
        '25',
        'حافلة متوسطة',
        'باص متوسط',
        'medium bus',
        'coach medium',
      ])) {
    return TouryVehicleImages.mediumBus;
  }
  if (_hasAny(haystack, const [
        'حافلة صغيرة',
        'ميني باص',
        'minibus',
        'mini bus',
        'coach_mini',
      ])) {
    return TouryVehicleImages.miniBus;
  }
  if (_hasAny(haystack, const [
        'فارهة',
        'فاخرة',
        'luxury',
        'premium',
        'سيارة فارهة',
      ])) {
    return TouryVehicleImages.luxury;
  }
  if (_hasAny(haystack, const [
        'دفع رباعي',
        '4x4',
        '4wd',
        'offroad',
        'سيارة دفع',
      ])) {
    return TouryVehicleImages.suv;
  }
  if (_hasAny(haystack, const [
        'عائلية',
        'family',
        'سيارة عائلية',
      ])) {
    return TouryVehicleImages.family;
  }
  if (_hasAny(haystack, const [
        'اقتصادية',
        'economy',
        'سيارة اقتصادية',
      ])) {
    return TouryVehicleImages.economy;
  }
  if (_hasAny(haystack, const ['حافلة', 'باص', 'bus', 'coach'])) {
    return TouryVehicleImages.largeBus;
  }

  return null;
}

bool _hasAny(String haystack, List<String> needles) {
  for (final needle in needles) {
    if (haystack.contains(needle.toLowerCase())) return true;
  }
  return false;
}

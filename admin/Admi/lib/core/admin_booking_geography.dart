import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/order_record.dart';

/// Trip geography from order snapshot only — never driver/customer profile.
class AdminBookingGeography {
  const AdminBookingGeography({
    required this.tripCountry,
    required this.tripRegion,
    required this.tripCity,
    required this.tripCityKnown,
  });

  static const unknownLabel = 'غير معروف';

  final String tripCountry;
  final String tripRegion;
  final String tripCity;
  final bool tripCityKnown;

  factory AdminBookingGeography.fromOrder(OrderRecord order) {
    final data = order.snapshotData;
    final city = _firstNonEmpty([
      order.villText.trim(),
      _str(data, ['vill_text', 'city_text', 'booking_city_text', 'trip_city']),
    ]);
    final country = _firstNonEmpty([
      _str(data, ['country_text', 'dolh_text', 'country_name']),
      _labelFromRef(order.revDolh),
    ]);
    final region = _firstNonEmpty([
      _str(data, ['region_text', 'cities_text', 'region_name']),
      _labelFromRef(order.citiesUserNow),
    ]);

    return AdminBookingGeography(
      tripCountry: country.isNotEmpty ? country : unknownLabel,
      tripRegion: region.isNotEmpty ? region : unknownLabel,
      tripCity: city.isNotEmpty ? city : unknownLabel,
      tripCityKnown: city.isNotEmpty,
    );
  }

  static String _str(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static String _firstNonEmpty(List<String> values) {
    for (final v in values) {
      if (v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static String _labelFromRef(DocumentReference? ref) {
    if (ref == null) return '';
    return _humanizeId(ref.id);
  }

  static String _humanizeId(String id) {
    final cleaned = id.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

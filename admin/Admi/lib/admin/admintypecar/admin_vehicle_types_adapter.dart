import '/backend/backend.dart';

/// Admin view-model for `type_car` (booking vehicle class / pricing tier).
///
/// Not make/model — those live on driver docs (`NameCar` / `ModelCar`).
/// Customer SoT: `type_car` + `isAvailableForListing` + `touryTypeCarSortKey`.
class AdminVehicleTypeRow {
  const AdminVehicleTypeRow({
    required this.record,
    required this.displayNameAr,
    required this.displayNameEn,
    required this.imageUrl,
    required this.active,
    required this.code,
    required this.hourlyRate,
    required this.minHours,
    required this.sortOrder,
    required this.passengers,
    required this.isBusLike,
    required this.hasPricing,
    required this.countryIso2,
    required this.classificationLabel,
  });

  final TypeCarRecord record;
  final String displayNameAr;
  final String displayNameEn;
  final String imageUrl;
  final bool active;
  final String code;
  final int hourlyRate;
  final int minHours;
  final int sortOrder;
  final int passengers;
  final bool isBusLike;
  final bool hasPricing;
  final String countryIso2;

  /// Display class: bus-like vs car class from name/code (no separate collection).
  final String classificationLabel;

  static String nameArOf(TypeCarRecord r) {
    final ar = (r.namesI18n['ar'] ?? '').trim();
    if (ar.isNotEmpty) return ar;
    if (r.naim.trim().isNotEmpty) return r.naim.trim();
    return (r.namesI18n['en'] ?? r.codeCar).trim().isEmpty
        ? '—'
        : (r.namesI18n['en'] ?? r.codeCar).trim();
  }

  static String nameEnOf(TypeCarRecord r) {
    final en = (r.namesI18n['en'] ?? '').trim();
    return en;
  }

  static String imageOf(TypeCarRecord r) {
    if (r.img.trim().isNotEmpty) return r.img.trim();
    if (r.icon.trim().isNotEmpty) return r.icon.trim();
    return '';
  }

  /// Matches Customer [TypeCarRecord.isAvailableForListing] semantics.
  static bool isActiveOf(TypeCarRecord r) {
    final data = r.snapshotData;
    if (data.containsKey('actev')) return data['actev'] == true;
    if (data.containsKey('acctev')) return data['acctev'] == true;
    // Legacy missing flag: Customer treats as available.
    return true;
  }

  static int sortKeyOf(TypeCarRecord r) {
    if (r.hasSortOrder() && r.sortOrder > 0) return r.sortOrder;
    if (r.hasNumTrteb() && r.numTrteb > 0) return r.numTrteb;
    return 0;
  }

  static String classificationOf(TypeCarRecord r) {
    if (r.ishafelh) return 'حافلة';
    final code = r.codeCar.toLowerCase();
    final name = '${r.naim} ${r.namesI18n['ar'] ?? ''} ${r.namesI18n['en'] ?? ''}'
        .toLowerCase();
    if (code.contains('coach') ||
        code.contains('bus') ||
        name.contains('حافل')) {
      return 'حافلة';
    }
    if (code.contains('suv') || name.contains('رباعي')) return 'SUV';
    if (code.contains('lux') ||
        code.contains('business') ||
        name.contains('فاره') ||
        name.contains('فاخر')) {
      return 'فارهة';
    }
    if (code.contains('family') || name.contains('عائل')) return 'عائلية';
    if (code.contains('econom') ||
        code.contains('airport') ||
        name.contains('اقتصاد')) {
      return 'اقتصادية';
    }
    return 'تصنيف مركبة';
  }

  static AdminVehicleTypeRow fromRecord(TypeCarRecord r) {
    return AdminVehicleTypeRow(
      record: r,
      displayNameAr: nameArOf(r),
      displayNameEn: nameEnOf(r),
      imageUrl: imageOf(r),
      active: isActiveOf(r),
      code: r.codeCar.trim().isNotEmpty ? r.codeCar.trim() : r.reference.id,
      hourlyRate: r.sr,
      minHours: r.aglSaat,
      sortOrder: sortKeyOf(r),
      passengers: r.passengers,
      isBusLike: r.ishafelh,
      hasPricing: r.sr > 0,
      countryIso2: r.countryIso2.trim().toUpperCase(),
      classificationLabel: classificationOf(r),
    );
  }

  bool matchesSearch(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (displayNameAr.toLowerCase().contains(q)) return true;
    if (displayNameEn.toLowerCase().contains(q)) return true;
    if (code.toLowerCase().contains(q)) return true;
    if (classificationLabel.toLowerCase().contains(q)) return true;
    if (record.reference.id.toLowerCase().contains(q)) return true;
    for (final v in record.namesI18n.values) {
      if (v.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

enum AdminVehicleTypeStatusFilter { all, active, inactive }

enum AdminVehicleTypeClassFilter { all, car, bus }

class AdminVehicleTypeFilters {
  const AdminVehicleTypeFilters({
    this.status = AdminVehicleTypeStatusFilter.all,
    this.classFilter = AdminVehicleTypeClassFilter.all,
    this.countryIso2 = '',
    this.searchQuery = '',
  });

  final AdminVehicleTypeStatusFilter status;
  final AdminVehicleTypeClassFilter classFilter;
  final String countryIso2;
  final String searchQuery;

  bool get hasActive =>
      status != AdminVehicleTypeStatusFilter.all ||
      classFilter != AdminVehicleTypeClassFilter.all ||
      countryIso2.trim().isNotEmpty ||
      searchQuery.trim().isNotEmpty;

  AdminVehicleTypeFilters copyWith({
    AdminVehicleTypeStatusFilter? status,
    AdminVehicleTypeClassFilter? classFilter,
    String? countryIso2,
    String? searchQuery,
  }) =>
      AdminVehicleTypeFilters(
        status: status ?? this.status,
        classFilter: classFilter ?? this.classFilter,
        countryIso2: countryIso2 ?? this.countryIso2,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  List<AdminVehicleTypeRow> apply(List<AdminVehicleTypeRow> rows) {
    var out = rows;
    final q = searchQuery.trim();
    if (q.isNotEmpty) {
      out = out.where((r) => r.matchesSearch(q)).toList(growable: false);
    }
    switch (status) {
      case AdminVehicleTypeStatusFilter.active:
        out = out.where((r) => r.active).toList(growable: false);
        break;
      case AdminVehicleTypeStatusFilter.inactive:
        out = out.where((r) => !r.active).toList(growable: false);
        break;
      case AdminVehicleTypeStatusFilter.all:
        break;
    }
    switch (classFilter) {
      case AdminVehicleTypeClassFilter.bus:
        out = out
            .where((r) => r.isBusLike || r.classificationLabel == 'حافلة')
            .toList(growable: false);
        break;
      case AdminVehicleTypeClassFilter.car:
        out = out
            .where((r) => !r.isBusLike && r.classificationLabel != 'حافلة')
            .toList(growable: false);
        break;
      case AdminVehicleTypeClassFilter.all:
        break;
    }
    final iso = countryIso2.trim().toUpperCase();
    if (iso.isNotEmpty) {
      out = out.where((r) {
        if (r.countryIso2 == iso) return true;
        final dolh = r.record.dolh?.id.toLowerCase() ?? '';
        if (iso == 'SA' &&
            (dolh.contains('saudi') || r.countryIso2.isEmpty)) {
          return true;
        }
        return false;
      }).toList(growable: false);
    }
    return out;
  }
}

/// Sort for Admin list: explicit sort key, then name.
List<AdminVehicleTypeRow> adminSortVehicleTypes(List<AdminVehicleTypeRow> rows) {
  final out = List<AdminVehicleTypeRow>.from(rows);
  out.sort((a, b) {
    final sa = a.sortOrder;
    final sb = b.sortOrder;
    if (sa > 0 && sb > 0 && sa != sb) return sa.compareTo(sb);
    if (sa > 0 && sb <= 0) return -1;
    if (sb > 0 && sa <= 0) return 1;
    return a.displayNameAr.compareTo(b.displayNameAr);
  });
  return out;
}

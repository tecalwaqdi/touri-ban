import '/backend/backend.dart';

/// Client-side landmark list filters (Admin catalog).
enum AdminLandmarkStatusFilter {
  all,
  active,
  inactive,
}

class AdminLandmarkListFilters {
  const AdminLandmarkListFilters({
    this.countryRef,
    this.regionRef,
    this.cityRef,
    this.status = AdminLandmarkStatusFilter.all,
    this.imageMissingOnly = false,
  });

  final DocumentReference? countryRef;
  final DocumentReference? regionRef;
  final DocumentReference? cityRef;
  final AdminLandmarkStatusFilter status;
  final bool imageMissingOnly;

  bool get hasActive =>
      countryRef != null ||
      regionRef != null ||
      cityRef != null ||
      status != AdminLandmarkStatusFilter.all ||
      imageMissingOnly;

  AdminLandmarkListFilters copyWith({
    DocumentReference? countryRef,
    DocumentReference? regionRef,
    DocumentReference? cityRef,
    AdminLandmarkStatusFilter? status,
    bool? imageMissingOnly,
    bool clearCountry = false,
    bool clearRegion = false,
    bool clearCity = false,
  }) {
    return AdminLandmarkListFilters(
      countryRef: clearCountry ? null : (countryRef ?? this.countryRef),
      regionRef: clearRegion ? null : (regionRef ?? this.regionRef),
      cityRef: clearCity ? null : (cityRef ?? this.cityRef),
      status: status ?? this.status,
      imageMissingOnly: imageMissingOnly ?? this.imageMissingOnly,
    );
  }

  static bool hasImage(MkanRecord m) {
    final a = m.img1.trim();
    final b = m.img2.trim();
    final c = m.img3.trim();
    return a.isNotEmpty || b.isNotEmpty || c.isNotEmpty;
  }

  List<MkanRecord> apply(List<MkanRecord> items) {
    var out = items;
    final country = countryRef;
    if (country != null) {
      out = out
          .where((m) => m.revDolh != null && m.revDolh!.path == country.path)
          .toList(growable: false);
    }
    final region = regionRef;
    if (region != null) {
      out = out
          .where((m) => m.idCit != null && m.idCit!.path == region.path)
          .toList(growable: false);
    }
    final city = cityRef;
    if (city != null) {
      out = out
          .where((m) => m.idVill != null && m.idVill!.path == city.path)
          .toList(growable: false);
    }
    switch (status) {
      case AdminLandmarkStatusFilter.active:
        out = out.where((m) => m.acctev).toList(growable: false);
        break;
      case AdminLandmarkStatusFilter.inactive:
        out = out.where((m) => !m.acctev).toList(growable: false);
        break;
      case AdminLandmarkStatusFilter.all:
        break;
    }
    if (imageMissingOnly) {
      out = out.where((m) => !hasImage(m)).toList(growable: false);
    }
    return out;
  }
}

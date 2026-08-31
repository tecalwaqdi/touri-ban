import '/backend/backend.dart';
import '/backend/admin_geo_cascade.dart';
import '/components/admin_location_service.dart';

/// Normalized landmark row for Admin list/details (dual-read, no schema break).
class AdminLandmarkRow {
  const AdminLandmarkRow({
    required this.record,
    required this.displayName,
    required this.description,
    required this.primaryImageUrl,
    required this.active,
    required this.category,
    required this.coordsLabel,
    required this.locationValid,
    required this.countryPath,
    required this.regionPath,
    required this.cityPath,
    required this.sortOrder,
  });

  final MkanRecord record;
  final String displayName;
  final String description;
  final String primaryImageUrl;
  final bool active;
  final String category;
  final String coordsLabel;
  final bool locationValid;
  final String countryPath;
  final String regionPath;
  final String cityPath;
  final int sortOrder;

  /// Mobile SoT: `img1` (+ legacy `img`), then `img2`/`img3`.
  static String primaryImageOf(MkanRecord record) {
    final data = record.snapshotData;
    String pick(String key) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return '';
    }

    final img1 = record.img1.trim().isNotEmpty ? record.img1.trim() : pick('img');
    if (img1.isNotEmpty) return img1;
    if (record.img2.trim().isNotEmpty) return record.img2.trim();
    if (record.img3.trim().isNotEmpty) return record.img3.trim();
    return '';
  }

  static String displayNameOf(MkanRecord record) {
    if (record.naim.trim().isNotEmpty) return record.naim.trim();
    final i18n = record.namesI18n;
    for (final key in ['ar', 'en', 'ru', 'ky']) {
      final v = (i18n[key] ?? '').trim();
      if (v.isNotEmpty) return v;
    }
    for (final v in i18n.values) {
      if (v.trim().isNotEmpty) return v.trim();
    }
    return '—';
  }

  static AdminLandmarkRow fromRecord(MkanRecord record) {
    final loc = record.location;
    final locErr = AdminGeoCascade.validateLatLng(loc);
    final coords = loc == null
        ? ''
        : AdminLocationService.formatCoordinates(loc);
    return AdminLandmarkRow(
      record: record,
      displayName: displayNameOf(record),
      description: record.osf.trim(),
      primaryImageUrl: primaryImageOf(record),
      active: record.acctev == true,
      category: record.tsnef.trim(),
      coordsLabel: coords,
      locationValid: loc != null && locErr == null,
      countryPath: record.revDolh?.path ?? '',
      regionPath: record.idCit?.path ?? '',
      cityPath: record.idVill?.path ?? '',
      sortOrder: record.hasSr() ? record.sr : 0,
    );
  }

  bool matchesSearch(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (displayName.toLowerCase().contains(q)) return true;
    if (description.toLowerCase().contains(q)) return true;
    if (category.toLowerCase().contains(q)) return true;
    if (record.address.toLowerCase().contains(q)) return true;
    if (record.mdh.toLowerCase().contains(q)) return true;
    if (record.reference.id.toLowerCase().contains(q)) return true;
    for (final v in record.namesI18n.values) {
      if (v.toLowerCase().contains(q)) return true;
    }
    for (final v in record.osfI18n.values) {
      if (v.toLowerCase().contains(q)) return true;
    }
    if (countryPath.toLowerCase().contains(q)) return true;
    if (cityPath.toLowerCase().contains(q)) return true;
    if (regionPath.toLowerCase().contains(q)) return true;
    return false;
  }
}

/// Coordinate / geo helpers exposed for tests.
abstract final class AdminLandmarkCoords {
  AdminLandmarkCoords._();

  static bool isValid(LatLng? location) =>
      AdminGeoCascade.validateLatLng(location) == null;
}

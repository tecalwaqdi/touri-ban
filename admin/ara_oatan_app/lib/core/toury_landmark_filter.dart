import '/app_state.dart';
import '/backend/backend.dart';
import '/core/saudi_city_registry.dart';
import '/core/toury_i18n_text.dart';
import '/core/toury_landmark_display_order.dart';
import '/flutter_flow/lat_lng.dart';

/// Names that must never appear as tourist landmarks.
final RegExp touryBannedLandmarkPattern = RegExp(
  r'\b('
  r'aircraft|airplane|aeroplane|fighter|jet|bomber|helicopter|'
  r'boeing|airbus|lockheed|mcdonnell|douglas|panavia|tornado|'
  r'hercules|tristar|dc-4|dc4|'
  r'mig-|su-|f-\d|707|747|777|a320|'
  r'tank\b|warship|missile|military vehicle'
  r')\b',
  caseSensitive: false,
);

bool touryIsBannedLandmarkName(String name) {
  final n = name.trim();
  if (n.isEmpty) return true;
  return touryBannedLandmarkPattern.hasMatch(n);
}

/// Removes banned / out-of-city landmarks already sitting in the trip cart
/// and keeps [FFAppState.mkan] in sync (fixes "already added" with empty cart).
int touryPurgeBannedCartItems([FFAppState? state]) {
  final app = state ?? FFAppState();
  final before = app.cartmkss.length;
  final expected = touryResolveActiveSaudiCity(app);
  final kept = app.cartmkss
      .where((e) {
        if (touryIsBannedLandmarkName(e.naim)) return false;
        if (expected == null) return true;
        final loc = e.loceshn;
        if (loc == null) return true;
        return touryLatLngInSaudiCity(loc, expected);
      })
      .toList(growable: false);
  final changed = kept.length != before;
  if (changed) {
    app.update(() {
      app.cartmkss = kept.toList();
      app.addcart = kept.length;
    });
  }
  tourySyncCartMkanRefs(app);
  return changed ? before - kept.length : 0;
}

/// Rebuild `mkan` refs from visible cart items so "already added" matches UI.
void tourySyncCartMkanRefs([FFAppState? state]) {
  final app = state ?? FFAppState();
  final refs = <DocumentReference>[];
  final seen = <String>{};
  for (final item in app.cartmkss) {
    final ref = item.revmkan;
    if (ref == null) continue;
    if (!seen.add(ref.path)) continue;
    refs.add(ref);
  }
  app.update(() {
    app.mkan = refs;
    if (app.addcart != app.cartmkss.length) {
      app.addcart = app.cartmkss.length;
    }
  });
}

/// True when this landmark ref is already in the trip cart.
bool touryLandmarkAlreadyInCart(DocumentReference? ref, [FFAppState? state]) {
  if (ref == null) return false;
  final app = state ?? FFAppState();
  if (app.mkan.any((e) => e.path == ref.path)) return true;
  return app.cartmkss.any((e) => e.revmkan?.path == ref.path);
}

bool touryMkanLooksLikeJunk(MkanRecord record) {
  if (touryIsBannedLandmarkName(record.naim)) return true;
  for (final value in record.namesI18n.values) {
    if (touryIsBannedLandmarkName(value)) return true;
  }
  return false;
}

/// Active Saudi city from selected village / GPS / city label.
SaudiCityDefinition? touryResolveActiveSaudiCity([FFAppState? state]) {
  final app = state ?? FFAppState();
  final village = app.villnow ?? app.villa ?? app.vil;
  final fromVillage = SaudiCityRegistry.cityFromVillageDocId(village?.id);
  if (fromVillage != null) return fromVillage;

  final label = app.naimvillatext.trim().isNotEmpty
      ? app.naimvillatext
      : app.villtextnow;
  final fromLabel = SaudiCityRegistry.cityFromName(label);
  if (fromLabel != null) return fromLabel;

  final anchor = app.mkanuserorder ?? app.latlngvill ?? app.akrLoceshn;
  if (anchor != null) {
    return SaudiCityRegistry.cityFromCoordinates(anchor);
  }
  return null;
}

bool touryLatLngInSaudiCity(LatLng point, SaudiCityDefinition city) {
  final actual = SaudiCityRegistry.cityFromCoordinates(point);
  if (actual != null) {
    return actual.key == city.key;
  }
  // Soft edge only when point is outside all known city bboxes.
  final km = SaudiCityRegistry.distanceKm(point, city.center);
  return km <= 12;
}

/// True when landmark coords belong to the user's active city.
/// Mis-tagged OSM docs (Jeddah under Makkah village id) are dropped here.
///
/// Non-Saudi villages must not be filtered by [SaudiCityRegistry] — Admin
/// landmarks outside KSA would otherwise disappear when leftover Saudi labels
/// remain in [FFAppState].
bool touryLandmarkMatchesActiveCity(MkanRecord record, [FFAppState? state]) {
  final app = state ?? FFAppState();
  final village = app.villnow ?? app.villa ?? app.vil;
  final fromVillage = SaudiCityRegistry.cityFromVillageDocId(village?.id);
  // Outside Saudi registry: id_vill query is authoritative — keep landmark.
  if (fromVillage == null && village != null) {
    return true;
  }
  final expected = fromVillage ?? touryResolveActiveSaudiCity(app);
  if (expected == null) return true;
  final loc = record.location;
  if (loc == null) return true;
  final actual = SaudiCityRegistry.cityFromCoordinates(loc);
  if (actual != null) {
    return actual.key == expected.key;
  }
  return touryLatLngInSaudiCity(loc, expected);
}

/// Cart subtitle: country + landmark's real city (not always user's city).
String touryLandmarkCartSubtitle(MkanRecord record, [FFAppState? state]) {
  final app = state ?? FFAppState();
  final country = app.naimdolh.trim().isNotEmpty
      ? app.naimdolh.trim()
      : 'المملكة العربية السعودية';
  final fromCoords = record.location != null
      ? SaudiCityRegistry.cityFromCoordinates(record.location!)
      : null;
  final city =
      fromCoords?.displayNameAr ??
      SaudiCityRegistry.cityFromVillageDocId(
        record.idVill?.id,
      )?.displayNameAr ??
      app.naimvillatext.trim();
  if (city.isEmpty) return country;
  return '$country- $city';
}

/// Filter for display: locale-visible + not banned + same city as user.
List<MkanRecord> touryFilterLandmarksForUi(
  Iterable<MkanRecord> items,
  String userLocaleKey, {
  FFAppState? state,
}) {
  final app = state ?? FFAppState();
  final out = items.where((m) {
    if (touryMkanLooksLikeJunk(m)) return false;
    if (!touryLandmarkMatchesActiveCity(m, app)) return false;
    // Prefer locale → en; never drop a real landmark just because Arabic
    // legacy has no ky/ru string yet (display layer applies fallbacks).
    final name = touryLocalizedText(
      m.namesI18n,
      m.naim,
      localeKey: userLocaleKey,
    );
    final enName = touryLocalizedText(m.namesI18n, m.naim, localeKey: 'en');
    final visible = name.isNotEmpty
        ? name
        : (enName.isNotEmpty ? enName : m.naim.trim());
    if (visible.isEmpty) return false;
    if (touryIsBannedLandmarkName(visible)) return false;
    if (touryIsBannedLandmarkName(m.naim)) return false;
    return true;
  }).toList();
  return TouryLandmarkDisplayOrder.sort(out);
}

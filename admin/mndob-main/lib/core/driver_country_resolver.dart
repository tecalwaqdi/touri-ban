import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/toury_country_registry.dart';

/// Canonical country document resolution for Driver registration/catalog/config.
abstract final class DriverCountryResolver {
  DriverCountryResolver._();

  static String? isoFromRef(DocumentReference? ref) =>
      TouryCountryRegistry.normalizeIso(ref?.id);

  static DocumentReference? preferredCountryRef(String? iso2) {
    final iso = (iso2 ?? '').trim().toUpperCase();
    if (iso.isEmpty) return null;
    final id = TouryCountryRegistry.preferredCountryDocId(iso);
    if (id == null || id.isEmpty) return null;
    return FirebaseFirestore.instance.collection('countries').doc(id);
  }

  /// Prefer canonical Firestore country id (e.g. kyrgyzstan over country_kg).
  static DocumentReference? canonicalCountryRef(DocumentReference? ref) {
    if (ref == null) return null;
    final iso = isoFromRef(ref);
    final preferred = iso != null ? preferredCountryRef(iso) : null;
    if (preferred != null) return preferred;
    return ref;
  }

  static DocumentReference? resolveRegistrationCountry({
    DocumentReference? dolh,
    String? locationIso2,
  }) {
    return canonicalCountryRef(dolh) ??
        preferredCountryRef(locationIso2) ??
        dolh;
  }

  static String? resolveRegistrationIso({
    DocumentReference? dolh,
    String? locationIso2,
  }) {
    return isoFromRef(dolh) ??
        TouryCountryRegistry.normalizeIso(locationIso2);
  }
}

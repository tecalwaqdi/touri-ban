import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/core/driver_geo_display.dart';
import '/core/toury_country_registry.dart';

class DriverTransportCompanyOption {
  const DriverTransportCompanyOption({
    required this.path,
    required this.name,
  });

  final String path;
  final String name;
}

/// Loads active transport companies for driver registration, scoped to the
/// driver's selected country (including ISO/doc-id aliases).
///
/// Firestore rules only allow signed-in clients to read docs with
/// `actev == true`, so every query MUST filter on that field or the whole
/// query is rejected (permission-denied → "Could not load…").
abstract final class DriverTransportCompanyCatalog {
  DriverTransportCompanyCatalog._();

  static bool isActiveCompany(Map<String, dynamic> data) {
    if (data.containsKey('actev')) {
      return data['actev'] == true;
    }
    if (data.containsKey('is_active')) {
      return data['is_active'] == true;
    }
    if (data.containsKey('active')) {
      return data['active'] == true;
    }
    return false;
  }

  static bool matchesCountry(
    Map<String, dynamic> data,
    DocumentReference? country,
  ) {
    if (country == null) return true;

    final rev = data['Rev_dolh'] ?? data['rev_dolh'] ?? data['dolh'];
    String? revId;
    String? revPath;
    if (rev is DocumentReference) {
      revId = rev.id;
      revPath = rev.path;
    } else if (rev is String && rev.trim().isNotEmpty) {
      final raw = rev.trim();
      revPath = raw.contains('/') ? raw : 'countries/$raw';
      revId = raw.contains('/') ? raw.split('/').last : raw;
    } else {
      return false;
    }

    if (revPath == country.path) return true;

    final aliases = TouryCountryRegistry.aliasDocIdsForCountryId(country.id);
    if (revId != null && aliases.contains(revId)) return true;

    final countryIso = TouryCountryRegistry.normalizeIso(country.id);
    final revIso = TouryCountryRegistry.normalizeIso(revId);
    return countryIso != null && revIso != null && countryIso == revIso;
  }

  static String displayName(Map<String, dynamic> data, String id) {
    return driverLocalizedMapLabel(data, fallbackId: id);
  }

  static Future<List<DriverTransportCompanyOption>> loadActiveForCountry(
    DocumentReference? country,
  ) async {
    // Rules: only `actev == true` docs are readable by drivers.
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await FirebaseFirestore.instance
          .collection('transport_company')
          .where('actev', isEqualTo: true)
          .get();
    } catch (e, st) {
      debugPrint('DriverTransportCompanyCatalog.load: $e\n$st');
      rethrow;
    }

    final options = <DriverTransportCompanyOption>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (!isActiveCompany(data)) continue;
      if (!matchesCountry(data, country)) continue;
      options.add(
        DriverTransportCompanyOption(
          path: doc.reference.path,
          name: displayName(data, doc.id),
        ),
      );
    }
    options.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return options;
  }
}

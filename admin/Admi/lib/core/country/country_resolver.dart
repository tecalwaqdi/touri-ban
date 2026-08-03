import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/core/auth/auth_claims.dart';

/// Canonical country identity — one logical country maps to one canonical ref.
class CanonicalCountry {
  const CanonicalCountry({
    required this.canonicalId,
    required this.canonicalRef,
    required this.aliasRefs,
    required this.displayName,
    required this.isSaudi,
  });

  final String canonicalId;
  final DocumentReference canonicalRef;
  final List<DocumentReference> aliasRefs;
  final String displayName;
  final bool isSaudi;

  List<DocumentReference> get allRefs => [canonicalRef, ...aliasRefs];

  Set<String> get allPaths => allRefs.map((r) => r.path).toSet();

  bool containsRef(DocumentReference? ref) {
    if (ref == null) return false;
    return allPaths.contains(ref.path);
  }

  bool pathsMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    return containsPath(a) && containsPath(b);
  }

  bool containsPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return allPaths.contains(path);
  }
}

/// Resolves countries to a single canonical ID and eliminates duplicate Saudi refs.
class CountryResolver {
  CountryResolver._();

  static const canonicalSaudiId = 'saudi_arabia';
  static const legacySaudiIds = ['saudi_arabia', 'demo_saudi'];

  static List<CanonicalCountry>? _cache;
  static Map<String, CanonicalCountry>? _byPath;

  static void clearCache() {
    _cache = null;
    _byPath = null;
  }

  static Future<void> ensureLoaded() async {
    if (_cache != null) return;
    await _load();
  }

  static Future<List<CanonicalCountry>> allCountries() async {
    await ensureLoaded();
    return List<CanonicalCountry>.from(_cache!);
  }

  static Future<CanonicalCountry?> resolveRef(DocumentReference? ref) async {
    if (ref == null) return null;
    await ensureLoaded();
    return _byPath![ref.path];
  }

  static Future<CanonicalCountry?> resolvePath(String? path) async {
    if (path == null) return null;
    await ensureLoaded();
    return _byPath![path];
  }

  static Future<CanonicalCountry?> activeForClaims(AuthClaims claims) async {
    final path = claims.countryId;
    if (path != null) return resolvePath(path);
    return null;
  }

  static Future<List<DocumentReference>> queryRefsForCanonical(
    CanonicalCountry country,
  ) async {
    return [country.canonicalRef];
  }

  static Future<List<DocumentReference>> queryRefsForPath(
    DocumentReference? ref,
  ) async {
    final canonical = await resolveRef(ref);
    if (canonical == null) {
      return ref != null ? [ref] : [];
    }
    return queryRefsForCanonical(canonical);
  }

  static Future<bool> sameScope(
    DocumentReference? a,
    DocumentReference? b,
  ) async {
    if (a == null || b == null) return false;
    final ca = await resolveRef(a);
    final cb = await resolveRef(b);
    if (ca != null && cb != null) return ca.canonicalId == cb.canonicalId;
    return a.path == b.path;
  }

  static Future<bool> refInCanonical(
    DocumentReference? ref,
    CanonicalCountry canonical,
  ) async {
    if (ref == null) return false;
    final resolved = await resolveRef(ref);
    if (resolved != null) return resolved.canonicalId == canonical.canonicalId;
    return canonical.containsRef(ref);
  }

  static Future<CanonicalCountry?> saudiCanonical() async {
    await ensureLoaded();
    for (final c in _cache!) {
      if (c.isSaudi) return c;
    }
    return null;
  }

  static Future<void> _load() async {
    final records = await queryCountriesRecordOnce(limit: 100);
    final saudiAliases = <DocumentReference>[];
    final others = <CountriesRecord>[];

    for (final record in records) {
      final id = record.reference.id;
      final isSaudi = record.saudi ||
          legacySaudiIds.contains(id) ||
          record.naim.toLowerCase().contains('saudi') ||
          record.naim.contains('سعود');
      if (isSaudi) {
        saudiAliases.add(record.reference);
      } else {
        others.add(record);
      }
    }

    for (final id in legacySaudiIds) {
      final ref = CountriesRecord.collection.doc(id);
      if (!saudiAliases.any((r) => r.path == ref.path)) {
        final snap = await ref.get();
        if (snap.exists) saudiAliases.add(ref);
      }
    }

    final canonical = <CanonicalCountry>[];

    if (saudiAliases.isNotEmpty) {
      final primary = saudiAliases.firstWhere(
        (r) => r.id == canonicalSaudiId,
        orElse: () => saudiAliases.first,
      );
      final aliases = saudiAliases.where((r) => r.path != primary.path).toList();
      canonical.add(
        CanonicalCountry(
          canonicalId: canonicalSaudiId,
          canonicalRef: primary,
          aliasRefs: aliases,
          displayName: 'Saudi Arabia',
          isSaudi: true,
        ),
      );
    }

    for (final record in others) {
      canonical.add(
        CanonicalCountry(
          canonicalId: record.reference.id,
          canonicalRef: record.reference,
          aliasRefs: const [],
          displayName: record.naim.isNotEmpty ? record.naim : record.reference.id,
          isSaudi: false,
        ),
      );
    }

    _cache = canonical;
    _byPath = {};
    for (final c in canonical) {
      for (final ref in c.allRefs) {
        _byPath![ref.path] = c;
      }
    }
  }
}

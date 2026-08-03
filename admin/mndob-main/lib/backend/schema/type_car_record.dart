import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/core/toury_country_registry.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TypeCarRecord extends FirestoreRecord {
  TypeCarRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};

  int? _sr;
  int get sr => _sr ?? 0;

  bool? _actev;
  bool get actev => _actev ?? false;

  /// نشط للعرض: actev=true، أو بدون حقل (بيانات قديمة).
  bool get isAvailableForListing {
    if (snapshotData.containsKey('actev')) {
      return snapshotData['actev'] == true;
    }
    if (snapshotData.containsKey('acctev')) {
      return snapshotData['acctev'] == true;
    }
    return true;
  }

  String? _img;
  String get img => _img ?? '';

  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  bool hasDolh() => _dolh != null;

  String? _countryIso2;
  String get countryIso2 => _countryIso2 ?? '';

  String? _codeCar;
  String get codeCar => _codeCar ?? '';

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    final rawNames = snapshotData['names_i18n'];
    if (rawNames is Map) {
      _namesI18n = rawNames.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    }
    _sr = castToType<int>(snapshotData['sr']);
    _actev = snapshotData['actev'] as bool?;
    _img = snapshotData['img'] as String?;
    _dolh = snapshotData['dolh'] as DocumentReference?;
    _countryIso2 = snapshotData['country_iso2'] as String?;
    _codeCar = snapshotData['codeCar'] as String?;
  }

  /// Matches by ISO first, then exact/alias country refs.
  bool matchesCountry({
    DocumentReference? countryRef,
    String? iso2,
    bool allowLegacySaudiFallback = true,
  }) {
    final iso = (iso2 ?? TouryCountryRegistry.normalizeIso(countryRef?.id) ?? '')
        .trim()
        .toUpperCase();
    final myIso = countryIso2.trim().toUpperCase();
    if (myIso.isNotEmpty && iso.isNotEmpty && myIso == iso) return true;

    if (dolh != null && countryRef != null) {
      if (dolh!.path == countryRef.path) return true;
      final dolhIso = TouryCountryRegistry.normalizeIso(dolh!.id);
      if (dolhIso != null && iso.isNotEmpty && dolhIso == iso) return true;
    }

    if (!hasDolh() && myIso.isEmpty) {
      return allowLegacySaudiFallback && (iso == 'SA' || iso.isEmpty);
    }
    return false;
  }

  /// Localized display name for current UI language.
  String localizedName(String languageCode) {
    final lang = languageCode.toLowerCase();
    final map = namesI18n;
    for (final key in [lang, if (lang == 'ky') 'ru', 'en', 'ar']) {
      final v = map[key]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return naim;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('type_car');

  static Stream<TypeCarRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TypeCarRecord.fromSnapshot(s));

  static Future<TypeCarRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TypeCarRecord.fromSnapshot(s));

  static TypeCarRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TypeCarRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TypeCarRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TypeCarRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TypeCarRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TypeCarRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTypeCarRecordData({
  String? naim,
  Map<String, String>? namesI18n,
  int? sr,
  bool? actev,
  String? img,
  DocumentReference? dolh,
  String? countryIso2,
  String? codeCar,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'names_i18n': namesI18n,
      'sr': sr,
      'actev': actev,
      'img': img,
      'dolh': dolh,
      'country_iso2': countryIso2,
      'codeCar': codeCar,
    }.withoutNulls,
  );
}

class TypeCarRecordDocumentEquality implements Equality<TypeCarRecord> {
  const TypeCarRecordDocumentEquality();

  @override
  bool equals(TypeCarRecord? e1, TypeCarRecord? e2) {
    return e1?.naim == e2?.naim && e1?.countryIso2 == e2?.countryIso2;
  }

  @override
  int hash(TypeCarRecord? e) =>
      const ListEquality().hash([e?.naim, e?.countryIso2, e?.dolh]);

  @override
  bool isValidKey(Object? o) => o is TypeCarRecord;
}

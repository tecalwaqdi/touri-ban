import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CitiesRecord extends FirestoreRecord {
  CitiesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  // "img" field.
  String? _img;
  String get img => _img ?? '';
  bool hasImg() => _img != null;

  // "dolh" field.
  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  bool hasDolh() => _dolh != null;

  // "acctev" field.
  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  // "vil" field.
  DocumentReference? _vil;
  DocumentReference? get vil => _vil;
  bool hasVil() => _vil != null;

  // "sorting" field.
  int? _sorting;
  int get sorting => _sorting ?? 0;
  bool hasSorting() => _sorting != null;

  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};
  Map<String, String>? _osfI18n;
  Map<String, String> get osfI18n => _osfI18n ?? const {};

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _osf = snapshotData['osf'] as String?;
    _img = snapshotData['img'] as String?;
    _dolh = docRefFromFirestore(snapshotData['dolh']);
    _acctev = snapshotData['acctev'] as bool?;
    _vil = docRefFromFirestore(snapshotData['vil']);
    _sorting = castToType<int>(snapshotData['sorting']);
    _namesI18n = _parseI18nStringMap(snapshotData['names_i18n']);
    _osfI18n = _parseI18nStringMap(snapshotData['osf_i18n']);
  }

  static Map<String, String>? _parseI18nStringMap(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final out = <String, String>{};
    raw.forEach((key, value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) out[key.toString()] = text;
    });
    return out.isEmpty ? null : out;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('cities');

  static Stream<CitiesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CitiesRecord.fromSnapshot(s));

  static Future<CitiesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CitiesRecord.fromSnapshot(s));

  static CitiesRecord fromSnapshot(DocumentSnapshot snapshot) => CitiesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CitiesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CitiesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CitiesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CitiesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCitiesRecordData({
  String? naim,
  String? osf,
  String? img,
  DocumentReference? dolh,
  bool? acctev,
  DocumentReference? vil,
  int? sorting,
  Map<String, String>? namesI18n,
  Map<String, String>? osfI18n,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'osf': osf,
      'img': img,
      'dolh': dolh,
      'acctev': acctev,
      'vil': vil,
      'sorting': sorting,
      'names_i18n': namesI18n,
      'osf_i18n': osfI18n,
    }.withoutNulls,
  );

  return firestoreData;
}

class CitiesRecordDocumentEquality implements Equality<CitiesRecord> {
  const CitiesRecordDocumentEquality();

  @override
  bool equals(CitiesRecord? e1, CitiesRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.osf == e2?.osf &&
        e1?.img == e2?.img &&
        e1?.dolh == e2?.dolh &&
        e1?.acctev == e2?.acctev &&
        e1?.vil == e2?.vil &&
        e1?.sorting == e2?.sorting;
  }

  @override
  int hash(CitiesRecord? e) => const ListEquality()
      .hash([e?.naim, e?.osf, e?.img, e?.dolh, e?.acctev, e?.vil, e?.sorting]);

  @override
  bool isValidKey(Object? o) => o is CitiesRecord;
}

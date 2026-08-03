import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TypeCarRecord extends FirestoreRecord {
  TypeCarRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "names_i18n" field.
  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};
  bool hasNamesI18n() => _namesI18n != null && _namesI18n!.isNotEmpty;

  // "sr" field.
  int? _sr;
  int get sr => _sr ?? 0;
  bool hasSr() => _sr != null;

  // "actev" field.
  bool? _actev;
  bool get actev => _actev ?? false;
  bool hasActev() => _actev != null;

  // "img" field.
  String? _img;
  String get img => _img ?? '';
  bool hasImg() => _img != null;

  // "ishafelh" field.
  bool? _ishafelh;
  bool get ishafelh => _ishafelh ?? false;
  bool hasIshafelh() => _ishafelh != null;

  // "vill" field.
  List<DocumentReference>? _vill;
  List<DocumentReference> get vill => _vill ?? const [];
  bool hasVill() => _vill != null;

  // "not" field.
  String? _not;
  String get not => _not ?? '';
  bool hasNot() => _not != null;

  // "agl_saat" field.
  int? _aglSaat;
  int get aglSaat => _aglSaat ?? 0;
  bool hasAglSaat() => _aglSaat != null;

  // "codeCar" field.
  String? _codeCar;
  String get codeCar => _codeCar ?? '';
  bool hasCodeCar() => _codeCar != null;

  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  bool hasDolh() => _dolh != null;

  String? _countryIso2;
  String get countryIso2 => _countryIso2 ?? '';
  bool hasCountryIso2() => _countryIso2 != null;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _namesI18n = _parseI18nStringMap(snapshotData['names_i18n']);
    _sr = castToType<int>(snapshotData['sr']);
    _actev = snapshotData['actev'] as bool?;
    _img = snapshotData['img'] as String?;
    _ishafelh = snapshotData['ishafelh'] as bool?;
    _vill = getDataList(snapshotData['vill']);
    _not = snapshotData['not'] as String?;
    _aglSaat = castToType<int>(snapshotData['agl_saat']);
    _codeCar = snapshotData['codeCar'] as String?;
    _dolh = snapshotData['dolh'] as DocumentReference?;
    _countryIso2 = snapshotData['country_iso2'] as String?;
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
  bool? ishafelh,
  String? not,
  int? aglSaat,
  String? codeCar,
  DocumentReference? dolh,
  String? countryIso2,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'names_i18n': namesI18n,
      'sr': sr,
      'actev': actev,
      'img': img,
      'ishafelh': ishafelh,
      'not': not,
      'agl_saat': aglSaat,
      'codeCar': codeCar,
      'dolh': dolh,
      'country_iso2': countryIso2,
    }.withoutNulls,
  );

  return firestoreData;
}

class TypeCarRecordDocumentEquality implements Equality<TypeCarRecord> {
  const TypeCarRecordDocumentEquality();

  @override
  bool equals(TypeCarRecord? e1, TypeCarRecord? e2) {
    const listEquality = ListEquality();
    const mapEquality = MapEquality<String, String>();
    return e1?.naim == e2?.naim &&
        mapEquality.equals(e1?.namesI18n, e2?.namesI18n) &&
        e1?.sr == e2?.sr &&
        e1?.actev == e2?.actev &&
        e1?.img == e2?.img &&
        e1?.ishafelh == e2?.ishafelh &&
        listEquality.equals(e1?.vill, e2?.vill) &&
        e1?.not == e2?.not &&
        e1?.aglSaat == e2?.aglSaat &&
        e1?.codeCar == e2?.codeCar;
  }

  @override
  int hash(TypeCarRecord? e) => const ListEquality().hash([
        e?.naim,
        e?.namesI18n,
        e?.sr,
        e?.actev,
        e?.img,
        e?.ishafelh,
        e?.vill,
        e?.not,
        e?.aglSaat,
        e?.codeCar,
      ]);

  @override
  bool isValidKey(Object? o) => o is TypeCarRecord;
}

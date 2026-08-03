import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class VillagesRecord extends FirestoreRecord {
  VillagesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "cities" field.
  DocumentReference? _cities;
  DocumentReference? get cities => _cities;
  bool hasCities() => _cities != null;

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "acctev" field.
  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  // "osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  // "img" field.
  String? _img;
  String get img => _img ?? '';
  bool hasImg() => _img != null;

  // "lat_ling" field.
  LatLng? _latLing;
  LatLng? get latLing => _latLing;
  bool hasLatLing() => _latLing != null;

  // "naim_viil_map" field.
  String? _naimViilMap;
  String get naimViilMap => _naimViilMap ?? '';
  bool hasNaimViilMap() => _naimViilMap != null;

  // "no_delete_place" field.
  bool? _noDeletePlace;
  bool get noDeletePlace => _noDeletePlace ?? false;
  bool hasNoDeletePlace() => _noDeletePlace != null;

  // "dolh" field.
  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  bool hasDolh() => _dolh != null;

  Map<String, String>? _namesI18n;
  Map<String, String> get namesI18n => _namesI18n ?? const {};
  Map<String, String>? _osfI18n;
  Map<String, String> get osfI18n => _osfI18n ?? const {};

  void _initializeFields() {
    _cities = docRefFromFirestore(snapshotData['cities']);
    _naim = snapshotData['naim'] as String?;
    _acctev = snapshotData['acctev'] as bool?;
    _osf = snapshotData['osf'] as String?;
    _img = snapshotData['img'] as String?;
    _latLing = snapshotData['lat_ling'] as LatLng?;
    _naimViilMap = snapshotData['naim_viil_map'] as String?;
    _noDeletePlace = snapshotData['no_delete_place'] as bool?;
    _dolh = docRefFromFirestore(snapshotData['dolh']);
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
      FirebaseFirestore.instance.collection('villages');

  static Stream<VillagesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => VillagesRecord.fromSnapshot(s));

  static Future<VillagesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => VillagesRecord.fromSnapshot(s));

  static VillagesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      VillagesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static VillagesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      VillagesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'VillagesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is VillagesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createVillagesRecordData({
  DocumentReference? cities,
  String? naim,
  bool? acctev,
  String? osf,
  String? img,
  LatLng? latLing,
  String? naimViilMap,
  bool? noDeletePlace,
  DocumentReference? dolh,
  Map<String, String>? namesI18n,
  Map<String, String>? osfI18n,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'cities': cities,
      'naim': naim,
      'acctev': acctev,
      'osf': osf,
      'img': img,
      'lat_ling': latLing,
      'naim_viil_map': naimViilMap,
      'no_delete_place': noDeletePlace,
      'dolh': dolh,
      'names_i18n': namesI18n,
      'osf_i18n': osfI18n,
    }.withoutNulls,
  );

  return firestoreData;
}

class VillagesRecordDocumentEquality implements Equality<VillagesRecord> {
  const VillagesRecordDocumentEquality();

  @override
  bool equals(VillagesRecord? e1, VillagesRecord? e2) {
    return e1?.cities == e2?.cities &&
        e1?.naim == e2?.naim &&
        e1?.acctev == e2?.acctev &&
        e1?.osf == e2?.osf &&
        e1?.img == e2?.img &&
        e1?.latLing == e2?.latLing &&
        e1?.naimViilMap == e2?.naimViilMap &&
        e1?.noDeletePlace == e2?.noDeletePlace &&
        e1?.dolh == e2?.dolh;
  }

  @override
  int hash(VillagesRecord? e) => const ListEquality().hash([
        e?.cities,
        e?.naim,
        e?.acctev,
        e?.osf,
        e?.img,
        e?.latLing,
        e?.naimViilMap,
        e?.noDeletePlace,
        e?.dolh
      ]);

  @override
  bool isValidKey(Object? o) => o is VillagesRecord;
}

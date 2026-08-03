import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdressuserRecord extends FirestoreRecord {
  AdressuserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "USER" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "TILET" field.
  String? _tilet;
  String get tilet => _tilet ?? '';
  bool hasTilet() => _tilet != null;

  // "VILL" field.
  DocumentReference? _vill;
  DocumentReference? get vill => _vill;
  bool hasVill() => _vill != null;

  // "map" field.
  LatLng? _map;
  LatLng? get map => _map;
  bool hasMap() => _map != null;

  // "naim_vill" field.
  String? _naimVill;
  String get naimVill => _naimVill ?? '';
  bool hasNaimVill() => _naimVill != null;

  // "data_add" field.
  DateTime? _dataAdd;
  DateTime? get dataAdd => _dataAdd;
  bool hasDataAdd() => _dataAdd != null;

  void _initializeFields() {
    _user = snapshotData['USER'] as DocumentReference?;
    _tilet = snapshotData['TILET'] as String?;
    _vill = snapshotData['VILL'] as DocumentReference?;
    _map = snapshotData['map'] as LatLng?;
    _naimVill = snapshotData['naim_vill'] as String?;
    _dataAdd = snapshotData['data_add'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ADRESSUSER');

  static Stream<AdressuserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AdressuserRecord.fromSnapshot(s));

  static Future<AdressuserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AdressuserRecord.fromSnapshot(s));

  static AdressuserRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AdressuserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AdressuserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AdressuserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AdressuserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AdressuserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAdressuserRecordData({
  DocumentReference? user,
  String? tilet,
  DocumentReference? vill,
  LatLng? map,
  String? naimVill,
  DateTime? dataAdd,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'USER': user,
      'TILET': tilet,
      'VILL': vill,
      'map': map,
      'naim_vill': naimVill,
      'data_add': dataAdd,
    }.withoutNulls,
  );

  return firestoreData;
}

class AdressuserRecordDocumentEquality implements Equality<AdressuserRecord> {
  const AdressuserRecordDocumentEquality();

  @override
  bool equals(AdressuserRecord? e1, AdressuserRecord? e2) {
    return e1?.user == e2?.user &&
        e1?.tilet == e2?.tilet &&
        e1?.vill == e2?.vill &&
        e1?.map == e2?.map &&
        e1?.naimVill == e2?.naimVill &&
        e1?.dataAdd == e2?.dataAdd;
  }

  @override
  int hash(AdressuserRecord? e) => const ListEquality()
      .hash([e?.user, e?.tilet, e?.vill, e?.map, e?.naimVill, e?.dataAdd]);

  @override
  bool isValidKey(Object? o) => o is AdressuserRecord;
}

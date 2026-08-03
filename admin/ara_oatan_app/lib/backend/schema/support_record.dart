import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SupportRecord extends FirestoreRecord {
  SupportRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  // "data" field.
  DateTime? _data;
  DateTime? get data => _data;
  bool hasData() => _data != null;

  // "RefUser" field.
  DocumentReference? _refUser;
  DocumentReference? get refUser => _refUser;
  bool hasRefUser() => _refUser != null;

  // "phone" field.
  int? _phone;
  int get phone => _phone ?? 0;
  bool hasPhone() => _phone != null;

  // "tsnef" field.
  String? _tsnef;
  String get tsnef => _tsnef ?? '';
  bool hasTsnef() => _tsnef != null;

  // "halh" field.
  Halhsupport? _halh;
  Halhsupport? get halh => _halh;
  bool hasHalh() => _halh != null;

  void _initializeFields() {
    _id = castToType<int>(snapshotData['id']);
    _naim = snapshotData['naim'] as String?;
    _osf = snapshotData['osf'] as String?;
    _data = snapshotData['data'] as DateTime?;
    _refUser = castDocRef(snapshotData['RefUser']);
    _phone = castToType<int>(snapshotData['phone']);
    _tsnef = snapshotData['tsnef'] as String?;
    _halh = snapshotData['halh'] is Halhsupport
        ? snapshotData['halh']
        : deserializeEnum<Halhsupport>(snapshotData['halh']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('support');

  static Stream<SupportRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SupportRecord.fromSnapshot(s));

  static Future<SupportRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SupportRecord.fromSnapshot(s));

  static SupportRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SupportRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SupportRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SupportRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SupportRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SupportRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSupportRecordData({
  int? id,
  String? naim,
  String? osf,
  DateTime? data,
  DocumentReference? refUser,
  int? phone,
  String? tsnef,
  Halhsupport? halh,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'id': id,
      'naim': naim,
      'osf': osf,
      'data': data,
      'RefUser': refUser,
      'phone': phone,
      'tsnef': tsnef,
      'halh': halh,
    }.withoutNulls,
  );

  return firestoreData;
}

class SupportRecordDocumentEquality implements Equality<SupportRecord> {
  const SupportRecordDocumentEquality();

  @override
  bool equals(SupportRecord? e1, SupportRecord? e2) {
    return e1?.id == e2?.id &&
        e1?.naim == e2?.naim &&
        e1?.osf == e2?.osf &&
        e1?.data == e2?.data &&
        e1?.refUser == e2?.refUser &&
        e1?.phone == e2?.phone &&
        e1?.tsnef == e2?.tsnef &&
        e1?.halh == e2?.halh;
  }

  @override
  int hash(SupportRecord? e) => const ListEquality().hash([
        e?.id,
        e?.naim,
        e?.osf,
        e?.data,
        e?.refUser,
        e?.phone,
        e?.tsnef,
        e?.halh
      ]);

  @override
  bool isValidKey(Object? o) => o is SupportRecord;
}

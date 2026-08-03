import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DemodeletRecord extends FirestoreRecord {
  DemodeletRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "iduser" field.
  DocumentReference? _iduser;
  DocumentReference? get iduser => _iduser;
  bool hasIduser() => _iduser != null;

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  void _initializeFields() {
    _iduser = snapshotData['iduser'] as DocumentReference?;
    _naim = snapshotData['naim'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('demodelet');

  static Stream<DemodeletRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DemodeletRecord.fromSnapshot(s));

  static Future<DemodeletRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DemodeletRecord.fromSnapshot(s));

  static DemodeletRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DemodeletRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DemodeletRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DemodeletRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DemodeletRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DemodeletRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDemodeletRecordData({
  DocumentReference? iduser,
  String? naim,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'iduser': iduser,
      'naim': naim,
    }.withoutNulls,
  );

  return firestoreData;
}

class DemodeletRecordDocumentEquality implements Equality<DemodeletRecord> {
  const DemodeletRecordDocumentEquality();

  @override
  bool equals(DemodeletRecord? e1, DemodeletRecord? e2) {
    return e1?.iduser == e2?.iduser && e1?.naim == e2?.naim;
  }

  @override
  int hash(DemodeletRecord? e) =>
      const ListEquality().hash([e?.iduser, e?.naim]);

  @override
  bool isValidKey(Object? o) => o is DemodeletRecord;
}

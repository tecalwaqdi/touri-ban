import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class IdlistorderRecord extends FirestoreRecord {
  IdlistorderRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  // "num" field.
  int? _num;
  int get num => _num ?? 0;
  bool hasNum() => _num != null;

  void _initializeFields() {
    _id = castToType<int>(snapshotData['id']);
    _num = castToType<int>(snapshotData['num']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('idlistorder');

  static Stream<IdlistorderRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => IdlistorderRecord.fromSnapshot(s));

  static Future<IdlistorderRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => IdlistorderRecord.fromSnapshot(s));

  static IdlistorderRecord fromSnapshot(DocumentSnapshot snapshot) =>
      IdlistorderRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static IdlistorderRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      IdlistorderRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'IdlistorderRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is IdlistorderRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createIdlistorderRecordData({
  int? id,
  int? num,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'id': id,
      'num': num,
    }.withoutNulls,
  );

  return firestoreData;
}

class IdlistorderRecordDocumentEquality implements Equality<IdlistorderRecord> {
  const IdlistorderRecordDocumentEquality();

  @override
  bool equals(IdlistorderRecord? e1, IdlistorderRecord? e2) {
    return e1?.id == e2?.id && e1?.num == e2?.num;
  }

  @override
  int hash(IdlistorderRecord? e) => const ListEquality().hash([e?.id, e?.num]);

  @override
  bool isValidKey(Object? o) => o is IdlistorderRecord;
}

import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BankRecord extends FirestoreRecord {
  BankRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "ID" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  void _initializeFields() {
    _id = castToType<int>(snapshotData['ID']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('bank');

  static Stream<BankRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BankRecord.fromSnapshot(s));

  static Future<BankRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BankRecord.fromSnapshot(s));

  static BankRecord fromSnapshot(DocumentSnapshot snapshot) => BankRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BankRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BankRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BankRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BankRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBankRecordData({
  int? id,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'ID': id,
    }.withoutNulls,
  );

  return firestoreData;
}

class BankRecordDocumentEquality implements Equality<BankRecord> {
  const BankRecordDocumentEquality();

  @override
  bool equals(BankRecord? e1, BankRecord? e2) {
    return e1?.id == e2?.id;
  }

  @override
  int hash(BankRecord? e) => const ListEquality().hash([e?.id]);

  @override
  bool isValidKey(Object? o) => o is BankRecord;
}

import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AutoNumRecord extends FirestoreRecord {
  AutoNumRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "auton" field.
  int? _auton;
  int get auton => _auton ?? 0;
  bool hasAuton() => _auton != null;

  void _initializeFields() {
    _auton = castToType<int>(snapshotData['auton']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('auto_num');

  static Stream<AutoNumRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AutoNumRecord.fromSnapshot(s));

  static Future<AutoNumRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AutoNumRecord.fromSnapshot(s));

  static AutoNumRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AutoNumRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AutoNumRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AutoNumRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AutoNumRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AutoNumRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAutoNumRecordData({
  int? auton,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'auton': auton,
    }.withoutNulls,
  );

  return firestoreData;
}

class AutoNumRecordDocumentEquality implements Equality<AutoNumRecord> {
  const AutoNumRecordDocumentEquality();

  @override
  bool equals(AutoNumRecord? e1, AutoNumRecord? e2) {
    return e1?.auton == e2?.auton;
  }

  @override
  int hash(AutoNumRecord? e) => const ListEquality().hash([e?.auton]);

  @override
  bool isValidKey(Object? o) => o is AutoNumRecord;
}

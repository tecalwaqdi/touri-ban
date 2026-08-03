import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ScondRecord extends FirestoreRecord {
  ScondRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "ssss" field.
  String? _ssss;
  String get ssss => _ssss ?? '';
  bool hasSsss() => _ssss != null;

  void _initializeFields() {
    _ssss = snapshotData['ssss'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('scond');

  static Stream<ScondRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ScondRecord.fromSnapshot(s));

  static Future<ScondRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ScondRecord.fromSnapshot(s));

  static ScondRecord fromSnapshot(DocumentSnapshot snapshot) => ScondRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ScondRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ScondRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ScondRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ScondRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createScondRecordData({
  String? ssss,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'ssss': ssss,
    }.withoutNulls,
  );

  return firestoreData;
}

class ScondRecordDocumentEquality implements Equality<ScondRecord> {
  const ScondRecordDocumentEquality();

  @override
  bool equals(ScondRecord? e1, ScondRecord? e2) {
    return e1?.ssss == e2?.ssss;
  }

  @override
  int hash(ScondRecord? e) => const ListEquality().hash([e?.ssss]);

  @override
  bool isValidKey(Object? o) => o is ScondRecord;
}

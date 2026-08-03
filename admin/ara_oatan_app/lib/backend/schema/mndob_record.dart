import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MndobRecord extends FirestoreRecord {
  MndobRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "phone" field.
  int? _phone;
  int get phone => _phone ?? 0;
  bool hasPhone() => _phone != null;

  void _initializeFields() {
    _phone = castToType<int>(snapshotData['phone']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('mndob');

  static Stream<MndobRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MndobRecord.fromSnapshot(s));

  static Future<MndobRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MndobRecord.fromSnapshot(s));

  static MndobRecord fromSnapshot(DocumentSnapshot snapshot) => MndobRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MndobRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MndobRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MndobRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MndobRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMndobRecordData({
  int? phone,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'phone': phone,
    }.withoutNulls,
  );

  return firestoreData;
}

class MndobRecordDocumentEquality implements Equality<MndobRecord> {
  const MndobRecordDocumentEquality();

  @override
  bool equals(MndobRecord? e1, MndobRecord? e2) {
    return e1?.phone == e2?.phone;
  }

  @override
  int hash(MndobRecord? e) => const ListEquality().hash([e?.phone]);

  @override
  bool isValidKey(Object? o) => o is MndobRecord;
}

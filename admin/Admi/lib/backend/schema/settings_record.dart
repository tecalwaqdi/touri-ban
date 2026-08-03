import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SettingsRecord extends FirestoreRecord {
  SettingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "ngl" field.
  bool? _ngl;
  bool get ngl => _ngl ?? false;
  bool hasNgl() => _ngl != null;

  // "dateU" field.
  DateTime? _dateU;
  DateTime? get dateU => _dateU;
  bool hasDateU() => _dateU != null;

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  // "islogenGoogle" field — enabled by default unless admin sets false.
  bool? _islogenGoogle;
  bool get islogenGoogle => _islogenGoogle ?? true;
  bool hasIslogenGoogle() => _islogenGoogle != null;

  void _initializeFields() {
    _ngl = snapshotData['ngl'] as bool?;
    _dateU = snapshotData['dateU'] as DateTime?;
    _id = castToType<int>(snapshotData['id']);
    _islogenGoogle = snapshotData['islogenGoogle'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Settings');

  static Stream<SettingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SettingsRecord.fromSnapshot(s));

  static Future<SettingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SettingsRecord.fromSnapshot(s));

  static SettingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SettingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SettingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SettingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SettingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SettingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSettingsRecordData({
  bool? ngl,
  DateTime? dateU,
  int? id,
  bool? islogenGoogle,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'ngl': ngl,
      'dateU': dateU,
      'id': id,
      'islogenGoogle': islogenGoogle,
    }.withoutNulls,
  );

  return firestoreData;
}

class SettingsRecordDocumentEquality implements Equality<SettingsRecord> {
  const SettingsRecordDocumentEquality();

  @override
  bool equals(SettingsRecord? e1, SettingsRecord? e2) {
    return e1?.ngl == e2?.ngl &&
        e1?.dateU == e2?.dateU &&
        e1?.id == e2?.id &&
        e1?.islogenGoogle == e2?.islogenGoogle;
  }

  @override
  int hash(SettingsRecord? e) =>
      const ListEquality().hash([e?.ngl, e?.dateU, e?.id, e?.islogenGoogle]);

  @override
  bool isValidKey(Object? o) => o is SettingsRecord;
}

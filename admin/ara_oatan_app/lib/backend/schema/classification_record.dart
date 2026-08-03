import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ClassificationRecord extends FirestoreRecord {
  ClassificationRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  // "acctev" field.
  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _osf = snapshotData['osf'] as String?;
    _acctev = snapshotData['acctev'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Classification');

  static Stream<ClassificationRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ClassificationRecord.fromSnapshot(s));

  static Future<ClassificationRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ClassificationRecord.fromSnapshot(s));

  static ClassificationRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ClassificationRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ClassificationRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ClassificationRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ClassificationRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ClassificationRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createClassificationRecordData({
  String? naim,
  String? osf,
  bool? acctev,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'osf': osf,
      'acctev': acctev,
    }.withoutNulls,
  );

  return firestoreData;
}

class ClassificationRecordDocumentEquality
    implements Equality<ClassificationRecord> {
  const ClassificationRecordDocumentEquality();

  @override
  bool equals(ClassificationRecord? e1, ClassificationRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.osf == e2?.osf &&
        e1?.acctev == e2?.acctev;
  }

  @override
  int hash(ClassificationRecord? e) =>
      const ListEquality().hash([e?.naim, e?.osf, e?.acctev]);

  @override
  bool isValidKey(Object? o) => o is ClassificationRecord;
}

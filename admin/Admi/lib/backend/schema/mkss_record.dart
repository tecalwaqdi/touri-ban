import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MkssRecord extends FirestoreRecord {
  MkssRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "loceshn" field.
  LatLng? _loceshn;
  LatLng? get loceshn => _loceshn;
  bool hasLoceshn() => _loceshn != null;

  // "sr" field.
  double? _sr;
  double get sr => _sr ?? 0.0;
  bool hasSr() => _sr != null;

  // "order" field.
  DocumentReference? _order;
  DocumentReference? get order => _order;
  bool hasOrder() => _order != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _loceshn = snapshotData['loceshn'] as LatLng?;
    _sr = castToType<double>(snapshotData['sr']);
    _order = snapshotData['order'] as DocumentReference?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('mkss')
          : FirebaseFirestore.instance.collectionGroup('mkss');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('mkss').doc(id);

  static Stream<MkssRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MkssRecord.fromSnapshot(s));

  static Future<MkssRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MkssRecord.fromSnapshot(s));

  static MkssRecord fromSnapshot(DocumentSnapshot snapshot) => MkssRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MkssRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MkssRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MkssRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MkssRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMkssRecordData({
  String? naim,
  LatLng? loceshn,
  double? sr,
  DocumentReference? order,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'loceshn': loceshn,
      'sr': sr,
      'order': order,
    }.withoutNulls,
  );

  return firestoreData;
}

class MkssRecordDocumentEquality implements Equality<MkssRecord> {
  const MkssRecordDocumentEquality();

  @override
  bool equals(MkssRecord? e1, MkssRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.loceshn == e2?.loceshn &&
        e1?.sr == e2?.sr &&
        e1?.order == e2?.order;
  }

  @override
  int hash(MkssRecord? e) =>
      const ListEquality().hash([e?.naim, e?.loceshn, e?.sr, e?.order]);

  @override
  bool isValidKey(Object? o) => o is MkssRecord;
}

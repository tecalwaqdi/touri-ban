import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ListamaknorderRecord extends FirestoreRecord {
  ListamaknorderRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "mkss" field.
  DocumentReference? _mkss;
  DocumentReference? get mkss => _mkss;
  bool hasMkss() => _mkss != null;

  // "loceshn" field.
  LatLng? _loceshn;
  LatLng? get loceshn => _loceshn;
  bool hasLoceshn() => _loceshn != null;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _mkss = snapshotData['mkss'] as DocumentReference?;
    _loceshn = snapshotData['loceshn'] as LatLng?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('listamaknorder');

  static Stream<ListamaknorderRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ListamaknorderRecord.fromSnapshot(s));

  static Future<ListamaknorderRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ListamaknorderRecord.fromSnapshot(s));

  static ListamaknorderRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ListamaknorderRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ListamaknorderRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ListamaknorderRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ListamaknorderRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ListamaknorderRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createListamaknorderRecordData({
  String? naim,
  DocumentReference? mkss,
  LatLng? loceshn,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'mkss': mkss,
      'loceshn': loceshn,
    }.withoutNulls,
  );

  return firestoreData;
}

class ListamaknorderRecordDocumentEquality
    implements Equality<ListamaknorderRecord> {
  const ListamaknorderRecordDocumentEquality();

  @override
  bool equals(ListamaknorderRecord? e1, ListamaknorderRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.mkss == e2?.mkss &&
        e1?.loceshn == e2?.loceshn;
  }

  @override
  int hash(ListamaknorderRecord? e) =>
      const ListEquality().hash([e?.naim, e?.mkss, e?.loceshn]);

  @override
  bool isValidKey(Object? o) => o is ListamaknorderRecord;
}

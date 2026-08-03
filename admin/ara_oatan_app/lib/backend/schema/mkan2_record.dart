import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class Mkan2Record extends FirestoreRecord {
  Mkan2Record._(
    super.reference,
    super.data,
  ) {
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

  // "list" field.
  List<AmaknCostmStruct>? _list;
  List<AmaknCostmStruct> get list => _list ?? const [];
  bool hasList() => _list != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _loceshn = snapshotData['loceshn'] as LatLng?;
    _list = getStructList(
      snapshotData['list'],
      AmaknCostmStruct.fromMap,
    );
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('mkan2')
          : FirebaseFirestore.instance.collectionGroup('mkan2');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('mkan2').doc(id);

  static Stream<Mkan2Record> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => Mkan2Record.fromSnapshot(s));

  static Future<Mkan2Record> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => Mkan2Record.fromSnapshot(s));

  static Mkan2Record fromSnapshot(DocumentSnapshot snapshot) => Mkan2Record._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static Mkan2Record getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      Mkan2Record._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'Mkan2Record(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is Mkan2Record &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMkan2RecordData({
  String? naim,
  LatLng? loceshn,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'loceshn': loceshn,
    }.withoutNulls,
  );

  return firestoreData;
}

class Mkan2RecordDocumentEquality implements Equality<Mkan2Record> {
  const Mkan2RecordDocumentEquality();

  @override
  bool equals(Mkan2Record? e1, Mkan2Record? e2) {
    const listEquality = ListEquality();
    return e1?.naim == e2?.naim &&
        e1?.loceshn == e2?.loceshn &&
        listEquality.equals(e1?.list, e2?.list);
  }

  @override
  int hash(Mkan2Record? e) =>
      const ListEquality().hash([e?.naim, e?.loceshn, e?.list]);

  @override
  bool isValidKey(Object? o) => o is Mkan2Record;
}

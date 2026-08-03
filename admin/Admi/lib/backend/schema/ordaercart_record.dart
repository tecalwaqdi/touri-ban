import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrdaercartRecord extends FirestoreRecord {
  OrdaercartRecord._(
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

  // "img" field.
  String? _img;
  String get img => _img ?? '';
  bool hasImg() => _img != null;

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "list" field.
  List<AmaknCostmStruct>? _list;
  List<AmaknCostmStruct> get list => _list ?? const [];
  bool hasList() => _list != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _loceshn = snapshotData['loceshn'] as LatLng?;
    _img = snapshotData['img'] as String?;
    _user = snapshotData['user'] as DocumentReference?;
    _list = getStructList(
      snapshotData['list'],
      AmaknCostmStruct.fromMap,
    );
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('ordaercart')
          : FirebaseFirestore.instance.collectionGroup('ordaercart');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('ordaercart').doc(id);

  static Stream<OrdaercartRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrdaercartRecord.fromSnapshot(s));

  static Future<OrdaercartRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrdaercartRecord.fromSnapshot(s));

  static OrdaercartRecord fromSnapshot(DocumentSnapshot snapshot) =>
      OrdaercartRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OrdaercartRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OrdaercartRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OrdaercartRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OrdaercartRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrdaercartRecordData({
  String? naim,
  LatLng? loceshn,
  String? img,
  DocumentReference? user,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'loceshn': loceshn,
      'img': img,
      'user': user,
    }.withoutNulls,
  );

  return firestoreData;
}

class OrdaercartRecordDocumentEquality implements Equality<OrdaercartRecord> {
  const OrdaercartRecordDocumentEquality();

  @override
  bool equals(OrdaercartRecord? e1, OrdaercartRecord? e2) {
    const listEquality = ListEquality();
    return e1?.naim == e2?.naim &&
        e1?.loceshn == e2?.loceshn &&
        e1?.img == e2?.img &&
        e1?.user == e2?.user &&
        listEquality.equals(e1?.list, e2?.list);
  }

  @override
  int hash(OrdaercartRecord? e) => const ListEquality()
      .hash([e?.naim, e?.loceshn, e?.img, e?.user, e?.list]);

  @override
  bool isValidKey(Object? o) => o is OrdaercartRecord;
}

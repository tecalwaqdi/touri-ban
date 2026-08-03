import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class Order2Record extends FirestoreRecord {
  Order2Record._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "vill" field.
  DocumentReference? _vill;
  DocumentReference? get vill => _vill;
  bool hasVill() => _vill != null;

  // "list" field.
  List<DocumentReference>? _list;
  List<DocumentReference> get list => _list ?? const [];
  bool hasList() => _list != null;

  // "listdatarhlh" field.
  List<DatarhlhStruct>? _listdatarhlh;
  List<DatarhlhStruct> get listdatarhlh => _listdatarhlh ?? const [];
  bool hasListdatarhlh() => _listdatarhlh != null;

  // "Rhlat" field.
  DatarhlhStruct? _rhlat;
  DatarhlhStruct get rhlat => _rhlat ?? DatarhlhStruct();
  bool hasRhlat() => _rhlat != null;

  // "dolh" field.
  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  bool hasDolh() => _dolh != null;

  // "amakn_cos" field.
  List<AmaknCostmStruct>? _amaknCos;
  List<AmaknCostmStruct> get amaknCos => _amaknCos ?? const [];
  bool hasAmaknCos() => _amaknCos != null;

  void _initializeFields() {
    _user = snapshotData['user'] as DocumentReference?;
    _vill = snapshotData['vill'] as DocumentReference?;
    _list = getDataList(snapshotData['list']);
    _listdatarhlh = getStructList(
      snapshotData['listdatarhlh'],
      DatarhlhStruct.fromMap,
    );
    _rhlat = snapshotData['Rhlat'] is DatarhlhStruct
        ? snapshotData['Rhlat']
        : DatarhlhStruct.maybeFromMap(snapshotData['Rhlat']);
    _dolh = snapshotData['dolh'] as DocumentReference?;
    _amaknCos = getStructList(
      snapshotData['amakn_cos'],
      AmaknCostmStruct.fromMap,
    );
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('order2');

  static Stream<Order2Record> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => Order2Record.fromSnapshot(s));

  static Future<Order2Record> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => Order2Record.fromSnapshot(s));

  static Order2Record fromSnapshot(DocumentSnapshot snapshot) => Order2Record._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static Order2Record getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      Order2Record._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'Order2Record(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is Order2Record &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrder2RecordData({
  DocumentReference? user,
  DocumentReference? vill,
  DatarhlhStruct? rhlat,
  DocumentReference? dolh,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
      'vill': vill,
      'Rhlat': DatarhlhStruct().toMap(),
      'dolh': dolh,
    }.withoutNulls,
  );

  // Handle nested data for "Rhlat" field.
  addDatarhlhStructData(firestoreData, rhlat, 'Rhlat');

  return firestoreData;
}

class Order2RecordDocumentEquality implements Equality<Order2Record> {
  const Order2RecordDocumentEquality();

  @override
  bool equals(Order2Record? e1, Order2Record? e2) {
    const listEquality = ListEquality();
    return e1?.user == e2?.user &&
        e1?.vill == e2?.vill &&
        listEquality.equals(e1?.list, e2?.list) &&
        listEquality.equals(e1?.listdatarhlh, e2?.listdatarhlh) &&
        e1?.rhlat == e2?.rhlat &&
        e1?.dolh == e2?.dolh &&
        listEquality.equals(e1?.amaknCos, e2?.amaknCos);
  }

  @override
  int hash(Order2Record? e) => const ListEquality().hash([
        e?.user,
        e?.vill,
        e?.list,
        e?.listdatarhlh,
        e?.rhlat,
        e?.dolh,
        e?.amaknCos
      ]);

  @override
  bool isValidKey(Object? o) => o is Order2Record;
}

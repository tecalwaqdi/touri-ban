import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrderMkssRecord extends FirestoreRecord {
  OrderMkssRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

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

  void _initializeFields() {
    _user = snapshotData['user'] as DocumentReference?;
    _naim = snapshotData['naim'] as String?;
    _loceshn = snapshotData['loceshn'] as LatLng?;
    _sr = castToType<double>(snapshotData['sr']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('order_mkss');

  static Stream<OrderMkssRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrderMkssRecord.fromSnapshot(s));

  static Future<OrderMkssRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrderMkssRecord.fromSnapshot(s));

  static OrderMkssRecord fromSnapshot(DocumentSnapshot snapshot) =>
      OrderMkssRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OrderMkssRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OrderMkssRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OrderMkssRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OrderMkssRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrderMkssRecordData({
  DocumentReference? user,
  String? naim,
  LatLng? loceshn,
  double? sr,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
      'naim': naim,
      'loceshn': loceshn,
      'sr': sr,
    }.withoutNulls,
  );

  return firestoreData;
}

class OrderMkssRecordDocumentEquality implements Equality<OrderMkssRecord> {
  const OrderMkssRecordDocumentEquality();

  @override
  bool equals(OrderMkssRecord? e1, OrderMkssRecord? e2) {
    return e1?.user == e2?.user &&
        e1?.naim == e2?.naim &&
        e1?.loceshn == e2?.loceshn &&
        e1?.sr == e2?.sr;
  }

  @override
  int hash(OrderMkssRecord? e) =>
      const ListEquality().hash([e?.user, e?.naim, e?.loceshn, e?.sr]);

  @override
  bool isValidKey(Object? o) => o is OrderMkssRecord;
}

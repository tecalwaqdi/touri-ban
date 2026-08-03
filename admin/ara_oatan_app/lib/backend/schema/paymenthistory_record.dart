import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PaymenthistoryRecord extends FirestoreRecord {
  PaymenthistoryRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "revOrder" field.
  DocumentReference? _revOrder;
  DocumentReference? get revOrder => _revOrder;
  bool hasRevOrder() => _revOrder != null;

  // "RevUser" field.
  DocumentReference? _revUser;
  DocumentReference? get revUser => _revUser;
  bool hasRevUser() => _revUser != null;

  // "Osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  // "DateAdd" field.
  DateTime? _dateAdd;
  DateTime? get dateAdd => _dateAdd;
  bool hasDateAdd() => _dateAdd != null;

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  // "total" field.
  double? _total;
  double get total => _total ?? 0.0;
  bool hasTotal() => _total != null;

  // "myserReference" field.
  String? _myserReference;
  String get myserReference => _myserReference ?? '';
  bool hasMyserReference() => _myserReference != null;

  void _initializeFields() {
    _revOrder = castDocRef(snapshotData['revOrder']);
    _revUser = castDocRef(snapshotData['RevUser']);
    _osf = snapshotData['Osf'] as String?;
    _dateAdd = snapshotData['DateAdd'] as DateTime?;
    _id = castToType<int>(snapshotData['id']);
    _total = castToType<double>(snapshotData['total']);
    _myserReference = snapshotData['myserReference'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Paymenthistory');

  static Stream<PaymenthistoryRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PaymenthistoryRecord.fromSnapshot(s));

  static Future<PaymenthistoryRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PaymenthistoryRecord.fromSnapshot(s));

  static PaymenthistoryRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PaymenthistoryRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PaymenthistoryRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PaymenthistoryRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PaymenthistoryRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PaymenthistoryRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPaymenthistoryRecordData({
  DocumentReference? revOrder,
  DocumentReference? revUser,
  String? osf,
  DateTime? dateAdd,
  int? id,
  double? total,
  String? myserReference,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'revOrder': revOrder,
      'RevUser': revUser,
      'Osf': osf,
      'DateAdd': dateAdd,
      'id': id,
      'total': total,
      'myserReference': myserReference,
    }.withoutNulls,
  );

  return firestoreData;
}

class PaymenthistoryRecordDocumentEquality
    implements Equality<PaymenthistoryRecord> {
  const PaymenthistoryRecordDocumentEquality();

  @override
  bool equals(PaymenthistoryRecord? e1, PaymenthistoryRecord? e2) {
    return e1?.revOrder == e2?.revOrder &&
        e1?.revUser == e2?.revUser &&
        e1?.osf == e2?.osf &&
        e1?.dateAdd == e2?.dateAdd &&
        e1?.id == e2?.id &&
        e1?.total == e2?.total &&
        e1?.myserReference == e2?.myserReference;
  }

  @override
  int hash(PaymenthistoryRecord? e) => const ListEquality().hash([
        e?.revOrder,
        e?.revUser,
        e?.osf,
        e?.dateAdd,
        e?.id,
        e?.total,
        e?.myserReference
      ]);

  @override
  bool isValidKey(Object? o) => o is PaymenthistoryRecord;
}

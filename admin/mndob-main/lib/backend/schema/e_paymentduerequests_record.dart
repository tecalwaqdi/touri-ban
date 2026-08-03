import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EPaymentduerequestsRecord extends FirestoreRecord {
  EPaymentduerequestsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userRev" field.
  DocumentReference? _userRev;
  DocumentReference? get userRev => _userRev;
  bool hasUserRev() => _userRev != null;

  // "total" field.
  double? _total;
  double get total => _total ?? 0.0;
  bool hasTotal() => _total != null;

  // "osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  bool hasOsf() => _osf != null;

  // "dateAdd" field.
  DateTime? _dateAdd;
  DateTime? get dateAdd => _dateAdd;
  bool hasDateAdd() => _dateAdd != null;

  // "okPay" field.
  bool? _okPay;
  bool get okPay => _okPay ?? false;
  bool hasOkPay() => _okPay != null;

  void _initializeFields() {
    _userRev = snapshotData['userRev'] as DocumentReference?;
    _total = castToType<double>(snapshotData['total']);
    _osf = snapshotData['osf'] as String?;
    _dateAdd = snapshotData['dateAdd'] as DateTime?;
    _okPay = snapshotData['okPay'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('E-paymentduerequests');

  static Stream<EPaymentduerequestsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EPaymentduerequestsRecord.fromSnapshot(s));

  static Future<EPaymentduerequestsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => EPaymentduerequestsRecord.fromSnapshot(s));

  static EPaymentduerequestsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EPaymentduerequestsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EPaymentduerequestsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EPaymentduerequestsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EPaymentduerequestsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EPaymentduerequestsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEPaymentduerequestsRecordData({
  DocumentReference? userRev,
  double? total,
  String? osf,
  DateTime? dateAdd,
  bool? okPay,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userRev': userRev,
      'total': total,
      'osf': osf,
      'dateAdd': dateAdd,
      'okPay': okPay,
    }.withoutNulls,
  );

  return firestoreData;
}

class EPaymentduerequestsRecordDocumentEquality
    implements Equality<EPaymentduerequestsRecord> {
  const EPaymentduerequestsRecordDocumentEquality();

  @override
  bool equals(EPaymentduerequestsRecord? e1, EPaymentduerequestsRecord? e2) {
    return e1?.userRev == e2?.userRev &&
        e1?.total == e2?.total &&
        e1?.osf == e2?.osf &&
        e1?.dateAdd == e2?.dateAdd &&
        e1?.okPay == e2?.okPay;
  }

  @override
  int hash(EPaymentduerequestsRecord? e) => const ListEquality()
      .hash([e?.userRev, e?.total, e?.osf, e?.dateAdd, e?.okPay]);

  @override
  bool isValidKey(Object? o) => o is EPaymentduerequestsRecord;
}

import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PaymentMethodsRecord extends FirestoreRecord {
  PaymentMethodsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "userRev" field.
  DocumentReference? _userRev;
  DocumentReference? get userRev => _userRev;
  bool hasUserRev() => _userRev != null;

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  /// PCI-safe last four digits only (preferred storage field).
  String? _last4;
  String get last4 => _last4 ?? '';
  bool hasLast4() => _last4 != null;

  // Legacy — may exist on old documents; never written by the app.
  // "yy" field.
  String? _yy;
  String get yy => _yy ?? '';
  bool hasYy() => _yy != null;

  // "mm" field.
  String? _mm;
  String get mm => _mm ?? '';
  bool hasMm() => _mm != null;

  // Legacy CVV — may exist on old documents; never written by the app.
  // "acctev" field.
  bool? _acctev;
  bool get acctev => _acctev ?? false;
  bool hasAcctev() => _acctev != null;

  // "dataAdd" field.
  DateTime? _dataAdd;
  DateTime? get dataAdd => _dataAdd;
  bool hasDataAdd() => _dataAdd != null;

  /// Display-safe last four digits (prefers [last4], falls back for legacy docs).
  String get displayLast4 => last4;

  void _initializeFields() {
    _userRev = castDocRef(snapshotData['userRev']);
    _naim = snapshotData['naim'] as String?;
    _last4 = snapshotData['last4'] as String?;
    _yy = snapshotData['yy'] as String?;
    _mm = snapshotData['mm'] as String?;
    _acctev = snapshotData['acctev'] as bool?;
    _dataAdd = snapshotData['dataAdd'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('PaymentMethods');

  static Stream<PaymentMethodsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PaymentMethodsRecord.fromSnapshot(s));

  static Future<PaymentMethodsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PaymentMethodsRecord.fromSnapshot(s));

  static PaymentMethodsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PaymentMethodsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PaymentMethodsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PaymentMethodsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PaymentMethodsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PaymentMethodsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPaymentMethodsRecordData({
  DocumentReference? userRev,
  String? naim,
  String? last4,
  String? yy,
  String? mm,
  bool? acctev,
  DateTime? dataAdd,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userRev': userRev,
      'naim': naim,
      'last4': last4,
      'yy': yy,
      'mm': mm,
      'acctev': acctev,
      'dataAdd': dataAdd,
    }.withoutNulls,
  );

  return firestoreData;
}

class PaymentMethodsRecordDocumentEquality
    implements Equality<PaymentMethodsRecord> {
  const PaymentMethodsRecordDocumentEquality();

  @override
  bool equals(PaymentMethodsRecord? e1, PaymentMethodsRecord? e2) {
    return e1?.userRev == e2?.userRev &&
        e1?.naim == e2?.naim &&
        e1?.last4 == e2?.last4 &&
        e1?.yy == e2?.yy &&
        e1?.mm == e2?.mm &&
        e1?.acctev == e2?.acctev &&
        e1?.dataAdd == e2?.dataAdd;
  }

  @override
  int hash(PaymentMethodsRecord? e) => const ListEquality().hash([
        e?.userRev,
        e?.naim,
        e?.last4,
        e?.yy,
        e?.mm,
        e?.acctev,
        e?.dataAdd,
      ]);

  @override
  bool isValidKey(Object? o) => o is PaymentMethodsRecord;
}

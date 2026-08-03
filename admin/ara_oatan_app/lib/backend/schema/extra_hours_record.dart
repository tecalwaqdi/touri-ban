import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ExtraHoursRecord extends FirestoreRecord {
  ExtraHoursRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "revUser" field.
  DocumentReference? _revUser;
  DocumentReference? get revUser => _revUser;
  bool hasRevUser() => _revUser != null;

  // "RevOrder" field.
  DocumentReference? _revOrder;
  DocumentReference? get revOrder => _revOrder;
  bool hasRevOrder() => _revOrder != null;

  // "RevMndob" field.
  DocumentReference? _revMndob;
  DocumentReference? get revMndob => _revMndob;
  bool hasRevMndob() => _revMndob != null;

  // "addSaat" field.
  int? _addSaat;
  int get addSaat => _addSaat ?? 0;
  bool hasAddSaat() => _addSaat != null;

  // "Total" field.
  double? _total;
  double get total => _total ?? 0.0;
  bool hasTotal() => _total != null;

  // "dateAdd" field.
  DateTime? _dateAdd;
  DateTime? get dateAdd => _dateAdd;
  bool hasDateAdd() => _dateAdd != null;

  // "halh" field.
  HalhOrder? _halh;
  HalhOrder? get halh => _halh;
  bool hasHalh() => _halh != null;

  // "paymentGatewayOrderId" field — Network International payment reference.
  String? _paymentGatewayOrderId;
  String get paymentGatewayOrderId => _paymentGatewayOrderId ?? '';
  bool hasPaymentGatewayOrderId() => _paymentGatewayOrderId != null;

  // "idPymentMoyser" field — legacy fallback.
  String? _idPymentMoyser;
  @Deprecated('Use paymentGatewayOrderId')
  String get idPymentMoyser =>
      paymentGatewayOrderId.isNotEmpty
          ? paymentGatewayOrderId
          : (_idPymentMoyser ?? '');
  bool hasIdPymentMoyser() =>
      hasPaymentGatewayOrderId() || _idPymentMoyser != null;

  // "idOrder" field.
  String? _idOrder;
  String get idOrder => _idOrder ?? '';
  bool hasIdOrder() => _idOrder != null;

  void _initializeFields() {
    _revUser = castDocRef(snapshotData['revUser']);
    _revOrder = castDocRef(snapshotData['RevOrder']);
    _revMndob = castDocRef(snapshotData['RevMndob']);
    _addSaat = castToType<int>(snapshotData['addSaat']);
    _total = castToType<double>(snapshotData['Total']);
    _dateAdd = snapshotData['dateAdd'] as DateTime?;
    _halh = snapshotData['halh'] is HalhOrder
        ? snapshotData['halh']
        : deserializeEnum<HalhOrder>(snapshotData['halh']);
    _paymentGatewayOrderId = (snapshotData['paymentGatewayOrderId'] ??
            snapshotData['idPymentMoyser'])
        as String?;
    _idPymentMoyser = snapshotData['idPymentMoyser'] as String?;
    _idOrder = snapshotData['idOrder'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ExtraHours');

  static Stream<ExtraHoursRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ExtraHoursRecord.fromSnapshot(s));

  static Future<ExtraHoursRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ExtraHoursRecord.fromSnapshot(s));

  static ExtraHoursRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ExtraHoursRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ExtraHoursRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ExtraHoursRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ExtraHoursRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ExtraHoursRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createExtraHoursRecordData({
  DocumentReference? revUser,
  DocumentReference? revOrder,
  DocumentReference? revMndob,
  int? addSaat,
  double? total,
  DateTime? dateAdd,
  HalhOrder? halh,
  String? paymentGatewayOrderId,
  String? idOrder,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'revUser': revUser,
      'RevOrder': revOrder,
      'RevMndob': revMndob,
      'addSaat': addSaat,
      'Total': total,
      'dateAdd': dateAdd,
      'halh': halh,
      'paymentGatewayOrderId': paymentGatewayOrderId,
      'idOrder': idOrder,
    }.withoutNulls,
  );

  return firestoreData;
}

class ExtraHoursRecordDocumentEquality implements Equality<ExtraHoursRecord> {
  const ExtraHoursRecordDocumentEquality();

  @override
  bool equals(ExtraHoursRecord? e1, ExtraHoursRecord? e2) {
    return e1?.revUser == e2?.revUser &&
        e1?.revOrder == e2?.revOrder &&
        e1?.revMndob == e2?.revMndob &&
        e1?.addSaat == e2?.addSaat &&
        e1?.total == e2?.total &&
        e1?.dateAdd == e2?.dateAdd &&
        e1?.halh == e2?.halh &&
        e1?.paymentGatewayOrderId == e2?.paymentGatewayOrderId &&
        e1?.idOrder == e2?.idOrder;
  }

  @override
  int hash(ExtraHoursRecord? e) => const ListEquality().hash([
        e?.revUser,
        e?.revOrder,
        e?.revMndob,
        e?.addSaat,
        e?.total,
        e?.dateAdd,
        e?.halh,
        e?.paymentGatewayOrderId,
        e?.idOrder
      ]);

  @override
  bool isValidKey(Object? o) => o is ExtraHoursRecord;
}

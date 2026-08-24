import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BankRecord extends FirestoreRecord {
  BankRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "infoBank" field.
  String? _infoBank;
  String get infoBank => _infoBank ?? '';
  bool hasInfoBank() => _infoBank != null;

  // "phone" field.
  String? _phone;
  String get phone => _phone ?? '';
  bool hasPhone() => _phone != null;

  // "BankName" field.
  String? _bankName;
  String get bankName => _bankName ?? '';
  bool hasBankName() => _bankName != null;

  // "AccountNumber" field.
  String? _accountNumber;
  String get accountNumber => _accountNumber ?? '';
  bool hasAccountNumber() => _accountNumber != null;

  // "IBAN" field.
  String? _iban;
  String get iban => _iban ?? '';
  bool hasIban() => _iban != null;

  // "AccountHolder" field.
  String? _accountHolder;
  String get accountHolder => _accountHolder ?? '';
  bool hasAccountHolder() => _accountHolder != null;

  // "ID" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  void _initializeFields() {
    _infoBank = snapshotData['infoBank'] as String?;
    _phone = snapshotData['phone'] as String?;
    _bankName = snapshotData['BankName'] as String?;
    _accountNumber = snapshotData['AccountNumber'] as String?;
    _iban = snapshotData['IBAN'] as String?;
    _accountHolder = snapshotData['AccountHolder'] as String?;
    _id = castToType<int>(snapshotData['ID']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('bank');

  static Stream<BankRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BankRecord.fromSnapshot(s));

  static Future<BankRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BankRecord.fromSnapshot(s));

  static BankRecord fromSnapshot(DocumentSnapshot snapshot) => BankRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BankRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BankRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BankRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BankRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBankRecordData({
  String? infoBank,
  String? phone,
  String? bankName,
  String? accountNumber,
  String? iban,
  String? accountHolder,
  int? id,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'infoBank': infoBank,
      'phone': phone,
      'BankName': bankName,
      'AccountNumber': accountNumber,
      'IBAN': iban,
      'AccountHolder': accountHolder,
      'ID': id,
    }.withoutNulls,
  );

  return firestoreData;
}

class BankRecordDocumentEquality implements Equality<BankRecord> {
  const BankRecordDocumentEquality();

  @override
  bool equals(BankRecord? e1, BankRecord? e2) {
    return e1?.infoBank == e2?.infoBank &&
        e1?.phone == e2?.phone &&
        e1?.bankName == e2?.bankName &&
        e1?.accountNumber == e2?.accountNumber &&
        e1?.iban == e2?.iban &&
        e1?.accountHolder == e2?.accountHolder &&
        e1?.id == e2?.id;
  }

  @override
  int hash(BankRecord? e) => const ListEquality().hash([
        e?.infoBank,
        e?.phone,
        e?.bankName,
        e?.accountNumber,
        e?.iban,
        e?.accountHolder,
        e?.id
      ]);

  @override
  bool isValidKey(Object? o) => o is BankRecord;
}

import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TransactionRecord extends FirestoreRecord {
  TransactionRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "userRef" field
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "walletRef" field
  DocumentReference? _walletRef;
  DocumentReference? get walletRef => _walletRef;
  bool hasWalletRef() => _walletRef != null;

  // "transactionId" field - unique ID for transaction
  String? _transactionId;
  String get transactionId => _transactionId ?? '';
  bool hasTransactionId() => _transactionId != null;

  // "amount" field
  double? _amount;
  double get amount => _amount ?? 0.0;
  bool hasAmount() => _amount != null;

  // "type" field - 'credit', 'debit', 'refund', 'transfer'
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "description" field
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "paymentMethodRef" field - optional, links to PaymentMethodsRecord
  DocumentReference? _paymentMethodRef;
  DocumentReference? get paymentMethodRef => _paymentMethodRef;
  bool hasPaymentMethodRef() => _paymentMethodRef != null;

  // "status" field - 'completed', 'pending', 'failed', 'cancelled'
  String? _status;
  String get status => _status ?? 'pending';
  bool hasStatus() => _status != null;

  // "createdAt" field
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updatedAt" field
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "referenceId" field - for order reference, refund reference, etc.
  String? _referenceId;
  String get referenceId => _referenceId ?? '';
  bool hasReferenceId() => _referenceId != null;

  // "notes" field - additional information
  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  void _initializeFields() {
    _userRef = castDocRef(snapshotData['userRef']);
    _walletRef = castDocRef(snapshotData['walletRef']);
    _transactionId = snapshotData['transactionId'] as String?;
    _amount = castToType<double>(snapshotData['amount']);
    _type = snapshotData['type'] as String?;
    _description = snapshotData['description'] as String?;
    _paymentMethodRef = castDocRef(snapshotData['paymentMethodRef']);
    _status = snapshotData['status'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _updatedAt = snapshotData['updatedAt'] as DateTime?;
    _referenceId = snapshotData['referenceId'] as String?;
    _notes = snapshotData['notes'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('transactions');

  static Stream<TransactionRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TransactionRecord.fromSnapshot(s));

  static Future<TransactionRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TransactionRecord.fromSnapshot(s));

  static TransactionRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TransactionRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TransactionRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TransactionRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TransactionRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TransactionRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTransactionRecordData({
  DocumentReference? userRef,
  DocumentReference? walletRef,
  String? transactionId,
  double? amount,
  String? type,
  String? description,
  DocumentReference? paymentMethodRef,
  String? status,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? referenceId,
  String? notes,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userRef': userRef,
      'walletRef': walletRef,
      'transactionId': transactionId,
      'amount': amount,
      'type': type,
      'description': description,
      'paymentMethodRef': paymentMethodRef,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'referenceId': referenceId,
      'notes': notes,
    }.withoutNulls,
  );

  return firestoreData;
}

class TransactionRecordDocumentEquality implements Equality<TransactionRecord> {
  const TransactionRecordDocumentEquality();

  @override
  bool equals(TransactionRecord? e1, TransactionRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.walletRef == e2?.walletRef &&
        e1?.transactionId == e2?.transactionId &&
        e1?.amount == e2?.amount &&
        e1?.type == e2?.type &&
        e1?.description == e2?.description &&
        e1?.paymentMethodRef == e2?.paymentMethodRef &&
        e1?.status == e2?.status &&
        e1?.createdAt == e2?.createdAt &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.referenceId == e2?.referenceId &&
        e1?.notes == e2?.notes;
  }

  @override
  int hash(TransactionRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.walletRef,
        e?.transactionId,
        e?.amount,
        e?.type,
        e?.description,
        e?.paymentMethodRef,
        e?.status,
        e?.createdAt,
        e?.updatedAt,
        e?.referenceId,
        e?.notes
      ]);

  @override
  bool isValidKey(Object? o) => o is TransactionRecord;
}
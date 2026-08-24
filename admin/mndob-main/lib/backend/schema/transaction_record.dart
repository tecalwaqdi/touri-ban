import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TransactionRecord extends FirestoreRecord {
  TransactionRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  DocumentReference? _walletRef;
  DocumentReference? get walletRef => _walletRef;
  bool hasWalletRef() => _walletRef != null;

  String? _transactionId;
  String get transactionId => _transactionId ?? '';
  bool hasTransactionId() => _transactionId != null;

  double? _amount;
  double get amount => _amount ?? 0.0;
  bool hasAmount() => _amount != null;

  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  String? _status;
  String get status => _status ?? 'pending';
  bool hasStatus() => _status != null;

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  String? _referenceId;
  String get referenceId => _referenceId ?? '';
  bool hasReferenceId() => _referenceId != null;

  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  void _initializeFields() {
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _walletRef = snapshotData['walletRef'] as DocumentReference?;
    _transactionId = snapshotData['transactionId'] as String?;
    _amount = castToType<double>(snapshotData['amount']);
    _type = snapshotData['type'] as String?;
    _description = snapshotData['description'] as String?;
    _status = snapshotData['status'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
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

class TransactionRecordDocumentEquality
    implements Equality<TransactionRecord> {
  const TransactionRecordDocumentEquality();

  @override
  bool equals(TransactionRecord? e1, TransactionRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.amount == e2?.amount &&
        e1?.type == e2?.type &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(TransactionRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.amount,
        e?.type,
        e?.createdAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is TransactionRecord;
}

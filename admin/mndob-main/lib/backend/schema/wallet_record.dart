import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class WalletRecord extends FirestoreRecord {
  WalletRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  double? _currentBalance;
  double get currentBalance => _currentBalance ?? 0.0;
  bool hasCurrentBalance() => _currentBalance != null;

  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;
  bool hasLastUpdated() => _lastUpdated != null;

  String? _currency;
  String get currency => _currency ?? 'SAR';
  bool hasCurrency() => _currency != null;

  bool? _isActive;
  bool get isActive => _isActive ?? true;
  bool hasIsActive() => _isActive != null;

  void _initializeFields() {
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _currentBalance = castToType<double>(snapshotData['currentBalance']);
    _lastUpdated = snapshotData['lastUpdated'] as DateTime?;
    _currency = snapshotData['currency'] as String?;
    _isActive = snapshotData['isActive'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('wallets');

  static Stream<WalletRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => WalletRecord.fromSnapshot(s));

  static Future<WalletRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => WalletRecord.fromSnapshot(s));

  static WalletRecord fromSnapshot(DocumentSnapshot snapshot) => WalletRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static WalletRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      WalletRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'WalletRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is WalletRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createWalletRecordData({
  DocumentReference? userRef,
  double? currentBalance,
  DateTime? lastUpdated,
  String? currency,
  bool? isActive,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'userRef': userRef,
      'currentBalance': currentBalance,
      'lastUpdated': lastUpdated,
      'currency': currency,
      'isActive': isActive,
    }.withoutNulls,
  );
}

class WalletRecordDocumentEquality implements Equality<WalletRecord> {
  const WalletRecordDocumentEquality();

  @override
  bool equals(WalletRecord? e1, WalletRecord? e2) {
    return e1?.userRef == e2?.userRef &&
        e1?.currentBalance == e2?.currentBalance &&
        e1?.lastUpdated == e2?.lastUpdated &&
        e1?.currency == e2?.currency &&
        e1?.isActive == e2?.isActive;
  }

  @override
  int hash(WalletRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.currentBalance,
        e?.lastUpdated,
        e?.currency,
        e?.isActive,
      ]);

  @override
  bool isValidKey(Object? o) => o is WalletRecord;
}

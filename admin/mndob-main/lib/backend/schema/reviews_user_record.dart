import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReviewsUserRecord extends FirestoreRecord {
  ReviewsUserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "RevUser" field.
  DocumentReference? _revUser;
  DocumentReference? get revUser => _revUser;
  bool hasRevUser() => _revUser != null;

  // "REVIEWSmsg" field.
  String? _rEVIEWSmsg;
  String get rEVIEWSmsg => _rEVIEWSmsg ?? '';
  bool hasREVIEWSmsg() => _rEVIEWSmsg != null;

  // "Ret" field.
  int? _ret;
  int get ret => _ret ?? 0;
  bool hasRet() => _ret != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "UserAlSend" field.
  DocumentReference? _userAlSend;
  DocumentReference? get userAlSend => _userAlSend;
  bool hasUserAlSend() => _userAlSend != null;

  // "orderRev" field.
  DocumentReference? _orderRev;
  DocumentReference? get orderRev => _orderRev;
  bool hasOrderRev() => _orderRev != null;

  void _initializeFields() {
    _revUser = snapshotData['RevUser'] as DocumentReference?;
    _rEVIEWSmsg = snapshotData['REVIEWSmsg'] as String?;
    _ret = castToType<int>(snapshotData['Ret']);
    _date = snapshotData['date'] as DateTime?;
    _userAlSend = snapshotData['UserAlSend'] as DocumentReference?;
    _orderRev = snapshotData['orderRev'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('ReviewsUser');

  static Stream<ReviewsUserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ReviewsUserRecord.fromSnapshot(s));

  static Future<ReviewsUserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ReviewsUserRecord.fromSnapshot(s));

  static ReviewsUserRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ReviewsUserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ReviewsUserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ReviewsUserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ReviewsUserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReviewsUserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createReviewsUserRecordData({
  DocumentReference? revUser,
  String? rEVIEWSmsg,
  int? ret,
  DateTime? date,
  DocumentReference? userAlSend,
  DocumentReference? orderRev,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'RevUser': revUser,
      'REVIEWSmsg': rEVIEWSmsg,
      'Ret': ret,
      'date': date,
      'UserAlSend': userAlSend,
      'orderRev': orderRev,
    }.withoutNulls,
  );

  return firestoreData;
}

class ReviewsUserRecordDocumentEquality implements Equality<ReviewsUserRecord> {
  const ReviewsUserRecordDocumentEquality();

  @override
  bool equals(ReviewsUserRecord? e1, ReviewsUserRecord? e2) {
    return e1?.revUser == e2?.revUser &&
        e1?.rEVIEWSmsg == e2?.rEVIEWSmsg &&
        e1?.ret == e2?.ret &&
        e1?.date == e2?.date &&
        e1?.userAlSend == e2?.userAlSend &&
        e1?.orderRev == e2?.orderRev;
  }

  @override
  int hash(ReviewsUserRecord? e) => const ListEquality().hash(
      [e?.revUser, e?.rEVIEWSmsg, e?.ret, e?.date, e?.userAlSend, e?.orderRev]);

  @override
  bool isValidKey(Object? o) => o is ReviewsUserRecord;
}

import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SupportRecord extends FirestoreRecord {
  SupportRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "sub" field.
  String? _sub;
  String get sub => _sub ?? '';
  bool hasSub() => _sub != null;

  // "phon_n" field.
  int? _phonN;
  int get phonN => _phonN ?? 0;
  bool hasPhonN() => _phonN != null;

  // "msg" field.
  String? _msg;
  String get msg => _msg ?? '';
  bool hasMsg() => _msg != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  void _initializeFields() {
    _user = snapshotData['user'] as DocumentReference?;
    _sub = snapshotData['sub'] as String?;
    _phonN = castToType<int>(snapshotData['phon_n']);
    _msg = snapshotData['msg'] as String?;
    _email = snapshotData['email'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('support');

  static Stream<SupportRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => SupportRecord.fromSnapshot(s));

  static Future<SupportRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => SupportRecord.fromSnapshot(s));

  static SupportRecord fromSnapshot(DocumentSnapshot snapshot) =>
      SupportRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static SupportRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      SupportRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'SupportRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is SupportRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createSupportRecordData({
  DocumentReference? user,
  String? sub,
  int? phonN,
  String? msg,
  String? email,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
      'sub': sub,
      'phon_n': phonN,
      'msg': msg,
      'email': email,
    }.withoutNulls,
  );

  return firestoreData;
}

class SupportRecordDocumentEquality implements Equality<SupportRecord> {
  const SupportRecordDocumentEquality();

  @override
  bool equals(SupportRecord? e1, SupportRecord? e2) {
    return e1?.user == e2?.user &&
        e1?.sub == e2?.sub &&
        e1?.phonN == e2?.phonN &&
        e1?.msg == e2?.msg &&
        e1?.email == e2?.email;
  }

  @override
  int hash(SupportRecord? e) =>
      const ListEquality().hash([e?.user, e?.sub, e?.phonN, e?.msg, e?.email]);

  @override
  bool isValidKey(Object? o) => o is SupportRecord;
}

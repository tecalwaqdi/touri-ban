import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChatRecord extends FirestoreRecord {
  ChatRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "idorder" field.
  DocumentReference? _idorder;
  DocumentReference? get idorder => _idorder;
  bool hasIdorder() => _idorder != null;

  // "user1" field.
  DocumentReference? _user1;
  DocumentReference? get user1 => _user1;
  bool hasUser1() => _user1 != null;

  // "msg" field.
  String? _msg;
  String get msg => _msg ?? '';
  bool hasMsg() => _msg != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  void _initializeFields() {
    _idorder = snapshotData['idorder'] as DocumentReference?;
    _user1 = snapshotData['user1'] as DocumentReference?;
    _msg = snapshotData['msg'] as String?;
    _date = snapshotData['date'] as DateTime?;
    _naim = snapshotData['naim'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('chat');

  static Stream<ChatRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ChatRecord.fromSnapshot(s));

  static Future<ChatRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ChatRecord.fromSnapshot(s));

  static ChatRecord fromSnapshot(DocumentSnapshot snapshot) => ChatRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChatRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChatRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChatRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChatRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChatRecordData({
  DocumentReference? idorder,
  DocumentReference? user1,
  String? msg,
  DateTime? date,
  String? naim,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'idorder': idorder,
      'user1': user1,
      'msg': msg,
      'date': date,
      'naim': naim,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChatRecordDocumentEquality implements Equality<ChatRecord> {
  const ChatRecordDocumentEquality();

  @override
  bool equals(ChatRecord? e1, ChatRecord? e2) {
    return e1?.idorder == e2?.idorder &&
        e1?.user1 == e2?.user1 &&
        e1?.msg == e2?.msg &&
        e1?.date == e2?.date &&
        e1?.naim == e2?.naim;
  }

  @override
  int hash(ChatRecord? e) => const ListEquality()
      .hash([e?.idorder, e?.user1, e?.msg, e?.date, e?.naim]);

  @override
  bool isValidKey(Object? o) => o is ChatRecord;
}

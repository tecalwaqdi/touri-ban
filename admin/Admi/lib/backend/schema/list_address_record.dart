import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ListAddressRecord extends FirestoreRecord {
  ListAddressRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "listadress" field.
  List<AddressStruct>? _listadress;
  List<AddressStruct> get listadress => _listadress ?? const [];
  bool hasListadress() => _listadress != null;

  void _initializeFields() {
    _user = snapshotData['user'] as DocumentReference?;
    _listadress = getStructList(
      snapshotData['listadress'],
      AddressStruct.fromMap,
    );
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('list_address');

  static Stream<ListAddressRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ListAddressRecord.fromSnapshot(s));

  static Future<ListAddressRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ListAddressRecord.fromSnapshot(s));

  static ListAddressRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ListAddressRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ListAddressRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ListAddressRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ListAddressRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ListAddressRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createListAddressRecordData({
  DocumentReference? user,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
    }.withoutNulls,
  );

  return firestoreData;
}

class ListAddressRecordDocumentEquality implements Equality<ListAddressRecord> {
  const ListAddressRecordDocumentEquality();

  @override
  bool equals(ListAddressRecord? e1, ListAddressRecord? e2) {
    const listEquality = ListEquality();
    return e1?.user == e2?.user &&
        listEquality.equals(e1?.listadress, e2?.listadress);
  }

  @override
  int hash(ListAddressRecord? e) =>
      const ListEquality().hash([e?.user, e?.listadress]);

  @override
  bool isValidKey(Object? o) => o is ListAddressRecord;
}

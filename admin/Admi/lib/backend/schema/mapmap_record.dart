import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MapmapRecord extends FirestoreRecord {
  MapmapRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "locehn" field.
  LatLng? _locehn;
  LatLng? get locehn => _locehn;
  bool hasLocehn() => _locehn != null;

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _locehn = snapshotData['locehn'] as LatLng?;
    _user = snapshotData['user'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('mapmap');

  static Stream<MapmapRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MapmapRecord.fromSnapshot(s));

  static Future<MapmapRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MapmapRecord.fromSnapshot(s));

  static MapmapRecord fromSnapshot(DocumentSnapshot snapshot) => MapmapRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MapmapRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MapmapRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MapmapRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MapmapRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMapmapRecordData({
  String? naim,
  LatLng? locehn,
  DocumentReference? user,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'locehn': locehn,
      'user': user,
    }.withoutNulls,
  );

  return firestoreData;
}

class MapmapRecordDocumentEquality implements Equality<MapmapRecord> {
  const MapmapRecordDocumentEquality();

  @override
  bool equals(MapmapRecord? e1, MapmapRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.locehn == e2?.locehn &&
        e1?.user == e2?.user;
  }

  @override
  int hash(MapmapRecord? e) =>
      const ListEquality().hash([e?.naim, e?.locehn, e?.user]);

  @override
  bool isValidKey(Object? o) => o is MapmapRecord;
}

import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CartRecord extends FirestoreRecord {
  CartRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "user" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "rhlh" field.
  DocumentReference? _rhlh;
  DocumentReference? get rhlh => _rhlh;
  bool hasRhlh() => _rhlh != null;

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  // "dolh" field.
  DocumentReference? _dolh;
  DocumentReference? get dolh => _dolh;
  bool hasDolh() => _dolh != null;

  // "sr" field.
  int? _sr;
  int get sr => _sr ?? 0;
  bool hasSr() => _sr != null;

  // "ser" field.
  double? _ser;
  double get ser => _ser ?? 0.0;
  bool hasSer() => _ser != null;

  // "ok" field.
  bool? _ok;
  bool get ok => _ok ?? false;
  bool hasOk() => _ok != null;

  // "loceshn" field.
  LatLng? _loceshn;
  LatLng? get loceshn => _loceshn;
  bool hasLoceshn() => _loceshn != null;

  // "total" field.
  int? _total;
  int get total => _total ?? 0;
  bool hasTotal() => _total != null;

  // "totall" field.
  double? _totall;
  double get totall => _totall ?? 0.0;
  bool hasTotall() => _totall != null;

  void _initializeFields() {
    _user = snapshotData['user'] as DocumentReference?;
    _rhlh = snapshotData['rhlh'] as DocumentReference?;
    _naim = snapshotData['naim'] as String?;
    _dolh = snapshotData['dolh'] as DocumentReference?;
    _sr = castToType<int>(snapshotData['sr']);
    _ser = castToType<double>(snapshotData['ser']);
    _ok = snapshotData['ok'] as bool?;
    _loceshn = snapshotData['loceshn'] as LatLng?;
    _total = castToType<int>(snapshotData['total']);
    _totall = castToType<double>(snapshotData['totall']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('cart');

  static Stream<CartRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CartRecord.fromSnapshot(s));

  static Future<CartRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CartRecord.fromSnapshot(s));

  static CartRecord fromSnapshot(DocumentSnapshot snapshot) => CartRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CartRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CartRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CartRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CartRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCartRecordData({
  DocumentReference? user,
  DocumentReference? rhlh,
  String? naim,
  DocumentReference? dolh,
  int? sr,
  double? ser,
  bool? ok,
  LatLng? loceshn,
  int? total,
  double? totall,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user': user,
      'rhlh': rhlh,
      'naim': naim,
      'dolh': dolh,
      'sr': sr,
      'ser': ser,
      'ok': ok,
      'loceshn': loceshn,
      'total': total,
      'totall': totall,
    }.withoutNulls,
  );

  return firestoreData;
}

class CartRecordDocumentEquality implements Equality<CartRecord> {
  const CartRecordDocumentEquality();

  @override
  bool equals(CartRecord? e1, CartRecord? e2) {
    return e1?.user == e2?.user &&
        e1?.rhlh == e2?.rhlh &&
        e1?.naim == e2?.naim &&
        e1?.dolh == e2?.dolh &&
        e1?.sr == e2?.sr &&
        e1?.ser == e2?.ser &&
        e1?.ok == e2?.ok &&
        e1?.loceshn == e2?.loceshn &&
        e1?.total == e2?.total &&
        e1?.totall == e2?.totall;
  }

  @override
  int hash(CartRecord? e) => const ListEquality().hash([
        e?.user,
        e?.rhlh,
        e?.naim,
        e?.dolh,
        e?.sr,
        e?.ser,
        e?.ok,
        e?.loceshn,
        e?.total,
        e?.totall
      ]);

  @override
  bool isValidKey(Object? o) => o is CartRecord;
}

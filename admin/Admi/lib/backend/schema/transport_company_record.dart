import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Licensed transport company (`transport_company` collection).
class TransportCompanyRecord extends FirestoreRecord {
  TransportCompanyRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _naim;
  String get naim => _naim ?? '';
  bool hasNaim() => _naim != null;

  String? _licenseNumber;
  String get licenseNumber => _licenseNumber ?? '';
  bool hasLicenseNumber() => _licenseNumber != null;

  DocumentReference? _revDolh;
  DocumentReference? get revDolh => _revDolh;
  bool hasRevDolh() => _revDolh != null;

  String? _dolhText;
  String get dolhText => _dolhText ?? '';
  bool hasDolhText() => _dolhText != null;

  String? _phone;
  String get phone => _phone ?? '';
  bool hasPhone() => _phone != null;

  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  bool? _actev;
  bool get actev => _actev ?? false;
  bool hasActev() => _actev != null;

  DocumentReference? _ownerUser;
  DocumentReference? get ownerUser => _ownerUser;
  bool hasOwnerUser() => _ownerUser != null;

  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  void _initializeFields() {
    _naim = snapshotData['naim'] as String?;
    _licenseNumber = snapshotData['license_number'] as String?;
    _revDolh = snapshotData['Rev_dolh'] as DocumentReference?;
    _dolhText = snapshotData['dolh_text'] as String?;
    _phone = snapshotData['phone'] as String?;
    _email = snapshotData['email'] as String?;
    _actev = snapshotData['actev'] as bool?;
    _ownerUser = snapshotData['owner_user'] as DocumentReference?;
    _createdTime = snapshotData['created_time'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('transport_company');

  static Stream<TransportCompanyRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TransportCompanyRecord.fromSnapshot(s));

  static Future<TransportCompanyRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TransportCompanyRecord.fromSnapshot(s));

  static TransportCompanyRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TransportCompanyRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TransportCompanyRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TransportCompanyRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TransportCompanyRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TransportCompanyRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTransportCompanyRecordData({
  String? naim,
  String? licenseNumber,
  DocumentReference? revDolh,
  String? dolhText,
  String? phone,
  String? email,
  bool? actev,
  DocumentReference? ownerUser,
  DateTime? createdTime,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'naim': naim,
      'license_number': licenseNumber,
      'Rev_dolh': revDolh,
      'dolh_text': dolhText,
      'phone': phone,
      'email': email,
      'actev': actev,
      'owner_user': ownerUser,
      'created_time': createdTime,
    }.withoutNulls,
  );

  return firestoreData;
}

class TransportCompanyRecordDocumentEquality
    implements Equality<TransportCompanyRecord> {
  const TransportCompanyRecordDocumentEquality();

  @override
  bool equals(TransportCompanyRecord? e1, TransportCompanyRecord? e2) {
    return e1?.naim == e2?.naim &&
        e1?.licenseNumber == e2?.licenseNumber &&
        e1?.revDolh == e2?.revDolh &&
        e1?.dolhText == e2?.dolhText &&
        e1?.phone == e2?.phone &&
        e1?.email == e2?.email &&
        e1?.actev == e2?.actev &&
        e1?.ownerUser == e2?.ownerUser &&
        e1?.createdTime == e2?.createdTime;
  }

  @override
  int hash(TransportCompanyRecord? e) => const ListEquality().hash([
        e?.naim,
        e?.licenseNumber,
        e?.revDolh,
        e?.dolhText,
        e?.phone,
        e?.email,
        e?.actev,
        e?.ownerUser,
        e?.createdTime,
      ]);

  @override
  bool isValidKey(Object? o) => o is TransportCompanyRecord;
}

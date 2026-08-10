import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserRecord extends FirestoreRecord {
  UserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "ismndob" field.
  bool? _ismndob;
  bool get ismndob => _ismndob ?? false;
  bool hasIsmndob() => _ismndob != null;

  // "phone_n" field.
  int? _phoneN;
  int get phoneN => _phoneN ?? 0;
  bool hasPhoneN() => _phoneN != null;

  // "mndob_vill" field.
  DocumentReference? _mndobVill;
  DocumentReference? get mndobVill => _mndobVill;
  bool hasMndobVill() => _mndobVill != null;

  // "img_id" field.
  String? _imgId;
  String get imgId => _imgId ?? '';
  bool hasImgId() => _imgId != null;

  // "img_id_rksh" field.
  String? _imgIdRksh;
  String get imgIdRksh => _imgIdRksh ?? '';
  bool hasImgIdRksh() => _imgIdRksh != null;

  // "img_id_car" field.
  String? _imgIdCar;
  String get imgIdCar => _imgIdCar ?? '';
  bool hasImgIdCar() => _imgIdCar != null;

  // "actev_mndob" field.
  bool? _actevMndob;
  bool get actevMndob => _actevMndob ?? false;
  bool hasActevMndob() => _actevMndob != null;

  // "mdenh_aml" field.
  String? _mdenhAml;
  String get mdenhAml => _mdenhAml ?? '';
  bool hasMdenhAml() => _mdenhAml != null;

  // "mndon_newacc" field.
  bool? _mndonNewacc;
  bool get mndonNewacc => _mndonNewacc ?? false;
  bool hasMndonNewacc() => _mndonNewacc != null;

  // "mndob_vill_text" field.
  String? _mndobVillText;
  String get mndobVillText => _mndobVillText ?? '';
  bool hasMndobVillText() => _mndobVillText != null;

  // "carRev_mndob" field.
  DocumentReference? _carRevMndob;
  DocumentReference? get carRevMndob => _carRevMndob;
  bool hasCarRevMndob() => _carRevMndob != null;

  // "sequenceNumber" field.
  String? _sequenceNumber;
  String get sequenceNumber => _sequenceNumber ?? '';
  bool hasSequenceNumber() => _sequenceNumber != null;

  // "driverId" field.
  String? _driverId;
  String get driverId => _driverId ?? '';
  bool hasDriverId() => _driverId != null;

  // "number_lohh_car" field.
  String? _numberLohhCar;
  String get numberLohhCar => _numberLohhCar ?? '';
  bool hasNumberLohhCar() => _numberLohhCar != null;

  // "ID_hoyh_MNDOB" field.
  String? _iDHoyhMNDOB;
  String get iDHoyhMNDOB => _iDHoyhMNDOB ?? '';
  bool hasIDHoyhMNDOB() => _iDHoyhMNDOB != null;

  // "mndob_type_car" field.
  DocumentReference? _mndobTypeCar;
  DocumentReference? get mndobTypeCar => _mndobTypeCar;
  bool hasMndobTypeCar() => _mndobTypeCar != null;

  // "ismndom" field.
  bool? _ismndom;
  bool get ismndom => _ismndom ?? false;
  bool hasIsmndom() => _ismndom != null;

  // "Rev_dolh" field — country scope for admin pending-driver lists.
  DocumentReference? _revDolh;
  DocumentReference? get revDolh => _revDolh;
  bool hasRevDolh() => _revDolh != null;

  // "total_mndob" field.
  int? _totalMndob;
  int get totalMndob => _totalMndob ?? 0;
  bool hasTotalMndob() => _totalMndob != null;

  // "total_app" field.
  int? _totalApp;
  int get totalApp => _totalApp ?? 0;
  bool hasTotalApp() => _totalApp != null;

  // "text_type_car_mndob" field.
  String? _textTypeCarMndob;
  String get textTypeCarMndob => _textTypeCarMndob ?? '';
  bool hasTextTypeCarMndob() => _textTypeCarMndob != null;

  // "totalMndob2" field.
  double? _totalMndob2;
  double get totalMndob2 => _totalMndob2 ?? 0.0;
  bool hasTotalMndob2() => _totalMndob2 != null;

  // "Reteng" field.
  List<int>? _reteng;
  List<int> get reteng => _reteng ?? const [];
  bool hasReteng() => _reteng != null;

  // "ngl" field.
  bool? _ngl;
  bool get ngl => _ngl ?? false;
  bool hasNgl() => _ngl != null;

  // "isHflh" field.
  bool? _isHflh;
  bool get isHflh => _isHflh ?? false;
  bool hasIsHflh() => _isHflh != null;

  // "Outstandingonlinepayment" field.
  double? _outstandingonlinepayment;
  double get outstandingonlinepayment => _outstandingonlinepayment ?? 0.0;
  bool hasOutstandingonlinepayment() => _outstandingonlinepayment != null;

  // "bankNaim" field.
  String? _bankNaim;
  String get bankNaim => _bankNaim ?? '';
  bool hasBankNaim() => _bankNaim != null;

  // "bankIdAcc" field.
  String? _bankIdAcc;
  String get bankIdAcc => _bankIdAcc ?? '';
  bool hasBankIdAcc() => _bankIdAcc != null;

  // "ipanBank" field.
  String? _ipanBank;
  String get ipanBank => _ipanBank ?? '';
  bool hasIpanBank() => _ipanBank != null;

  // "banknaimAcc" field.
  String? _banknaimAcc;
  String get banknaimAcc => _banknaimAcc ?? '';
  bool hasBanknaimAcc() => _banknaimAcc != null;

  // "loceshnMndobNow" field.
  LatLng? _loceshnMndobNow;
  LatLng? get loceshnMndobNow => _loceshnMndobNow;
  bool hasLoceshnMndobNow() => _loceshnMndobNow != null;

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "loceshnMn" field.
  LatLng? _loceshnMn;
  LatLng? get loceshnMn => _loceshnMn;
  bool hasLoceshnMn() => _loceshnMn != null;

  // "NameCar" field.
  String? _nameCar;
  String get nameCar => _nameCar ?? '';
  bool hasNameCar() => _nameCar != null;

  // "ModelCar" field.
  String? _modelCar;
  String get modelCar => _modelCar ?? '';
  bool hasModelCar() => _modelCar != null;

  // "registration_status" — draft | pending_review | changes_requested | approved | rejected | suspended
  String? _registrationStatus;
  String get registrationStatus => _registrationStatus ?? '';
  bool hasRegistrationStatus() => _registrationStatus != null;

  // "rejection_reason" — admin note shown to driver when rejected / changes requested
  String? _rejectionReason;
  String get rejectionReason => _rejectionReason ?? '';
  bool hasRejectionReason() => _rejectionReason != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _ismndob = snapshotData['ismndob'] as bool?;
    _phoneN = castToType<int>(snapshotData['phone_n']);
    _mndobVill = snapshotData['mndob_vill'] as DocumentReference?;
    _imgId = snapshotData['img_id'] as String?;
    _imgIdRksh = snapshotData['img_id_rksh'] as String?;
    _imgIdCar = snapshotData['img_id_car'] as String?;
    _actevMndob = snapshotData['actev_mndob'] as bool?;
    _mdenhAml = snapshotData['mdenh_aml'] as String?;
    _mndonNewacc = snapshotData['mndon_newacc'] as bool?;
    _mndobVillText = snapshotData['mndob_vill_text'] as String?;
    _carRevMndob = snapshotData['carRev_mndob'] as DocumentReference?;
    _sequenceNumber = snapshotData['sequenceNumber'] as String?;
    _driverId = snapshotData['driverId'] as String?;
    _numberLohhCar = snapshotData['number_lohh_car'] as String?;
    _iDHoyhMNDOB = snapshotData['ID_hoyh_MNDOB'] as String?;
    _mndobTypeCar = snapshotData['mndob_type_car'] as DocumentReference?;
    _ismndom = snapshotData['ismndom'] as bool?;
    _revDolh = snapshotData['Rev_dolh'] as DocumentReference?;
    _totalMndob = castToType<int>(snapshotData['total_mndob']);
    _totalApp = castToType<int>(snapshotData['total_app']);
    _textTypeCarMndob = snapshotData['text_type_car_mndob'] as String?;
    _totalMndob2 = castToType<double>(snapshotData['totalMndob2']);
    _reteng = getDataList(snapshotData['Reteng']);
    _ngl = snapshotData['ngl'] as bool?;
    _isHflh = snapshotData['isHflh'] as bool?;
    _outstandingonlinepayment =
        castToType<double>(snapshotData['Outstandingonlinepayment']);
    _bankNaim = snapshotData['bankNaim'] as String?;
    _bankIdAcc = snapshotData['bankIdAcc'] as String?;
    _ipanBank = snapshotData['ipanBank'] as String?;
    _banknaimAcc = snapshotData['banknaimAcc'] as String?;
    _loceshnMndobNow = snapshotData['loceshnMndobNow'] as LatLng?;
    _userId = snapshotData['userId'] as String?;
    _loceshnMn = snapshotData['loceshnMn'] as LatLng?;
    _nameCar = snapshotData['NameCar'] as String?;
    _modelCar = snapshotData['ModelCar'] as String?;
    _registrationStatus = snapshotData['registration_status'] as String?;
    _rejectionReason = snapshotData['rejection_reason'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user');

  static Stream<UserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserRecord.fromSnapshot(s));

  static Future<UserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserRecord.fromSnapshot(s));

  static UserRecord fromSnapshot(DocumentSnapshot snapshot) {
    final raw = snapshot.data();
    if (raw == null || raw is! Map) {
      return UserRecord._(
        snapshot.reference,
        mapFromFirestore(<String, dynamic>{}),
      );
    }
    return UserRecord._(
      snapshot.reference,
      mapFromFirestore(Map<String, dynamic>.from(raw)),
    );
  }

  static UserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserRecordData({
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
  bool? ismndob,
  int? phoneN,
  DocumentReference? mndobVill,
  String? imgId,
  String? imgIdRksh,
  String? imgIdCar,
  bool? actevMndob,
  String? mdenhAml,
  bool? mndonNewacc,
  String? mndobVillText,
  DocumentReference? carRevMndob,
  String? sequenceNumber,
  String? driverId,
  String? numberLohhCar,
  String? iDHoyhMNDOB,
  DocumentReference? mndobTypeCar,
  bool? ismndom,
  DocumentReference? revDolh,
  int? totalMndob,
  int? totalApp,
  String? textTypeCarMndob,
  double? totalMndob2,
  bool? ngl,
  bool? isHflh,
  double? outstandingonlinepayment,
  String? bankNaim,
  String? bankIdAcc,
  String? ipanBank,
  String? banknaimAcc,
  LatLng? loceshnMndobNow,
  String? userId,
  LatLng? loceshnMn,
  String? nameCar,
  String? modelCar,
  String? registrationStatus,
  String? rejectionReason,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'ismndob': ismndob,
      'phone_n': phoneN,
      'mndob_vill': mndobVill,
      'img_id': imgId,
      'img_id_rksh': imgIdRksh,
      'img_id_car': imgIdCar,
      'actev_mndob': actevMndob,
      'mdenh_aml': mdenhAml,
      'mndon_newacc': mndonNewacc,
      'mndob_vill_text': mndobVillText,
      'carRev_mndob': carRevMndob,
      'sequenceNumber': sequenceNumber,
      'driverId': driverId,
      'number_lohh_car': numberLohhCar,
      'ID_hoyh_MNDOB': iDHoyhMNDOB,
      'mndob_type_car': mndobTypeCar,
      'ismndom': ismndom,
      'Rev_dolh': revDolh,
      'total_mndob': totalMndob,
      'total_app': totalApp,
      'text_type_car_mndob': textTypeCarMndob,
      'totalMndob2': totalMndob2,
      'ngl': ngl,
      'isHflh': isHflh,
      'Outstandingonlinepayment': outstandingonlinepayment,
      'bankNaim': bankNaim,
      'bankIdAcc': bankIdAcc,
      'ipanBank': ipanBank,
      'banknaimAcc': banknaimAcc,
      'loceshnMndobNow': loceshnMndobNow,
      'userId': userId,
      'loceshnMn': loceshnMn,
      'NameCar': nameCar,
      'ModelCar': modelCar,
      'registration_status': registrationStatus,
      'rejection_reason': rejectionReason,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserRecordDocumentEquality implements Equality<UserRecord> {
  const UserRecordDocumentEquality();

  @override
  bool equals(UserRecord? e1, UserRecord? e2) {
    const listEquality = ListEquality();
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.ismndob == e2?.ismndob &&
        e1?.phoneN == e2?.phoneN &&
        e1?.mndobVill == e2?.mndobVill &&
        e1?.imgId == e2?.imgId &&
        e1?.imgIdRksh == e2?.imgIdRksh &&
        e1?.imgIdCar == e2?.imgIdCar &&
        e1?.actevMndob == e2?.actevMndob &&
        e1?.mdenhAml == e2?.mdenhAml &&
        e1?.mndonNewacc == e2?.mndonNewacc &&
        e1?.mndobVillText == e2?.mndobVillText &&
        e1?.carRevMndob == e2?.carRevMndob &&
        e1?.sequenceNumber == e2?.sequenceNumber &&
        e1?.driverId == e2?.driverId &&
        e1?.numberLohhCar == e2?.numberLohhCar &&
        e1?.iDHoyhMNDOB == e2?.iDHoyhMNDOB &&
        e1?.mndobTypeCar == e2?.mndobTypeCar &&
        e1?.ismndom == e2?.ismndom &&
        e1?.totalMndob == e2?.totalMndob &&
        e1?.totalApp == e2?.totalApp &&
        e1?.textTypeCarMndob == e2?.textTypeCarMndob &&
        e1?.totalMndob2 == e2?.totalMndob2 &&
        listEquality.equals(e1?.reteng, e2?.reteng) &&
        e1?.ngl == e2?.ngl &&
        e1?.isHflh == e2?.isHflh &&
        e1?.outstandingonlinepayment == e2?.outstandingonlinepayment &&
        e1?.bankNaim == e2?.bankNaim &&
        e1?.bankIdAcc == e2?.bankIdAcc &&
        e1?.ipanBank == e2?.ipanBank &&
        e1?.banknaimAcc == e2?.banknaimAcc &&
        e1?.loceshnMndobNow == e2?.loceshnMndobNow &&
        e1?.userId == e2?.userId &&
        e1?.loceshnMn == e2?.loceshnMn &&
        e1?.nameCar == e2?.nameCar &&
        e1?.modelCar == e2?.modelCar;
  }

  @override
  int hash(UserRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber,
        e?.ismndob,
        e?.phoneN,
        e?.mndobVill,
        e?.imgId,
        e?.imgIdRksh,
        e?.imgIdCar,
        e?.actevMndob,
        e?.mdenhAml,
        e?.mndonNewacc,
        e?.mndobVillText,
        e?.carRevMndob,
        e?.sequenceNumber,
        e?.driverId,
        e?.numberLohhCar,
        e?.iDHoyhMNDOB,
        e?.mndobTypeCar,
        e?.ismndom,
        e?.totalMndob,
        e?.totalApp,
        e?.textTypeCarMndob,
        e?.totalMndob2,
        e?.reteng,
        e?.ngl,
        e?.isHflh,
        e?.outstandingonlinepayment,
        e?.bankNaim,
        e?.bankIdAcc,
        e?.ipanBank,
        e?.banknaimAcc,
        e?.loceshnMndobNow,
        e?.userId,
        e?.loceshnMn,
        e?.nameCar,
        e?.modelCar
      ]);

  @override
  bool isValidKey(Object? o) => o is UserRecord;
}

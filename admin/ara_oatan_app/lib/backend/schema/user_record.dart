import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserRecord extends FirestoreRecord {
  UserRecord._(
    super.reference,
    super.data,
  ) {
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

  // "address" field.
  List<AddressStruct>? _address;
  List<AddressStruct> get address => _address ?? const [];
  bool hasAddress() => _address != null;

  // "ismndom" field.
  bool? _ismndom;
  bool get ismndom => _ismndom ?? false;
  bool hasIsmndom() => _ismndom != null;

  // "mndob_vill" field.
  DocumentReference? _mndobVill;
  DocumentReference? get mndobVill => _mndobVill;
  bool hasMndobVill() => _mndobVill != null;

  // "mndob_type_car" field.
  DocumentReference? _mndobTypeCar;
  DocumentReference? get mndobTypeCar => _mndobTypeCar;
  bool hasMndobTypeCar() => _mndobTypeCar != null;

  // "phone_n" field.
  int? _phoneN;
  int get phoneN => _phoneN ?? 0;
  bool hasPhoneN() => _phoneN != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "data_cart" field.
  List<AmaknCostmStruct>? _dataCart;
  List<AmaknCostmStruct> get dataCart => _dataCart ?? const [];
  bool hasDataCart() => _dataCart != null;

  // "adresslist" field.
  List<AddressStruct>? _adresslist;
  List<AddressStruct> get adresslist => _adresslist ?? const [];
  bool hasAdresslist() => _adresslist != null;

  // "ismndob" field.
  bool? _ismndob;
  bool get ismndob => _ismndob ?? false;
  bool hasIsmndob() => _ismndob != null;

  // "actev_mndob" field.
  bool? _actevMndob;
  bool get actevMndob => _actevMndob ?? false;
  bool hasActevMndob() => _actevMndob != null;

  // "img_id_rksh" field.
  String? _imgIdRksh;
  String get imgIdRksh => _imgIdRksh ?? '';
  bool hasImgIdRksh() => _imgIdRksh != null;

  // "img_id" field.
  String? _imgId;
  String get imgId => _imgId ?? '';
  bool hasImgId() => _imgId != null;

  // "img_id_car" field.
  String? _imgIdCar;
  String get imgIdCar => _imgIdCar ?? '';
  bool hasImgIdCar() => _imgIdCar != null;

  // "mndob_user" field.
  DocumentReference? _mndobUser;
  DocumentReference? get mndobUser => _mndobUser;
  bool hasMndobUser() => _mndobUser != null;

  // "actev_user" field.
  bool? _actevUser;
  bool get actevUser => _actevUser ?? false;
  bool hasActevUser() => _actevUser != null;

  // "mndob_vill_text" field.
  String? _mndobVillText;
  String get mndobVillText => _mndobVillText ?? '';
  bool hasMndobVillText() => _mndobVillText != null;

  // "ismzod" field.
  bool? _ismzod;
  bool get ismzod => _ismzod ?? false;
  bool hasIsmzod() => _ismzod != null;

  // "mndon_newacc" field.
  bool? _mndonNewacc;
  bool get mndonNewacc => _mndonNewacc ?? false;
  bool hasMndonNewacc() => _mndonNewacc != null;

  // "total_app" field.
  int? _totalApp;
  int get totalApp => _totalApp ?? 0;
  bool hasTotalApp() => _totalApp != null;

  // "total_mndob" field.
  int? _totalMndob;
  int get totalMndob => _totalMndob ?? 0;
  bool hasTotalMndob() => _totalMndob != null;

  // "isAdmin" field.
  bool? _isAdmin;
  bool get isAdmin => _isAdmin ?? false;
  bool hasIsAdmin() => _isAdmin != null;

  // "isAdminRule" field.
  int? _isAdminRule;
  int get isAdminRule => _isAdminRule ?? 0;
  bool hasIsAdminRule() => _isAdminRule != null;

  // "Reteng" field.
  List<int>? _reteng;
  List<int> get reteng => _reteng ?? const [];
  bool hasReteng() => _reteng != null;

  // "ngl" field.
  bool? _ngl;
  bool get ngl => _ngl ?? false;
  bool hasNgl() => _ngl != null;

  // "loceshnMndobNow" field.
  LatLng? _loceshnMndobNow;
  LatLng? get loceshnMndobNow => _loceshnMndobNow;
  bool hasLoceshnMndobNow() => _loceshnMndobNow != null;

  // "NameCar" field.
  String? _nameCar;
  String get nameCar => _nameCar ?? '';
  bool hasNameCar() => _nameCar != null;

  // "ModelCar" field.
  String? _modelCar;
  String get modelCar => _modelCar ?? '';
  bool hasModelCar() => _modelCar != null;

  // "preferred_locale" field.
  String? _preferredLocale;
  String get preferredLocale => _preferredLocale ?? '';
  bool hasPreferredLocale() => _preferredLocale != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _address = getStructList(
      snapshotData['address'],
      AddressStruct.fromMap,
    );
    _ismndom = snapshotData['ismndom'] as bool?;
    _mndobVill = castDocRef(snapshotData['mndob_vill']);
    _mndobTypeCar = castDocRef(snapshotData['mndob_type_car']);
    _phoneN = castToType<int>(snapshotData['phone_n']);
    _phoneNumber = snapshotData['phone_number'] as String?;
    _dataCart = getStructList(
      snapshotData['data_cart'],
      AmaknCostmStruct.fromMap,
    );
    _adresslist = getStructList(
      snapshotData['adresslist'],
      AddressStruct.fromMap,
    );
    _ismndob = snapshotData['ismndob'] as bool?;
    _actevMndob = snapshotData['actev_mndob'] as bool?;
    _imgIdRksh = snapshotData['img_id_rksh'] as String?;
    _imgId = snapshotData['img_id'] as String?;
    _imgIdCar = snapshotData['img_id_car'] as String?;
    _mndobUser = castDocRef(snapshotData['mndob_user']);
    _actevUser = snapshotData['actev_user'] as bool?;
    _mndobVillText = snapshotData['mndob_vill_text'] as String?;
    _ismzod = snapshotData['ismzod'] as bool?;
    _mndonNewacc = snapshotData['mndon_newacc'] as bool?;
    _totalApp = castToType<int>(snapshotData['total_app']);
    _totalMndob = castToType<int>(snapshotData['total_mndob']);
    _isAdmin = snapshotData['isAdmin'] as bool?;
    _isAdminRule = castToType<int>(snapshotData['isAdminRule']);
    _reteng = getDataList(snapshotData['Reteng']);
    _ngl = snapshotData['ngl'] as bool?;
    _loceshnMndobNow = snapshotData['loceshnMndobNow'] as LatLng?;
    _nameCar = snapshotData['NameCar'] as String?;
    _modelCar = snapshotData['ModelCar'] as String?;
    _preferredLocale = snapshotData['preferred_locale'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user');

  static Stream<UserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserRecord.fromSnapshot(s));

  static Future<UserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserRecord.fromSnapshot(s));

  static UserRecord fromSnapshot(DocumentSnapshot snapshot) => UserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

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
  bool? ismndom,
  DocumentReference? mndobVill,
  DocumentReference? mndobTypeCar,
  int? phoneN,
  String? phoneNumber,
  bool? ismndob,
  bool? actevMndob,
  String? imgIdRksh,
  String? imgId,
  String? imgIdCar,
  DocumentReference? mndobUser,
  bool? actevUser,
  String? mndobVillText,
  bool? ismzod,
  bool? mndonNewacc,
  int? totalApp,
  int? totalMndob,
  bool? isAdmin,
  int? isAdminRule,
  bool? ngl,
  LatLng? loceshnMndobNow,
  String? nameCar,
  String? modelCar,
  String? preferredLocale,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'ismndom': ismndom,
      'mndob_vill': mndobVill,
      'mndob_type_car': mndobTypeCar,
      'phone_n': phoneN,
      'phone_number': phoneNumber,
      'ismndob': ismndob,
      'actev_mndob': actevMndob,
      'img_id_rksh': imgIdRksh,
      'img_id': imgId,
      'img_id_car': imgIdCar,
      'mndob_user': mndobUser,
      'actev_user': actevUser,
      'mndob_vill_text': mndobVillText,
      'ismzod': ismzod,
      'mndon_newacc': mndonNewacc,
      'total_app': totalApp,
      'total_mndob': totalMndob,
      'isAdmin': isAdmin,
      'isAdminRule': isAdminRule,
      'ngl': ngl,
      'loceshnMndobNow': loceshnMndobNow,
      'NameCar': nameCar,
      'ModelCar': modelCar,
      'preferred_locale': preferredLocale,
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
        listEquality.equals(e1?.address, e2?.address) &&
        e1?.ismndom == e2?.ismndom &&
        e1?.mndobVill == e2?.mndobVill &&
        e1?.mndobTypeCar == e2?.mndobTypeCar &&
        e1?.phoneN == e2?.phoneN &&
        e1?.phoneNumber == e2?.phoneNumber &&
        listEquality.equals(e1?.dataCart, e2?.dataCart) &&
        listEquality.equals(e1?.adresslist, e2?.adresslist) &&
        e1?.ismndob == e2?.ismndob &&
        e1?.actevMndob == e2?.actevMndob &&
        e1?.imgIdRksh == e2?.imgIdRksh &&
        e1?.imgId == e2?.imgId &&
        e1?.imgIdCar == e2?.imgIdCar &&
        e1?.mndobUser == e2?.mndobUser &&
        e1?.actevUser == e2?.actevUser &&
        e1?.mndobVillText == e2?.mndobVillText &&
        e1?.ismzod == e2?.ismzod &&
        e1?.mndonNewacc == e2?.mndonNewacc &&
        e1?.totalApp == e2?.totalApp &&
        e1?.totalMndob == e2?.totalMndob &&
        e1?.isAdmin == e2?.isAdmin &&
        e1?.isAdminRule == e2?.isAdminRule &&
        listEquality.equals(e1?.reteng, e2?.reteng) &&
        e1?.ngl == e2?.ngl &&
        e1?.loceshnMndobNow == e2?.loceshnMndobNow &&
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
        e?.address,
        e?.ismndom,
        e?.mndobVill,
        e?.mndobTypeCar,
        e?.phoneN,
        e?.phoneNumber,
        e?.dataCart,
        e?.adresslist,
        e?.ismndob,
        e?.actevMndob,
        e?.imgIdRksh,
        e?.imgId,
        e?.imgIdCar,
        e?.mndobUser,
        e?.actevUser,
        e?.mndobVillText,
        e?.ismzod,
        e?.mndonNewacc,
        e?.totalApp,
        e?.totalMndob,
        e?.isAdmin,
        e?.isAdminRule,
        e?.reteng,
        e?.ngl,
        e?.loceshnMndobNow,
        e?.nameCar,
        e?.modelCar
      ]);

  @override
  bool isValidKey(Object? o) => o is UserRecord;
}

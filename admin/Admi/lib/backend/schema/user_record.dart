import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

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

  // "Isagent" field.
  bool? _isagent;
  bool get isagent => _isagent ?? false;
  bool hasIsagent() => _isagent != null;

  // "dolh_agent" field.
  String? _dolhAgent;
  String get dolhAgent => _dolhAgent ?? '';
  bool hasDolhAgent() => _dolhAgent != null;

  // "Rev_dloh_agent" field.
  DocumentReference? _revDlohAgent;
  DocumentReference? get revDlohAgent => _revDlohAgent;
  bool hasRevDlohAgent() => _revDlohAgent != null;

  // "Agent_total" field.
  double? _agentTotal;
  double get agentTotal => _agentTotal ?? 0.0;
  bool hasAgentTotal() => _agentTotal != null;

  // "vat_percent" field.
  double? _vatPercent;
  double get vatPercent => _vatPercent ?? 0.0;
  bool hasVatPercent() => _vatPercent != null;

  // "app_commission_percent" field.
  double? _appCommissionPercent;
  double get appCommissionPercent => _appCommissionPercent ?? 0.0;
  bool hasAppCommissionPercent() => _appCommissionPercent != null;

  // "Bookings_Agent" field.
  int? _bookingsAgent;
  int get bookingsAgent => _bookingsAgent ?? 0;
  bool hasBookingsAgent() => _bookingsAgent != null;

  // "IsAdmin" field.
  bool? _isAdmin;

  /// اذا نوع اليوزر ادمن
  bool get isAdmin => _isAdmin ?? false;
  bool hasIsAdmin() => _isAdmin != null;

  // "agent_date_reg" field.
  DateTime? _agentDateReg;
  DateTime? get agentDateReg => _agentDateReg;
  bool hasAgentDateReg() => _agentDateReg != null;

  // "agent_date_end" field.
  DateTime? _agentDateEnd;
  DateTime? get agentDateEnd => _agentDateEnd;
  bool hasAgentDateEnd() => _agentDateEnd != null;

  // "driverid" field.
  String? _driverid;
  String get driverid => _driverid ?? '';
  bool hasDriverid() => _driverid != null;

  // "ismzod" field.
  bool? _ismzod;
  bool get ismzod => _ismzod ?? false;
  bool hasIsmzod() => _ismzod != null;

  // "isAdminRule" field.
  int? _isAdminRule;
  int get isAdminRule => _isAdminRule ?? 0;
  /// Parsed admin rule (handles int, double, string in Firestore).
  int get adminRuleValue => _isAdminRule ?? 0;
  bool hasIsAdminRule() => _isAdminRule != null;

  // "total_app" field.
  double? _totalApp;
  double get totalApp => _totalApp ?? 0.0;
  bool hasTotalApp() => _totalApp != null;

  // "text_type_car_mndob" field.
  String? _textTypeCarMndob;
  String get textTypeCarMndob => _textTypeCarMndob ?? '';
  bool hasTextTypeCarMndob() => _textTypeCarMndob != null;

  // "is_partner" field.
  bool? _isPartner;
  bool get isPartner => _isPartner ?? false;
  bool hasIsPartner() => _isPartner != null;

  // "partner_mkan" field.
  DocumentReference? _partnerMkanRef;
  DocumentReference? get partnerMkanRef => _partnerMkanRef;
  bool hasPartnerMkanRef() => _partnerMkanRef != null;

  // "transport_company" field.
  DocumentReference? _transportCompany;
  DocumentReference? get transportCompany => _transportCompany;
  bool hasTransportCompany() => _transportCompany != null;

  // "transport_company_text" field.
  String? _transportCompanyText;
  String get transportCompanyText => _transportCompanyText ?? '';
  bool hasTransportCompanyText() => _transportCompanyText != null;

  // Tour guide fields.
  bool? _isTourGuide;
  bool get isTourGuide => _isTourGuide ?? false;
  bool hasIsTourGuide() => _isTourGuide != null;

  String? _tourGuideStatus;
  String get tourGuideStatus => _tourGuideStatus ?? 'none';
  bool hasTourGuideStatus() => _tourGuideStatus != null;

  String? _tourGuidePermitUrl;
  String get tourGuidePermitUrl => _tourGuidePermitUrl ?? '';
  bool hasTourGuidePermitUrl() => _tourGuidePermitUrl != null;

  // "Rev_dolh" field — country scope for app users / reps / support linkage.
  DocumentReference? _revDolh;
  DocumentReference? get revDolh => _revDolh;
  bool hasRevDolh() => _revDolh != null;

  void _initializeFields() {
    _email = _readFirestoreString(snapshotData['email']);
    _displayName = _readFirestoreString(snapshotData['display_name']);
    _photoUrl = _readFirestoreString(snapshotData['photo_url']);
    _uid = _readFirestoreString(snapshotData['uid']);
    _createdTime = _readFirestoreDate(snapshotData['created_time']);
    _address = getStructList(
      snapshotData['address'],
      AddressStruct.fromMap,
    );
    _ismndom = _readFirestoreBool(snapshotData['ismndom']);
    _mndobVill = docRefFromFirestore(snapshotData['mndob_vill']);
    _mndobTypeCar = docRefFromFirestore(snapshotData['mndob_type_car']);
    _phoneN = _readFirestoreInt(snapshotData['phone_n']);
    _phoneNumber = _readFirestoreString(snapshotData['phone_number']);
    _dataCart = getStructList(
      snapshotData['data_cart'],
      AmaknCostmStruct.fromMap,
    );
    _adresslist = getStructList(
      snapshotData['adresslist'],
      AddressStruct.fromMap,
    );
    _ismndob = _readFirestoreBool(snapshotData['ismndob']);
    _actevMndob = _readFirestoreBool(snapshotData['actev_mndob']);
    _imgIdRksh = _readFirestoreString(snapshotData['img_id_rksh']);
    _imgId = _readFirestoreString(snapshotData['img_id']);
    _imgIdCar = _readFirestoreString(snapshotData['img_id_car']);
    _mndobUser = docRefFromFirestore(snapshotData['mndob_user']);
    _actevUser = _readFirestoreBool(snapshotData['actev_user']);
    _mndobVillText = _readFirestoreString(snapshotData['mndob_vill_text']);
    _isagent = _readFirestoreBool(snapshotData['Isagent']) ??
        _readFirestoreBool(snapshotData['isagent']);
    _dolhAgent = _readFirestoreString(snapshotData['dolh_agent']);
    _revDlohAgent = docRefFromFirestore(snapshotData['Rev_dloh_agent']);
    _agentTotal = _readFirestoreDouble(snapshotData['Agent_total']);
    _vatPercent = _readFirestoreDouble(snapshotData['vat_percent']);
    _appCommissionPercent =
        _readFirestoreDouble(snapshotData['app_commission_percent']);
    _bookingsAgent = _readFirestoreInt(snapshotData['Bookings_Agent']);
    _isAdmin = _readFirestoreBool(snapshotData['IsAdmin']) ??
        _readFirestoreBool(snapshotData['isAdmin']);
    _agentDateReg = _readFirestoreDate(snapshotData['agent_date_reg']);
    _agentDateEnd = _readFirestoreDate(snapshotData['agent_date_end']);
    _driverid = _readFirestoreString(snapshotData['driverid']);
    _ismzod = _readFirestoreBool(snapshotData['ismzod']);
    _isAdminRule = _readFirestoreInt(snapshotData['isAdminRule']) ??
        _readFirestoreInt(snapshotData['IsAdminRule']);
    _totalApp = _readFirestoreDouble(snapshotData['total_app']);
    _textTypeCarMndob = _readFirestoreString(snapshotData['text_type_car_mndob']);
    _isPartner = _readFirestoreBool(snapshotData['is_partner']);
    _partnerMkanRef = docRefFromFirestore(snapshotData['partner_mkan']);
    _transportCompany = docRefFromFirestore(snapshotData['transport_company']);
    _transportCompanyText =
        _readFirestoreString(snapshotData['transport_company_text']);
    _isTourGuide = _readFirestoreBool(snapshotData['is_tour_guide']);
    _tourGuideStatus = _readFirestoreString(snapshotData['tour_guide_status']);
    _tourGuidePermitUrl =
        _readFirestoreString(snapshotData['tour_guide_permit_url']);
    _revDolh = docRefFromFirestore(snapshotData['Rev_dolh']);
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
  bool? isagent,
  String? dolhAgent,
  DocumentReference? revDlohAgent,
  double? agentTotal,
  double? vatPercent,
  double? appCommissionPercent,
  int? bookingsAgent,
  bool? isAdmin,
  DateTime? agentDateReg,
  DateTime? agentDateEnd,
  String? driverid,
  bool? ismzod,
  int? isAdminRule,
  double? totalApp,
  String? textTypeCarMndob,
  bool? isPartner,
  DocumentReference? partnerMkanRef,
  DocumentReference? transportCompany,
  String? transportCompanyText,
  DocumentReference? revDolh,
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
      'Isagent': isagent,
      'dolh_agent': dolhAgent,
      'Rev_dloh_agent': revDlohAgent,
      'Agent_total': agentTotal,
      'vat_percent': vatPercent,
      'app_commission_percent': appCommissionPercent,
      'Bookings_Agent': bookingsAgent,
      'IsAdmin': isAdmin,
      'agent_date_reg': agentDateReg,
      'agent_date_end': agentDateEnd,
      'driverid': driverid,
      'ismzod': ismzod,
      'isAdminRule': isAdminRule,
      'total_app': totalApp,
      'text_type_car_mndob': textTypeCarMndob,
      'is_partner': isPartner,
      'partner_mkan': partnerMkanRef,
      'transport_company': transportCompany,
      'transport_company_text': transportCompanyText,
      'Rev_dolh': revDolh,
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
        e1?.isagent == e2?.isagent &&
        e1?.dolhAgent == e2?.dolhAgent &&
        e1?.revDlohAgent == e2?.revDlohAgent &&
        e1?.agentTotal == e2?.agentTotal &&
        e1?.vatPercent == e2?.vatPercent &&
        e1?.appCommissionPercent == e2?.appCommissionPercent &&
        e1?.bookingsAgent == e2?.bookingsAgent &&
        e1?.isAdmin == e2?.isAdmin &&
        e1?.agentDateReg == e2?.agentDateReg &&
        e1?.agentDateEnd == e2?.agentDateEnd &&
        e1?.driverid == e2?.driverid &&
        e1?.ismzod == e2?.ismzod &&
        e1?.isAdminRule == e2?.isAdminRule &&
        e1?.totalApp == e2?.totalApp &&
        e1?.textTypeCarMndob == e2?.textTypeCarMndob;
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
        e?.isagent,
        e?.dolhAgent,
        e?.revDlohAgent,
        e?.agentTotal,
        e?.vatPercent,
        e?.appCommissionPercent,
        e?.bookingsAgent,
        e?.isAdmin,
        e?.agentDateReg,
        e?.agentDateEnd,
        e?.driverid,
        e?.ismzod,
        e?.isAdminRule,
        e?.totalApp,
        e?.textTypeCarMndob
      ]);

  @override
  bool isValidKey(Object? o) => o is UserRecord;
}

int? _readFirestoreInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _readFirestoreDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? _readFirestoreString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

bool? _readFirestoreBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  return null;
}

DateTime? _readFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    if (value > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
  }
  return null;
}

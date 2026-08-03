import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrderRecord extends FirestoreRecord {
  OrderRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "rhlh" field.
  List<DocumentReference>? _rhlh;
  List<DocumentReference> get rhlh => _rhlh ?? const [];
  bool hasRhlh() => _rhlh != null;

  // "total" field.
  double? _total;
  double get total => _total ?? 0.0;
  bool hasTotal() => _total != null;

  // "USER" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "LOKESHN" field.
  LatLng? _lokeshn;
  LatLng? get lokeshn => _lokeshn;
  bool hasLokeshn() => _lokeshn != null;

  // "data_order" field.
  DateTime? _dataOrder;
  DateTime? get dataOrder => _dataOrder;
  bool hasDataOrder() => _dataOrder != null;

  // "cartext" field.
  String? _cartext;
  String get cartext => _cartext ?? '';
  bool hasCartext() => _cartext != null;

  // "carRev" field.
  DocumentReference? _carRev;
  DocumentReference? get carRev => _carRev;
  bool hasCarRev() => _carRev != null;

  // "mndob_user" field.
  DocumentReference? _mndobUser;
  DocumentReference? get mndobUser => _mndobUser;
  bool hasMndobUser() => _mndobUser != null;

  // "mzod_user" field.
  List<DocumentReference>? _mzodUser;
  List<DocumentReference> get mzodUser => _mzodUser ?? const [];
  bool hasMzodUser() => _mzodUser != null;

  // "mdend" field.
  DocumentReference? _mdend;
  DocumentReference? get mdend => _mdend;
  bool hasMdend() => _mdend != null;

  // "img_mndob" field.
  String? _imgMndob;
  String get imgMndob => _imgMndob ?? '';
  bool hasImgMndob() => _imgMndob != null;

  // "halh_text" field.
  String? _halhText;
  String get halhText => _halhText ?? '';
  bool hasHalhText() => _halhText != null;

  // "naim_user_text" field.
  String? _naimUserText;
  String get naimUserText => _naimUserText ?? '';
  bool hasNaimUserText() => _naimUserText != null;

  // "vill" field.
  DocumentReference? _vill;
  DocumentReference? get vill => _vill;
  bool hasVill() => _vill != null;

  // "naim_mndob_text" field.
  String? _naimMndobText;
  String get naimMndobText => _naimMndobText ?? '';
  bool hasNaimMndobText() => _naimMndobText != null;

  // "phone_numper" field.
  int? _phoneNumper;
  int get phoneNumper => _phoneNumper ?? 0;
  bool hasPhoneNumper() => _phoneNumper != null;

  // "vill_text" field.
  String? _villText;
  String get villText => _villText ?? '';
  bool hasVillText() => _villText != null;

  // "add_cart_numer" field.
  int? _addCartNumer;
  int get addCartNumer => _addCartNumer ?? 0;
  bool hasAddCartNumer() => _addCartNumer != null;

  // "phone_nu_mndob" field.
  int? _phoneNuMndob;
  int get phoneNuMndob => _phoneNuMndob ?? 0;
  bool hasPhoneNuMndob() => _phoneNuMndob != null;

  // "listamakn" field.
  AmaknCostmStruct? _listamakn;
  AmaknCostmStruct get listamakn => _listamakn ?? AmaknCostmStruct();
  bool hasListamakn() => _listamakn != null;

  // "cities_user_now" field.
  DocumentReference? _citiesUserNow;
  DocumentReference? get citiesUserNow => _citiesUserNow;
  bool hasCitiesUserNow() => _citiesUserNow != null;

  // "total_taim" field.
  int? _totalTaim;
  int get totalTaim => _totalTaim ?? 0;
  bool hasTotalTaim() => _totalTaim != null;

  // "listAmakn" field.
  List<AmaknCostmStruct>? _listAmakn;
  List<AmaknCostmStruct> get listAmakn => _listAmakn ?? const [];
  bool hasListAmakn() => _listAmakn != null;

  // "halh" field.
  String? _halh;
  String get halh => _halh ?? '';
  bool hasHalh() => _halh != null;

  // "IDorder" field.
  String? _iDorder;
  String get iDorder => _iDorder ?? '';
  bool hasIDorder() => _iDorder != null;

  // "norder" field.
  int? _norder;
  int get norder => _norder ?? 0;
  bool hasNorder() => _norder != null;

  // "total_mndob" field.
  int? _totalMndob;
  int get totalMndob => _totalMndob ?? 0;
  bool hasTotalMndob() => _totalMndob != null;

  // "total_vat" field.
  int? _totalVat;
  int get totalVat => _totalVat ?? 0;
  bool hasTotalVat() => _totalVat != null;

  // "total_app" field.
  int? _totalApp;
  int get totalApp => _totalApp ?? 0;
  bool hasTotalApp() => _totalApp != null;

  // "halh_order" field.
  Halh? _halhOrder;
  Halh? get halhOrder => _halhOrder;
  bool hasHalhOrder() => _halhOrder != null;

  // "Schedule" field.
  DateTime? _schedule;
  DateTime? get schedule => _schedule;
  bool hasSchedule() => _schedule != null;

  // "fullSchedule" field.
  String? _fullSchedule;
  String get fullSchedule => _fullSchedule ?? '';
  bool hasFullSchedule() => _fullSchedule != null;

  // "imgProfileClent" field.
  String? _imgProfileClent;
  String get imgProfileClent => _imgProfileClent ?? '';
  bool hasImgProfileClent() => _imgProfileClent != null;

  // "loceshStreng" field.
  String? _loceshStreng;
  String get loceshStreng => _loceshStreng ?? '';
  bool hasLoceshStreng() => _loceshStreng != null;

  // "ALLNOW" field.
  bool? _allnow;
  bool get allnow => _allnow ?? false;
  bool hasAllnow() => _allnow != null;

  // "ActiveOrder" field.
  bool? _activeOrder;
  bool get activeOrder => _activeOrder ?? false;
  bool hasActiveOrder() => _activeOrder != null;

  // "total_mndob2" field.
  double? _totalMndob2;
  double get totalMndob2 => _totalMndob2 ?? 0.0;
  bool hasTotalMndob2() => _totalMndob2 != null;

  // "ksm" field.
  double? _ksm;
  double get ksm => _ksm ?? 0.0;
  bool hasKsm() => _ksm != null;

  // "DriverGuide" field.
  bool? _driverGuide;
  bool get driverGuide => _driverGuide ?? false;
  bool hasDriverGuide() => _driverGuide != null;

  // "ReviewMndonsend" field.
  bool? _reviewMndonsend;
  bool get reviewMndonsend => _reviewMndonsend ?? false;
  bool hasReviewMndonsend() => _reviewMndonsend != null;

  // "RetengUser" field.
  double? _retengUser;
  double get retengUser => _retengUser ?? 0.0;
  bool hasRetengUser() => _retengUser != null;

  // "carmndob" field.
  String? _carmndob;
  String get carmndob => _carmndob ?? '';
  bool hasCarmndob() => _carmndob != null;

  // "halhOrderMndob" field.
  HalhOrder? _halhOrderMndob;
  HalhOrder? get halhOrderMndob => _halhOrderMndob;
  bool hasHalhOrderMndob() => _halhOrderMndob != null;

  // "revewSendClent" field.
  bool? _revewSendClent;
  bool get revewSendClent => _revewSendClent ?? false;
  bool hasRevewSendClent() => _revewSendClent != null;

  // "SrSAAH" field.
  double? _srSAAH;
  double get srSAAH => _srSAAH ?? 0.0;
  bool hasSrSAAH() => _srSAAH != null;

  // "PaymentMethod" field.
  PaymentMethod? _paymentMethod;
  PaymentMethod? get paymentMethod => _paymentMethod;
  bool hasPaymentMethod() => _paymentMethod != null;

  // "ngeniusOrderId" field — Network International payment reference.
  String? _ngeniusOrderId;
  String get ngeniusOrderId => _ngeniusOrderId ?? '';
  bool hasNgeniusOrderId() => _ngeniusOrderId != null;

  /// مرجع الدفع (يقرأ الحقل الجديد أو idMoyser للطلبات القديمة).
  String get paymentGatewayOrderId =>
      ngeniusOrderId.isNotEmpty ? ngeniusOrderId : (_idMoyser ?? '');

  // "idMoyser" field — legacy, read-only fallback.
  String? _idMoyser;
  @Deprecated('Use ngeniusOrderId')
  String get idMoyser => paymentGatewayOrderId;
  bool hasIdMoyser() => hasNgeniusOrderId() || _idMoyser != null;

  // "NotSestem" field.
  String? _notSestem;
  String get notSestem => _notSestem ?? '';
  bool hasNotSestem() => _notSestem != null;

  // "endTime" field.
  DateTime? _endTime;
  DateTime? get endTime => _endTime;
  bool hasEndTime() => _endTime != null;

  // "START" field.
  DateTime? _start;
  DateTime? get start => _start;
  bool hasStart() => _start != null;

  // "mapuser" field.
  LatLng? _mapuser;
  LatLng? get mapuser => _mapuser;
  bool hasMapuser() => _mapuser != null;

  // "ModelCar" field.
  String? _modelCar;
  String get modelCar => _modelCar ?? '';
  bool hasModelCar() => _modelCar != null;

  // "NameCar" field.
  String? _nameCar;
  String get nameCar => _nameCar ?? '';
  bool hasNameCar() => _nameCar != null;

  void _initializeFields() {
    _rhlh = getDataList<DocumentReference>(snapshotData['rhlh']);
    _total = castToType<double>(snapshotData['total']);
    _user = castDocRef(snapshotData['USER']);
    _lokeshn = snapshotData['LOKESHN'] as LatLng?;
    _dataOrder = snapshotData['data_order'] as DateTime?;
    _cartext = snapshotData['cartext'] as String?;
    _carRev = castDocRef(snapshotData['carRev']);
    _mndobUser = castDocRef(snapshotData['mndob_user']);
    _mzodUser = getDataList<DocumentReference>(snapshotData['mzod_user']);
    _mdend = castDocRef(snapshotData['mdend']);
    _imgMndob = snapshotData['img_mndob'] as String?;
    _halhText = snapshotData['halh_text'] as String?;
    _naimUserText = snapshotData['naim_user_text'] as String?;
    _vill = castDocRef(snapshotData['vill']);
    _naimMndobText = snapshotData['naim_mndob_text'] as String?;
    _phoneNumper = castToType<int>(snapshotData['phone_numper']);
    _villText = snapshotData['vill_text'] as String?;
    _addCartNumer = castToType<int>(snapshotData['add_cart_numer']);
    _phoneNuMndob = castToType<int>(snapshotData['phone_nu_mndob']);
    _listamakn = snapshotData['listamakn'] is AmaknCostmStruct
        ? snapshotData['listamakn']
        : AmaknCostmStruct.maybeFromMap(snapshotData['listamakn']);
    _citiesUserNow = castDocRef(snapshotData['cities_user_now']);
    _totalTaim = castToType<int>(snapshotData['total_taim']);
    _listAmakn = getStructList(
      snapshotData['listAmakn'],
      AmaknCostmStruct.fromMap,
    );
    _halh = snapshotData['halh'] as String?;
    _iDorder = snapshotData['IDorder'] as String?;
    _norder = castToType<int>(snapshotData['norder']);
    _totalMndob = castToType<int>(snapshotData['total_mndob']);
    _totalVat = castToType<int>(snapshotData['total_vat']);
    _totalApp = castToType<int>(snapshotData['total_app']);
    _halhOrder = snapshotData['halh_order'] is Halh
        ? snapshotData['halh_order']
        : deserializeEnum<Halh>(snapshotData['halh_order']);
    _schedule = snapshotData['Schedule'] as DateTime?;
    _fullSchedule = snapshotData['fullSchedule'] as String?;
    _imgProfileClent = snapshotData['imgProfileClent'] as String?;
    _loceshStreng = snapshotData['loceshStreng'] as String?;
    _allnow = snapshotData['ALLNOW'] as bool?;
    _activeOrder = snapshotData['ActiveOrder'] as bool?;
    _totalMndob2 = castToType<double>(snapshotData['total_mndob2']);
    _ksm = castToType<double>(snapshotData['ksm']);
    _driverGuide = snapshotData['DriverGuide'] as bool?;
    _reviewMndonsend = snapshotData['ReviewMndonsend'] as bool?;
    _retengUser = castToType<double>(snapshotData['RetengUser']);
    _carmndob = snapshotData['carmndob'] as String?;
    _halhOrderMndob = snapshotData['halhOrderMndob'] is HalhOrder
        ? snapshotData['halhOrderMndob']
        : deserializeEnum<HalhOrder>(snapshotData['halhOrderMndob']);
    _revewSendClent = snapshotData['revewSendClent'] as bool?;
    _srSAAH = castToType<double>(snapshotData['SrSAAH']);
    _paymentMethod = snapshotData['PaymentMethod'] is PaymentMethod
        ? snapshotData['PaymentMethod']
        : deserializeEnum<PaymentMethod>(snapshotData['PaymentMethod']);
    _ngeniusOrderId = (snapshotData['ngeniusOrderId'] ?? snapshotData['idMoyser'])
        as String?;
    _idMoyser = snapshotData['idMoyser'] as String?;
    _notSestem = snapshotData['NotSestem'] as String?;
    _endTime = snapshotData['endTime'] as DateTime?;
    _start = snapshotData['START'] as DateTime?;
    _mapuser = snapshotData['mapuser'] as LatLng?;
    _modelCar = snapshotData['ModelCar'] as String?;
    _nameCar = snapshotData['NameCar'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('order');

  static Stream<OrderRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrderRecord.fromSnapshot(s));

  static Future<OrderRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrderRecord.fromSnapshot(s));

  static OrderRecord fromSnapshot(DocumentSnapshot snapshot) => OrderRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OrderRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OrderRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OrderRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OrderRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrderRecordData({
  double? total,
  DocumentReference? user,
  LatLng? lokeshn,
  DateTime? dataOrder,
  String? cartext,
  DocumentReference? carRev,
  DocumentReference? mndobUser,
  DocumentReference? mdend,
  String? imgMndob,
  String? halhText,
  String? naimUserText,
  DocumentReference? vill,
  String? naimMndobText,
  int? phoneNumper,
  String? villText,
  int? addCartNumer,
  int? phoneNuMndob,
  AmaknCostmStruct? listamakn,
  DocumentReference? citiesUserNow,
  int? totalTaim,
  String? halh,
  String? iDorder,
  int? norder,
  int? totalMndob,
  int? totalVat,
  int? totalApp,
  Halh? halhOrder,
  DateTime? schedule,
  String? fullSchedule,
  String? imgProfileClent,
  String? loceshStreng,
  bool? allnow,
  bool? activeOrder,
  double? totalMndob2,
  double? ksm,
  bool? driverGuide,
  bool? reviewMndonsend,
  double? retengUser,
  String? carmndob,
  HalhOrder? halhOrderMndob,
  bool? revewSendClent,
  double? srSAAH,
  PaymentMethod? paymentMethod,
  String? ngeniusOrderId,
  String? notSestem,
  DateTime? endTime,
  DateTime? start,
  LatLng? mapuser,
  String? modelCar,
  String? nameCar,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'total': total,
      'USER': user,
      'LOKESHN': lokeshn,
      'data_order': dataOrder,
      'cartext': cartext,
      'carRev': carRev,
      'mndob_user': mndobUser,
      'mdend': mdend,
      'img_mndob': imgMndob,
      'halh_text': halhText,
      'naim_user_text': naimUserText,
      'vill': vill,
      'naim_mndob_text': naimMndobText,
      'phone_numper': phoneNumper,
      'vill_text': villText,
      'add_cart_numer': addCartNumer,
      'phone_nu_mndob': phoneNuMndob,
      'listamakn': AmaknCostmStruct().toMap(),
      'cities_user_now': citiesUserNow,
      'total_taim': totalTaim,
      'halh': halh,
      'IDorder': iDorder,
      'norder': norder,
      'total_mndob': totalMndob,
      'total_vat': totalVat,
      'total_app': totalApp,
      'halh_order': halhOrder,
      'Schedule': schedule,
      'fullSchedule': fullSchedule,
      'imgProfileClent': imgProfileClent,
      'loceshStreng': loceshStreng,
      'ALLNOW': allnow,
      'ActiveOrder': activeOrder,
      'total_mndob2': totalMndob2,
      'ksm': ksm,
      'DriverGuide': driverGuide,
      'ReviewMndonsend': reviewMndonsend,
      'RetengUser': retengUser,
      'carmndob': carmndob,
      'halhOrderMndob': halhOrderMndob,
      'revewSendClent': revewSendClent,
      'SrSAAH': srSAAH,
      'PaymentMethod': paymentMethod,
      'ngeniusOrderId': ngeniusOrderId,
      'NotSestem': notSestem,
      'endTime': endTime,
      'START': start,
      'mapuser': mapuser,
      'ModelCar': modelCar,
      'NameCar': nameCar,
    }.withoutNulls,
  );

  // Handle nested data for "listamakn" field.
  addAmaknCostmStructData(firestoreData, listamakn, 'listamakn');

  return firestoreData;
}

class OrderRecordDocumentEquality implements Equality<OrderRecord> {
  const OrderRecordDocumentEquality();

  @override
  bool equals(OrderRecord? e1, OrderRecord? e2) {
    const listEquality = ListEquality();
    return listEquality.equals(e1?.rhlh, e2?.rhlh) &&
        e1?.total == e2?.total &&
        e1?.user == e2?.user &&
        e1?.lokeshn == e2?.lokeshn &&
        e1?.dataOrder == e2?.dataOrder &&
        e1?.cartext == e2?.cartext &&
        e1?.carRev == e2?.carRev &&
        e1?.mndobUser == e2?.mndobUser &&
        listEquality.equals(e1?.mzodUser, e2?.mzodUser) &&
        e1?.mdend == e2?.mdend &&
        e1?.imgMndob == e2?.imgMndob &&
        e1?.halhText == e2?.halhText &&
        e1?.naimUserText == e2?.naimUserText &&
        e1?.vill == e2?.vill &&
        e1?.naimMndobText == e2?.naimMndobText &&
        e1?.phoneNumper == e2?.phoneNumper &&
        e1?.villText == e2?.villText &&
        e1?.addCartNumer == e2?.addCartNumer &&
        e1?.phoneNuMndob == e2?.phoneNuMndob &&
        e1?.listamakn == e2?.listamakn &&
        e1?.citiesUserNow == e2?.citiesUserNow &&
        e1?.totalTaim == e2?.totalTaim &&
        listEquality.equals(e1?.listAmakn, e2?.listAmakn) &&
        e1?.halh == e2?.halh &&
        e1?.iDorder == e2?.iDorder &&
        e1?.norder == e2?.norder &&
        e1?.totalMndob == e2?.totalMndob &&
        e1?.totalVat == e2?.totalVat &&
        e1?.totalApp == e2?.totalApp &&
        e1?.halhOrder == e2?.halhOrder &&
        e1?.schedule == e2?.schedule &&
        e1?.fullSchedule == e2?.fullSchedule &&
        e1?.imgProfileClent == e2?.imgProfileClent &&
        e1?.loceshStreng == e2?.loceshStreng &&
        e1?.allnow == e2?.allnow &&
        e1?.activeOrder == e2?.activeOrder &&
        e1?.totalMndob2 == e2?.totalMndob2 &&
        e1?.ksm == e2?.ksm &&
        e1?.driverGuide == e2?.driverGuide &&
        e1?.reviewMndonsend == e2?.reviewMndonsend &&
        e1?.retengUser == e2?.retengUser &&
        e1?.carmndob == e2?.carmndob &&
        e1?.halhOrderMndob == e2?.halhOrderMndob &&
        e1?.revewSendClent == e2?.revewSendClent &&
        e1?.srSAAH == e2?.srSAAH &&
        e1?.paymentMethod == e2?.paymentMethod &&
        e1?.ngeniusOrderId == e2?.ngeniusOrderId &&
        e1?.notSestem == e2?.notSestem &&
        e1?.endTime == e2?.endTime &&
        e1?.start == e2?.start &&
        e1?.mapuser == e2?.mapuser &&
        e1?.modelCar == e2?.modelCar &&
        e1?.nameCar == e2?.nameCar;
  }

  @override
  int hash(OrderRecord? e) => const ListEquality().hash([
        e?.rhlh,
        e?.total,
        e?.user,
        e?.lokeshn,
        e?.dataOrder,
        e?.cartext,
        e?.carRev,
        e?.mndobUser,
        e?.mzodUser,
        e?.mdend,
        e?.imgMndob,
        e?.halhText,
        e?.naimUserText,
        e?.vill,
        e?.naimMndobText,
        e?.phoneNumper,
        e?.villText,
        e?.addCartNumer,
        e?.phoneNuMndob,
        e?.listamakn,
        e?.citiesUserNow,
        e?.totalTaim,
        e?.listAmakn,
        e?.halh,
        e?.iDorder,
        e?.norder,
        e?.totalMndob,
        e?.totalVat,
        e?.totalApp,
        e?.halhOrder,
        e?.schedule,
        e?.fullSchedule,
        e?.imgProfileClent,
        e?.loceshStreng,
        e?.allnow,
        e?.activeOrder,
        e?.totalMndob2,
        e?.ksm,
        e?.driverGuide,
        e?.reviewMndonsend,
        e?.retengUser,
        e?.carmndob,
        e?.halhOrderMndob,
        e?.revewSendClent,
        e?.srSAAH,
        e?.paymentMethod,
        e?.ngeniusOrderId,
        e?.notSestem,
        e?.endTime,
        e?.start,
        e?.mapuser,
        e?.modelCar,
        e?.nameCar
      ]);

  @override
  bool isValidKey(Object? o) => o is OrderRecord;
}

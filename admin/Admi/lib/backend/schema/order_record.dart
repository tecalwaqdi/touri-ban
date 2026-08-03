import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrderRecord extends FirestoreRecord {
  OrderRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
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

  // "Rev_dolh" field.
  DocumentReference? _revDolh;
  DocumentReference? get revDolh => _revDolh;
  bool hasRevDolh() => _revDolh != null;

  // "ALLNOW" field.
  bool? _allnow;
  bool get allnow => _allnow ?? false;
  bool hasAllnow() => _allnow != null;

  // "partner_mkans" field — denormalized landmark refs for partner queries.
  List<DocumentReference>? _partnerMkans;
  List<DocumentReference> get partnerMkans => _partnerMkans ?? const [];
  bool hasPartnerMkans() => _partnerMkans != null && _partnerMkans!.isNotEmpty;

  // "mapuser" field.
  LatLng? _mapuser;
  LatLng? get mapuser => _mapuser;
  bool hasMapuser() => _mapuser != null;

  // "PaymentMethod" field.
  PaymentMethod? _paymentMethod;
  PaymentMethod? get paymentMethod => _paymentMethod;
  bool hasPaymentMethod() => _paymentMethod != null;

  // "ngeniusOrderId" field — Network International payment reference.
  String? _ngeniusOrderId;
  String get ngeniusOrderId => _ngeniusOrderId ?? '';
  bool hasNgeniusOrderId() => _ngeniusOrderId != null;

  String get paymentGatewayOrderId =>
      ngeniusOrderId.isNotEmpty ? ngeniusOrderId : (_idMoyser ?? '');

  // Legacy Moyasar reference (read-only).
  String? _idMoyser;
  String get idMoyser => paymentGatewayOrderId;
  bool hasIdMoyser() => hasNgeniusOrderId() || _idMoyser != null;

  // "total_mndob2" field.
  int? _totalMndob2;
  int get totalMndob2 => _totalMndob2 ?? 0;
  bool hasTotalMndob2() => _totalMndob2 != null;

  void _initializeFields() {
    _rhlh = getDataList(snapshotData['rhlh']);
    _total = castToType<double>(snapshotData['total']);
    _user = snapshotData['USER'] as DocumentReference?;
    _lokeshn = snapshotData['LOKESHN'] as LatLng?;
    _dataOrder = snapshotData['data_order'] as DateTime?;
    _cartext = snapshotData['cartext'] as String?;
    _carRev = snapshotData['carRev'] as DocumentReference?;
    _mndobUser = snapshotData['mndob_user'] as DocumentReference?;
    _mzodUser = getDataList(snapshotData['mzod_user']);
    _mdend = snapshotData['mdend'] as DocumentReference?;
    _imgMndob = snapshotData['img_mndob'] as String?;
    _halhText = snapshotData['halh_text'] as String?;
    _naimUserText = snapshotData['naim_user_text'] as String?;
    _vill = snapshotData['vill'] as DocumentReference?;
    _naimMndobText = snapshotData['naim_mndob_text'] as String?;
    _phoneNumper = castToType<int>(snapshotData['phone_numper']);
    _villText = snapshotData['vill_text'] as String?;
    _addCartNumer = castToType<int>(snapshotData['add_cart_numer']);
    _phoneNuMndob = castToType<int>(snapshotData['phone_nu_mndob']);
    _listamakn = snapshotData['listamakn'] is AmaknCostmStruct
        ? snapshotData['listamakn']
        : AmaknCostmStruct.maybeFromMap(snapshotData['listamakn']);
    _citiesUserNow = snapshotData['cities_user_now'] as DocumentReference?;
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
    _revDolh = snapshotData['Rev_dolh'] as DocumentReference?;
    _allnow = snapshotData['ALLNOW'] as bool?;
    _partnerMkans = getDataList(snapshotData['partner_mkans']);
    _mapuser = snapshotData['mapuser'] as LatLng?;
    _paymentMethod = snapshotData['PaymentMethod'] is PaymentMethod
        ? snapshotData['PaymentMethod']
        : deserializeEnum<PaymentMethod>(snapshotData['PaymentMethod']);
    _ngeniusOrderId = (snapshotData['ngeniusOrderId'] ?? snapshotData['idMoyser'])
        as String?;
    _idMoyser = snapshotData['idMoyser'] as String?;
    _totalMndob2 = castToType<int>(snapshotData['total_mndob2']);
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
  DocumentReference? revDolh,
  bool? allnow,
  List<DocumentReference>? partnerMkans,
  LatLng? mapuser,
  PaymentMethod? paymentMethod,
  String? ngeniusOrderId,
  int? totalMndob2,
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
      'Rev_dolh': revDolh,
      'ALLNOW': allnow,
      'partner_mkans': partnerMkans,
      'mapuser': mapuser,
      'PaymentMethod': paymentMethod,
      'ngeniusOrderId': ngeniusOrderId,
      'total_mndob2': totalMndob2,
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
        e1?.revDolh == e2?.revDolh &&
        e1?.allnow == e2?.allnow &&
        e1?.mapuser == e2?.mapuser &&
        e1?.paymentMethod == e2?.paymentMethod &&
        e1?.totalMndob2 == e2?.totalMndob2;
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
        e?.revDolh,
        e?.allnow,
        e?.mapuser,
        e?.paymentMethod,
        e?.totalMndob2
      ]);

  @override
  bool isValidKey(Object? o) => o is OrderRecord;
}

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
  double get total => _total ?? 0;
  bool hasTotal() => _total != null;

  // "USER" field.
  DocumentReference? _user;
  DocumentReference? get user => _user;
  bool hasUser() => _user != null;

  // "mndob_user" field.
  DocumentReference? _mndobUser;
  DocumentReference? get mndobUser => _mndobUser;
  bool hasMndobUser() => _mndobUser != null;

  // "halh_text" field.
  String? _halhText;
  String get halhText => _halhText ?? '';
  bool hasHalhText() => _halhText != null;

  // "naim_mndob_text" field.
  String? _naimMndobText;
  String get naimMndobText => _naimMndobText ?? '';
  bool hasNaimMndobText() => _naimMndobText != null;

  // "naim_user_text" field.
  String? _naimUserText;
  String get naimUserText => _naimUserText ?? '';
  bool hasNaimUserText() => _naimUserText != null;

  // "phone_numper" field.
  int? _phoneNumper;
  int get phoneNumper => _phoneNumper ?? 0;
  bool hasPhoneNumper() => _phoneNumper != null;

  // "phone_nu_mndob" field.
  int? _phoneNuMndob;
  int get phoneNuMndob => _phoneNuMndob ?? 0;
  bool hasPhoneNuMndob() => _phoneNuMndob != null;

  // "vill" field.
  DocumentReference? _vill;
  DocumentReference? get vill => _vill;
  bool hasVill() => _vill != null;

  // "data_order" field.
  DateTime? _dataOrder;
  DateTime? get dataOrder => _dataOrder;
  bool hasDataOrder() => _dataOrder != null;

  // "add_cart_numer" field.
  int? _addCartNumer;
  int get addCartNumer => _addCartNumer ?? 0;
  bool hasAddCartNumer() => _addCartNumer != null;

  // "total_taim" field.
  int? _totalTaim;
  int get totalTaim => _totalTaim ?? 0;
  bool hasTotalTaim() => _totalTaim != null;

  // "cities_user_now" field.
  DocumentReference? _citiesUserNow;
  DocumentReference? get citiesUserNow => _citiesUserNow;
  bool hasCitiesUserNow() => _citiesUserNow != null;

  // "listAmakn" field.
  List<AmaknCoistmStruct>? _listAmakn;
  List<AmaknCoistmStruct> get listAmakn => _listAmakn ?? const [];
  bool hasListAmakn() => _listAmakn != null;

  // "halh" field.
  String? _halh;
  String get halh => _halh ?? '';
  bool hasHalh() => _halh != null;

  // "vill_text" field.
  String? _villText;
  String get villText => _villText ?? '';
  bool hasVillText() => _villText != null;

  // "IDorder" field.
  String? _iDorder;
  String get iDorder => _iDorder ?? '';
  bool hasIDorder() => _iDorder != null;

  // "carRev" field.
  DocumentReference? _carRev;
  DocumentReference? get carRev => _carRev;
  bool hasCarRev() => _carRev != null;

  // "durationInSeconds" field.
  int? _durationInSeconds;
  int get durationInSeconds => _durationInSeconds ?? 0;
  bool hasDurationInSeconds() => _durationInSeconds != null;

  // "customerRating" field.
  double? _customerRating;
  double get customerRating => _customerRating ?? 0.0;
  bool hasCustomerRating() => _customerRating != null;

  // "customerWaitingTimeInSeconds" field.
  int? _customerWaitingTimeInSeconds;
  int get customerWaitingTimeInSeconds => _customerWaitingTimeInSeconds ?? 0;
  bool hasCustomerWaitingTimeInSeconds() =>
      _customerWaitingTimeInSeconds != null;

  // "originLatitude" field.
  double? _originLatitude;
  double get originLatitude => _originLatitude ?? 0.0;
  bool hasOriginLatitude() => _originLatitude != null;

  // "originLongitude" field.
  double? _originLongitude;
  double get originLongitude => _originLongitude ?? 0.0;
  bool hasOriginLongitude() => _originLongitude != null;

  // "destinationLatitude" field.
  double? _destinationLatitude;
  double get destinationLatitude => _destinationLatitude ?? 0.0;
  bool hasDestinationLatitude() => _destinationLatitude != null;

  // "destinationLongitude" field.
  double? _destinationLongitude;
  double get destinationLongitude => _destinationLongitude ?? 0.0;
  bool hasDestinationLongitude() => _destinationLongitude != null;

  // "pickupTimestamp" field.
  String? _pickupTimestamp;
  String get pickupTimestamp => _pickupTimestamp ?? '';
  bool hasPickupTimestamp() => _pickupTimestamp != null;

  // "dropoffTimestamp" field.
  String? _dropoffTimestamp;
  String get dropoffTimestamp => _dropoffTimestamp ?? '';
  bool hasDropoffTimestamp() => _dropoffTimestamp != null;

  // "START" field.
  DateTime? _start;
  DateTime? get start => _start;
  bool hasStart() => _start != null;

  // "imgProfileClent" field.
  String? _imgProfileClent;
  String get imgProfileClent => _imgProfileClent ?? '';
  bool hasImgProfileClent() => _imgProfileClent != null;

  // "total_mndob" field — Driver Net (SAR major).
  double? _totalMndob;
  double get totalMndob => _totalMndob ?? 0;
  bool hasTotalMndob() => _totalMndob != null;

  // "total_app" field — Platform fee (SAR major).
  double? _totalApp;
  double get totalApp => _totalApp ?? 0;
  bool hasTotalApp() => _totalApp != null;

  // "loceshStreng" field.
  String? _loceshStreng;
  String get loceshStreng => _loceshStreng ?? '';
  bool hasLoceshStreng() => _loceshStreng != null;

  // "LOKESHN" field.
  LatLng? _lokeshn;
  LatLng? get lokeshn => _lokeshn;
  bool hasLokeshn() => _lokeshn != null;

  // "ALLNOW" field.
  bool? _allnow;
  bool get allnow => _allnow ?? false;
  bool hasAllnow() => _allnow != null;

  // "total_vat" field — Recorded VAT (SAR major).
  double? _totalVat;
  double get totalVat => _totalVat ?? 0;
  bool hasTotalVat() => _totalVat != null;

  // "DATEEND" field.
  DateTime? _dateend;
  DateTime? get dateend => _dateend;
  bool hasDateend() => _dateend != null;

  // "ActiveOrder" field.
  bool? _activeOrder;
  bool get activeOrder => _activeOrder ?? false;
  bool hasActiveOrder() => _activeOrder != null;

  // "total_mndob2" field.
  double? _totalMndob2;
  double get totalMndob2 => _totalMndob2 ?? 0.0;
  bool hasTotalMndob2() => _totalMndob2 != null;

  // "ReviewMndobsend" field.
  bool? _reviewMndobsend;
  bool get reviewMndobsend => _reviewMndobsend ?? false;
  bool hasReviewMndobsend() => _reviewMndobsend != null;

  // "ReviewClentSend" field.
  bool? _reviewClentSend;
  bool get reviewClentSend => _reviewClentSend ?? false;
  bool hasReviewClentSend() => _reviewClentSend != null;

  // "RetengUser" field.
  double? _retengUser;
  double get retengUser => _retengUser ?? 0.0;
  bool hasRetengUser() => _retengUser != null;

  // "nn" field.
  int? _nn;
  int get nn => _nn ?? 0;
  bool hasNn() => _nn != null;

  // "halhOrderMndob" field.
  HalhOrder? _halhOrderMndob;
  HalhOrder? get halhOrderMndob => _halhOrderMndob;
  bool hasHalhOrderMndob() => _halhOrderMndob != null;

  // "carmndob" field.
  String? _carmndob;
  String get carmndob => _carmndob ?? '';
  bool hasCarmndob() => _carmndob != null;

  // "orderRev" field.
  DocumentReference? _orderRev;
  DocumentReference? get orderRev => _orderRev;
  bool hasOrderRev() => _orderRev != null;

  // "PaymentMethod" field.
  PaymentMethod? _paymentMethod;
  PaymentMethod? get paymentMethod => _paymentMethod;
  bool hasPaymentMethod() => _paymentMethod != null;

  // "endTime" field.
  DateTime? _endTime;
  DateTime? get endTime => _endTime;
  bool hasEndTime() => _endTime != null;

  // "mapuser" field.
  LatLng? _mapuser;
  LatLng? get mapuser => _mapuser;
  bool hasMapuser() => _mapuser != null;

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  // "NameCar" field.
  String? _nameCar;
  String get nameCar => _nameCar ?? '';
  bool hasNameCar() => _nameCar != null;

  // "ModelCar" field.
  String? _modelCar;
  String get modelCar => _modelCar ?? '';
  bool hasModelCar() => _modelCar != null;

  void _initializeFields() {
    _rhlh = getDataList(snapshotData['rhlh']);
    _total = castToType<double>(snapshotData['total']);
    _user = snapshotData['USER'] as DocumentReference?;
    _mndobUser = snapshotData['mndob_user'] as DocumentReference?;
    _halhText = snapshotData['halh_text'] as String?;
    _naimMndobText = snapshotData['naim_mndob_text'] as String?;
    _naimUserText = snapshotData['naim_user_text'] as String?;
    _phoneNumper = castToType<int>(snapshotData['phone_numper']);
    _phoneNuMndob = castToType<int>(snapshotData['phone_nu_mndob']);
    _vill = snapshotData['vill'] as DocumentReference?;
    _dataOrder = snapshotData['data_order'] as DateTime?;
    _addCartNumer = castToType<int>(snapshotData['add_cart_numer']);
    _totalTaim = castToType<int>(snapshotData['total_taim']);
    _citiesUserNow = snapshotData['cities_user_now'] as DocumentReference?;
    _listAmakn = getStructList(
      snapshotData['listAmakn'],
      AmaknCoistmStruct.fromMap,
    );
    _halh = snapshotData['halh'] as String?;
    _villText = snapshotData['vill_text'] as String?;
    _iDorder = snapshotData['IDorder'] as String?;
    _carRev = snapshotData['carRev'] as DocumentReference?;
    _durationInSeconds = castToType<int>(snapshotData['durationInSeconds']);
    _customerRating = castToType<double>(snapshotData['customerRating']);
    _customerWaitingTimeInSeconds =
        castToType<int>(snapshotData['customerWaitingTimeInSeconds']);
    _originLatitude = castToType<double>(snapshotData['originLatitude']);
    _originLongitude = castToType<double>(snapshotData['originLongitude']);
    _destinationLatitude =
        castToType<double>(snapshotData['destinationLatitude']);
    _destinationLongitude =
        castToType<double>(snapshotData['destinationLongitude']);
    _pickupTimestamp = snapshotData['pickupTimestamp'] as String?;
    _dropoffTimestamp = snapshotData['dropoffTimestamp'] as String?;
    _start = snapshotData['START'] as DateTime?;
    _imgProfileClent = snapshotData['imgProfileClent'] as String?;
    _totalMndob = castToType<double>(snapshotData['total_mndob']);
    _totalApp = castToType<double>(snapshotData['total_app']);
    _loceshStreng = snapshotData['loceshStreng'] as String?;
    _lokeshn = snapshotData['LOKESHN'] as LatLng?;
    _allnow = snapshotData['ALLNOW'] as bool?;
    _totalVat = castToType<double>(snapshotData['total_vat']);
    _dateend = snapshotData['DATEEND'] as DateTime?;
    _activeOrder = snapshotData['ActiveOrder'] as bool?;
    _totalMndob2 = castToType<double>(snapshotData['total_mndob2']);
    _reviewMndobsend = snapshotData['ReviewMndobsend'] as bool?;
    _reviewClentSend = snapshotData['ReviewClentSend'] as bool?;
    _retengUser = castToType<double>(snapshotData['RetengUser']);
    _nn = castToType<int>(snapshotData['nn']);
    _halhOrderMndob = snapshotData['halhOrderMndob'] is HalhOrder
        ? snapshotData['halhOrderMndob']
        : deserializeEnum<HalhOrder>(snapshotData['halhOrderMndob']);
    _carmndob = snapshotData['carmndob'] as String?;
    _orderRev = snapshotData['orderRev'] as DocumentReference?;
    _paymentMethod = snapshotData['PaymentMethod'] is PaymentMethod
        ? snapshotData['PaymentMethod']
        : deserializeEnum<PaymentMethod>(snapshotData['PaymentMethod']);
    _endTime = snapshotData['endTime'] as DateTime?;
    _mapuser = snapshotData['mapuser'] as LatLng?;
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _nameCar = snapshotData['NameCar'] as String?;
    _modelCar = snapshotData['ModelCar'] as String?;
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
  DocumentReference? mndobUser,
  String? halhText,
  String? naimMndobText,
  String? naimUserText,
  int? phoneNumper,
  int? phoneNuMndob,
  DocumentReference? vill,
  DateTime? dataOrder,
  int? addCartNumer,
  int? totalTaim,
  DocumentReference? citiesUserNow,
  String? halh,
  String? villText,
  String? iDorder,
  DocumentReference? carRev,
  int? durationInSeconds,
  double? customerRating,
  int? customerWaitingTimeInSeconds,
  double? originLatitude,
  double? originLongitude,
  double? destinationLatitude,
  double? destinationLongitude,
  String? pickupTimestamp,
  String? dropoffTimestamp,
  DateTime? start,
  String? imgProfileClent,
  double? totalMndob,
  double? totalApp,
  String? loceshStreng,
  LatLng? lokeshn,
  bool? allnow,
  double? totalVat,
  DateTime? dateend,
  bool? activeOrder,
  double? totalMndob2,
  bool? reviewMndobsend,
  bool? reviewClentSend,
  double? retengUser,
  int? nn,
  HalhOrder? halhOrderMndob,
  String? carmndob,
  DocumentReference? orderRev,
  PaymentMethod? paymentMethod,
  DateTime? endTime,
  LatLng? mapuser,
  DateTime? timestamp,
  String? nameCar,
  String? modelCar,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'total': total,
      'USER': user,
      'mndob_user': mndobUser,
      'halh_text': halhText,
      'naim_mndob_text': naimMndobText,
      'naim_user_text': naimUserText,
      'phone_numper': phoneNumper,
      'phone_nu_mndob': phoneNuMndob,
      'vill': vill,
      'data_order': dataOrder,
      'add_cart_numer': addCartNumer,
      'total_taim': totalTaim,
      'cities_user_now': citiesUserNow,
      'halh': halh,
      'vill_text': villText,
      'IDorder': iDorder,
      'carRev': carRev,
      'durationInSeconds': durationInSeconds,
      'customerRating': customerRating,
      'customerWaitingTimeInSeconds': customerWaitingTimeInSeconds,
      'originLatitude': originLatitude,
      'originLongitude': originLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'pickupTimestamp': pickupTimestamp,
      'dropoffTimestamp': dropoffTimestamp,
      'START': start,
      'imgProfileClent': imgProfileClent,
      'total_mndob': totalMndob,
      'total_app': totalApp,
      'loceshStreng': loceshStreng,
      'LOKESHN': lokeshn,
      'ALLNOW': allnow,
      'total_vat': totalVat,
      'DATEEND': dateend,
      'ActiveOrder': activeOrder,
      'total_mndob2': totalMndob2,
      'ReviewMndobsend': reviewMndobsend,
      'ReviewClentSend': reviewClentSend,
      'RetengUser': retengUser,
      'nn': nn,
      'halhOrderMndob': halhOrderMndob,
      'carmndob': carmndob,
      'orderRev': orderRev,
      'PaymentMethod': paymentMethod,
      'endTime': endTime,
      'mapuser': mapuser,
      'timestamp': timestamp,
      'NameCar': nameCar,
      'ModelCar': modelCar,
    }.withoutNulls,
  );

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
        e1?.mndobUser == e2?.mndobUser &&
        e1?.halhText == e2?.halhText &&
        e1?.naimMndobText == e2?.naimMndobText &&
        e1?.naimUserText == e2?.naimUserText &&
        e1?.phoneNumper == e2?.phoneNumper &&
        e1?.phoneNuMndob == e2?.phoneNuMndob &&
        e1?.vill == e2?.vill &&
        e1?.dataOrder == e2?.dataOrder &&
        e1?.addCartNumer == e2?.addCartNumer &&
        e1?.totalTaim == e2?.totalTaim &&
        e1?.citiesUserNow == e2?.citiesUserNow &&
        listEquality.equals(e1?.listAmakn, e2?.listAmakn) &&
        e1?.halh == e2?.halh &&
        e1?.villText == e2?.villText &&
        e1?.iDorder == e2?.iDorder &&
        e1?.carRev == e2?.carRev &&
        e1?.durationInSeconds == e2?.durationInSeconds &&
        e1?.customerRating == e2?.customerRating &&
        e1?.customerWaitingTimeInSeconds == e2?.customerWaitingTimeInSeconds &&
        e1?.originLatitude == e2?.originLatitude &&
        e1?.originLongitude == e2?.originLongitude &&
        e1?.destinationLatitude == e2?.destinationLatitude &&
        e1?.destinationLongitude == e2?.destinationLongitude &&
        e1?.pickupTimestamp == e2?.pickupTimestamp &&
        e1?.dropoffTimestamp == e2?.dropoffTimestamp &&
        e1?.start == e2?.start &&
        e1?.imgProfileClent == e2?.imgProfileClent &&
        e1?.totalMndob == e2?.totalMndob &&
        e1?.totalApp == e2?.totalApp &&
        e1?.loceshStreng == e2?.loceshStreng &&
        e1?.lokeshn == e2?.lokeshn &&
        e1?.allnow == e2?.allnow &&
        e1?.totalVat == e2?.totalVat &&
        e1?.dateend == e2?.dateend &&
        e1?.activeOrder == e2?.activeOrder &&
        e1?.totalMndob2 == e2?.totalMndob2 &&
        e1?.reviewMndobsend == e2?.reviewMndobsend &&
        e1?.reviewClentSend == e2?.reviewClentSend &&
        e1?.retengUser == e2?.retengUser &&
        e1?.nn == e2?.nn &&
        e1?.halhOrderMndob == e2?.halhOrderMndob &&
        e1?.carmndob == e2?.carmndob &&
        e1?.orderRev == e2?.orderRev &&
        e1?.paymentMethod == e2?.paymentMethod &&
        e1?.endTime == e2?.endTime &&
        e1?.mapuser == e2?.mapuser &&
        e1?.timestamp == e2?.timestamp &&
        e1?.nameCar == e2?.nameCar &&
        e1?.modelCar == e2?.modelCar;
  }

  @override
  int hash(OrderRecord? e) => const ListEquality().hash([
        e?.rhlh,
        e?.total,
        e?.user,
        e?.mndobUser,
        e?.halhText,
        e?.naimMndobText,
        e?.naimUserText,
        e?.phoneNumper,
        e?.phoneNuMndob,
        e?.vill,
        e?.dataOrder,
        e?.addCartNumer,
        e?.totalTaim,
        e?.citiesUserNow,
        e?.listAmakn,
        e?.halh,
        e?.villText,
        e?.iDorder,
        e?.carRev,
        e?.durationInSeconds,
        e?.customerRating,
        e?.customerWaitingTimeInSeconds,
        e?.originLatitude,
        e?.originLongitude,
        e?.destinationLatitude,
        e?.destinationLongitude,
        e?.pickupTimestamp,
        e?.dropoffTimestamp,
        e?.start,
        e?.imgProfileClent,
        e?.totalMndob,
        e?.totalApp,
        e?.loceshStreng,
        e?.lokeshn,
        e?.allnow,
        e?.totalVat,
        e?.dateend,
        e?.activeOrder,
        e?.totalMndob2,
        e?.reviewMndobsend,
        e?.reviewClentSend,
        e?.retengUser,
        e?.nn,
        e?.halhOrderMndob,
        e?.carmndob,
        e?.orderRev,
        e?.paymentMethod,
        e?.endTime,
        e?.mapuser,
        e?.timestamp,
        e?.nameCar,
        e?.modelCar
      ]);

  @override
  bool isValidKey(Object? o) => o is OrderRecord;
}

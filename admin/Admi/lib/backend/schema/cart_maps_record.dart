import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CartMapsRecord extends FirestoreRecord {
  CartMapsRecord._(
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

  // "idorder" field.
  int? _idorder;
  int get idorder => _idorder ?? 0;
  bool hasIdorder() => _idorder != null;

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

  // "halh" field.
  Halh? _halh;
  Halh? get halh => _halh;
  bool hasHalh() => _halh != null;

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

  // "num" field.
  int? _num;
  int get num => _num ?? 0;
  bool hasNum() => _num != null;

  void _initializeFields() {
    _rhlh = getDataList(snapshotData['rhlh']);
    _total = castToType<double>(snapshotData['total']);
    _user = snapshotData['USER'] as DocumentReference?;
    _lokeshn = snapshotData['LOKESHN'] as LatLng?;
    _idorder = castToType<int>(snapshotData['idorder']);
    _dataOrder = snapshotData['data_order'] as DateTime?;
    _cartext = snapshotData['cartext'] as String?;
    _carRev = snapshotData['carRev'] as DocumentReference?;
    _halh = snapshotData['halh'] is Halh
        ? snapshotData['halh']
        : deserializeEnum<Halh>(snapshotData['halh']);
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
    _num = castToType<int>(snapshotData['num']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('cart_maps');

  static Stream<CartMapsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CartMapsRecord.fromSnapshot(s));

  static Future<CartMapsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CartMapsRecord.fromSnapshot(s));

  static CartMapsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CartMapsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CartMapsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CartMapsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CartMapsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CartMapsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCartMapsRecordData({
  double? total,
  DocumentReference? user,
  LatLng? lokeshn,
  int? idorder,
  DateTime? dataOrder,
  String? cartext,
  DocumentReference? carRev,
  Halh? halh,
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
  int? num,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'total': total,
      'USER': user,
      'LOKESHN': lokeshn,
      'idorder': idorder,
      'data_order': dataOrder,
      'cartext': cartext,
      'carRev': carRev,
      'halh': halh,
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
      'num': num,
    }.withoutNulls,
  );

  return firestoreData;
}

class CartMapsRecordDocumentEquality implements Equality<CartMapsRecord> {
  const CartMapsRecordDocumentEquality();

  @override
  bool equals(CartMapsRecord? e1, CartMapsRecord? e2) {
    const listEquality = ListEquality();
    return listEquality.equals(e1?.rhlh, e2?.rhlh) &&
        e1?.total == e2?.total &&
        e1?.user == e2?.user &&
        e1?.lokeshn == e2?.lokeshn &&
        e1?.idorder == e2?.idorder &&
        e1?.dataOrder == e2?.dataOrder &&
        e1?.cartext == e2?.cartext &&
        e1?.carRev == e2?.carRev &&
        e1?.halh == e2?.halh &&
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
        e1?.num == e2?.num;
  }

  @override
  int hash(CartMapsRecord? e) => const ListEquality().hash([
        e?.rhlh,
        e?.total,
        e?.user,
        e?.lokeshn,
        e?.idorder,
        e?.dataOrder,
        e?.cartext,
        e?.carRev,
        e?.halh,
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
        e?.num
      ]);

  @override
  bool isValidKey(Object? o) => o is CartMapsRecord;
}

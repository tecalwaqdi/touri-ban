// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class CartItemStruct extends FFFirebaseStruct {
  CartItemStruct({
    DocumentReference? itemRef,
    double? totalPrice,
    String? dolh,
    String? naim,
    LatLng? loceshn,
    DocumentReference? ivill,
    String? ivillText,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _itemRef = itemRef,
        _totalPrice = totalPrice,
        _dolh = dolh,
        _naim = naim,
        _loceshn = loceshn,
        _ivill = ivill,
        _ivillText = ivillText,
        super(firestoreUtilData);

  // "itemRef" field.
  DocumentReference? _itemRef;
  DocumentReference? get itemRef => _itemRef;
  set itemRef(DocumentReference? val) => _itemRef = val;

  bool hasItemRef() => _itemRef != null;

  // "totalPrice" field.
  double? _totalPrice;
  double get totalPrice => _totalPrice ?? 0.0;
  set totalPrice(double? val) => _totalPrice = val;

  void incrementTotalPrice(double amount) => totalPrice = totalPrice + amount;

  bool hasTotalPrice() => _totalPrice != null;

  // "dolh" field.
  String? _dolh;
  String get dolh => _dolh ?? '';
  set dolh(String? val) => _dolh = val;

  bool hasDolh() => _dolh != null;

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  set naim(String? val) => _naim = val;

  bool hasNaim() => _naim != null;

  // "loceshn" field.
  LatLng? _loceshn;
  LatLng? get loceshn => _loceshn;
  set loceshn(LatLng? val) => _loceshn = val;

  bool hasLoceshn() => _loceshn != null;

  // "ivill" field.
  DocumentReference? _ivill;
  DocumentReference? get ivill => _ivill;
  set ivill(DocumentReference? val) => _ivill = val;

  bool hasIvill() => _ivill != null;

  // "ivill_text" field.
  String? _ivillText;
  String get ivillText => _ivillText ?? '';
  set ivillText(String? val) => _ivillText = val;

  bool hasIvillText() => _ivillText != null;

  static CartItemStruct fromMap(Map<String, dynamic> data) => CartItemStruct(
        itemRef: data['itemRef'] as DocumentReference?,
        totalPrice: castToType<double>(data['totalPrice']),
        dolh: data['dolh'] as String?,
        naim: data['naim'] as String?,
        loceshn: data['loceshn'] as LatLng?,
        ivill: data['ivill'] as DocumentReference?,
        ivillText: data['ivill_text'] as String?,
      );

  static CartItemStruct? maybeFromMap(dynamic data) =>
      data is Map ? CartItemStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'itemRef': _itemRef,
        'totalPrice': _totalPrice,
        'dolh': _dolh,
        'naim': _naim,
        'loceshn': _loceshn,
        'ivill': _ivill,
        'ivill_text': _ivillText,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'itemRef': serializeParam(
          _itemRef,
          ParamType.DocumentReference,
        ),
        'totalPrice': serializeParam(
          _totalPrice,
          ParamType.double,
        ),
        'dolh': serializeParam(
          _dolh,
          ParamType.String,
        ),
        'naim': serializeParam(
          _naim,
          ParamType.String,
        ),
        'loceshn': serializeParam(
          _loceshn,
          ParamType.LatLng,
        ),
        'ivill': serializeParam(
          _ivill,
          ParamType.DocumentReference,
        ),
        'ivill_text': serializeParam(
          _ivillText,
          ParamType.String,
        ),
      }.withoutNulls;

  static CartItemStruct fromSerializableMap(Map<String, dynamic> data) =>
      CartItemStruct(
        itemRef: deserializeParam(
          data['itemRef'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['mkan'],
        ),
        totalPrice: deserializeParam(
          data['totalPrice'],
          ParamType.double,
          false,
        ),
        dolh: deserializeParam(
          data['dolh'],
          ParamType.String,
          false,
        ),
        naim: deserializeParam(
          data['naim'],
          ParamType.String,
          false,
        ),
        loceshn: deserializeParam(
          data['loceshn'],
          ParamType.LatLng,
          false,
        ),
        ivill: deserializeParam(
          data['ivill'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['villages'],
        ),
        ivillText: deserializeParam(
          data['ivill_text'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'CartItemStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CartItemStruct &&
        itemRef == other.itemRef &&
        totalPrice == other.totalPrice &&
        dolh == other.dolh &&
        naim == other.naim &&
        loceshn == other.loceshn &&
        ivill == other.ivill &&
        ivillText == other.ivillText;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([itemRef, totalPrice, dolh, naim, loceshn, ivill, ivillText]);
}

CartItemStruct createCartItemStruct({
  DocumentReference? itemRef,
  double? totalPrice,
  String? dolh,
  String? naim,
  LatLng? loceshn,
  DocumentReference? ivill,
  String? ivillText,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    CartItemStruct(
      itemRef: itemRef,
      totalPrice: totalPrice,
      dolh: dolh,
      naim: naim,
      loceshn: loceshn,
      ivill: ivill,
      ivillText: ivillText,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

CartItemStruct? updateCartItemStruct(
  CartItemStruct? cartItem, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    cartItem
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addCartItemStructData(
  Map<String, dynamic> firestoreData,
  CartItemStruct? cartItem,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (cartItem == null) {
    return;
  }
  if (cartItem.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && cartItem.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final cartItemData = getCartItemFirestoreData(cartItem, forFieldValue);
  final nestedData = cartItemData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = cartItem.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getCartItemFirestoreData(
  CartItemStruct? cartItem, [
  bool forFieldValue = false,
]) {
  if (cartItem == null) {
    return {};
  }
  final firestoreData = mapToFirestore(cartItem.toMap());

  // Add any Firestore field values
  cartItem.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getCartItemListFirestoreData(
  List<CartItemStruct>? cartItems,
) =>
    cartItems?.map((e) => getCartItemFirestoreData(e, true)).toList() ?? [];

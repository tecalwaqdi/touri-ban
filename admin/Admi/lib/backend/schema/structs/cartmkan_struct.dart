// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class CartmkanStruct extends FFFirebaseStruct {
  CartmkanStruct({
    DocumentReference? rhlh,
    bool? actev,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _rhlh = rhlh,
        _actev = actev,
        super(firestoreUtilData);

  // "rhlh" field.
  DocumentReference? _rhlh;
  DocumentReference? get rhlh => _rhlh;
  set rhlh(DocumentReference? val) => _rhlh = val;

  bool hasRhlh() => _rhlh != null;

  // "actev" field.
  bool? _actev;
  bool get actev => _actev ?? false;
  set actev(bool? val) => _actev = val;

  bool hasActev() => _actev != null;

  static CartmkanStruct fromMap(Map<String, dynamic> data) => CartmkanStruct(
        rhlh: data['rhlh'] as DocumentReference?,
        actev: data['actev'] as bool?,
      );

  static CartmkanStruct? maybeFromMap(dynamic data) =>
      data is Map ? CartmkanStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'rhlh': _rhlh,
        'actev': _actev,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'rhlh': serializeParam(
          _rhlh,
          ParamType.DocumentReference,
        ),
        'actev': serializeParam(
          _actev,
          ParamType.bool,
        ),
      }.withoutNulls;

  static CartmkanStruct fromSerializableMap(Map<String, dynamic> data) =>
      CartmkanStruct(
        rhlh: deserializeParam(
          data['rhlh'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['mkan'],
        ),
        actev: deserializeParam(
          data['actev'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'CartmkanStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CartmkanStruct &&
        rhlh == other.rhlh &&
        actev == other.actev;
  }

  @override
  int get hashCode => const ListEquality().hash([rhlh, actev]);
}

CartmkanStruct createCartmkanStruct({
  DocumentReference? rhlh,
  bool? actev,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    CartmkanStruct(
      rhlh: rhlh,
      actev: actev,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

CartmkanStruct? updateCartmkanStruct(
  CartmkanStruct? cartmkan, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    cartmkan
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addCartmkanStructData(
  Map<String, dynamic> firestoreData,
  CartmkanStruct? cartmkan,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (cartmkan == null) {
    return;
  }
  if (cartmkan.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && cartmkan.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final cartmkanData = getCartmkanFirestoreData(cartmkan, forFieldValue);
  final nestedData = cartmkanData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = cartmkan.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getCartmkanFirestoreData(
  CartmkanStruct? cartmkan, [
  bool forFieldValue = false,
]) {
  if (cartmkan == null) {
    return {};
  }
  final firestoreData = mapToFirestore(cartmkan.toMap());

  // Add any Firestore field values
  cartmkan.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getCartmkanListFirestoreData(
  List<CartmkanStruct>? cartmkans,
) =>
    cartmkans?.map((e) => getCartmkanFirestoreData(e, true)).toList() ?? [];

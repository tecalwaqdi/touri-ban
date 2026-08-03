// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class IsAddRhlhStruct extends FFFirebaseStruct {
  IsAddRhlhStruct({
    DocumentReference? idrhlh,
    bool? add,
    List<DocumentReference>? rhlh,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _idrhlh = idrhlh,
        _add = add,
        _rhlh = rhlh,
        super(firestoreUtilData);

  // "idrhlh" field.
  DocumentReference? _idrhlh;
  DocumentReference? get idrhlh => _idrhlh;
  set idrhlh(DocumentReference? val) => _idrhlh = val;

  bool hasIdrhlh() => _idrhlh != null;

  // "add" field.
  bool? _add;
  bool get add => _add ?? false;
  set add(bool? val) => _add = val;

  bool hasAdd() => _add != null;

  // "Rhlh" field.
  List<DocumentReference>? _rhlh;
  List<DocumentReference> get rhlh => _rhlh ?? const [];
  set rhlh(List<DocumentReference>? val) => _rhlh = val;

  void updateRhlh(Function(List<DocumentReference>) updateFn) {
    updateFn(_rhlh ??= []);
  }

  bool hasRhlh() => _rhlh != null;

  static IsAddRhlhStruct fromMap(Map<String, dynamic> data) => IsAddRhlhStruct(
        idrhlh: data['idrhlh'] as DocumentReference?,
        add: data['add'] as bool?,
        rhlh: getDataList(data['Rhlh']),
      );

  static IsAddRhlhStruct? maybeFromMap(dynamic data) => data is Map
      ? IsAddRhlhStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'idrhlh': _idrhlh,
        'add': _add,
        'Rhlh': _rhlh,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'idrhlh': serializeParam(
          _idrhlh,
          ParamType.DocumentReference,
        ),
        'add': serializeParam(
          _add,
          ParamType.bool,
        ),
        'Rhlh': serializeParam(
          _rhlh,
          ParamType.DocumentReference,
          isList: true,
        ),
      }.withoutNulls;

  static IsAddRhlhStruct fromSerializableMap(Map<String, dynamic> data) =>
      IsAddRhlhStruct(
        idrhlh: deserializeParam(
          data['idrhlh'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['mkan'],
        ),
        add: deserializeParam(
          data['add'],
          ParamType.bool,
          false,
        ),
        rhlh: deserializeParam<DocumentReference>(
          data['Rhlh'],
          ParamType.DocumentReference,
          true,
          collectionNamePath: ['mkan'],
        ),
      );

  @override
  String toString() => 'IsAddRhlhStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is IsAddRhlhStruct &&
        idrhlh == other.idrhlh &&
        add == other.add &&
        listEquality.equals(rhlh, other.rhlh);
  }

  @override
  int get hashCode => const ListEquality().hash([idrhlh, add, rhlh]);
}

IsAddRhlhStruct createIsAddRhlhStruct({
  DocumentReference? idrhlh,
  bool? add,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    IsAddRhlhStruct(
      idrhlh: idrhlh,
      add: add,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

IsAddRhlhStruct? updateIsAddRhlhStruct(
  IsAddRhlhStruct? isAddRhlh, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    isAddRhlh
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addIsAddRhlhStructData(
  Map<String, dynamic> firestoreData,
  IsAddRhlhStruct? isAddRhlh,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (isAddRhlh == null) {
    return;
  }
  if (isAddRhlh.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && isAddRhlh.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final isAddRhlhData = getIsAddRhlhFirestoreData(isAddRhlh, forFieldValue);
  final nestedData = isAddRhlhData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = isAddRhlh.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getIsAddRhlhFirestoreData(
  IsAddRhlhStruct? isAddRhlh, [
  bool forFieldValue = false,
]) {
  if (isAddRhlh == null) {
    return {};
  }
  final firestoreData = mapToFirestore(isAddRhlh.toMap());

  // Add any Firestore field values
  isAddRhlh.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getIsAddRhlhListFirestoreData(
  List<IsAddRhlhStruct>? isAddRhlhs,
) =>
    isAddRhlhs?.map((e) => getIsAddRhlhFirestoreData(e, true)).toList() ?? [];

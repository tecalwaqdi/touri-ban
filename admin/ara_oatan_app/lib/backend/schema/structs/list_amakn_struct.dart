// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class ListAmaknStruct extends FFFirebaseStruct {
  ListAmaknStruct({
    String? naim,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _naim = naim,
        super(firestoreUtilData);

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  set naim(String? val) => _naim = val;

  bool hasNaim() => _naim != null;

  static ListAmaknStruct fromMap(Map<String, dynamic> data) => ListAmaknStruct(
        naim: data['naim'] as String?,
      );

  static ListAmaknStruct? maybeFromMap(dynamic data) => data is Map
      ? ListAmaknStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'naim': _naim,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'naim': serializeParam(
          _naim,
          ParamType.String,
        ),
      }.withoutNulls;

  static ListAmaknStruct fromSerializableMap(Map<String, dynamic> data) =>
      ListAmaknStruct(
        naim: deserializeParam(
          data['naim'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ListAmaknStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ListAmaknStruct && naim == other.naim;
  }

  @override
  int get hashCode => const ListEquality().hash([naim]);
}

ListAmaknStruct createListAmaknStruct({
  String? naim,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ListAmaknStruct(
      naim: naim,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ListAmaknStruct? updateListAmaknStruct(
  ListAmaknStruct? listAmakn, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    listAmakn
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addListAmaknStructData(
  Map<String, dynamic> firestoreData,
  ListAmaknStruct? listAmakn,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (listAmakn == null) {
    return;
  }
  if (listAmakn.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && listAmakn.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final listAmaknData = getListAmaknFirestoreData(listAmakn, forFieldValue);
  final nestedData = listAmaknData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = listAmakn.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getListAmaknFirestoreData(
  ListAmaknStruct? listAmakn, [
  bool forFieldValue = false,
]) {
  if (listAmakn == null) {
    return {};
  }
  final firestoreData = mapToFirestore(listAmakn.toMap());

  // Add any Firestore field values
  listAmakn.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getListAmaknListFirestoreData(
  List<ListAmaknStruct>? listAmakns,
) =>
    listAmakns?.map((e) => getListAmaknFirestoreData(e, true)).toList() ?? [];

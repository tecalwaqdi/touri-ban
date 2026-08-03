// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class DatarhlhStruct extends FFFirebaseStruct {
  DatarhlhStruct({
    String? naim,
    String? osf,
    LatLng? map,
    DocumentReference? order2,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _naim = naim,
        _osf = osf,
        _map = map,
        _order2 = order2,
        super(firestoreUtilData);

  // "naim" field.
  String? _naim;
  String get naim => _naim ?? '';
  set naim(String? val) => _naim = val;

  bool hasNaim() => _naim != null;

  // "osf" field.
  String? _osf;
  String get osf => _osf ?? '';
  set osf(String? val) => _osf = val;

  bool hasOsf() => _osf != null;

  // "map" field.
  LatLng? _map;
  LatLng? get map => _map;
  set map(LatLng? val) => _map = val;

  bool hasMap() => _map != null;

  // "order2" field.
  DocumentReference? _order2;
  DocumentReference? get order2 => _order2;
  set order2(DocumentReference? val) => _order2 = val;

  bool hasOrder2() => _order2 != null;

  static DatarhlhStruct fromMap(Map<String, dynamic> data) => DatarhlhStruct(
        naim: data['naim'] as String?,
        osf: data['osf'] as String?,
        map: data['map'] as LatLng?,
        order2: data['order2'] as DocumentReference?,
      );

  static DatarhlhStruct? maybeFromMap(dynamic data) =>
      data is Map ? DatarhlhStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'naim': _naim,
        'osf': _osf,
        'map': _map,
        'order2': _order2,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'naim': serializeParam(
          _naim,
          ParamType.String,
        ),
        'osf': serializeParam(
          _osf,
          ParamType.String,
        ),
        'map': serializeParam(
          _map,
          ParamType.LatLng,
        ),
        'order2': serializeParam(
          _order2,
          ParamType.DocumentReference,
        ),
      }.withoutNulls;

  static DatarhlhStruct fromSerializableMap(Map<String, dynamic> data) =>
      DatarhlhStruct(
        naim: deserializeParam(
          data['naim'],
          ParamType.String,
          false,
        ),
        osf: deserializeParam(
          data['osf'],
          ParamType.String,
          false,
        ),
        map: deserializeParam(
          data['map'],
          ParamType.LatLng,
          false,
        ),
        order2: deserializeParam(
          data['order2'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['order2'],
        ),
      );

  @override
  String toString() => 'DatarhlhStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DatarhlhStruct &&
        naim == other.naim &&
        osf == other.osf &&
        map == other.map &&
        order2 == other.order2;
  }

  @override
  int get hashCode => const ListEquality().hash([naim, osf, map, order2]);
}

DatarhlhStruct createDatarhlhStruct({
  String? naim,
  String? osf,
  LatLng? map,
  DocumentReference? order2,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DatarhlhStruct(
      naim: naim,
      osf: osf,
      map: map,
      order2: order2,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DatarhlhStruct? updateDatarhlhStruct(
  DatarhlhStruct? datarhlh, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    datarhlh
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDatarhlhStructData(
  Map<String, dynamic> firestoreData,
  DatarhlhStruct? datarhlh,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (datarhlh == null) {
    return;
  }
  if (datarhlh.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && datarhlh.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final datarhlhData = getDatarhlhFirestoreData(datarhlh, forFieldValue);
  final nestedData = datarhlhData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = datarhlh.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDatarhlhFirestoreData(
  DatarhlhStruct? datarhlh, [
  bool forFieldValue = false,
]) {
  if (datarhlh == null) {
    return {};
  }
  final firestoreData = mapToFirestore(datarhlh.toMap());

  // Add any Firestore field values
  datarhlh.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDatarhlhListFirestoreData(
  List<DatarhlhStruct>? datarhlhs,
) =>
    datarhlhs?.map((e) => getDatarhlhFirestoreData(e, true)).toList() ?? [];
